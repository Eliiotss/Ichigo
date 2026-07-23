import XCTest
@testable import AppFeature

/// Behavioural tests for ``FlashcardReviewEngine`` — the state machine that moves
/// a card between new / learning / review / relearning and schedules its next due
/// date, mirroring Anki's learning-step semantics on top of FSRS.
final class FlashcardReviewEngineTests: XCTestCase {
    private let engine = FlashcardReviewEngine()
    private let settings = FlashcardSettings()

    private func newCard() -> FlashcardProgress {
        FlashcardProgress(
            id: "card", level: "vocabulary_N5", front: "日", back: "hari",
            state: .new, dueDate: Date(), stability: 0.1, difficulty: 5.0,
            reps: 0, lapses: 0, lastReview: nil, scheduledDays: 0, learningStepIndex: 0
        )
    }

    private func reviewCard(lapses: Int = 0, difficulty: Double = 5.0) -> FlashcardProgress {
        let yesterday = Date().addingTimeInterval(-86_400)
        return FlashcardProgress(
            id: "card", level: "vocabulary_N5", front: "日", back: "hari",
            state: .review, dueDate: yesterday, stability: 15, difficulty: difficulty,
            reps: 5, lapses: lapses, lastReview: yesterday, scheduledDays: 15, learningStepIndex: 0
        )
    }

    func testNewCardWithEasyGraduatesToReview() {
        let (updated, log) = engine.review(card: newCard(), grade: .easy, settings: settings)
        XCTAssertEqual(updated.state, .review)
        XCTAssertGreaterThanOrEqual(updated.scheduledDays, 1)
        XCTAssertGreaterThan(updated.dueDate, Date())
        XCTAssertEqual(log.grade, .easy)
        XCTAssertEqual(updated.reps, 1)
    }

    func testNewCardWithGoodEntersLearning() {
        let (updated, _) = engine.review(card: newCard(), grade: .good, settings: settings)
        XCTAssertEqual(updated.state, .learning)
    }

    func testLearningGraduatesAfterAllSteps() {
        // Default learning steps are [1, 10] minutes, so three "good" answers
        // (step 0 -> step 1 -> graduate) move a new card into review.
        var card = newCard()
        card = engine.review(card: card, grade: .good, settings: settings).0
        card = engine.review(card: card, grade: .good, settings: settings).0
        card = engine.review(card: card, grade: .good, settings: settings).0
        XCTAssertEqual(card.state, .review)
    }

    func testAgainDuringLearningResetsToFirstStep() {
        var card = engine.review(card: newCard(), grade: .good, settings: settings).0
        card = engine.review(card: card, grade: .again, settings: settings).0
        XCTAssertEqual(card.state, .learning)
        XCTAssertEqual(card.learningStepIndex, 0)
    }

    func testReviewAgainMovesToRelearningAndCountsLapse() {
        let (updated, _) = engine.review(card: reviewCard(), grade: .again, settings: settings)
        XCTAssertEqual(updated.state, .relearning)
        XCTAssertEqual(updated.lapses, 1)
    }

    func testReviewGoodStaysInReview() {
        let (updated, _) = engine.review(card: reviewCard(), grade: .good, settings: settings)
        XCTAssertEqual(updated.state, .review)
        XCTAssertGreaterThanOrEqual(updated.scheduledDays, 1)
    }

    func testLeechThresholdForcesMaximumDifficulty() {
        // One lapse below the leech threshold; the failing review pushes it over.
        let card = reviewCard(lapses: settings.leechThreshold - 1, difficulty: 4.0)
        let (updated, _) = engine.review(card: card, grade: .again, settings: settings)
        XCTAssertEqual(updated.lapses, settings.leechThreshold)
        XCTAssertEqual(updated.difficulty, 10.0, accuracy: 1e-9)
    }

    func testReviewLogCapturesTransition() {
        let (updated, log) = engine.review(card: reviewCard(), grade: .hard, settings: settings)
        XCTAssertEqual(log.cardId, updated.id)
        XCTAssertEqual(log.levelId, updated.level)
        XCTAssertEqual(log.state, updated.state)
        XCTAssertEqual(log.nextDueDate, updated.dueDate)
    }
}
