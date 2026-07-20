import SwiftUI
import SwiftData
import Charts

/// History window: a "This Week" overview, multi-week trends, and a per-exercise browser.
struct HistoryView: View {
    private enum Tab: Hashable { case overview, trends, exercises }
    @State private var tab: Tab = .overview

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("This Week").tag(Tab.overview)
                Text("Trends").tag(Tab.trends)
                Text("Exercises").tag(Tab.exercises)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 380)
            .padding(12)

            Divider()

            switch tab {
            case .overview: OverviewTab()
            case .trends: TrendsTab()
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
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())
            .map { StatsCalculator.weekly(completed: completed, now: $0) }
        let change = TrendsCalculator.percentChange(
            current: stats.totalVolumeKg,
            previous: lastWeek?.totalVolumeKg ?? 0
        )
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            StatTile(title: "Workouts", value: "\(stats.workouts)", symbol: "figure.strengthtraining.traditional")
            StatTile(title: "Sets", value: "\(stats.totalSets)", symbol: "list.number")
            StatTile(title: "Reps", value: "\(stats.totalReps)", symbol: "repeat")
            StatTile(
                title: "Volume",
                value: StatTile.volumeText(stats.totalVolumeKg),
                symbol: "scalemass",
                caption: change.map { String(format: "%+.0f%% vs last week", $0) },
                captionColor: StatTile.deltaColor(change ?? 0)
            )
            StatTile(title: "Active days", value: "\(stats.activeDays)", symbol: "calendar")
            StatTile(title: "Streak", value: "\(streak)\(streak == 1 ? " day" : " days")", symbol: "flame.fill")
        }
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
