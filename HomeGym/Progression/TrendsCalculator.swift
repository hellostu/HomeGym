import Foundation

/// One calendar week's training totals, for the multi-week trend charts.
struct WeekTrendPoint: Equatable, Identifiable {
    let weekStart: Date
    var workouts: Int = 0
    var sets: Int = 0
    var volumeKg: Double = 0

    var id: Date { weekStart }
}

/// Overall strength for a week, relative to each weighted exercise's first logged
/// session (100 = baseline), averaged across exercises trained so far.
struct StrengthIndexPoint: Equatable, Identifiable {
    let weekStart: Date
    let index: Double

    var id: Date { weekStart }
}

/// A personal record recovered by replaying session history through PRDetector.
struct PREvent: Equatable, Identifiable {
    let date: Date
    let exerciseName: String
    let record: PRDetector.Record

    var id: String { "\(exerciseName)|\(date.timeIntervalSinceReferenceDate)" }
}

/// Cross-exercise progress over time, decoupled from SwiftData fetching so it's
/// unit-testable. Complements StatsCalculator, which covers a single week.
enum TrendsCalculator {
    /// Totals for the last `weeks` calendar weeks (oldest first, the week containing
    /// `now` last). Quiet weeks are zero-filled so charts show gaps, not skips.
    static func weeklySeries(
        completed sessions: [SnackSession],
        weeks: Int,
        now: Date,
        calendar: Calendar = .current
    ) -> [WeekTrendPoint] {
        guard weeks > 0, let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }

        var points: [WeekTrendPoint] = []
        for offset in -(weeks - 1)...0 {
            guard let start = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeek.start) else { continue }
            points.append(WeekTrendPoint(weekStart: start))
        }

        for session in sessions where session.completed {
            guard let week = calendar.dateInterval(of: .weekOfYear, for: session.date),
                  let index = points.firstIndex(where: { $0.weekStart == week.start }) else { continue }
            points[index].workouts += 1
            points[index].sets += session.sets.count
            for set in session.sets {
                points[index].volumeKg += set.weight * Double(set.reps)
            }
        }
        return points
    }

    /// A single "how strong am I overall?" line: each weighted exercise's current
    /// working weight (its most recent session's top weight) as a fraction of its
    /// first-ever top weight, averaged across exercises and scaled so 100 = baseline.
    /// Weeks with no weighted history yet produce no point.
    static func strengthIndex(
        completed sessions: [SnackSession],
        weeks: Int,
        now: Date,
        calendar: Calendar = .current
    ) -> [StrengthIndexPoint] {
        guard weeks > 0, let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }

        var histories: [ObjectIdentifier: [SnackSession]] = [:]
        for session in sessions where session.completed && session.topWeight > 0 {
            guard let exercise = session.exercise, exercise.equipment.isWeighted else { continue }
            histories[ObjectIdentifier(exercise), default: []].append(session)
        }
        let ordered = histories.values.map { $0.sorted { $0.date < $1.date } }

        var points: [StrengthIndexPoint] = []
        for offset in -(weeks - 1)...0 {
            guard let start = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeek.start),
                  let week = calendar.dateInterval(of: .weekOfYear, for: start) else { continue }

            var ratios: [Double] = []
            for history in ordered {
                guard let baseline = history.first?.topWeight, baseline > 0,
                      let latest = history.last(where: { $0.date < week.end }) else { continue }
                ratios.append(latest.topWeight / baseline)
            }
            guard !ratios.isEmpty else { continue }
            points.append(StrengthIndexPoint(weekStart: start, index: ratios.reduce(0, +) / Double(ratios.count) * 100))
        }
        return points
    }

    /// Replays each exercise's history through PRDetector to recover every PR ever
    /// set, newest first. The first session per exercise is a baseline, not a PR.
    static func personalRecords(completed sessions: [SnackSession]) -> [PREvent] {
        var histories: [ObjectIdentifier: (name: String, weighted: Bool, sessions: [SnackSession])] = [:]
        for session in sessions where session.completed {
            guard let exercise = session.exercise else { continue }
            let key = ObjectIdentifier(exercise)
            histories[key, default: (exercise.name, exercise.equipment.isWeighted, [])].sessions.append(session)
        }

        var events: [PREvent] = []
        for history in histories.values {
            let ordered = history.sessions.sorted { $0.date < $1.date }
            for (index, session) in ordered.enumerated() {
                if let record = PRDetector.record(for: session, previous: Array(ordered[..<index]), weighted: history.weighted) {
                    events.append(PREvent(date: session.date, exerciseName: history.name, record: record))
                }
            }
        }
        return events.sorted { $0.date > $1.date }
    }

    /// Percent change from `previous` to `current`; nil when there's no meaningful
    /// baseline to compare against (previous is zero).
    static func percentChange(current: Double, previous: Double) -> Double? {
        guard previous > 0 else { return nil }
        return (current - previous) / previous * 100
    }
}
