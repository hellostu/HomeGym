import XCTest
@testable import HomeGym

final class PlateMathTests: XCTestCase {

    // MARK: - Per-side plate breakdown

    func testBarbellBreaksPerSideIntoLargestPlatesFirst() {
        // 60 kg on a 20 kg bar → 20 kg per side → one 20.
        let plates = PlateMath.perSidePlates(total: 60, equipment: .barbell)
        XCTAssertEqual(plates?.map(\.weight), [20])
        XCTAssertEqual(plates?.map(\.count), [1])
    }

    func testBarbellCombinesMultiplePlateSizes() {
        // 95 kg on a 20 kg bar → 37.5 kg per side → 25 + 10 + 2.5.
        let plates = PlateMath.perSidePlates(total: 95, equipment: .barbell)
        XCTAssertEqual(plates?.map(\.weight), [25, 10, 2.5])
        XCTAssertEqual(plates?.map(\.count), [1, 1, 1])
    }

    func testBarbellRepeatsAPlateWhenNeeded() {
        // 110 kg on a 20 kg bar → 45 kg per side → 25 + 20.
        // 130 kg → 55 kg per side → 2×25 + 5.
        let plates = PlateMath.perSidePlates(total: 130, equipment: .barbell)
        XCTAssertEqual(plates?.map(\.weight), [25, 5])
        XCTAssertEqual(plates?.map(\.count), [2, 1])
    }

    func testEmptyBarHasNoPlates() {
        XCTAssertEqual(PlateMath.perSidePlates(total: 20, equipment: .barbell), [])
        XCTAssertEqual(PlateMath.perSidePlates(total: 9.5, equipment: .ezBar), [])
    }

    func testEZBarSubtractsItsOwnBaseWeight() {
        // 29.5 kg on a 9.5 kg EZ bar → 10 kg per side → one 10.
        let plates = PlateMath.perSidePlates(total: 29.5, equipment: .ezBar)
        XCTAssertEqual(plates?.map(\.weight), [10])
        XCTAssertEqual(plates?.map(\.count), [1])
    }

    func testNonBarEquipmentReturnsNil() {
        XCTAssertNil(PlateMath.perSidePlates(total: 20, equipment: .adjustableDumbbells))
        XCTAssertNil(PlateMath.perSidePlates(total: 0, equipment: .bodyweight))
    }

    // MARK: - Human-readable description

    func testDescriptionJoinsPlatesLargestFirst() {
        XCTAssertEqual(PlateMath.perSideDescription(total: 95, equipment: .barbell), "25 + 10 + 2.5")
    }

    func testDescriptionUsesMultiplierForRepeatedPlates() {
        XCTAssertEqual(PlateMath.perSideDescription(total: 130, equipment: .barbell), "2×25 + 5")
    }

    func testDescriptionIsNilForEmptyBarAndNonBars() {
        XCTAssertNil(PlateMath.perSideDescription(total: 20, equipment: .barbell))
        XCTAssertNil(PlateMath.perSideDescription(total: 15, equipment: .adjustableDumbbells))
    }
}
