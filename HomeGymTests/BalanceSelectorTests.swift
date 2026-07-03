import XCTest
@testable import HomeGym

final class BalanceSelectorTests: XCTestCase {

    private func c(_ group: MuscleGroup, sets: Int, day: Int) -> BalanceSelector.Candidate {
        BalanceSelector.Candidate(group: group, setsThisWeek: sets, lastTrained: Date(timeIntervalSince1970: TimeInterval(day) * 86_400))
    }

    func testPicksTheGroupWithFewestSetsThisWeek() {
        let picked = BalanceSelector.mostBehind([
            c(.biceps, sets: 6, day: 3),
            c(.legs, sets: 1, day: 3),
            c(.chest, sets: 3, day: 3)
        ])
        XCTAssertEqual(picked, .legs)
    }

    func testTieOnSetsFallsBackToLeastRecentlyTrained() {
        let picked = BalanceSelector.mostBehind([
            c(.legs, sets: 3, day: 5),      // trained more recently
            c(.back, sets: 3, day: 1),      // longest ago
            c(.chest, sets: 3, day: 3)
        ])
        XCTAssertEqual(picked, .back)
    }

    func testReturnsNilWhenNoCandidates() {
        XCTAssertNil(BalanceSelector.mostBehind([]))
    }
}
