import XCTest
@testable import HomeGym

final class ExerciseLibraryTests: XCTestCase {

    func testEverySeededExerciseHasHowToGuidance() {
        for exercise in ExerciseLibrary.seedExercises() {
            XCTAssertFalse(exercise.instructions.isEmpty, "\(exercise.name) is missing how-to steps")
            XCTAssertFalse(exercise.formTip.isEmpty, "\(exercise.name) is missing a form tip")
        }
    }

    func testEverySeededExerciseHasADemoURL() {
        for exercise in ExerciseLibrary.seedExercises() {
            XCTAssertNotNil(exercise.demoVideoURL, "\(exercise.name) produced no demo URL")
        }
    }

    func testDemoURLIsAWebSearchForTheExercise() {
        let curl = ExerciseLibrary.seedExercises().first { $0.name == "Dumbbell Curl" }!
        let url = curl.demoVideoURL!.absoluteString
        XCTAssertTrue(url.hasPrefix("https://"))
        XCTAssertTrue(url.contains("Dumbbell"))
    }

    func testSingleSideExercisesAreMarkedUnilateral() {
        let byName = Dictionary(uniqueKeysWithValues: ExerciseLibrary.seedExercises().map { ($0.name, $0) })
        XCTAssertEqual(byName["DB Row"]?.isUnilateral, true)
        XCTAssertEqual(byName["DB Walking Lunge"]?.isUnilateral, true)
        // Two-handed / both-sides-together moves stay bilateral.
        XCTAssertEqual(byName["DB Bench Press"]?.isUnilateral, false)
        XCTAssertEqual(byName["Goblet Squat"]?.isUnilateral, false)
        XCTAssertEqual(byName["Barbell Bench Press"]?.isUnilateral, false)
    }
}
