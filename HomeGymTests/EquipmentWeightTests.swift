import XCTest
@testable import HomeGym

final class EquipmentWeightTests: XCTestCase {

    // MARK: - Adjustable dumbbells (fixed ladder)

    func testDumbbellNextRungAcrossAGap() {
        XCTAssertEqual(Equipment.adjustableDumbbells.nextWeight(above: 13.6), 15.9)
        XCTAssertEqual(Equipment.adjustableDumbbells.nextWeight(above: 11.3), 12.5)
    }

    func testDumbbellHasNoRungAboveMax() {
        XCTAssertNil(Equipment.adjustableDumbbells.nextWeight(above: 31.8))
    }

    func testDumbbellSnapPicksNearestRung() {
        XCTAssertEqual(Equipment.adjustableDumbbells.snap(8), 7.9)
        XCTAssertEqual(Equipment.adjustableDumbbells.snap(16), 15.9)
    }

    // MARK: - Barbell (20 kg base, 5 kg steps)

    func testBarbellStepsByFiveFromBase() {
        XCTAssertEqual(Equipment.barbell.baseWeight, 20)
        XCTAssertEqual(Equipment.barbell.nextWeight(above: 20), 25)
        XCTAssertEqual(Equipment.barbell.nextWeight(above: 30), 35)
    }

    func testBarbellWontGoBelowEmptyBar() {
        XCTAssertNil(Equipment.barbell.previousWeight(below: 20))
        XCTAssertEqual(Equipment.barbell.previousWeight(below: 25), 20)
    }

    // MARK: - EZ bar (9.5 kg base, 5 kg steps)

    func testEZBarUsesNineAndHalfBase() {
        XCTAssertEqual(Equipment.ezBar.baseWeight, 9.5)
        XCTAssertEqual(Equipment.ezBar.nextWeight(above: 9.5), 14.5)
        XCTAssertEqual(Equipment.ezBar.snap(15), 14.5)   // 15 kg isn't achievable
    }
}
