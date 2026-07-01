import Foundation
import SwiftData

/// The seed catalogue of exercises, restricted to the gear in Stu's gym:
/// adjustable dumbbells, a barbell + rack, an EZ curl bar, and an adjustable bench.
enum ExerciseLibrary {

    /// Builds fresh (unsaved) Exercise models. `startingWeight` values are
    /// deliberately conservative first-time suggestions in kg.
    static func seedExercises() -> [Exercise] {
        [
            // Biceps
            Exercise(name: "Dumbbell Curl", muscleGroup: .biceps, equipment: .adjustableDumbbells, startingWeight: 8),
            Exercise(name: "EZ-Bar Curl", muscleGroup: .biceps, equipment: .ezBar, startingWeight: 15),
            Exercise(name: "Hammer Curl", muscleGroup: .biceps, equipment: .adjustableDumbbells, startingWeight: 8),

            // Triceps
            Exercise(name: "Overhead DB Extension", muscleGroup: .triceps, equipment: .adjustableDumbbells, startingWeight: 8),
            Exercise(name: "EZ-Bar Skullcrusher", muscleGroup: .triceps, equipment: .ezBar, startingWeight: 15),
            Exercise(name: "Bench Dip", muscleGroup: .triceps, equipment: .bench, startingWeight: 0),

            // Shoulders
            Exercise(name: "DB Shoulder Press", muscleGroup: .shoulders, equipment: .adjustableDumbbells, startingWeight: 10),
            Exercise(name: "DB Lateral Raise", muscleGroup: .shoulders, equipment: .adjustableDumbbells, repRangeLower: 10, repRangeUpper: 15, startingWeight: 6),
            Exercise(name: "Barbell Overhead Press", muscleGroup: .shoulders, equipment: .barbell, startingWeight: 25),

            // Chest
            Exercise(name: "DB Bench Press", muscleGroup: .chest, equipment: .adjustableDumbbells, startingWeight: 14),
            Exercise(name: "Barbell Bench Press", muscleGroup: .chest, equipment: .barbell, startingWeight: 30),
            Exercise(name: "Push-Up", muscleGroup: .chest, equipment: .bodyweight, repRangeLower: 10, repRangeUpper: 20, startingWeight: 0),

            // Back
            Exercise(name: "DB Row", muscleGroup: .back, equipment: .adjustableDumbbells, startingWeight: 14),
            Exercise(name: "Barbell Row", muscleGroup: .back, equipment: .barbell, startingWeight: 30),
            Exercise(name: "DB Pullover", muscleGroup: .back, equipment: .adjustableDumbbells, startingWeight: 12),

            // Legs
            Exercise(name: "Goblet Squat", muscleGroup: .legs, equipment: .adjustableDumbbells, startingWeight: 16),
            Exercise(name: "Barbell Squat", muscleGroup: .legs, equipment: .barbell, startingWeight: 40),
            Exercise(name: "DB Walking Lunge", muscleGroup: .legs, equipment: .adjustableDumbbells, startingWeight: 10),
            Exercise(name: "DB Romanian Deadlift", muscleGroup: .legs, equipment: .adjustableDumbbells, startingWeight: 16),

            // Core
            Exercise(name: "Ab-Wheel Rollout", muscleGroup: .core, equipment: .bodyweight, repRangeLower: 6, repRangeUpper: 12, startingWeight: 0),
            Exercise(name: "Weighted Crunch", muscleGroup: .core, equipment: .adjustableDumbbells, repRangeLower: 10, repRangeUpper: 15, startingWeight: 5),
            Exercise(name: "Plank (sec)", muscleGroup: .core, equipment: .bodyweight, repRangeLower: 30, repRangeUpper: 60, startingWeight: 0),
        ]
    }

    /// Seeds the store on first launch (when no exercises exist yet).
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for exercise in seedExercises() {
            context.insert(exercise)
        }

        if (try? context.fetchCount(FetchDescriptor<AppSettings>())) ?? 0 == 0 {
            context.insert(AppSettings())
        }
        try? context.save()
    }
}
