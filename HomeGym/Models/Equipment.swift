import Foundation

/// The gear available in Stu's home gym. Each piece knows how it can actually be
/// loaded — a fixed ladder for the adjustable dumbbells, or an empty-bar base plus a
/// minimum plate step for the barbell / EZ bar — which drives progression suggestions.
enum Equipment: String, CaseIterable, Codable, Identifiable {
    case adjustableDumbbells
    case barbell
    case ezBar
    case bench          // bench-only bodyweight moves (e.g. dips)
    case bodyweight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .adjustableDumbbells: return "Adjustable Dumbbells"
        case .barbell: return "Barbell"
        case .ezBar: return "EZ Curl Bar"
        case .bench: return "Bench"
        case .bodyweight: return "Bodyweight"
        }
    }

    /// Weight of the empty implement (kg). Plates are added on top of this.
    var baseWeight: Double {
        switch self {
        case .barbell: return 20.0
        case .ezBar: return 9.5
        default: return 0.0
        }
    }

    /// Smallest realistic *total* weight step (kg) when progressing this equipment.
    /// The barbell/EZ bar move in 5 kg jumps because the smallest plate is 2.5 kg and
    /// it goes on both sides. Dumbbells use their fixed ladder instead of this value.
    var defaultIncrement: Double {
        switch self {
        case .adjustableDumbbells: return 2.0   // nominal; real steps come from the ladder
        case .barbell, .ezBar: return 5.0        // 2.5 kg plate on each side
        case .bench, .bodyweight: return 0.0     // progressed by reps, not load
        }
    }

    /// Whether load is meaningful for this equipment. Bodyweight moves progress on reps only.
    var isWeighted: Bool {
        defaultIncrement > 0
    }

    /// Fixed set of loads for equipment that can only make certain weights (dumbbells).
    /// nil means "continuous" — use `baseWeight` + `defaultIncrement` steps instead.
    var availableWeights: [Double]? {
        switch self {
        case .adjustableDumbbells: return WeightLadder.adjustableDumbbell
        default: return nil
        }
    }

    // MARK: - Achievable weights

    /// The next load strictly above `weight` this equipment can actually make,
    /// or nil if it's already maxed out (only possible on the dumbbell ladder).
    func nextWeight(above weight: Double) -> Double? {
        if let ladder = availableWeights {
            return WeightLadder.next(above: weight, in: ladder)
        }
        guard isWeighted else { return nil }
        let steps = ((weight - baseWeight) / defaultIncrement + 1e-6).rounded(.down)
        return baseWeight + (steps + 1) * defaultIncrement
    }

    /// The previous achievable load strictly below `weight`, or nil at the bottom.
    func previousWeight(below weight: Double) -> Double? {
        if let ladder = availableWeights {
            return WeightLadder.previous(below: weight, in: ladder)
        }
        guard isWeighted else { return nil }
        let previous = snap(weight) - defaultIncrement
        return previous >= baseWeight ? previous : nil
    }

    /// Snaps an arbitrary weight to the nearest load this equipment can make.
    func snap(_ weight: Double) -> Double {
        if let ladder = availableWeights {
            return WeightLadder.snap(weight, to: ladder)
        }
        guard isWeighted else { return weight }
        if weight <= baseWeight { return baseWeight }
        let steps = max(0, ((weight - baseWeight) / defaultIncrement).rounded())
        return baseWeight + steps * defaultIncrement
    }
}
