import XCTest
@testable import AppFeature

/// Tests for the bidirectional sync merge. The guarantee under test is that a
/// merge never loses review progress: the most recently reviewed copy of a card
/// wins, review logs are unioned, and streaks only ever grow.
final class BackupMergeTests: XCTestCase {
    private let ref = Date(timeIntervalSinceReferenceDate: 700_000_000) // fixed base

    // MARK: - Fixtures

    private func card(_ id: String, reps: Int, lastReview: Date?, due: Date) -> FlashcardProgress {
        FlashcardProgress(id: id, level: "N5", front: "f", back: "b", state: .review,
                          dueDate: due, stability: 10, difficulty: 5, reps: reps, lapses: 0,
                          lastReview: lastReview, scheduledDays: 3, learningStepIndex: 0)
    }

    private func progressBlob(_ cards: [FlashcardProgress]) -> Data {
        let map = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
        return try! JSONEncoder().encode(map)
    }

    private func decodeProgress(_ data: Data?) -> [String: FlashcardProgress] {
        guard let data else { return [:] }
        return (try? JSONDecoder().decode([String: FlashcardProgress].self, from: data)) ?? [:]
    }

    private func reviewLog(_ id: UUID, at: Date) -> FlashcardReviewLog {
        FlashcardReviewLog(id: id, cardId: "c", levelId: "N5", grade: .good,
                           reviewedAt: at, nextDueDate: at.addingTimeInterval(86_400), state: .review)
    }

    private func reviewsBlob(_ logs: [FlashcardReviewLog]) -> Data {
        try! JSONEncoder().encode(logs)
    }

    private func payload(createdAt: Date,
                         progress: Data? = nil,
                         reviews: Data? = nil,
                         streak: Int? = nil,
                         dailyTarget: Int? = nil,
                         userName: String? = nil,
                         newToday: [String: [String]] = [:]) -> BackupPayload {
        BackupPayload(schemaVersion: 1, createdAt: createdAt, appVersion: "1.0",
                      flashcardProgress: progress, flashcardSettings: nil, flashcardReviews: reviews,
                      flashcardAnalyticsSummary: nil, flashcardSyncMetadata: nil,
                      hiraganaCount: nil, katakanaCount: nil,
                      streak: streak, lastStudyDayKey: nil, lastResetDayKey: nil, lastStudyDate: nil,
                      newTodayLists: newToday, dailyAnalytics: [:],
                      userName: userName, userEmail: nil, dailyTarget: dailyTarget,
                      notifEnabled: nil, notifHour: nil, appearance: nil)
    }

    // MARK: - Per-card newest review wins

    func testCardWithMoreRecentReviewWins() {
        let older = card("v1", reps: 3, lastReview: ref, due: ref.addingTimeInterval(86_400))
        let newer = card("v1", reps: 5, lastReview: ref.addingTimeInterval(3_600), due: ref.addingTimeInterval(5 * 86_400))

        // Remote snapshot is stamped newer overall, but the *local* card was
        // reviewed more recently — the per-card rule must still keep the local one.
        let local = payload(createdAt: ref, progress: progressBlob([newer]))
        let remote = payload(createdAt: ref.addingTimeInterval(10_000), progress: progressBlob([older]))

        let merged = BackupMerge.merge(local: local, remote: remote)
        let card = decodeProgress(merged.flashcardProgress)["v1"]
        XCTAssertEqual(card?.reps, 5)
        XCTAssertEqual(card?.lastReview, ref.addingTimeInterval(3_600))
    }

    func testCardsUniqueToEachSideAreBothKept() {
        let a = card("a", reps: 1, lastReview: ref, due: ref)
        let b = card("b", reps: 1, lastReview: ref, due: ref)
        let local = payload(createdAt: ref, progress: progressBlob([a]))
        let remote = payload(createdAt: ref, progress: progressBlob([b]))

        let merged = decodeProgress(BackupMerge.merge(local: local, remote: remote).flashcardProgress)
        XCTAssertEqual(Set(merged.keys), ["a", "b"])
    }

    func testNilProgressFallsBackToOtherSide() {
        let a = card("a", reps: 2, lastReview: ref, due: ref)
        let local = payload(createdAt: ref, progress: nil)
        let remote = payload(createdAt: ref, progress: progressBlob([a]))
        let merged = decodeProgress(BackupMerge.merge(local: local, remote: remote).flashcardProgress)
        XCTAssertEqual(merged["a"]?.reps, 2)
    }

    // MARK: - Review log union

    func testReviewLogsAreUnionedAndDeduplicated() {
        let shared = UUID()
        let localOnly = UUID()
        let remoteOnly = UUID()
        let local = payload(createdAt: ref, reviews: reviewsBlob([
            reviewLog(shared, at: ref), reviewLog(localOnly, at: ref.addingTimeInterval(100))
        ]))
        let remote = payload(createdAt: ref, reviews: reviewsBlob([
            reviewLog(shared, at: ref), reviewLog(remoteOnly, at: ref.addingTimeInterval(200))
        ]))

        let merged = BackupMerge.merge(local: local, remote: remote)
        let logs = try! JSONDecoder().decode([FlashcardReviewLog].self, from: merged.flashcardReviews!)
        XCTAssertEqual(Set(logs.map(\.id)), [shared, localOnly, remoteOnly])
        // Sorted ascending by reviewedAt.
        XCTAssertEqual(logs.map(\.reviewedAt), logs.map(\.reviewedAt).sorted())
    }

    // MARK: - Scalars

    func testStreakTakesTheLarger() {
        let local = payload(createdAt: ref.addingTimeInterval(10_000), streak: 3)
        let remote = payload(createdAt: ref, streak: 12)
        XCTAssertEqual(BackupMerge.merge(local: local, remote: remote).streak, 12)
    }

    func testPreferenceFromNewerSnapshotWins() {
        let local = payload(createdAt: ref, dailyTarget: 20, userName: "Old")
        let remote = payload(createdAt: ref.addingTimeInterval(5_000), dailyTarget: 45, userName: "New")
        let merged = BackupMerge.merge(local: local, remote: remote)
        XCTAssertEqual(merged.dailyTarget, 45)
        XCTAssertEqual(merged.userName, "New")
    }

    func testNewerNilPreferenceFallsBackToOlderValue() {
        // Newer snapshot lacks a username; the older non-nil value must survive.
        let local = payload(createdAt: ref, userName: "Budi")
        let remote = payload(createdAt: ref.addingTimeInterval(5_000), userName: nil)
        XCTAssertEqual(BackupMerge.merge(local: local, remote: remote).userName, "Budi")
    }

    func testNewTodayListsAreUnioned() {
        let key = "flashcard_new_today_vocabulary_N5_2026-08-02"
        let local = payload(createdAt: ref, newToday: [key: ["a", "b"]])
        let remote = payload(createdAt: ref, newToday: [key: ["b", "c"]])
        let merged = BackupMerge.merge(local: local, remote: remote)
        XCTAssertEqual(merged.newTodayLists[key].map(Set.init), ["a", "b", "c"])
    }

    func testMergedCreatedAtIsTheLater() {
        let local = payload(createdAt: ref)
        let remote = payload(createdAt: ref.addingTimeInterval(9_000))
        XCTAssertEqual(BackupMerge.merge(local: local, remote: remote).createdAt, ref.addingTimeInterval(9_000))
    }
}
