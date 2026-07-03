import XCTest
@testable import HomeGym

final class BalanceSelectorTests: XCTestCase {

    private func c(_ group: MuscleGroup, sets: Int, target: Int, day: Int) -> BalanceSelector.Candidate {
        BalanceSelector.Candidate(group: group, setsThisWeek: sets, weeklyTarget: target,
                                  lastTrained: Date(timeIntervalSince1970: TimeInterval(day) * 86_400))
    }

    func testPicksTheGroupFurthestBelowItsTarget() {
        let picked = BalanceSelector.mostBehind([
            c(.biceps, sets: 3, target: 6, day: 3),   // 50% done
            c(.legs, sets: 3, target: 10, day: 3),    // 30% done — most behind
            c(.chest, sets: 4, target: 9, day: 3)      // 44%
        ])
        XCTAssertEqual(picked, .legs)
    }

    func testWeightingCanPrioritiseAGroupWithMoreRawSets() {
        // Legs has MORE raw sets than biceps, but a higher target, so it's still behind.
        let picked = BalanceSelector.mostBehind([
            c(.legs, sets: 4, target: 10, day: 3),    // 40%
            c(.biceps, sets: 3, target: 6, day: 3)     // 50%
        ])
        XCTAssertEqual(picked, .legs)
    }

    func testTieOnFillRatioFallsBackToLeastRecentlyTrained() {
        let picked = BalanceSelector.mostBehind([
            c(.legs, sets: 3, target: 6, day: 5),
            c(.back, sets: 3, target: 6, day: 1),      // longest ago
            c(.chest, sets: 3, target: 6, day: 3)
        ])
        XCTAssertEqual(picked, .back)
    }

    func testReturnsNilWhenNoCandidates() {
        XCTAssertNil(BalanceSelector.mostBehind([]))
    }
}
