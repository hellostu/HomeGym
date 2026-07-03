import SwiftUI
import SwiftData
import Charts

/// History window: a holistic "This Week" overview and a per-exercise browser.
struct HistoryView: View {
    private enum Tab: Hashable { case overview, exercises }
    @State private var tab: Tab = .overview

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("This Week").tag(Tab.overview)
                Text("Exercises").tag(Tab.exercises)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 320)
            .padding(12)

            Divider()

            switch tab {
            case .overview: OverviewTab()
            case .exercises: ExerciseHistoryTab()
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

/// The weekly muscle heat-map + global stat tiles.
private struct OverviewTab: View {
    @Query(filter: #Predicate<SnackSession> { $0.completed }, sort: \SnackSession.date)
    private var completed: [SnackSession]

    var body: some View {
        let stats = StatsCalculator.weekly(completed: completed, now: Date())
        let streak = StatsCalculator.currentStreak(completed: completed, now: Date())

        ScrollView {
            VStack(spacing: 28) {
                statTiles(stats, streak: streak)

                VStack(spacing: 12) {
                    Text("This week's muscle map").font(.headline)
                    BodyHeatMap(stats: stats)
                    HeatLegend()
                }

                perGroupBreakdown(stats)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    private func statTiles(_ stats: WeeklyStats, streak: Int) -> some View {
        let volume = stats.totalVolumeKg
        let volumeText = volume >= 1000
            ? String(format: "%.1ft", volume / 1000)
            : "\(Int(volume.rounded())) kg"
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            tile("Workouts", "\(stats.workouts)", "figure.strengthtraining.traditional")
            tile("Sets", "\(stats.totalSets)", "list.number")
            tile("Reps", "\(stats.totalReps)", "repeat")
            tile("Volume", volumeText, "scalemass")
            tile("Active days", "\(stats.activeDays)", "calendar")
            tile("Streak", "\(streak)\(streak == 1 ? " day" : " days")", "flame.fill")
        }
    }

    private func tile(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            Text(value).font(.title2.weight(.semibold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.4)))
    }

    private func perGroupBreakdown(_ stats: WeeklyStats) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sets by muscle group").font(.headline)
            Text("Target sets per week are weighted — bigger muscles need more.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(MuscleGroup.allCases) { group in
                HStack {
                    Text(group.displayName)
                    Spacer()
                    Text("\(stats.sets(for: group)) / \(group.weeklySetTarget)")
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                .font(.callout)
            }
        }
        .frame(maxWidth: 360)
    }
}

/// The original per-exercise history: last performance + a top-weight trend line.
private struct ExerciseHistoryTab: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(filter: #Predicate<SnackSession> { $0.completed }, sort: \SnackSession.date)
    private var completedSessions: [SnackSession]

    @State private var selection: Exercise?

    var body: some View {
        NavigationSplitView {
            List(trainedExercises, selection: $selection) { exercise in
                NavigationLink(value: exercise) {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                        Text(exercise.muscleGroup.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Exercises")
            .frame(minWidth: 220)
        } detail: {
            if let selection {
                detail(for: selection)
            } else {
                ContentUnavailableView(
                    "Select an exercise",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Your logged workouts will show here.")
                )
            }
        }
        .frame(minWidth: 640, minHeight: 420)
    }

    /// Only exercises with at least one completed session.
    private var trainedExercises: [Exercise] {
        let trainedIDs = Set(completedSessions.compactMap { $0.exercise?.persistentModelID })
        return exercises.filter { trainedIDs.contains($0.persistentModelID) }
    }

    private func sessions(for exercise: Exercise) -> [SnackSession] {
        completedSessions
            .filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
            .sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private func detail(for exercise: Exercise) -> some View {
        let sessions = sessions(for: exercise)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(exercise.name).font(.largeTitle.bold())

                if exercise.equipment.isWeighted {
                    chart(for: sessions)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent sessions").font(.headline)
                    ForEach(sessions.reversed()) { session in
                        sessionRow(session, weighted: exercise.equipment.isWeighted)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func chart(for sessions: [SnackSession]) -> some View {
        Chart(sessions) { session in
            LineMark(
                x: .value("Date", session.date),
                y: .value("Top weight (kg)", session.topWeight)
            )
            .symbol(.circle)
        }
        .frame(height: 200)
        .chartYAxisLabel("Top weight (kg)")
    }

    private func sessionRow(_ session: SnackSession, weighted: Bool) -> some View {
        HStack(alignment: .top) {
            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .foregroundStyle(.secondary)
                .frame(width: 160, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(session.orderedSets.enumerated()), id: \.offset) { i, set in
                    Text(weighted
                         ? "Set \(i + 1): \(set.reps) × \(ProgressionEngine.format(set.weight)) kg"
                         : "Set \(i + 1): \(set.reps) reps")
                        .monospacedDigit()
                }
            }
        }
        .font(.callout)
    }
}
