import Foundation

/// What the app suggests you attempt next for a given exercise.
struct Suggestion: Equatable {
    var weight: Double
    var reps: Int
    var sets: Int
    /// Human-readable reason shown in the popup, e.g. "You hit 3×12 @ 10 kg — try 12 kg".
    var rationale: String
    /// True when this suggestion bumps the load versus last time.
    var isProgression: Bool
}

/// Pure double-progression logic. Kept free of SwiftData so it is trivially testable:
/// callers pass in the exercise's parameters and its recent *completed* sessions.
enum ProgressionEngine {

    /// - Parameters:
    ///   - exercise: the library exercise being suggested.
    ///   - history: completed sessions for this exercise, any order.
    static func suggest(for exercise: Exercise, history: [SnackSession]) -> Suggestion {
        let lower = exercise.repRangeLower
        let upper = exercise.repRangeUpper
        let sets = exercise.defaultSets

        // Most recent completed session with at least one logged set.
        let last = history
            .filter { $0.completed && !$0.sets.isEmpty }
            .sorted { $0.date > $1.date }
            .first

        guard let last else {
            // First time: conservative starting load, snapped to a weight the
            // equipment can actually make, at the bottom of the rep range.
            let w = exercise.equipment.isWeighted && exercise.startingWeight > 0
                ? exercise.equipment.snap(exercise.startingWeight)
                : exercise.startingWeight
            let weightPart = exercise.equipment.isWeighted && w > 0 ? " @ \(Self.format(w)) kg" : ""
            return Suggestion(
                weight: w,
                reps: lower,
                sets: sets,
                rationale: "First time — start with \(sets)×\(lower)\(weightPart) and see how it feels.",
                isProgression: false
            )
        }

        let workingSets = last.orderedSets
        let lastWeight = mode(of: workingSets.map(\.weight)) ?? last.targetWeight
        let allHitTop = workingSets.count >= sets && workingSets.allSatisfy { $0.reps >= upper && $0.weight >= lastWeight }

        if allHitTop {
            if exercise.equipment.isWeighted {
                if let next = exercise.equipment.nextWeight(above: lastWeight) {
                    return Suggestion(
                        weight: next,
                        reps: lower,
                        sets: sets,
                        rationale: "You hit \(sets)×\(upper) @ \(Self.format(lastWeight)) kg last time — step up to the next setting, \(Self.format(next)) kg.",
                        isProgression: true
                    )
                } else {
                    // Already at the heaviest load this equipment can make (top of the
                    // dumbbell ladder): keep the weight and add reps instead.
                    return Suggestion(
                        weight: lastWeight,
                        reps: upper + 2,
                        sets: sets,
                        rationale: "You're at the heaviest setting (\(Self.format(lastWeight)) kg) — add reps or slow the tempo.",
                        isProgression: false
                    )
                }
            } else {
                // Bodyweight: progress by adding reps beyond the range.
                let next = upper + 2
                return Suggestion(
                    weight: 0,
                    reps: next,
                    sets: sets,
                    rationale: "You maxed the rep range last time — push for \(next) this session.",
                    isProgression: true
                )
            }
        }

        // Haven't topped out yet: same load, chase the top of the range.
        let bestReps = workingSets.map(\.reps).max() ?? lower
        let target = min(bestReps + 1, upper)
        let weightPart = exercise.equipment.isWeighted && lastWeight > 0 ? " @ \(Self.format(lastWeight)) kg" : ""
        return Suggestion(
            weight: lastWeight,
            reps: target,
            sets: sets,
            rationale: "Stay at \(Self.format(lastWeight)) kg — aim for \(sets)×\(target)\(weightPart) to close in on the top of the range."
                .replacingOccurrences(of: " @ 0 kg", with: ""),
            isProgression: false
        )
    }

    /// Most frequent value (the weight actually worked at across sets).
    private static func mode(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let counts = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
        return counts.max { a, b in a.value < b.value }?.key
    }

    /// Trims a trailing ".0" so 12.0 shows as "12" but 12.5 stays "12.5".
    static func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
