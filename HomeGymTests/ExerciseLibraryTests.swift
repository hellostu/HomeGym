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
}
