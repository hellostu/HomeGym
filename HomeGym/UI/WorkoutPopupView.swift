import SwiftUI
import SwiftData

/// The floating prompt: shows the suggested exercise + target, lets Stu log each set,
/// then finish, skip, or snooze.
struct WorkoutPopupView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.openURL) private var openURL

    @StateObject private var restTimer = RestTimer()
    @State private var weight: Double = 0
    @State private var reps: Int = 8
    @State private var primedFor: PersistentIdentifier?
    @State private var showHowTo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    targetCard
                    warmupCue
                    howTo
                    loggedSets
                }
            }
            entryRow
            restRow
            actions
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay { celebrationOverlay }
        .onAppear(perform: primeIfNeeded)
        .onChange(of: exercise?.persistentModelID) { primeIfNeeded() }
    }

    private var exercise: Exercise? { coordinator.activeSession?.exercise }
    private var suggestion: Suggestion? { coordinator.currentSuggestion }
    /// Weight shown "each" only for exercises using a dumbbell in each hand.
    private var pairedDumbbells: Bool {
        exercise?.equipment == .adjustableDumbbells && exercise?.usesSingleDumbbell == false
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: exercise?.muscleGroup.symbolName ?? "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise?.name ?? "Workout")
                    .font(.title2.weight(.semibold))
                if let exercise {
                    Text("\(exercise.muscleGroup.displayName) · \(exercise.equipment.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var warmupCue: some View {
        if exercise?.equipment == .barbell {
            Label("Do 1–2 light warm-up sets before your working sets.", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let s = suggestion {
                Text(targetLine(s))
                    .font(.headline)
                if exercise?.isUnilateral == true {
                    Label("Do both sides for each set", systemImage: "arrow.left.arrow.right")
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
                Text(s.rationale)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.5)))
    }

    private var eachSuffix: String { pairedDumbbells ? " each" : "" }

    private func targetLine(_ s: Suggestion) -> String {
        let weighted = (exercise?.equipment.isWeighted ?? false) && s.weight > 0
        let w = weighted ? " @ \(ProgressionEngine.format(s.weight)) kg\(eachSuffix)" : ""
        let perSide = exercise?.isUnilateral == true ? " per side" : ""
        return "Target: \(s.sets) × \(s.reps) reps\(perSide)\(w)"
    }

    @ViewBuilder
    private var howTo: some View {
        let steps = exercise?.instructions ?? []
        VStack(alignment: .leading, spacing: 8) {
            if !steps.isEmpty {
                DisclosureGroup(isExpanded: $showHowTo) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(index + 1).")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                Text(step)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if let tip = exercise?.formTip, !tip.isEmpty {
                            Label(tip, systemImage: "lightbulb.fill")
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .font(.callout)
                    .padding(.top, 6)
                } label: {
                    Text("How to do it").font(.headline)
                }
            }
            if let url = exercise?.demoVideoURL {
                Button {
                    openURL(url)
                } label: {
                    Label("Watch demo", systemImage: "play.rectangle.fill")
                }
            }
        }
    }

    private var loggedSets: some View {
        let sets = coordinator.activeSession?.orderedSets ?? []
        return VStack(alignment: .leading, spacing: 8) {
            if !sets.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(setDescription(set))
                                .monospacedDigit()
                        }
                        .font(.callout)
                    }
                }
                HStack {
                    Button {
                        coordinator.repeatLastSet()
                        restTimer.start(seconds: coordinator.settings.restSeconds)
                    } label: {
                        Label("Repeat last set", systemImage: "arrow.clockwise")
                    }
                    Spacer()
                    Button(role: .destructive) {
                        coordinator.removeLastSet()
                    } label: {
                        Label("Undo last", systemImage: "arrow.uturn.backward")
                    }
                }
                .font(.callout)
            }
        }
    }

    private func setDescription(_ set: WorkoutSet) -> String {
        let weighted = (exercise?.equipment.isWeighted ?? false) && set.weight > 0
        return weighted
            ? "\(set.reps) reps @ \(ProgressionEngine.format(set.weight)) kg\(eachSuffix)"
            : "\(set.reps) reps"
    }

    private var entryRow: some View {
        let weighted = exercise?.equipment.isWeighted ?? false
        return HStack(spacing: 12) {
            if weighted, let equipment = exercise?.equipment {
                weightStepper(for: equipment)
            }
            labeledStepper(title: "reps", value: Binding(
                get: { Double(reps) },
                set: { reps = Int($0) }
            ), step: 1, format: "%.0f")
            Button {
                coordinator.logSet(weight: weighted ? weight : 0, reps: reps)
                restTimer.start(seconds: coordinator.settings.restSeconds)
            } label: {
                Label("Log set", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// Rest countdown between sets. Auto-starts when a set is logged; can also be
    /// started manually. Shows remaining time + progress with quick +15s / Skip controls.
    @ViewBuilder
    private var restRow: some View {
        if restTimer.isRunning {
            HStack(spacing: 12) {
                Image(systemName: "timer").foregroundStyle(.tint)
                Text(RestTimer.format(restTimer.remaining))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 48, alignment: .leading)
                ProgressView(value: restTimer.progress)
                Button("+15s") { restTimer.add(seconds: 15) }
                Button("Skip") { restTimer.stop() }
            }
        } else {
            Button {
                restTimer.start(seconds: coordinator.settings.restSeconds)
            } label: {
                Label("Start rest (\(coordinator.settings.restSeconds)s)", systemImage: "timer")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    /// Weight stepper that snaps to loads the equipment can actually make (dumbbell
    /// ladder rungs, or empty-bar + plate-pair steps for the barbell / EZ bar).
    private func weightStepper(for equipment: Equipment) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("kg").font(.caption).foregroundStyle(.secondary)
            Stepper {
                Text(ProgressionEngine.format(weight))
                    .monospacedDigit()
                    .frame(minWidth: 44, alignment: .leading)
            } onIncrement: {
                weight = equipment.nextWeight(above: weight) ?? weight
            } onDecrement: {
                weight = equipment.previousWeight(below: weight) ?? weight
            }
        }
    }

    private func labeledStepper(title: String, value: Binding<Double>, step: Double, format: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Stepper(value: value, in: 0...999, step: step) {
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .frame(minWidth: 44, alignment: .leading)
            }
        }
    }

    private var actions: some View {
        let noSets = coordinator.activeSession?.sets.isEmpty ?? true
        return HStack {
            Button(role: .cancel) { coordinator.skipSession() } label: {
                Text("Skip")
            }
            if noSets {
                Button("Swap") { coordinator.swapExercise() }
            }
            Button("Snooze 15m") { coordinator.snooze(minutes: 15) }
            Spacer()
            Button {
                coordinator.finishSession()
            } label: {
                Text("Done")
            }
            .buttonStyle(.borderedProminent)
            .disabled(noSets)
        }
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        if let message = coordinator.celebration {
            ZStack {
                Color.black.opacity(0.35).ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("🎉").font(.system(size: 52))
                    Text(message)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    if let name = exercise?.name {
                        Text(name).foregroundStyle(.secondary)
                    }
                    Button("Nice! 💪") { coordinator.dismissCelebration() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
                .padding(28)
                .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
                .padding(30)
            }
        }
    }

    /// Primes the weight/reps entry from the suggestion (or the last logged set when
    /// resuming). Re-runs when the exercise changes — e.g. after a Swap.
    private func primeIfNeeded() {
        let id = exercise?.persistentModelID
        guard id != primedFor, let s = suggestion else { return }
        primedFor = id
        if let last = coordinator.activeSession?.orderedSets.last {
            weight = last.weight
            reps = last.reps
        } else if let equipment = exercise?.equipment, equipment.isWeighted, s.weight > 0 {
            weight = equipment.snap(s.weight)
            reps = s.reps
        } else {
            weight = s.weight
            reps = s.reps
        }
    }
}
