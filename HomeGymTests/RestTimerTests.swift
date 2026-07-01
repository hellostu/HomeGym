import XCTest
@testable import HomeGym

final class RestTimerTests: XCTestCase {

    func testRemainingCountsDownFromEndDate() {
        let now = Date(timeIntervalSince1970: 1_000)
        let end = now.addingTimeInterval(90)
        XCTAssertEqual(RestTimer.remaining(endDate: end, now: now), 90, accuracy: 0.001)
    }

    func testRemainingNeverGoesNegative() {
        let now = Date(timeIntervalSince1970: 1_000)
        let end = now.addingTimeInterval(-5)   // already elapsed
        XCTAssertEqual(RestTimer.remaining(endDate: end, now: now), 0)
    }

    func testRemainingIsZeroWhenIdle() {
        XCTAssertEqual(RestTimer.remaining(endDate: nil, now: Date()), 0)
    }

    func testFormatRoundsUpToWholeSeconds() {
        XCTAssertEqual(RestTimer.format(90), "1:30")
        XCTAssertEqual(RestTimer.format(0.2), "0:01")   // 0.2s left still reads 0:01
        XCTAssertEqual(RestTimer.format(0), "0:00")
        XCTAssertEqual(RestTimer.format(125), "2:05")
    }
}
