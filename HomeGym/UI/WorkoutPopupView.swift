import SwiftUI

/// The floating prompt: shows the suggested exercise + target, lets Stu log each set,
/// then finish, skip, or snooze.
struct WorkoutPopupView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.openURL) private var openURL

    @State private var weight: Double = 0
    @State private var reps: Int = 8
    @State private var didPrime = false
    @State private var showHowTo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    targetCard
                    howTo
                    loggedSets
                }
            }
            entryRow
            actions
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: primeFromSuggestion)
    }

    private var exercise: Exercise? { coordinator.activeSession?.exercise }
    private var suggestion: Suggestion? { coordinator.currentSuggestion }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: exercise?.muscleGroup.symbolName ?? "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise?.name ?? "Workout")
                    .font(.title2.weight(.semibold))
                if let group = exercise?.muscleGroup.displayName {
                    Text(group).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let s = suggestion {
                Text(targetLine(s))
                    .font(.headline)
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

    private func targetLine(_ s: Suggestion) -> String {
        let weighted = (exercise?.equipment.isWeighted ?? false) && s.weight > 0
        let w = weighted ? " @ \(ProgressionEngine.format(s.weight)) kg" : ""
        return "Target: \(s.sets) × \(s.reps) reps\(w)"
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
        return VStack(alignment: .leading, spacing: 4) {
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
    }

    private func setDescription(_ set: WorkoutSet) -> String {
        let weighted = (exercise?.equipment.isWeighted ?? false) && set.weight > 0
        return weighted
            ? "\(set.reps) reps @ \(ProgressionEngine.format(set.weight)) kg"
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
            } label: {
                Label("Log set", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
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
        HStack {
            Button(role: .cancel) { coordinator.skipSession() } label: {
                Text("Skip")
            }
            Button("Snooze 15m") { coordinator.snooze(minutes: 15) }
            Spacer()
            if let last = coordinator.activeSession?.orderedSets.last, last.reps > 0 {
                Button("Undo set") { coordinator.removeLastSet() }
            }
            Button {
                coordinator.finishSession()
            } label: {
                Text("Done")
            }
            .buttonStyle(.borderedProminent)
            .disabled((coordinator.activeSession?.sets.isEmpty ?? true))
        }
    }

    private func primeFromSuggestion() {
        guard !didPrime, let s = suggestion else { return }
        // Resuming a session with logged sets: continue from the last set's numbers.
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
        didPrime = true
    }
}
