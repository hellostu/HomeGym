import SwiftUI
import SwiftData
import Charts

/// Multi-week progress across all exercises: volume trend, an overall strength
/// index, and a PR feed — the "am I actually improving?" view.
struct TrendsTab: View {
    @Query(filter: #Predicate<SnackSession> { $0.completed }, sort: \SnackSession.date)
    private var completed: [SnackSession]

    /// How far back the charts look.
    private static let weekWindow = 12

    var body: some View {
        if completed.isEmpty {
            ContentUnavailableView(
                "No workouts yet",
                systemImage: "chart.bar.xaxis",
                description: Text("Trends appear once you've logged a few sessions.")
            )
        } else {
            content
        }
    }

    private var content: some View {
        let now = Date()
        let volume = TrendsCalculator.weeklySeries(completed: completed, weeks: Self.weekWindow, now: now)
        let strength = TrendsCalculator.strengthIndex(completed: completed, weeks: Self.weekWindow, now: now)
        let prs = TrendsCalculator.personalRecords(completed: completed)

        return ScrollView {
            VStack(spacing: 28) {
                summaryTiles(volume: volume, strength: strength, prs: prs, now: now)
                volumeChart(volume)
                strengthSection(strength)
                prFeed(prs)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    private func summaryTiles(
        volume: [WeekTrendPoint],
        strength: [StrengthIndexPoint],
        prs: [PREvent],
        now: Date
    ) -> some View {
        let thisWeek = volume.last?.volumeKg ?? 0
        let lastWeek = volume.dropLast().last?.volumeKg ?? 0
        let change = TrendsCalculator.percentChange(current: thisWeek, previous: lastWeek)

        let monthPRs = prs.filter { Calendar.current.isDate($0.date, equalTo: now, toGranularity: .month) }
        let weightPRs = monthPRs.filter { $0.record.kind == .weight }.count

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            StatTile(
                title: "Volume this week",
                value: StatTile.volumeText(thisWeek),
                symbol: "scalemass",
                caption: change.map { String(format: "%+.0f%% vs last week", $0) },
                captionColor: StatTile.deltaColor(change ?? 0)
            )
            StatTile(
                title: "Strength index",
                value: strength.last.map { String(format: "%+.0f%%", $0.index - 100) } ?? "—",
                symbol: "chart.line.uptrend.xyaxis",
                caption: strength.isEmpty ? nil : "vs your first sessions"
            )
            StatTile(
                title: "PRs this month",
                value: "\(monthPRs.count)",
                symbol: "trophy",
                caption: monthPRs.isEmpty ? nil : "\(weightPRs) weight · \(monthPRs.count - weightPRs) reps"
            )
        }
        .frame(maxWidth: 560)
    }

    private func volumeChart(_ series: [WeekTrendPoint]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly volume").font(.headline)
            Chart(series) { point in
                BarMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Volume (kg)", point.volumeKg)
                )
                .cornerRadius(3)
            }
            .frame(height: 180)
            .chartYAxisLabel("kg")
        }
        .frame(maxWidth: 560)
    }

    @ViewBuilder
    private func strengthSection(_ series: [StrengthIndexPoint]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Strength index").font(.headline)
            Text("Each weighted exercise's working weight vs its first session, averaged. 100 = where you started.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if series.count < 2 {
                Text("Not enough weighted history yet — log a few more weeks.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            } else {
                strengthChart(series)
            }
        }
        .frame(maxWidth: 560, alignment: .leading)
    }

    private func strengthChart(_ series: [StrengthIndexPoint]) -> some View {
        let low = series.map(\.index).min() ?? 100
        let high = series.map(\.index).max() ?? 100
        return Chart {
            RuleMark(y: .value("Baseline", 100))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            ForEach(series) { point in
                LineMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Index", point.index)
                )
                .symbol(.circle)
            }
        }
        .chartYScale(domain: (low - 5)...(high + 5))
        .frame(height: 180)
        .chartYAxisLabel("% of baseline")
    }

    private func prFeed(_ prs: [PREvent]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent PRs").font(.headline)
            if prs.isEmpty {
                Text("No PRs yet — your first session for an exercise sets the baseline; beating it sets a record.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(prs.prefix(10)) { pr in
                    HStack {
                        Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .leading)
                        Text(pr.exerciseName)
                        Spacer()
                        Text(label(for: pr.record))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .font(.callout)
                }
            }
        }
        .frame(maxWidth: 560, alignment: .leading)
    }

    private func label(for record: PRDetector.Record) -> String {
        switch record.kind {
        case .weight: "\(ProgressionEngine.format(record.weight)) kg × \(record.reps) — weight PR"
        case .reps: "\(record.reps) reps — rep PR"
        }
    }
}
