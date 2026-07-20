import XCTest
@testable import HomeGym

final class TrendsCalculatorTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 2   // Monday
        return cal
    }()

    // June 2025: the 2nd is a Monday, so weeks run 2–8, 9–15, 16–22.
    private func date(_ d: Int, h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2025, month: 6, day: d, hour: h))!
    }

    private func exercise(
        _ name: String,
        _ group: MuscleGroup = .biceps,
        equipment: Equipment = .adjustableDumbbells
    ) -> Exercise {
        Exercise(name: name, muscleGroup: group, equipment: equipment)
    }

    private func session(_ ex: Exercise, weight: Double, reps: [Int], day: Int) -> SnackSession {
        let s = SnackSession(exercise: ex, targetSets: reps.count, targetReps: 12, targetWeight: weight, completed: true)
        s.date = date(day)
        s.sets = reps.enumerated().map { WorkoutSet(weight: weight, reps: $0.element, order: $0.offset) }
        return s
    }

    // MARK: weeklySeries

    func testWeeklySeriesBucketsAndZeroFillsQuietWeeks() {
        let curl = exercise("Curl")
        let sessions = [
            session(curl, weight: 10, reps: [10, 10], day: 2),   // week of Jun 2: 200 kg
            session(curl, weight: 10, reps: [10], day: 17),      // week of Jun 16: 100 kg
        ]

        let series = TrendsCalculator.weeklySeries(completed: sessions, weeks: 3, now: date(18), calendar: calendar)

        XCTAssertEqual(series.count, 3)
        XCTAssertEqual(series[0].weekStart, date(2, h: 0))
        XCTAssertEqual(series[0].workouts, 1)
        XCTAssertEqual(series[0].sets, 2)
        XCTAssertEqual(series[0].volumeKg, 200)
        XCTAssertEqual(series[1].volumeKg, 0)   // quiet week is present, not skipped
        XCTAssertEqual(series[2].volumeKg, 100)
    }

    func testWeeklySeriesIgnoresSessionsOutsideTheWindow() {
        let curl = exercise("Curl")
        let old = session(curl, weight: 10, reps: [10], day: 2)

        let series = TrendsCalculator.weeklySeries(completed: [old], weeks: 2, now: date(18), calendar: calendar)

        XCTAssertEqual(series.map(\.volumeKg), [0, 0])
    }

    // MARK: strengthIndex

    func testStrengthIndexBaselinesAndCarriesForwardQuietWeeks() {
        let curl = exercise("Curl")
        let sessions = [
            session(curl, weight: 10, reps: [10], day: 2),    // baseline: 10 kg
            session(curl, weight: 12, reps: [10], day: 16),   // two weeks later: 12 kg
        ]

        let points = TrendsCalculator.strengthIndex(completed: sessions, weeks: 3, now: date(18), calendar: calendar)

        XCTAssertEqual(points.count, 3)
        XCTAssertEqual(points[0].index, 100, accuracy: 0.0001)
        XCTAssertEqual(points[1].index, 100, accuracy: 0.0001)   // quiet week keeps the last known weight
        XCTAssertEqual(points[2].index, 120, accuracy: 0.0001)
    }

    func testStrengthIndexAveragesAcrossExercises() {
        let curl = exercise("Curl")
        let squat = exercise("Squat", .legs)
        let sessions = [
            session(curl, weight: 10, reps: [10], day: 2),
            session(squat, weight: 20, reps: [10], day: 2),
            session(curl, weight: 12, reps: [10], day: 9),    // +20%
            session(squat, weight: 20, reps: [10], day: 9),   // unchanged
        ]

        let points = TrendsCalculator.strengthIndex(completed: sessions, weeks: 2, now: date(10), calendar: calendar)

        XCTAssertEqual(points.last?.index ?? 0, 110, accuracy: 0.0001)
    }

    func testStrengthIndexSkipsBodyweightAndWeeksBeforeFirstSession() {
        let pushup = exercise("Push-up", .chest, equipment: .bodyweight)
        let curl = exercise("Curl")
        let sessions = [
            session(pushup, weight: 0, reps: [15], day: 2),
            session(curl, weight: 10, reps: [10], day: 9),
        ]

        let points = TrendsCalculator.strengthIndex(completed: sessions, weeks: 2, now: date(10), calendar: calendar)

        // Week of Jun 2 has only bodyweight work → no point; Jun 9 baselines the curl.
        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0].weekStart, date(9, h: 0))
        XCTAssertEqual(points[0].index, 100, accuracy: 0.0001)
    }

    // MARK: personalRecords

    func testPersonalRecordsReplayHistoryNewestFirst() {
        let curl = exercise("Curl")
        let squat = exercise("Squat", .legs)
        let sessions = [
            session(curl, weight: 10, reps: [10], day: 2),    // baseline, no PR
            session(curl, weight: 12, reps: [8], day: 4),     // weight PR
            session(squat, weight: 20, reps: [10], day: 3),   // baseline, no PR
            session(squat, weight: 20, reps: [12], day: 5),   // rep PR at the same weight
        ]

        let prs = TrendsCalculator.personalRecords(completed: sessions)

        XCTAssertEqual(prs.count, 2)
        XCTAssertEqual(prs[0].exerciseName, "Squat")
        XCTAssertEqual(prs[0].record, PRDetector.Record(kind: .reps, weight: 20, reps: 12))
        XCTAssertEqual(prs[1].exerciseName, "Curl")
        XCTAssertEqual(prs[1].record, PRDetector.Record(kind: .weight, weight: 12, reps: 8))
    }

    // MARK: percentChange

    func testPercentChange() {
        XCTAssertEqual(TrendsCalculator.percentChange(current: 110, previous: 100) ?? 0, 10, accuracy: 0.0001)
        XCTAssertNil(TrendsCalculator.percentChange(current: 50, previous: 0))
    }
}
