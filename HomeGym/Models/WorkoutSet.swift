import Foundation
import SwiftData

/// One logged set within a snack session.
@Model
final class WorkoutSet {
    var weight: Double
    var reps: Int
    var timestamp: Date
    var order: Int
    var session: SnackSession?

    init(weight: Double, reps: Int, order: Int, timestamp: Date = .now, session: SnackSession? = nil) {
        self.weight = weight
        self.reps = reps
        self.order = order
        self.timestamp = timestamp
        self.session = session
    }
}
