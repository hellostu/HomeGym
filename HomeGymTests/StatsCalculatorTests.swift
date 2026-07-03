import XCTest
@testable import HomeGym

final class StatsCalculatorTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 2   // Monday
        return cal
    }()

    private func date(_ d: Int, h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2025, month: 6, day: d, hour: h))!
    }

    private func exercise(_ name: String, _ group: MuscleGroup) -> Exercise {
        Exercise(name: name, muscleGroup: group, equipment: .adjustableDumbbells)
    }

    private func session(_ ex: Exercise, weight: Double, reps: [Int], day: Int, completed: Bool = true) -> SnackSession {
        let s = SnackSession(exercise: ex, targetSets: reps.count, targetReps: 12, targetWeight: weight, completed: completed)
        s.date = date(day)
        s.sets = reps.enumerated().map { WorkoutSet(weight: weight, reps: $0.element, order: $0.offset) }
        return s
    }

    func testWeeklyAggregatesSetsRepsVolumeAndGroups() {
        let curl = exercise("Curl", .biceps)
        let squat = exercise("Squat", .legs)
        let sessions = [
            session(curl, weight: 10, reps: [12, 12], day: 2),   // Mon: 2 sets, 240 kg
            session(curl, weight: 10, reps: [10], day: 3),        // Tue: 1 set, 100 kg
            session(squat, weight: 20, reps: [10, 10], day: 4),   // Wed: 2 sets, 400 kg
        ]

        let stats = StatsCalculator.weekly(completed: sessions, now: date(4), calendar: calendar)

        XCTAssertEqual(stats.workouts, 3)
        XCTAssertEqual(stats.totalSets, 5)
        XCTAssertEqual(stats.totalReps, 54)
        XCTAssertEqual(stats.totalVolumeKg, 240 + 100 + 400)
        XCTAssertEqual(stats.activeDays, 3)
        XCTAssertEqual(stats.sets(for: .biceps), 3)
        XCTAssertEqual(stats.sets(for: .legs), 2)
        XCTAssertEqual(stats.sets(for: .chest), 0)
        XCTAssertEqual(stats.maxGroupSets, 3)
    }

    func testWeeklyExcludesSessionsOutsideThisWeek() {
        let curl = exercise("Curl", .biceps)
        let lastWeek = session(curl, weight: 10, reps: [12], day: 2)   // Mon of this week
        let thisWeek = session(curl, weight: 10, reps: [12], day: 4)

        // now is day 4; day 2 is same week (Mon–Sun), so both count. Use a prior-week one:
        let prior = session(curl, weight: 10, reps: [12], day: 2)
        prior.date = calendar.date(byAdding: .day, value: -7, to: date(4))!

        let stats = StatsCalculator.weekly(completed: [lastWeek, thisWeek, prior], now: date(4), calendar: calendar)
        XCTAssertEqual(stats.workouts, 2)   // prior week excluded
    }

    func testCurrentStreakCountsConsecutiveDays() {
        let curl = exercise("Curl", .biceps)
        let sessions = [
            session(curl, weight: 10, reps: [10], day: 2),
            session(curl, weight: 10, reps: [10], day: 3),
            session(curl, weight: 10, reps: [10], day: 4),
        ]
        XCTAssertEqual(StatsCalculator.currentStreak(completed: sessions, now: date(4), calendar: calendar), 3)
    }

    func testStreakSurvivesTodayNotDoneYet() {
        let curl = exercise("Curl", .biceps)
        let sessions = [
            session(curl, weight: 10, reps: [10], day: 2),
            session(curl, weight: 10, reps: [10], day: 3),
        ]
        // now is day 4 (nothing logged yet today) — streak counts back from yesterday.
        XCTAssertEqual(StatsCalculator.currentStreak(completed: sessions, now: date(4), calendar: calendar), 2)
    }

    func testStreakBreaksOnAGapDay() {
        let curl = exercise("Curl", .biceps)
        let sessions = [
            session(curl, weight: 10, reps: [10], day: 2),
            // gap on day 3
            session(curl, weight: 10, reps: [10], day: 4),
        ]
        XCTAssertEqual(StatsCalculator.currentStreak(completed: sessions, now: date(4), calendar: calendar), 1)
    }
}
