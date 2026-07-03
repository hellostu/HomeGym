import Foundation

/// Detects whether a just-completed session set a personal record for its exercise,
/// compared with prior completed sessions. Pure and unit-tested.
enum PRDetector {
    struct Record: Equatable {
        enum Kind: Equatable { case weight, reps }
        let kind: Kind
        let weight: Double
        let reps: Int
    }

    /// - Parameters:
    ///   - session: the just-completed session.
    ///   - previous: earlier completed sessions for the *same* exercise (excluding this one).
    ///   - weighted: whether the exercise uses load.
    /// Returns a record if this session beat the previous best. The very first session
    /// for an exercise is a baseline, not a PR, so it returns nil when there's no history.
    static func record(for session: SnackSession, previous: [SnackSession], weighted: Bool) -> Record? {
        let sets = session.sets
        guard !sets.isEmpty, !previous.isEmpty else { return nil }

        if weighted {
            let topWeight = sets.map(\.weight).max() ?? 0
            let repsAtTop = sets.filter { $0.weight == topWeight }.map(\.reps).max() ?? 0
            let priorTopWeight = previous.flatMap { $0.sets }.map(\.weight).max() ?? 0

            if topWeight > priorTopWeight {
                return Record(kind: .weight, weight: topWeight, reps: repsAtTop)
            }
            if topWeight == priorTopWeight, topWeight > 0 {
                let priorRepsAtTop = previous
                    .flatMap { $0.sets }
                    .filter { $0.weight == topWeight }
                    .map(\.reps)
                    .max() ?? 0
                if repsAtTop > priorRepsAtTop {
                    return Record(kind: .reps, weight: topWeight, reps: repsAtTop)
                }
            }
            return nil
        } else {
            let bestReps = sets.map(\.reps).max() ?? 0
            let priorReps = previous.flatMap { $0.sets }.map(\.reps).max() ?? 0
            return bestReps > priorReps ? Record(kind: .reps, weight: 0, reps: bestReps) : nil
        }
    }
}
