import XCTest
@testable import HomeGym

final class ProgressionEngineTests: XCTestCase {

    private func curl() -> Exercise {
        Exercise(
            name: "Dumbbell Curl",
            muscleGroup: .biceps,
            equipment: .adjustableDumbbells,
            repRangeLower: 8,
            repRangeUpper: 12,
            defaultSets: 3,
            weightIncrement: 2,
            startingWeight: 8
        )
    }

    private func session(weight: Double, reps: [Int], date: Date = .now) -> SnackSession {
        let s = SnackSession(exercise: nil, targetSets: reps.count, targetReps: 12, targetWeight: weight, completed: true)
        s.date = date
        s.sets = reps.enumerated().map { WorkoutSet(weight: weight, reps: $0.element, order: $0.offset) }
        return s
    }

    func testFirstTimeSuggestsStartingWeightAtBottomOfRange() {
        let exercise = curl()
        let suggestion = ProgressionEngine.suggest(for: exercise, history: [])

        XCTAssertEqual(suggestion.weight, 8)
        XCTAssertEqual(suggestion.reps, 8)          // repRangeLower
        XCTAssertEqual(suggestion.sets, 3)
        XCTAssertFalse(suggestion.isProgression)
    }

    func testHittingTopOfRangeOnAllSetsSuggestsMoreWeight() {
        let exercise = curl()
        let history = [session(weight: 10, reps: [12, 12, 12])]

        let suggestion = ProgressionEngine.suggest(for: exercise, history: history)

        XCTAssertEqual(suggestion.weight, 12)       // 10 + 2 increment
        XCTAssertEqual(suggestion.reps, 8)          // reset to bottom of range
        XCTAssertTrue(suggestion.isProgression)
    }

    func testPartialSessionKeepsWeightAndChasesReps() {
        let exercise = curl()
        let history = [session(weight: 10, reps: [12, 10, 9])]

        let suggestion = ProgressionEngine.suggest(for: exercise, history: history)

        XCTAssertEqual(suggestion.weight, 10)       // hold the weight
        XCTAssertFalse(suggestion.isProgression)
        XCTAssertLessThanOrEqual(suggestion.reps, exercise.repRangeUpper)
    }

    func testUsesMostRecentCompletedSession() {
        let exercise = curl()
        let old = session(weight: 8, reps: [8, 8, 8], date: Date(timeIntervalSince1970: 1_000))
        let recent = session(weight: 12, reps: [12, 12, 12], date: Date(timeIntervalSince1970: 2_000))

        let suggestion = ProgressionEngine.suggest(for: exercise, history: [old, recent])

        XCTAssertEqual(suggestion.weight, 14)       // progresses from the recent 12 kg
        XCTAssertTrue(suggestion.isProgression)
    }

    func testBodyweightExerciseProgressesOnReps() {
        let pushup = Exercise(
            name: "Push-Up",
            muscleGroup: .chest,
            equipment: .bodyweight,
            repRangeLower: 10,
            repRangeUpper: 20,
            defaultSets: 3,
            startingWeight: 0
        )
        let history = [session(weight: 0, reps: [20, 20, 20])]

        let suggestion = ProgressionEngine.suggest(for: pushup, history: history)

        XCTAssertEqual(suggestion.weight, 0)
        XCTAssertGreaterThan(suggestion.reps, pushup.repRangeUpper)
        XCTAssertTrue(suggestion.isProgression)
    }
}
