import Foundation

/// The muscle groups HomeGym rotates through so a week of snack workouts stays balanced.
enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case biceps
    case triceps
    case shoulders
    case chest
    case back
    case legs
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
        case .core: return "Core"
        }
    }

    /// SF Symbol used in menus and the popup.
    var symbolName: String {
        switch self {
        case .biceps, .triceps, .shoulders, .chest, .back: return "figure.strengthtraining.traditional"
        case .legs: return "figure.strengthtraining.functional"
        case .core: return "figure.core.training"
        }
    }
}
