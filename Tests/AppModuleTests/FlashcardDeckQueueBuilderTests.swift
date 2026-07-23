import XCTest
@testable import AppModule

/// Tests for ``FlashcardDeckQueueBuilder`` — the logic that assembles a study
/// session from due cards plus a capped number of brand-new cards.
final class FlashcardDeckQueueBuilderTests: XCTestCase {
    private let builder = FlashcardDeckQueueBuilder()

    private func card(_ id: String) -> FlashcardDeckCard {
        FlashcardDeckCard(vocab: VocabularyItem(id: id, kanji: "字", hiragana: "じ", arti: "arti", jenisKata: "Kata Benda"))
    }

    private func progress(id: String, dueOffset: TimeInterval, lapses: Int = 0) -> FlashcardProgress {
        FlashcardProgress(
            id: id, level: "vocabulary_N5", front: "字", back: "arti",
            state: .review, dueDate: Date().addingTimeInterval(dueOffset), stability: 10,
            difficulty: 5, reps: 3, lapses: lapses, lastReview: Date().addingTimeInterval(-86_400),
            scheduledDays: 10, learningStepIndex: 0
        )
    }

    func testNewCardsAreCappedByDailyLimit() {
        let cards = (0..<50).map { card("new-\($0)") }
        let settings = FlashcardSettings() // newCardsPerDay == 35
        let queue = builder.build(levelKey: "vocabulary_N5", items: cards, progress: [:], settings: settings)
        XCTAssertEqual(queue.count, settings.newCardsPerDay)
    }

    func testCardsStudiedTodayReduceNewLimit() {
        let cards = (0..<50).map { card("new-\($0)") }
        let settings = FlashcardSettings()
        let queue = builder.build(
            levelKey: "vocabulary_N5", items: cards, progress: [:], settings: settings,
            newCardsAlreadyStudiedToday: 30
        )
        XCTAssertEqual(queue.count, settings.newCardsPerDay - 30)
    }

    func testDueCardsAreOrderedByMostOverdue() {
        let cards = [card("a"), card("b"), card("c")]
        let progressMap: [String: FlashcardProgress] = [
            "a": progress(id: "a", dueOffset: -3_600),   // 1h overdue
            "b": progress(id: "b", dueOffset: -7_200),   // 2h overdue (most)
            "c": progress(id: "c", dueOffset: -1_800)    // 30m overdue
        ]
        let queue = builder.build(levelKey: "vocabulary_N5", items: cards, progress: progressMap, settings: FlashcardSettings())
        XCTAssertEqual(queue.map(\.id), ["b", "a", "c"])
    }

    func testCardsNotYetDueAreExcluded() {
        let cards = [card("future")]
        let progressMap = ["future": progress(id: "future", dueOffset: 86_400)] // due tomorrow
        let queue = builder.build(levelKey: "vocabulary_N5", items: cards, progress: progressMap, settings: FlashcardSettings())
        XCTAssertTrue(queue.isEmpty)
    }

    func testDueAndNewCardsAreCombinedWithoutDuplicates() {
        let due = card("due")
        let fresh = card("fresh")
        let progressMap = ["due": progress(id: "due", dueOffset: -600)]
        let queue = builder.build(levelKey: "vocabulary_N5", items: [due, fresh], progress: progressMap, settings: FlashcardSettings())
        XCTAssertEqual(Set(queue.map(\.id)), ["due", "fresh"])
        XCTAssertEqual(queue.count, 2)
    }
}
