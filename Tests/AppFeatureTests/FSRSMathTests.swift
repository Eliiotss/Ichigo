import XCTest
@testable import AppFeature

/// Unit tests for the FSRS-6 mathematics that drive scheduling. These are pure,
/// deterministic functions and form the correctness backbone of the app.
final class FSRSMathTests: XCTestCase {
    private let weights = FlashcardSettings().fsrsWeights

    func testInitialStabilityMatchesWeightsAndFloor() {
        XCTAssertEqual(FSRSMath.initialStability(grade: .again, w: weights), weights[0], accuracy: 1e-9)
        XCTAssertEqual(FSRSMath.initialStability(grade: .easy, w: weights), weights[3], accuracy: 1e-9)
        XCTAssertGreaterThanOrEqual(FSRSMath.initialStability(grade: .again, w: weights), 0.1)
    }

    func testInitialDifficultyIsClampedToRange() {
        for grade in FlashcardGrade.allCases {
            let d = FSRSMath.initialDifficulty(grade: grade, w: weights)
            XCTAssertGreaterThanOrEqual(d, 1.0)
            XCTAssertLessThanOrEqual(d, 10.0)
        }
    }

    func testRetrievabilityIsOneAtZeroElapsed() {
        let r = FSRSMath.retrievability(elapsedDays: 0, stability: 10, w: weights)
        XCTAssertEqual(r, 1.0, accuracy: 1e-9)
    }

    func testRetrievabilityDecaysOverTime() {
        let near = FSRSMath.retrievability(elapsedDays: 1, stability: 10, w: weights)
        let far = FSRSMath.retrievability(elapsedDays: 30, stability: 10, w: weights)
        XCTAssertGreaterThan(near, far)
        XCTAssertTrue((0...1).contains(far))
        XCTAssertTrue((0...1).contains(near))
    }

    func testRetrievabilityZeroForNonPositiveStability() {
        XCTAssertEqual(FSRSMath.retrievability(elapsedDays: 5, stability: 0, w: weights), 0)
    }

    func testNextIntervalIsAtLeastOneAndClamped() {
        let short = FSRSMath.nextInterval(stability: 0.2, desiredRetention: 0.9, maximumDays: 36500, w: weights)
        XCTAssertGreaterThanOrEqual(short, 1)

        let capped = FSRSMath.nextInterval(stability: 1_000_000, desiredRetention: 0.9, maximumDays: 10, w: weights)
        XCTAssertLessThanOrEqual(capped, 10)
    }

    func testNextIntervalGrowsWithStability() {
        let low = FSRSMath.nextInterval(stability: 5, desiredRetention: 0.9, maximumDays: 36500, w: weights)
        let high = FSRSMath.nextInterval(stability: 50, desiredRetention: 0.9, maximumDays: 36500, w: weights)
        XCTAssertGreaterThan(high, low)
    }

    func testNextDifficultyStaysWithinRange() {
        for grade in FlashcardGrade.allCases {
            let d = FSRSMath.nextDifficulty(current: 5.0, grade: grade, w: weights)
            XCTAssertGreaterThanOrEqual(d, 1.0)
            XCTAssertLessThanOrEqual(d, 10.0)
        }
    }

    func testStabilityOnRecallStaysAboveFloor() {
        let s = FSRSMath.nextStabilityOnRecall(stability: 10, difficulty: 5, retrievability: 0.9, grade: .good, w: weights)
        XCTAssertGreaterThanOrEqual(s, 0.1)
    }

    func testStabilityOnForgetStaysAboveFloor() {
        let s = FSRSMath.nextStabilityOnForget(stability: 10, difficulty: 5, retrievability: 0.9, w: weights)
        XCTAssertGreaterThanOrEqual(s, 0.1)
    }
}
