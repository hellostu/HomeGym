import Foundation

/// The muscle groups HomeGym rotates through so a week of snack workouts stays balanced.
enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case biceps
    case triceps
    case shoulders
    case chest
    case back
    case legs
    case glutes
    case core

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .shoulders: return "Shoulders"
        case .chest: return "Chest"
        case .back: return "Back"
        case .legs: return "Legs"
        case .glutes: return "Glutes"
        case .core: return "Core"
        }
    }

    /// Target sets per week for a group to count as fully trained. Bigger muscles need
    /// more volume, so legs/back need more sets to "glow" than arms — this weights both
    /// the heat-map colour and how often the group is prioritised.
    var weeklySetTarget: Int {
        switch self {
        case .legs, .back: return 10
        case .chest: return 9
        case .glutes, .shoulders: return 8
        case .biceps, .triceps, .core: return 6
        }
    }

    /// SF Symbol used in menus and the popup.
    var symbolName: String {
        switch self {
        case .biceps, .triceps, .shoulders, .chest, .back: return "figure.strengthtraining.traditional"
        case .legs, .glutes: return "figure.strengthtraining.functional"
        case .core: return "figure.core.training"
        }
    }
}
