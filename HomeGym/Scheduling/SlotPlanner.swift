import Foundation

/// Plain scheduling parameters, decoupled from the SwiftData `AppSettings` model
/// so the planner is trivially unit-testable.
struct SchedulingParams: Equatable {
    var workStartHour: Int = 9
    var workEndHour: Int = 17
    var targetWorkoutsPerDay: Int = 3
    var minGapMinutes: Int = 90
    var weekdaysOnly: Bool = true
}

/// Pure functions that decide *when* to prompt. No timers, no calendar, no storage —
/// everything is passed in, so behaviour is deterministic and testable.
enum SlotPlanner {

    /// The planned prompt times for a given day, spread across work hours while
    /// respecting `minGapMinutes` and `targetWorkoutsPerDay`.
    ///
    /// - Parameter randomOffset: given a max jitter (seconds), returns an offset in
    ///   `[-max, +max]`. Defaults to zero (segment midpoints) for deterministic tests;
    ///   the live scheduler injects real randomness so prompts feel spontaneous.
    static func plannedSlots(
        for day: Date,
        params: SchedulingParams,
        calendar: Calendar = .current,
        randomOffset: (Double) -> Double = { _ in 0 }
    ) -> [Date] {
        guard let start = calendar.date(bySettingHour: params.workStartHour, minute: 0, second: 0, of: day),
              let end = calendar.date(bySettingHour: params.workEndHour, minute: 0, second: 0, of: day),
              end > start else {
            return []
        }

        if params.weekdaysOnly && !isWeekday(day, calendar: calendar) {
            return []
        }

        let total = end.timeIntervalSince(start)                 // seconds in the work window
        let minGap = Double(max(0, params.minGapMinutes)) * 60

        // Largest count that still respects the minimum gap.
        let maxByGap = minGap > 0 ? max(1, Int(total / minGap)) : params.targetWorkoutsPerDay
        let n = max(1, min(params.targetWorkoutsPerDay, maxByGap))

        let segment = total / Double(n)
        // Jitter budget that provably preserves the minimum gap (see plan notes).
        let maxJitter = segment > minGap ? (segment - minGap) / 2 * 0.9 : 0

        return (0..<n).map { i in
            let base = start.timeIntervalSince1970 + segment * (Double(i) + 0.5)
            let jittered = base + randomOffset(maxJitter)
            return Date(timeIntervalSince1970: jittered)
        }
    }

    /// The next prompt time strictly after `now` that is not blocked by a busy calendar.
    /// Looks at today's remaining slots first, then rolls forward up to `lookaheadDays`.
    static func nextSlot(
        after now: Date,
        params: SchedulingParams,
        calendar: Calendar = .current,
        lookaheadDays: Int = 7,
        randomOffset: (Double) -> Double = { _ in 0 },
        isBusy: (Date) -> Bool = { _ in false }
    ) -> Date? {
        for dayOffset in 0...lookaheadDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let slots = plannedSlots(for: day, params: params, calendar: calendar, randomOffset: randomOffset)
            for slot in slots where slot > now && !isBusy(slot) {
                return slot
            }
        }
        return nil
    }

    static func isWeekday(_ date: Date, calendar: Calendar = .current) -> Bool {
        !calendar.isDateInWeekend(date)
    }
}
