import XCTest
@testable import HomeGym

final class ProgressionEngineTests: XCTestCase {

    private func curl(startingWeight: Double = 6.8) -> Exercise {
        Exercise(
            name: "Dumbbell Curl",
            muscleGroup: .biceps,
            equipment: .adjustableDumbbells,
            repRangeLower: 8,
            repRangeUpper: 12,
            defaultSets: 3,
            startingWeight: startingWeight
        )
    }

    private func barbellBench() -> Exercise {
        Exercise(
            name: "Barbell Bench Press",
            muscleGroup: .chest,
            equipment: .barbell,
            repRangeLower: 8,
            repRangeUpper: 12,
            defaultSets: 3,
            startingWeight: 30
        )
    }

    private func session(weight: Double, reps: [Int], date: Date = .now) -> SnackSession {
        let s = SnackSession(exercise: nil, targetSets: reps.count, targetReps: 12, targetWeight: weight, completed: true)
        s.date = date
        s.sets = reps.enumerated().map { WorkoutSet(weight: weight, reps: $0.element, order: $0.offset) }
        return s
    }

    func testFirstTimeSuggestsStartingWeightAtBottomOfRange() {
        let exercise = curl(startingWeight: 6.8)    // already a real dumbbell rung
        let suggestion = ProgressionEngine.suggest(for: exercise, history: [])

        XCTAssertEqual(suggestion.weight, 6.8)
        XCTAssertEqual(suggestion.reps, 8)          // repRangeLower
        XCTAssertEqual(suggestion.sets, 3)
        XCTAssertFalse(suggestion.isProgression)
    }

    func testFirstTimeSnapsStartingWeightToNearestDumbbellRung() {
        let exercise = curl(startingWeight: 8)      // 8 kg isn't a rung; nearest is 7.9
        let suggestion = ProgressionEngine.suggest(for: exercise, history: [])
        XCTAssertEqual(suggestion.weight, 7.9)
    }

    func testDumbbellProgressionJumpsToNextRung() {
        let exercise = curl()
        let history = [session(weight: 11.3, reps: [12, 12, 12])]

        let suggestion = ProgressionEngine.suggest(for: exercise, history: history)

        XCTAssertEqual(suggestion.weight, 12.5)     // next rung above 11.3
        XCTAssertEqual(suggestion.reps, 8)          // reset to bottom of range
        XCTAssertTrue(suggestion.isProgression)
    }

    func testDumbbellProgressionRespectsLadderGap() {
        let exercise = curl()
        let history = [session(weight: 13.6, reps: [12, 12, 12])]

        let suggestion = ProgressionEngine.suggest(for: exercise, history: history)

        XCTAssertEqual(suggestion.weight, 15.9)     // ladder skips 14.7 → jumps to 15.9
        XCTAssertTrue(suggestion.isProgression)
    }

    func testDumbbellAtTopRungAddsRepsInsteadOfWeight() {
        let exercise = curl()
        let history = [session(weight: 31.8, reps: [12, 12, 12])] // heaviest setting

        let suggestion = ProgressionEngine.suggest(for: exercise, history: history)

        XCTAssertEqual(suggestion.weight, 31.8)     // can't go heavier
        XCTAssertGreaterThan(suggestion.reps, exercise.repRangeUpper)
        XCTAssertFalse(suggestion.isProgression)
    }

    func testBarbellProgressesByFiveKilos() {
        let exercise = barbellBench()
        let history = [session(weight: 30, reps: [12, 12, 12])]

        let suggestion = ProgressionEngine.suggest(for: exercise, history: history)

        XCTAssertEqual(suggestion.weight, 35)       // 2.5 kg plate on each side
        XCTAssertTrue(suggestion.isProgression)
    }

    func testPartialSessionKeepsWeightAndChasesReps() {
        let exercise = curl()
        let history = [session(weight: 11.3, reps: [12, 10, 9])]

        let suggestion = ProgressionEngine.suggest(for: exercise, history: history)

        XCTAssertEqual(suggestion.weight, 11.3)     // hold the weight
        XCTAssertFalse(suggestion.isProgression)
        XCTAssertLessThanOrEqual(suggestion.reps, exercise.repRangeUpper)
    }

    func testUsesMostRecentCompletedSession() {
        let exercise = curl()
        let old = session(weight: 9.0, reps: [8, 8, 8], date: Date(timeIntervalSince1970: 1_000))
        let recent = session(weight: 11.3, reps: [12, 12, 12], date: Date(timeIntervalSince1970: 2_000))

        let suggestion = ProgressionEngine.suggest(for: exercise, history: [old, recent])

        XCTAssertEqual(suggestion.weight, 12.5)     // progresses from the recent 11.3 kg
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
