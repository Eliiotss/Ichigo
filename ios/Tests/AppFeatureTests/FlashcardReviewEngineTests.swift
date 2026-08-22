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

    func testGoodGraduatesAtGraduatingInterval() {
        // "Cara A": kartu baru yang lulus lewat Bagus memakai interval kelulusan
        // tetap `graduatingIntervalDays` (1 hari) — jadi kartu hari-1 muncul lagi
        // di hari-2, bukan dihitung dari stability.
        var card = newCard()
        card = engine.review(card: card, grade: .good, settings: settings).0
        card = engine.review(card: card, grade: .good, settings: settings).0
        card = engine.review(card: card, grade: .good, settings: settings).0
        XCTAssertEqual(card.state, .review)
        XCTAssertEqual(card.scheduledDays, settings.graduatingIntervalDays)
    }

    func testEasyGraduatesAtEasyInterval() {
        let (updated, _) = engine.review(card: newCard(), grade: .easy, settings: settings)
        XCTAssertEqual(updated.state, .review)
        XCTAssertEqual(updated.scheduledDays, settings.easyIntervalDays)
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

    // MARK: - Regresi: "lupa memangkas jadwal sesuai FSRS"
    //
    // Mengunci perilaku yang diminta: kartu yang sudah diingat, saat dijawab
    // Ulang, jadwalnya dipangkas lewat rumus lupa FSRS; sedangkan Susah tetap
    // recall berhasil (tumbuh lebih lambat, bukan memangkas).

    /// Kartu "review" matang: jatuh tempo hari ini dan terakhir direview
    /// `scheduledDays` hari lalu, supaya retrievability terhitung seperti di
    /// aplikasi (bukan review di hari yang sama).
    private func matureReview(stability: Double, difficulty: Double = 5.0, scheduledDays: Int) -> FlashcardProgress {
        let last = Calendar.current.date(byAdding: .day, value: -scheduledDays, to: Date())
        return FlashcardProgress(
            id: "card", level: "vocabulary_N5", front: "日", back: "hari",
            state: .review, dueDate: Date(), stability: stability, difficulty: difficulty,
            reps: 8, lapses: 0, lastReview: last, scheduledDays: scheduledDays, learningStepIndex: 0
        )
    }

    /// Memundurkan `lastReview` sebanyak interval terjadwal, jadi penilaian
    /// berikutnya dihitung seolah kartu direview tepat saat jatuh tempo.
    private func aged(_ card: FlashcardProgress) -> FlashcardProgress {
        var c = card
        c.lastReview = Calendar.current.date(byAdding: .day, value: -max(card.scheduledDays, 1), to: Date())
        return c
    }

    func testForgettingAfterRecallCutsScheduleViaFSRS() {
        let card = matureReview(stability: 100, difficulty: 4.0, scheduledDays: 108)
        let (afterAgain, _) = engine.review(card: card, grade: .again, settings: settings)
        XCTAssertEqual(afterAgain.state, .relearning)
        XCTAssertEqual(afterAgain.lapses, card.lapses + 1)
        XCTAssertLessThan(afterAgain.stability, card.stability)       // nextStabilityOnForget menurunkan S
        XCTAssertGreaterThan(afterAgain.difficulty, card.difficulty)  // difficulty naik saat lupa

        // Setelah lolos relearning (Bagus), interval jauh lebih kecil dari sebelum lupa.
        let (graduated, _) = engine.review(card: afterAgain, grade: .good, settings: settings)
        XCTAssertEqual(graduated.state, .review)
        XCTAssertLessThan(graduated.scheduledDays, card.scheduledDays)
    }

    func testHardStaysAboveButGrowsSlowerThanGood() {
        let base = matureReview(stability: 15, difficulty: 5.0, scheduledDays: 15)
        let (good, _) = engine.review(card: base, grade: .good, settings: settings)
        let (hard, _) = engine.review(card: base, grade: .hard, settings: settings)

        // Keduanya recall berhasil: stability tidak pernah turun di bawah semula.
        XCTAssertGreaterThanOrEqual(hard.stability, base.stability)
        XCTAssertGreaterThanOrEqual(good.stability, base.stability)
        // Susah tumbuh lebih lambat dari Bagus, dan difficulty-nya lebih tinggi.
        XCTAssertLessThan(hard.stability, good.stability)
        XCTAssertLessThanOrEqual(hard.scheduledDays, good.scheduledDays)
        XCTAssertGreaterThan(hard.difficulty, good.difficulty)
    }

    func testChainMudahBagusSusahThenUlangCutsSchedule() {
        // Mudah → lulus langsung
        var card = engine.review(card: newCard(), grade: .easy, settings: settings).0
        let i1 = card.scheduledDays
        XCTAssertGreaterThanOrEqual(i1, 1)

        // Bagus → interval naik
        card = engine.review(card: aged(card), grade: .good, settings: settings).0
        let i2 = card.scheduledDays
        XCTAssertGreaterThan(i2, i1)

        // Susah → masih naik (recall berhasil), bukan memangkas
        card = engine.review(card: aged(card), grade: .hard, settings: settings).0
        let i3 = card.scheduledDays
        XCTAssertGreaterThan(i3, i2)

        // Ulang → jadwal dipangkas lewat rumus lupa FSRS
        let stabilityBeforeForget = card.stability
        let (afterAgain, _) = engine.review(card: aged(card), grade: .again, settings: settings)
        XCTAssertEqual(afterAgain.state, .relearning)
        XCTAssertLessThan(afterAgain.stability, stabilityBeforeForget)

        let graduated = engine.review(card: afterAgain, grade: .good, settings: settings).0
        XCTAssertEqual(graduated.state, .review)
        XCTAssertLessThan(graduated.scheduledDays, i3)
    }
}
