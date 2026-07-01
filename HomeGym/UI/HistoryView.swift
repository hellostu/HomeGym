import SwiftUI
import SwiftData
import Charts

/// Per-exercise history: last performance + a top-weight trend line.
struct HistoryView: View {
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
