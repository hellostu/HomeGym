import Foundation

/// Holistic training stats for a period, decoupled from SwiftData fetching so it's
/// unit-testable.
struct WeeklyStats: Equatable {
    var workouts: Int = 0
    var totalSets: Int = 0
    var totalReps: Int = 0
    var totalVolumeKg: Double = 0
    var activeDays: Int = 0
    var perGroupSets: [MuscleGroup: Int] = [:]

    func sets(for group: MuscleGroup) -> Int { perGroupSets[group] ?? 0 }
    var maxGroupSets: Int { perGroupSets.values.max() ?? 0 }
}

enum StatsCalculator {
    /// Aggregates completed sessions falling in the calendar week containing `now`.
    static func weekly(completed sessions: [SnackSession], now: Date, calendar: Calendar = .current) -> WeeklyStats {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return WeeklyStats() }
        let inWeek = sessions.filter { $0.completed && week.contains($0.date) }

        var stats = WeeklyStats()
        stats.workouts = inWeek.count
        var days = Set<Date>()
        for session in inWeek {
            days.insert(calendar.startOfDay(for: session.date))
            stats.totalSets += session.sets.count
            for set in session.sets {
                stats.totalReps += set.reps
                stats.totalVolumeKg += set.weight * Double(set.reps)
            }
            if let group = session.exercise?.muscleGroup {
                stats.perGroupSets[group, default: 0] += session.sets.count
            }
        }
        stats.activeDays = days.count
        return stats
    }

    /// Consecutive days up to today with at least one completed workout. Today not
    /// being done *yet* doesn't break the streak — it counts back from yesterday.
    static func currentStreak(completed sessions: [SnackSession], now: Date, calendar: Calendar = .current) -> Int {
        let trained = Set(sessions.filter { $0.completed }.map { calendar.startOfDay(for: $0.date) })
        guard !trained.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: now)
        if !trained.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while trained.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
}
