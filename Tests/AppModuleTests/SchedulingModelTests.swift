import XCTest
@testable import AppModule

/// Tests for the value types and helpers that surround scheduling: progress
/// flags, the day-key used for streaks, the retention validator, analytics and
/// deck-card mapping.
final class SchedulingModelTests: XCTestCase {

    // MARK: - FlashcardProgress flags

    private func progress(state: FlashcardCardState, scheduledDays: Int, dueOffset: TimeInterval) -> FlashcardProgress {
        FlashcardProgress(
            id: "x", level: "vocabulary_N5", front: "a", back: "b",
            state: state, dueDate: Date().addingTimeInterval(dueOffset), stability: 10,
            difficulty: 5, reps: 1, lapses: 0, lastReview: Date().addingTimeInterval(-86_400),
            scheduledDays: scheduledDays, learningStepIndex: 0
        )
    }

    func testIsMasteredRequiresReviewStateAndLongInterval() {
        XCTAssertTrue(progress(state: .review, scheduledDays: 21, dueOffset: 3_600).isMastered)
        XCTAssertFalse(progress(state: .review, scheduledDays: 20, dueOffset: 3_600).isMastered)
        XCTAssertFalse(progress(state: .learning, scheduledDays: 30, dueOffset: 3_600).isMastered)
    }

    func testIsDueReflectsDueDate() {
        XCTAssertTrue(progress(state: .review, scheduledDays: 5, dueOffset: -60).isDue)
        XCTAssertFalse(progress(state: .review, scheduledDays: 5, dueOffset: 60).isDue)
    }

    // MARK: - Level key

    func testFlashcardLevelKeyFormat() {
        XCTAssertEqual(flashcardLevelKey(mode: .vocabulary, levelId: "N5"), "vocabulary_N5")
        XCTAssertEqual(flashcardLevelKey(mode: .grammar, levelId: "N4"), "grammar_N4")
    }

    // MARK: - Day key

    func testDayKeyCompactFormat() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        let key = FlashcardDayKey.today(calendar: calendar, date: date)
        XCTAssertEqual(key.compact, "2026-01-05-Asia/Tokyo")
    }

    // MARK: - Retention validator

    func testValidatorAcceptsHealthyProgress() {
        let valid = FlashcardProgress(
            id: "x", level: "k", front: "a", back: "b", state: .review,
            dueDate: Date().addingTimeInterval(3_600), stability: 5, difficulty: 5,
            reps: 2, lapses: 0, lastReview: Date(), scheduledDays: 5, learningStepIndex: 0
        )
        XCTAssertTrue(FSRSRetentionValidator().validate(progress: valid).isValid)
    }

    func testValidatorRejectsOutOfRangeValues() {
        let lowStability = FlashcardProgress(
            id: "x", level: "k", front: "a", back: "b", state: .learning,
            dueDate: Date(), stability: 0.05, difficulty: 5, reps: 0, lapses: 0,
            lastReview: nil, scheduledDays: 0, learningStepIndex: 0
        )
        XCTAssertFalse(FSRSRetentionValidator().validate(progress: lowStability).isValid)

        let badDifficulty = FlashcardProgress(
            id: "x", level: "k", front: "a", back: "b", state: .learning,
            dueDate: Date(), stability: 5, difficulty: 12, reps: 0, lapses: 0,
            lastReview: nil, scheduledDays: 0, learningStepIndex: 0
        )
        XCTAssertFalse(FSRSRetentionValidator().validate(progress: badDifficulty).isValid)
    }

    // MARK: - Analytics accuracy

    func testAnalyticsAccuracy() {
        let summary = FlashcardAnalyticsSummary(
            totalReviews: 10, againCount: 2, hardCount: 3, goodCount: 4, easyCount: 1, lastReviewedAt: nil
        )
        XCTAssertEqual(summary.accuracy, 0.8, accuracy: 1e-9)
    }

    func testAnalyticsAccuracyWithNoReviews() {
        let summary = FlashcardAnalyticsSummary(
            totalReviews: 0, againCount: 0, hardCount: 0, goodCount: 0, easyCount: 0, lastReviewedAt: nil
        )
        XCTAssertEqual(summary.accuracy, 0)
    }

    // MARK: - Deck-card mapping

    func testDeckCardFromVocabulary() {
        let card = FlashcardDeckCard(vocab: VocabularyItem(id: "1", kanji: "日", hiragana: "ひ", arti: "hari", jenisKata: "Kata Benda"))
        XCTAssertEqual(card.mode, .vocabulary)
        XCTAssertEqual(card.front, "日")
        XCTAssertEqual(card.revealedTitle, "ひ")
        XCTAssertEqual(card.revealedBody, "hari")
        XCTAssertEqual(card.revealedTag, "Kata Benda")
    }

    func testDeckCardFromGrammarUsesExplanation() {
        let card = FlashcardDeckCard(grammar: .sample)
        XCTAssertEqual(card.mode, .grammar)
        XCTAssertEqual(card.front, GrammarItem.sample.pattern)
        XCTAssertEqual(card.revealedTitle, GrammarItem.sample.meaning)
        XCTAssertEqual(card.revealedBody, GrammarItem.sample.explanation)
    }
}
