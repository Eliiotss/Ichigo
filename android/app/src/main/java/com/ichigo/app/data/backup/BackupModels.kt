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
        // Per-card: newer lastReview wins (null = never reviewed = loses to a real review).
        val byId = LinkedHashMap<String, BackupProgress>()
        for (p in a.progress) byId[p.id] = p
        for (p in b.progress) {
            val existing = byId[p.id]
            byId[p.id] = if (existing == null || (p.lastReview ?: Long.MIN_VALUE) >= (existing.lastReview ?: Long.MIN_VALUE)) p else existing
        }

        // New-today: union by (levelKey, day, cardId).
        val newToday = (a.newToday + b.newToday).distinctBy { Triple(it.levelKey, it.day, it.cardId) }

        // Kana: max count per (kana, script).
        val kanaMap = HashMap<Pair<String, String>, Int>()
        for (k in a.kanaCounts + b.kanaCounts) {
            val key = k.kana to k.script
            kanaMap[key] = maxOf(kanaMap[key] ?: 0, k.count)
        }
        val kana = kanaMap.map { (k, v) -> BackupKana(k.first, k.second, v) }

        // Analytics: whichever recorded more reviews (proxy for the more-studied device).
        val analytics = if (a.analytics.totalReviews >= b.analytics.totalReviews) a.analytics else b.analytics

        // Preferences + day keys: newer snapshot wins.
        val newer = if (a.createdAt >= b.createdAt) a else b
        val older = if (a.createdAt >= b.createdAt) b else a

        return BackupPayload(
            schemaVersion = maxOf(a.schemaVersion, b.schemaVersion),
            createdAt = maxOf(a.createdAt, b.createdAt),
            deviceId = newer.deviceId,
            progress = byId.values.toList(),
            streak = maxOf(a.streak, b.streak),
            lastStudyDayKey = newer.lastStudyDayKey ?: older.lastStudyDayKey,
            lastResetDayKey = newer.lastResetDayKey ?: older.lastResetDayKey,
            newToday = newToday,
            kanaCounts = kana,
            analytics = analytics,
            userName = newer.userName ?: older.userName,
            userEmail = newer.userEmail ?: older.userEmail,
            dailyTarget = newer.dailyTarget ?: older.dailyTarget,
            notifEnabled = newer.notifEnabled ?: older.notifEnabled,
            notifHour = newer.notifHour ?: older.notifHour,
            appearance = newer.appearance ?: older.appearance,
        )
    }
}
