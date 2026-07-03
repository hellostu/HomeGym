import XCTest
@testable import HomeGym

final class PRDetectorTests: XCTestCase {

    private func session(_ weight: Double, reps: [Int], epoch: TimeInterval) -> SnackSession {
        let s = SnackSession(exercise: nil, targetSets: reps.count, targetReps: 12, targetWeight: weight, completed: true)
        s.date = Date(timeIntervalSince1970: epoch)
        s.sets = reps.enumerated().map { WorkoutSet(weight: weight, reps: $0.element, order: $0.offset) }
        return s
    }

    func testNoPROnFirstEverSession() {
        let current = session(10, reps: [12, 12, 12], epoch: 1_000)
        XCTAssertNil(PRDetector.record(for: current, previous: [], weighted: true))
    }

    func testHeavierWeightIsAWeightPR() {
        let previous = [session(10, reps: [12, 12, 12], epoch: 1_000)]
        let current = session(12.5, reps: [8, 8, 8], epoch: 2_000)

        let pr = PRDetector.record(for: current, previous: previous, weighted: true)
        XCTAssertEqual(pr?.kind, .weight)
        XCTAssertEqual(pr?.weight, 12.5)
    }

    func testMoreRepsAtSameTopWeightIsARepPR() {
        let previous = [session(10, reps: [10, 10, 10], epoch: 1_000)]
        let current = session(10, reps: [12, 11, 10], epoch: 2_000)

        let pr = PRDetector.record(for: current, previous: previous, weighted: true)
        XCTAssertEqual(pr?.kind, .reps)
        XCTAssertEqual(pr?.reps, 12)
    }

    func testNoPRWhenNeitherHeavierNorMoreReps() {
        let previous = [session(12.5, reps: [12, 12, 12], epoch: 1_000)]
        let current = session(10, reps: [12, 12, 12], epoch: 2_000)
        XCTAssertNil(PRDetector.record(for: current, previous: previous, weighted: true))
    }

    func testBodyweightPRIsByReps() {
        let previous = [session(0, reps: [15, 15, 15], epoch: 1_000)]
        let current = session(0, reps: [20, 18, 16], epoch: 2_000)

        let pr = PRDetector.record(for: current, previous: previous, weighted: false)
        XCTAssertEqual(pr?.kind, .reps)
        XCTAssertEqual(pr?.reps, 20)
    }
}
