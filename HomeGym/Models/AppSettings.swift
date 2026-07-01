import Foundation
import SwiftData

/// Single-row settings object controlling when and how often HomeGym prompts.
@Model
final class AppSettings {
    var workStartHour: Int          // 24h, e.g. 9
    var workEndHour: Int            // 24h, e.g. 17
    var targetWorkoutsPerDay: Int
    var minGapMinutes: Int
    var weekdaysOnly: Bool
    /// When true, an event on the calendar blocks a prompt (deferred to a free slot).
    var calendarBusyIsBlocking: Bool
    /// Muscle groups the user wants included, stored as raw strings.
    var enabledMuscleGroupsRaw: [String]
    /// If the user pauses for the day, prompting resumes the next eligible day.
    var pausedUntil: Date?
    /// Default rest-timer duration between sets, in seconds. Defaulted for migration.
    var restSeconds: Int = 90

    init(
        workStartHour: Int = 9,
        workEndHour: Int = 17,
        targetWorkoutsPerDay: Int = 3,
        minGapMinutes: Int = 90,
        weekdaysOnly: Bool = true,
        calendarBusyIsBlocking: Bool = true,
        enabledMuscleGroups: [MuscleGroup] = MuscleGroup.allCases,
        pausedUntil: Date? = nil,
        restSeconds: Int = 90
    ) {
        self.workStartHour = workStartHour
        self.workEndHour = workEndHour
        self.targetWorkoutsPerDay = targetWorkoutsPerDay
        self.minGapMinutes = minGapMinutes
        self.weekdaysOnly = weekdaysOnly
        self.calendarBusyIsBlocking = calendarBusyIsBlocking
        self.enabledMuscleGroupsRaw = enabledMuscleGroups.map(\.rawValue)
        self.pausedUntil = pausedUntil
        self.restSeconds = restSeconds
    }

    var enabledMuscleGroups: Set<MuscleGroup> {
        get { Set(enabledMuscleGroupsRaw.compactMap(MuscleGroup.init(rawValue:))) }
        set { enabledMuscleGroupsRaw = newValue.map(\.rawValue) }
    }
}
