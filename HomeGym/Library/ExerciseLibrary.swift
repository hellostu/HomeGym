import Foundation
import SwiftData

/// The seed catalogue of exercises, restricted to the gear in Stu's gym:
/// adjustable dumbbells, a barbell + rack, an EZ curl bar, and an adjustable bench.
enum ExerciseLibrary {

    /// How-to steps + a key form cue for an exercise.
    struct Guidance {
        let steps: [String]
        let tip: String
    }

    /// Keyed by exercise name so it can both seed new stores and backfill existing ones.
    static let guidance: [String: Guidance] = [
        "Dumbbell Curl": Guidance(steps: [
            "Stand tall with a dumbbell in each hand, arms hanging, palms facing forward.",
            "Keeping your elbows tucked at your sides, curl the weights up to shoulder height.",
            "Squeeze the biceps at the top, then lower slowly under control."
        ], tip: "Don't swing — keep your upper arms still and move only the forearms."),
        "EZ-Bar Curl": Guidance(steps: [
            "Hold the EZ bar with an underhand grip on the angled sections, arms extended.",
            "Curl the bar toward your chest, keeping your elbows pinned to your sides.",
            "Pause at the top, then lower slowly to full extension."
        ], tip: "Keep your wrists neutral on the angled grip to spare the forearms."),
        "Hammer Curl": Guidance(steps: [
            "Stand with a dumbbell in each hand, palms facing your body (thumbs up).",
            "Curl the weights up while keeping your palms facing inward the whole time.",
            "Lower under control back to the start."
        ], tip: "The neutral grip targets the brachialis and forearms — no wrist rotation."),
        "Overhead DB Extension": Guidance(steps: [
            "Hold one dumbbell with both hands overhead, arms straight.",
            "Keeping your elbows pointing forward, lower the weight behind your head.",
            "Extend back up until your arms are straight, squeezing the triceps."
        ], tip: "Keep your upper arms vertical and still; only the forearms move."),
        "EZ-Bar Skullcrusher": Guidance(steps: [
            "Lie on the bench holding the EZ bar over your chest, arms straight.",
            "Bend at the elbows to lower the bar toward your forehead.",
            "Extend back to straight arms without flaring the elbows out."
        ], tip: "Keep elbows tucked and pointing up; lower to just above the brow."),
        "Bench Dip": Guidance(steps: [
            "Sit on the bench edge, hands beside your hips, feet out in front.",
            "Slide off and lower your body by bending the elbows to about 90°.",
            "Press back up until your arms are straight."
        ], tip: "Keep your back close to the bench and shoulders down, away from your ears."),
        "DB Shoulder Press": Guidance(steps: [
            "Sit or stand holding dumbbells at shoulder height, palms facing forward.",
            "Press the weights overhead until your arms are nearly straight.",
            "Lower under control back to shoulder height."
        ], tip: "Brace your core and keep your ribs down — don't arch your lower back."),
        "DB Lateral Raise": Guidance(steps: [
            "Stand with dumbbells at your sides, a slight bend in the elbows.",
            "Raise the weights out to the sides up to shoulder height.",
            "Lower slowly, leading with your elbows rather than your hands."
        ], tip: "Keep it light and controlled — imagine pouring water at the top."),
        "Barbell Overhead Press": Guidance(steps: [
            "Hold the bar at shoulder height, hands just outside the shoulders, elbows under.",
            "Brace, then press the bar overhead, moving your head slightly back then through.",
            "Lock out overhead, then lower under control to the shoulders."
        ], tip: "Squeeze your glutes and brace hard; don't lean back to press."),
        "DB Bench Press": Guidance(steps: [
            "Lie on the bench with a dumbbell in each hand at chest level, palms forward.",
            "Press the weights up until your arms are straight and the dumbbells nearly touch.",
            "Lower under control until you feel a stretch across the chest."
        ], tip: "Keep your shoulder blades pinched back and feet flat on the floor."),
        "Barbell Bench Press": Guidance(steps: [
            "Lie back, grip the bar slightly wider than your shoulders, unrack over your chest.",
            "Lower the bar to your mid-chest, elbows about 45° from your body.",
            "Press back up to straight arms."
        ], tip: "Keep wrists stacked over elbows and shoulder blades retracted. Use the safeties."),
        "Push-Up": Guidance(steps: [
            "Start in a plank, hands slightly wider than your shoulders, body in a straight line.",
            "Lower your chest toward the floor, elbows about 45°.",
            "Press back up to full arm extension."
        ], tip: "Keep a tight core and neutral neck — no sagging hips."),
        "DB Row": Guidance(steps: [
            "Hinge forward with a flat back, one hand and knee supported on the bench.",
            "Let the dumbbell hang, then pull it to your hip, driving the elbow back.",
            "Lower under control to a full stretch."
        ], tip: "Lead with the elbow and squeeze the shoulder blade; don't twist the torso."),
        "Barbell Row": Guidance(steps: [
            "Hinge at the hips with a flat back, bar hanging at arm's length.",
            "Pull the bar to your lower ribs / upper stomach, elbows back.",
            "Lower under control to the start."
        ], tip: "Keep your back flat and core braced; avoid jerking with the lower back."),
        "DB Pullover": Guidance(steps: [
            "Lie on the bench holding one dumbbell over your chest with both hands.",
            "Keeping a slight elbow bend, lower the weight back behind your head.",
            "Pull it back over your chest, feeling the lats and chest work."
        ], tip: "Move only at the shoulders; keep your hips down and core tight."),
        "Goblet Squat": Guidance(steps: [
            "Hold a dumbbell vertically against your chest with both hands.",
            "Squat down, knees tracking over your toes, until thighs are about parallel.",
            "Drive through your heels to stand tall."
        ], tip: "Keep your chest up and elbows inside your knees at the bottom."),
        "Barbell Squat": Guidance(steps: [
            "Bar on your upper back, feet shoulder-width, toes turned slightly out.",
            "Brace, then sit down and back, keeping knees tracking over your toes.",
            "Drive up through mid-foot to standing."
        ], tip: "Chest up, back neutral, descend to at least parallel. Set the safeties."),
        "DB Walking Lunge": Guidance(steps: [
            "Hold a dumbbell in each hand at your sides, standing tall.",
            "Step forward and lower until both knees are about 90°.",
            "Push through the front heel to step straight into the next lunge."
        ], tip: "Keep your torso upright; don't let the front knee cave inward."),
        "DB Romanian Deadlift": Guidance(steps: [
            "Hold dumbbells in front of your thighs, knees softly bent.",
            "Hinge at the hips, pushing them back, lowering the weights along your legs.",
            "Drive your hips forward to stand, squeezing the glutes."
        ], tip: "Flat back, weights close, feel the hamstring stretch — don't round over."),
        "Ab-Wheel Rollout": Guidance(steps: [
            "Kneel and grip the wheel under your shoulders, core braced.",
            "Roll the wheel forward, extending as far as you can control without arching.",
            "Pull back to the start using your abs."
        ], tip: "Keep your hips tucked and back from arching — only go as far as you control."),
        "Weighted Crunch": Guidance(steps: [
            "Lie on your back, knees bent, holding a dumbbell against your chest.",
            "Curl your shoulders off the floor, crunching your ribs toward your hips.",
            "Lower slowly under control."
        ], tip: "Move through the abs, not the neck; exhale as you crunch up."),
        "Plank (sec)": Guidance(steps: [
            "Forearms under your shoulders, body in a straight line from head to heels.",
            "Brace your abs and glutes and hold for the target number of seconds.",
            "Breathe steadily; don't let your hips sag or pike up."
        ], tip: "Squeeze glutes and pull elbows toward toes for full-body tension."),
    ]

    /// Builds fresh (unsaved) Exercise models. `startingWeight` values are
    /// deliberately conservative first-time suggestions in kg.
    static func seedExercises() -> [Exercise] {
        let exercises: [Exercise] = [
            // Biceps
            Exercise(name: "Dumbbell Curl", muscleGroup: .biceps, equipment: .adjustableDumbbells, startingWeight: 8),
            Exercise(name: "EZ-Bar Curl", muscleGroup: .biceps, equipment: .ezBar, startingWeight: 14.5),
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
        for exercise in exercises {
            if let g = guidance[exercise.name] {
                exercise.instructions = g.steps
                exercise.formTip = g.tip
            }
        }
        return exercises
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

    /// Backfills how-to guidance onto exercises that predate it (e.g. an already-seeded
    /// store from an earlier version). Cheap to run on every launch.
    @MainActor
    static func ensureGuidance(_ context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var changed = false
        for exercise in all where exercise.instructions.isEmpty {
            if let g = guidance[exercise.name] {
                exercise.instructions = g.steps
                exercise.formTip = g.tip
                changed = true
            }
        }
        if changed { try? context.save() }
    }
}
