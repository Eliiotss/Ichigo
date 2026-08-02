import Foundation

/// Merges two ``BackupPayload`` snapshots into one, so cloud sync can be
/// *bidirectional* like Anki rather than a destructive overwrite.
///
/// The guiding rule is **never lose review progress**:
/// - **Per flashcard** (`flashcard_progress_v1`): the copy whose `lastReview` is
///   more recent wins. Studying a card on one device and then opening another
///   device therefore keeps the most recent schedule for that card. Ties break
///   toward the copy with more repetitions.
/// - **Review history** (`flashcard_reviews_v1`): the union of both logs, keyed
///   by the log's UUID, so no completed review is ever dropped.
/// - **Streak**: the larger of the two — a streak is never lost to a merge.
/// - **Day-boundary keys and preferences** (target, username, theme, …): the
///   *newer snapshot* wins, falling back to the other side when it is absent so a
///   value is never blanked out by an older, emptier snapshot.
/// - **Opaque blobs** (analytics summary, sync metadata, kana counts): newer
///   snapshot wins.
///
/// The inner `Data` blobs are the verbatim JSON produced by the individual
/// stores, which use a *default* `JSONEncoder`/`JSONDecoder`. This type must use
/// the same coders when it decodes and re-encodes them, otherwise the merged blob
/// would not round-trip back through the stores.
enum BackupMerge {
    /// Cap mirrors `FlashcardReviewStore.maxStoredLogs` so a merged log list never
    /// grows past what the store itself keeps.
    static let maxReviewLogs = 20_000

    static func merge(local: BackupPayload, remote: BackupPayload) -> BackupPayload {
        let localNewer = local.createdAt >= remote.createdAt

        func lww<T>(_ l: T?, _ r: T?) -> T? {
            localNewer ? (l ?? r) : (r ?? l)
        }

        return BackupPayload(
            schemaVersion: max(local.schemaVersion, remote.schemaVersion),
            createdAt: max(local.createdAt, remote.createdAt),
            appVersion: localNewer ? local.appVersion : remote.appVersion,
            flashcardProgress: mergeProgress(local.flashcardProgress, remote.flashcardProgress, localNewer: localNewer),
            flashcardSettings: lww(local.flashcardSettings, remote.flashcardSettings),
            flashcardReviews: mergeReviews(local.flashcardReviews, remote.flashcardReviews, localNewer: localNewer),
            flashcardAnalyticsSummary: lww(local.flashcardAnalyticsSummary, remote.flashcardAnalyticsSummary),
            flashcardSyncMetadata: lww(local.flashcardSyncMetadata, remote.flashcardSyncMetadata),
            hiraganaCount: lww(local.hiraganaCount, remote.hiraganaCount),
            katakanaCount: lww(local.katakanaCount, remote.katakanaCount),
            streak: mergeStreak(local.streak, remote.streak),
            lastStudyDayKey: lww(local.lastStudyDayKey, remote.lastStudyDayKey),
            lastResetDayKey: lww(local.lastResetDayKey, remote.lastResetDayKey),
            lastStudyDate: mergeMaxDate(local.lastStudyDate, remote.lastStudyDate),
            newTodayLists: mergeNewToday(local.newTodayLists, remote.newTodayLists),
            dailyAnalytics: mergeDailyAnalytics(local.dailyAnalytics, remote.dailyAnalytics, localNewer: localNewer),
            userName: lww(local.userName, remote.userName),
            userEmail: lww(local.userEmail, remote.userEmail),
            dailyTarget: lww(local.dailyTarget, remote.dailyTarget),
            notifEnabled: lww(local.notifEnabled, remote.notifEnabled),
            notifHour: lww(local.notifHour, remote.notifHour),
            appearance: lww(local.appearance, remote.appearance)
        )
    }

    // MARK: - Flashcard progress (per-card, newest review wins)

    static func mergeProgress(_ l: Data?, _ r: Data?, localNewer: Bool) -> Data? {
        guard let l else { return r }
        guard let r else { return l }
        let decoder = JSONDecoder()
        guard let localMap = try? decoder.decode([String: FlashcardProgress].self, from: l),
              let remoteMap = try? decoder.decode([String: FlashcardProgress].self, from: r) else {
            // One side is unreadable — keep the newer snapshot's bytes rather than
            // risk fabricating a broken merge.
            return localNewer ? l : r
        }
        var merged = localMap
        for (id, remoteCard) in remoteMap {
            if let localCard = merged[id] {
                merged[id] = winner(localCard, remoteCard)
            } else {
                merged[id] = remoteCard
            }
        }
        return (try? JSONEncoder().encode(merged)) ?? (localNewer ? l : r)
    }

    /// The card whose most recent review is later wins; ties break toward more
    /// repetitions, then toward `a` (the local side) for determinism.
    private static func winner(_ a: FlashcardProgress, _ b: FlashcardProgress) -> FlashcardProgress {
        let aReview = a.lastReview ?? .distantPast
        let bReview = b.lastReview ?? .distantPast
        if aReview != bReview { return aReview > bReview ? a : b }
        if a.reps != b.reps { return a.reps > b.reps ? a : b }
        return a
    }

    // MARK: - Review logs (union by id)

    static func mergeReviews(_ l: Data?, _ r: Data?, localNewer: Bool) -> Data? {
        guard let l else { return r }
        guard let r else { return l }
        let decoder = JSONDecoder()
        guard let localLogs = try? decoder.decode([FlashcardReviewLog].self, from: l),
              let remoteLogs = try? decoder.decode([FlashcardReviewLog].self, from: r) else {
            return localNewer ? l : r
        }
        var byId: [UUID: FlashcardReviewLog] = [:]
        for log in localLogs { byId[log.id] = log }
        for log in remoteLogs { byId[log.id] = log }
        var merged = byId.values.sorted { $0.reviewedAt < $1.reviewedAt }
        if merged.count > maxReviewLogs { merged = Array(merged.suffix(maxReviewLogs)) }
        return (try? JSONEncoder().encode(merged)) ?? (localNewer ? l : r)
    }

    // MARK: - Scalars & dictionaries

    private static func mergeStreak(_ l: Int?, _ r: Int?) -> Int? {
        switch (l, r) {
        case let (l?, r?): return max(l, r)
        case let (l?, nil): return l
        case let (nil, r?): return r
        default: return nil
        }
    }

    private static func mergeMaxDate(_ l: Date?, _ r: Date?) -> Date? {
        switch (l, r) {
        case let (l?, r?): return max(l, r)
        case let (l?, nil): return l
        case let (nil, r?): return r
        default: return nil
        }
    }

    /// Which new cards were introduced on a given day: union the id lists per day
    /// so a card counted as "new" on either device stays counted once.
    static func mergeNewToday(_ l: [String: [String]], _ r: [String: [String]]) -> [String: [String]] {
        var merged = l
        for (key, ids) in r {
            guard let existing = merged[key] else { merged[key] = ids; continue }
            var seen = Set(existing)
            var combined = existing
            for id in ids where seen.insert(id).inserted { combined.append(id) }
            merged[key] = combined
        }
        return merged
    }

    static func mergeDailyAnalytics(_ l: [String: Data], _ r: [String: Data], localNewer: Bool) -> [String: Data] {
        var merged = l
        for (key, data) in r where merged[key] == nil || !localNewer {
            merged[key] = data
        }
        return merged
    }
}
