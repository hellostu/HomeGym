import Foundation

/// Discrete weight "ladders" for equipment that can only make certain loads.
///
/// Stu's adjustable dumbbells are a pound-based set, so the achievable weights are
/// the odd kg values printed on the converter sticker — and the ladder has gaps where
/// the set skips a stop (e.g. 13.6 → 15.9). Progression must land on a real rung, not
/// an arbitrary `current + increment` value the dumbbell can't actually be set to.
enum WeightLadder {

    /// Available per-hand dumbbell weights in kg (converted from the imperial set).
    static let adjustableDumbbell: [Double] = [
        4.5, 5.7, 6.8, 7.9, 9.0, 10.2, 11.3, 12.5, 13.6,
        15.9, 17.0, 18.1, 20.4, 21.5, 22.6, 24.9, 26.0, 27.2,
        29.5, 30.6, 31.8
    ]

    /// The next achievable rung strictly above `weight`, or nil if already at the top.
    static func next(above weight: Double, in ladder: [Double]) -> Double? {
        ladder.first { $0 > weight + 0.01 }
    }

    /// The previous achievable rung strictly below `weight`, or nil if at the bottom.
    static func previous(below weight: Double, in ladder: [Double]) -> Double? {
        ladder.last { $0 < weight - 0.01 }
    }

    /// The closest rung to an arbitrary weight — used to snap starting suggestions.
    static func snap(_ weight: Double, to ladder: [Double]) -> Double {
        ladder.min { abs($0 - weight) < abs($1 - weight) } ?? weight
    }
}
