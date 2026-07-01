import XCTest
@testable import HomeGym

final class SessionResumeTests: XCTestCase {

    private func exercise() -> Exercise {
        Exercise(name: "Dumbbell Curl", muscleGroup: .biceps, equipment: .adjustableDumbbells)
    }

    private func session(_ epoch: TimeInterval, completed: Bool = false, skipped: Bool = false, hasExercise: Bool = true) -> SnackSession {
        let s = SnackSession(exercise: hasExercise ? exercise() : nil, targetSets: 3, targetReps: 8, targetWeight: 6.8)
        s.date = Date(timeIntervalSince1970: epoch)
        s.completed = completed
        s.skipped = skipped
        return s
    }

    func testResumesMostRecentUnfinishedSession() {
        let old = session(1_000)
        let recent = session(2_000)
        XCTAssertTrue(SessionResume.candidate(from: [old, recent]) === recent)
    }

    func testIgnoresCompletedAndSkippedSessions() {
        let done = session(3_000, completed: true)
        let skipped = session(2_500, skipped: true)
        let open = session(1_000)
        XCTAssertTrue(SessionResume.candidate(from: [done, skipped, open]) === open)
    }

    func testReturnsNilWhenNothingIsOpen() {
        let done = session(3_000, completed: true)
        let skipped = session(2_000, skipped: true)
        XCTAssertNil(SessionResume.candidate(from: [done, skipped]))
    }

    func testIgnoresSessionsWithoutAnExercise() {
        let orphan = session(2_000, hasExercise: false)
        XCTAssertNil(SessionResume.candidate(from: [orphan]))
    }
}
