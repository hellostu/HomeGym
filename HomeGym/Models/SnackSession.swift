import Foundation
import SwiftData

/// A single prompted mini-workout: which exercise, the targets suggested at the
/// time, and the sets actually logged.
@Model
final class SnackSession {
    var date: Date
    var exercise: Exercise?
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double
    var completed: Bool
    var skipped: Bool

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet]

    init(
        date: Date = .now,
        exercise: Exercise?,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Double,
        completed: Bool = false,
        skipped: Bool = false,
        sets: [WorkoutSet] = []
    ) {
        self.date = date
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.completed = completed
        self.skipped = skipped
        self.sets = sets
    }

    /// Sets ordered as they were performed.
    var orderedSets: [WorkoutSet] {
        sets.sorted { $0.order < $1.order }
    }

    /// Heaviest weight lifted in the session — used for the history trend line.
    var topWeight: Double {
        sets.map(\.weight).max() ?? 0
    }
}
