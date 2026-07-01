import Foundation
import SwiftData

/// A library exercise. Muscle group and equipment are stored as raw strings for
/// robust SwiftData persistence, with typed accessors for the rest of the app.
@Model
final class Exercise {
    var name: String
    var muscleGroupRaw: String
    var equipmentRaw: String
    var repRangeLower: Int
    var repRangeUpper: Int
    var defaultSets: Int
    var weightIncrement: Double
    /// Conservative first-time load suggestion (kg). Zero for bodyweight moves.
    var startingWeight: Double
    var isEnabled: Bool
    /// When this exercise was last performed — drives least-recently-trained rotation.
    var lastPerformed: Date?

    init(
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        repRangeLower: Int = 8,
        repRangeUpper: Int = 12,
        defaultSets: Int = 3,
        weightIncrement: Double? = nil,
        startingWeight: Double = 0,
        isEnabled: Bool = true,
        lastPerformed: Date? = nil
    ) {
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.equipmentRaw = equipment.rawValue
        self.repRangeLower = repRangeLower
        self.repRangeUpper = repRangeUpper
        self.defaultSets = defaultSets
        self.weightIncrement = weightIncrement ?? equipment.defaultIncrement
        self.startingWeight = startingWeight
        self.isEnabled = isEnabled
        self.lastPerformed = lastPerformed
    }

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .core }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .bodyweight }
        set { equipmentRaw = newValue.rawValue }
    }

    var repRangeDescription: String {
        "\(repRangeLower)–\(repRangeUpper)"
    }
}
