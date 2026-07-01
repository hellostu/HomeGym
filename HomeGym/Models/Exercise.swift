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
    /// Ordered how-to steps shown in the popup. Defaulted so existing stores migrate.
    var instructions: [String] = []
    /// A single key form cue. Defaulted for lightweight migration.
    var formTip: String = ""
    /// Worked one side at a time (e.g. DB row, walking lunge): the target is "per side"
    /// and you do both sides for each logged set. Defaulted for lightweight migration.
    var isUnilateral: Bool = false

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
        lastPerformed: Date? = nil,
        instructions: [String] = [],
        formTip: String = "",
        isUnilateral: Bool = false
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
        self.instructions = instructions
        self.formTip = formTip
        self.isUnilateral = isUnilateral
    }

    /// A video demonstration for this exercise — a YouTube search so it always resolves
    /// to current, relevant clips rather than a hard-coded video that could disappear.
    var demoVideoURL: URL? {
        var components = URLComponents(string: "https://www.youtube.com/results")
        components?.queryItems = [URLQueryItem(name: "search_query", value: "\(name) exercise proper form")]
        return components?.url
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
