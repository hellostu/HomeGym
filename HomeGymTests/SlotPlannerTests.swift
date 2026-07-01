import XCTest
@testable import HomeGym

final class SlotPlannerTests: XCTestCase {

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    /// 2025-06-02 is a Monday; 2025-06-01 is a Sunday.
    private func date(y: Int = 2025, m: Int = 6, d: Int, h: Int = 0, min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private let params = SchedulingParams(
        workStartHour: 9, workEndHour: 17,
        targetWorkoutsPerDay: 3, minGapMinutes: 90, weekdaysOnly: true
    )

    func testPlannedSlotsRespectCountWindowAndGap() {
        let slots = SlotPlanner.plannedSlots(for: date(d: 2), params: params, calendar: calendar)

        XCTAssertEqual(slots.count, 3)

        let start = date(d: 2, h: 9)
        let end = date(d: 2, h: 17)
        for slot in slots {
            XCTAssertGreaterThanOrEqual(slot, start)
            XCTAssertLessThanOrEqual(slot, end)
        }

        let gaps = zip(slots, slots.dropFirst()).map { $1.timeIntervalSince($0) }
        for gap in gaps {
            XCTAssertGreaterThanOrEqual(gap, Double(params.minGapMinutes) * 60)
        }
    }

    func testWeekdaysOnlyExcludesWeekend() {
        let slots = SlotPlanner.plannedSlots(for: date(d: 1), params: params, calendar: calendar) // Sunday
        XCTAssertTrue(slots.isEmpty)
    }

    func testNextSlotSkipsBusyTimes() {
        let now = date(d: 2, h: 9)
        // Mark the 13:00 slot as busy.
        let busy: (Date) -> Bool = { slot in
            self.calendar.component(.hour, from: slot) == 13
        }

        let next = SlotPlanner.nextSlot(after: now, params: params, calendar: calendar, isBusy: busy)

        XCTAssertNotNil(next)
        if let next {
            XCTAssertFalse(busy(next), "Scheduler must never land on a busy slot")
            XCTAssertGreaterThan(next, now)
        }
    }

    func testNextSlotRollsToNextWeekdayWhenTodayIsExhausted() {
        // Friday 2025-06-06 at 23:00 — no slots left today, weekend skipped, so Monday.
        let fridayNight = date(d: 6, h: 23)
        let next = SlotPlanner.nextSlot(after: fridayNight, params: params, calendar: calendar)

        XCTAssertNotNil(next)
        if let next {
            let weekday = calendar.component(.weekday, from: next)
            XCTAssertFalse(calendar.isDateInWeekend(next))
            XCTAssertEqual(weekday, 2, "Should roll forward to Monday")
        }
    }
}
