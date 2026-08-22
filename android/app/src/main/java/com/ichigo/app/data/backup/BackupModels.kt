package com.ichigo.app.data.backup

import kotlinx.serialization.Serializable

/**
 * Portable snapshot of all local learning progress, synced to Google Drive's
 * private appDataFolder. The merge philosophy mirrors the iOS `BackupMerge` and
 * the web port: for each card the copy with the newer last review wins, the
 * streak takes the higher value, and preferences follow the newer snapshot.
 *
 * This is an Android↔Android format (JSON). Interop with the iOS/web formats can
 * be added later; the field names are kept close to the app's models.
 */
@Serializable
data class BackupPayload(
    val schemaVersion: Int = 1,
    val createdAt: Long = 0,
    val deviceId: String = "",
    val progress: List<BackupProgress> = emptyList(),
    val streak: Int = 0,
    val lastStudyDayKey: String? = null,
    val lastResetDayKey: String? = null,
    val newToday: List<BackupNewToday> = emptyList(),
    val kanaCounts: List<BackupKana> = emptyList(),
    val analytics: BackupAnalytics = BackupAnalytics(),
    /**
     * Epoch millis of the last "Reset progress" the user performed, or null if
     * never. This is a **tombstone**: anything not studied since this moment is
     * dropped by [BackupMerge], which is what makes a reset stick instead of
     * being undone by the next sync. Optional, so backups written by older
     * versions still decode (they simply carry no tombstone).
     */
    val resetAt: Long? = null,
    /**
     * Per-word progress for the Vocab multiple-choice quiz. Optional (default
     * empty) so older backups still decode; merged per-word by newer
     * `lastAnswered`, and cleared by the same reset tombstone as [progress].
     */
    val quizResults: List<BackupQuizResult> = emptyList(),
    val userName: String? = null,
    val userEmail: String? = null,
    val dailyTarget: Int? = null,
    val notifEnabled: Boolean? = null,
    val notifHour: Int? = null,
    val appearance: String? = null,
)

@Serializable
data class BackupProgress(
    val id: String,
    val level: String,
    val front: String,
    val back: String,
    val state: String,
    val dueDate: Long,
    val stability: Double,
    val difficulty: Double,
    val reps: Int,
    val lapses: Int,
    val lastReview: Long?,
    val scheduledDays: Int,
    val learningStepIndex: Int,
)

@Serializable
data class BackupNewToday(val levelKey: String, val day: String, val cardId: String)

@Serializable
data class BackupKana(val kana: String, val script: String, val count: Int)

@Serializable
data class BackupQuizResult(val wordId: String, val score: Int, val lastAnswered: Long)

@Serializable
data class BackupAnalytics(
    val totalReviews: Int = 0,
    val again: Int = 0,
    val hard: Int = 0,
    val good: Int = 0,
    val easy: Int = 0,
    val lastReviewedAt: Long? = null,
)

/**
 * Merges two snapshots into one, resolving conflicts the same way as the iOS
 * app so progress is never lost.
 */
object BackupMerge {

    fun merge(a: BackupPayload, b: BackupPayload): BackupPayload {
        // The newest reset wins. Everything that was not studied since then is
        // considered deleted on purpose — see [BackupPayload.resetAt].
        val resetAt = maxOf(a.resetAt ?: 0L, b.resetAt ?: 0L)

        // Per-card: newer lastReview wins (null = never reviewed = loses to a real review).
        val byId = LinkedHashMap<String, BackupProgress>()
        for (p in a.progress) byId[p.id] = p
        for (p in b.progress) {
            val existing = byId[p.id]
            byId[p.id] = if (existing == null || (p.lastReview ?: Long.MIN_VALUE) >= (existing.lastReview ?: Long.MIN_VALUE)) p else existing
        }
        // A card survives a reset only if it was reviewed at or after it.
        val progress = byId.values.filter { survivesReset(it.lastReview, resetAt) }
        val keptIds = progress.mapTo(HashSet()) { it.id }

        // New-today: union by (levelKey, day, cardId), minus anything the reset removed.
        val newToday = (a.newToday + b.newToday)
            .distinctBy { Triple(it.levelKey, it.day, it.cardId) }
            .filter { resetAt == 0L || it.cardId in keptIds }

        // Kana: max count per (kana, script). Reset does not clear kana progress
        // (FlashcardRepository.resetAll leaves the kana_count table alone), so
        // the tombstone deliberately does not apply here.
        val kanaMap = HashMap<Pair<String, String>, Int>()
        for (k in a.kanaCounts + b.kanaCounts) {
            val key = k.kana to k.script
            kanaMap[key] = maxOf(kanaMap[key] ?: 0, k.count)
        }
        val kana = kanaMap.map { (k, v) -> BackupKana(k.first, k.second, v) }

        // Quiz results: newer lastAnswered wins per word; cleared by the same
        // reset tombstone as flashcard progress (resetAll wipes quiz_result too).
        val quizById = LinkedHashMap<String, BackupQuizResult>()
        for (q in a.quizResults) quizById[q.wordId] = q
        for (q in b.quizResults) {
            val existing = quizById[q.wordId]
            quizById[q.wordId] = if (existing == null || q.lastAnswered >= existing.lastAnswered) q else existing
        }
        val quizResults = quizById.values.filter { survivesReset(it.lastAnswered, resetAt) }

        // Analytics / streak may only come from a side whose data post-dates the
        // reset; otherwise a stale device would restore the old totals.
        val liveSides = listOf(a, b).filter { isPostReset(it, resetAt) }
        val analytics = liveSides.maxByOrNull { it.analytics.totalReviews }?.analytics ?: BackupAnalytics()
        val streak = liveSides.maxOfOrNull { it.streak } ?: 0

        // Preferences + day keys: newer snapshot wins.
        val newer = if (a.createdAt >= b.createdAt) a else b
        val older = if (a.createdAt >= b.createdAt) b else a

        return BackupPayload(
            schemaVersion = maxOf(a.schemaVersion, b.schemaVersion),
            createdAt = maxOf(a.createdAt, b.createdAt),
            deviceId = newer.deviceId,
            progress = progress,
            streak = streak,
            lastStudyDayKey = newer.lastStudyDayKey ?: older.lastStudyDayKey,
            lastResetDayKey = newer.lastResetDayKey ?: older.lastResetDayKey,
            newToday = newToday,
            kanaCounts = kana,
            analytics = analytics,
            resetAt = resetAt.takeIf { it > 0L },
            quizResults = quizResults,
            userName = newer.userName ?: older.userName,
            userEmail = newer.userEmail ?: older.userEmail,
            dailyTarget = newer.dailyTarget ?: older.dailyTarget,
            notifEnabled = newer.notifEnabled ?: older.notifEnabled,
            notifHour = newer.notifHour ?: older.notifHour,
            appearance = newer.appearance ?: older.appearance,
        )
    }

    /** No tombstone → keep everything. Otherwise: only cards studied since it. */
    private fun survivesReset(lastReview: Long?, resetAt: Long): Boolean =
        resetAt == 0L || (lastReview ?: Long.MIN_VALUE) >= resetAt

    /**
     * True when this snapshot's study data is at least as new as the reset —
     * either because this is the device that reset, or because it has recorded a
     * review since. Used to decide whose streak/analytics may survive.
     */
    private fun isPostReset(p: BackupPayload, resetAt: Long): Boolean =
        resetAt == 0L ||
            (p.resetAt ?: 0L) >= resetAt ||
            (p.analytics.lastReviewedAt ?: Long.MIN_VALUE) >= resetAt
}
