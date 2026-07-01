import Foundation

/// The gear available in Stu's home gym. Each piece knows the smallest weight
/// step you can realistically add, which drives progression suggestions.
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

    /// Smallest sensible weight increment (kg) when progressing this equipment.
    /// Dumbbells are per-hand adjustable in ~2 kg steps; the barbell takes small plates.
    var defaultIncrement: Double {
        switch self {
        case .adjustableDumbbells: return 2.0
        case .barbell: return 2.5
        case .ezBar: return 2.5
        case .bench, .bodyweight: return 0.0   // progressed by reps, not load
        }
    }

    /// Whether load is meaningful for this equipment. Bodyweight moves progress on reps only.
    var isWeighted: Bool {
        defaultIncrement > 0
    }
}
