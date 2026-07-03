import Foundation

/// Chooses which muscle group to train next so the week stays balanced — the app's
/// "personal trainer" logic. Picks the group you're most behind on (fewest sets this
/// week), breaking ties by whatever has gone longest without training. Pure/testable.
enum BalanceSelector {
    struct Candidate {
        let group: MuscleGroup
        let setsThisWeek: Int
        let lastTrained: Date
    }

    static func mostBehind(_ candidates: [Candidate]) -> MuscleGroup? {
        candidates.min { a, b in
            if a.setsThisWeek != b.setsThisWeek { return a.setsThisWeek < b.setsThisWeek }
            return a.lastTrained < b.lastTrained
        }?.group
    }
}
