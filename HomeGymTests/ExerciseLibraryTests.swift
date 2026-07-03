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

    func testRosterCoversPreviouslyMissingAreas() {
        let byName = Dictionary(uniqueKeysWithValues: ExerciseLibrary.seedExercises().map { ($0.name, $0) })
        XCTAssertEqual(byName["Standing Calf Raise"]?.muscleGroup, .legs)       // calves
        XCTAssertEqual(byName["Incline DB Press"]?.muscleGroup, .chest)         // upper chest
        XCTAssertEqual(byName["DB Rear Delt Fly"]?.muscleGroup, .shoulders)     // rear delts
        XCTAssertEqual(byName["Bulgarian Split Squat"]?.muscleGroup, .legs)
        XCTAssertEqual(byName["Bulgarian Split Squat"]?.isUnilateral, true)
    }

    func testGlutesGroupHasHipDominantExercises() {
        let byName = Dictionary(uniqueKeysWithValues: ExerciseLibrary.seedExercises().map { ($0.name, $0) })
        XCTAssertEqual(byName["DB Romanian Deadlift"]?.muscleGroup, .glutes)
        XCTAssertEqual(byName["Barbell Hip Thrust"]?.muscleGroup, .glutes)
        XCTAssertEqual(byName["DB Glute Bridge"]?.muscleGroup, .glutes)
        // Quad-dominant work stays under Legs.
        XCTAssertEqual(byName["Barbell Squat"]?.muscleGroup, .legs)
        XCTAssertEqual(byName["DB Walking Lunge"]?.muscleGroup, .legs)
    }

    func testSingleDumbbellExercisesAreFlagged() {
        let byName = Dictionary(uniqueKeysWithValues: ExerciseLibrary.seedExercises().map { ($0.name, $0) })
        // One dumbbell (both hands or one at a time) → weight isn't "each".
        XCTAssertEqual(byName["Goblet Squat"]?.usesSingleDumbbell, true)
        XCTAssertEqual(byName["DB Pullover"]?.usesSingleDumbbell, true)
        XCTAssertEqual(byName["DB Row"]?.usesSingleDumbbell, true)
        // A dumbbell in each hand → "each" applies.
        XCTAssertEqual(byName["Dumbbell Curl"]?.usesSingleDumbbell, false)
        XCTAssertEqual(byName["DB Shoulder Press"]?.usesSingleDumbbell, false)
    }
}
