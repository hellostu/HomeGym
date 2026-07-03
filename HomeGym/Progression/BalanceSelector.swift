import Foundation

/// Chooses which muscle group to train next so the week stays balanced — the app's
/// "personal trainer" logic. Picks the group you're most behind on (fewest sets this
/// week), breaking ties by whatever has gone longest without training. Pure/testable.
enum BalanceSelector {
    struct Candidate {
        let group: MuscleGroup
        let setsThisWeek: Int
        let weeklyTarget: Int
        let lastTrained: Date

        /// How much of this week's target is done (0 = untouched). Lower = more behind.
        var fillRatio: Double { Double(setsThisWeek) / Double(max(1, weeklyTarget)) }
    }

    /// The group most behind its *weighted* weekly target (so a big muscle like legs
    /// stays "behind" until it's had proportionally more sets), tie-broken by whatever
    /// has gone longest without training.
    static func mostBehind(_ candidates: [Candidate]) -> MuscleGroup? {
        candidates.min { a, b in
            if a.fillRatio != b.fillRatio { return a.fillRatio < b.fillRatio }
            return a.lastTrained < b.lastTrained
        }?.group
    }
}
