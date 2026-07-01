import Foundation
import SwiftData
import SwiftUI

/// The app's brain. Owns the SwiftData context and the supporting services, decides
/// which exercise to prompt, shows the popup, records results, and reschedules.
@MainActor
final class AppCoordinator: ObservableObject {
    let context: ModelContext
    let calendar = CalendarService()
    let notifications = NotificationService()
    let scheduler = WorkoutScheduler()
    private let windowController = WorkoutWindowController()

    /// The session currently being logged in the popup, plus the suggestion shown.
    @Published var activeSession: SnackSession?
    @Published var currentSuggestion: Suggestion?

    private var didBootstrap = false

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Lifecycle

    func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true

        ExerciseLibrary.seedIfNeeded(context)
        ExerciseLibrary.ensureGuidance(context)
        calendar.refreshAuthorization()
        Task { await notifications.refreshAuthorization() }

        scheduler.isBusy = { [weak self] date in
            guard let self, self.settings.calendarBusyIsBlocking else { return false }
            return self.calendar.isBusy(at: date)
        }
        scheduler.onFire = { [weak self] in self?.handleScheduledFire() }
        reloadSchedule()
    }

    /// Re-reads settings and arms the next prompt. Call after any settings change.
    func reloadSchedule() {
        let s = settings
        scheduler.params = SchedulingParams(
            workStartHour: s.workStartHour,
            workEndHour: s.workEndHour,
            targetWorkoutsPerDay: s.targetWorkoutsPerDay,
            minGapMinutes: s.minGapMinutes,
            weekdaysOnly: s.weekdaysOnly
        )
        scheduler.reschedule(paused: isPausedNow)
    }

    // MARK: - Firing

    private func handleScheduledFire() {
        // If a meeting started since scheduling, defer to just after it.
        if settings.calendarBusyIsBlocking, let busyEnd = calendar.busyEndDate(at: .now) {
            scheduler.reschedule(now: busyEnd.addingTimeInterval(60))
            return
        }
        startWorkoutNow(postNotification: true)
    }

    /// Present a workout immediately (menu "Do a workout now" or a fired slot).
    /// Resumes the most recent unfinished session so you can pick up where you left
    /// off; only plans a fresh workout when the last one was completed or skipped.
    func startWorkoutNow(postNotification: Bool = false) {
        let session: SnackSession
        let suggestion: Suggestion

        if let existing = activeSession ?? resumableSession(), let exercise = existing.exercise {
            // Resume: rebuild the suggestion for the same exercise (its completed
            // history is unchanged, so this reproduces the original targets).
            session = existing
            suggestion = ProgressionEngine.suggest(for: exercise, history: completedSessions(for: exercise))
        } else {
            guard let plan = planWorkout() else { return }
            let fresh = SnackSession(
                exercise: plan.exercise,
                targetSets: plan.suggestion.sets,
                targetReps: plan.suggestion.reps,
                targetWeight: plan.suggestion.weight
            )
            context.insert(fresh)
            try? context.save()
            session = fresh
            suggestion = plan.suggestion
        }

        activeSession = session
        currentSuggestion = suggestion

        if postNotification, let name = session.exercise?.name {
            let done = session.sets.count
            let progress = done > 0 ? " (\(done)/\(suggestion.sets) done)" : ""
            let perSide = session.exercise?.isUnilateral == true ? " per side" : ""
            notifications.postWorkoutPrompt(
                title: "Time for a snack workout 💪",
                body: "\(suggestion.sets)×\(suggestion.reps) \(name)\(perSide)\(progress)"
            )
        }
        windowController.show(coordinator: self)
    }

    // MARK: - Planning

    struct WorkoutPlan {
        let exercise: Exercise
        let suggestion: Suggestion
    }

    /// Picks the least-recently-trained enabled muscle group, then the least-recently
    /// performed exercise within it, and builds a progression suggestion.
    func planWorkout() -> WorkoutPlan? {
        let enabledGroups = settings.enabledMuscleGroups
        let candidates = allExercises().filter { $0.isEnabled && enabledGroups.contains($0.muscleGroup) }
        guard !candidates.isEmpty else { return nil }

        // Group -> most recent training date (nil = never trained, sorts first).
        let byGroup = Dictionary(grouping: candidates, by: \.muscleGroup)
        let group = byGroup.min { lhs, rhs in
            lastTrained(lhs.value) < lastTrained(rhs.value)
        }?.key

        let pool = group.map { g in candidates.filter { $0.muscleGroup == g } } ?? candidates
        guard let exercise = pool.min(by: { ($0.lastPerformed ?? .distantPast) < ($1.lastPerformed ?? .distantPast) }) else {
            return nil
        }

        let history = completedSessions(for: exercise)
        let suggestion = ProgressionEngine.suggest(for: exercise, history: history)
        return WorkoutPlan(exercise: exercise, suggestion: suggestion)
    }

    private func lastTrained(_ exercises: [Exercise]) -> Date {
        exercises.compactMap(\.lastPerformed).max() ?? .distantPast
    }

    // MARK: - Recording results

    func logSet(weight: Double, reps: Int) {
        guard let session = activeSession else { return }
        let set = WorkoutSet(weight: weight, reps: reps, order: session.sets.count, session: session)
        context.insert(set)
        session.sets.append(set)
        try? context.save()
    }

    func removeLastSet() {
        guard let session = activeSession, let last = session.orderedSets.last else { return }
        session.sets.removeAll { $0 === last }
        context.delete(last)
        try? context.save()
    }

    func finishSession() {
        guard let session = activeSession else { return }
        session.completed = !session.sets.isEmpty
        session.exercise?.lastPerformed = .now
        try? context.save()
        endActive()
    }

    func skipSession() {
        guard let session = activeSession else { return }
        session.skipped = true
        try? context.save()
        endActive()
    }

    func snooze(minutes: Int = 15) {
        // Discard the just-created (empty) session and re-arm sooner.
        if let session = activeSession, session.sets.isEmpty {
            context.delete(session)
            try? context.save()
        }
        endActive(reschedule: false)
        scheduler.snooze(minutes: minutes)
    }

    private func endActive(reschedule: Bool = true) {
        windowController.close()
        activeSession = nil
        currentSuggestion = nil
        if reschedule { reloadSchedule() }
    }

    func pauseForToday() {
        let end = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
        settings.pausedUntil = end
        try? context.save()
        scheduler.pause()
    }

    func resume() {
        settings.pausedUntil = nil
        try? context.save()
        reloadSchedule()
    }

    var isPausedNow: Bool {
        guard let until = settings.pausedUntil else { return false }
        return until > .now
    }

    // MARK: - Data access

    private(set) lazy var settings: AppSettings = fetchOrCreateSettings()

    private func fetchOrCreateSettings() -> AppSettings {
        if let existing = try? context.fetch(FetchDescriptor<AppSettings>()).first {
            return existing
        }
        let created = AppSettings()
        context.insert(created)
        try? context.save()
        return created
    }

    func allExercises() -> [Exercise] {
        (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
    }

    private func completedSessions(for exercise: Exercise) -> [SnackSession] {
        let all = (try? context.fetch(FetchDescriptor<SnackSession>())) ?? []
        return all.filter { $0.completed && $0.exercise?.persistentModelID == exercise.persistentModelID }
    }

    /// The most recent unfinished session (neither completed nor skipped) whose exercise
    /// still exists — what "Do a workout now" resumes so you can pick up where you left off.
    private func resumableSession() -> SnackSession? {
        let all = (try? context.fetch(FetchDescriptor<SnackSession>())) ?? []
        return SessionResume.candidate(from: all)
    }
}
