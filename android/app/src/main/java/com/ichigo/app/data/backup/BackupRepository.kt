package com.ichigo.app.data.backup

import com.ichigo.app.data.flashcard.FlashcardAnalyticsSummary
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.data.local.dao.KanaCountDao
import com.ichigo.app.data.local.dao.NewCardTodayDao
import com.ichigo.app.data.local.dao.ProgressDao
import com.ichigo.app.data.local.entity.KanaCountEntity
import com.ichigo.app.data.local.entity.NewCardTodayEntity
import com.ichigo.app.data.local.entity.ProgressEntity
import com.ichigo.app.data.model.AppAppearance
import com.ichigo.app.data.repository.FlashcardRepository
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Turns the local database + preferences into a [BackupPayload] and back. Used by
 * the Drive sync manager to push/pull-merge, the Android equivalent of the iOS
 * `BackupService` capturing/restoring the `UserDefaults` stores.
 */
@Singleton
class BackupRepository @Inject constructor(
    private val progressDao: ProgressDao,
    private val newCardTodayDao: NewCardTodayDao,
    private val kanaCountDao: KanaCountDao,
    private val prefs: AppPreferences,
    private val flashcards: FlashcardRepository,
) {
    suspend fun export(deviceId: String): BackupPayload {
        val progress = progressDao.getAll().map {
            BackupProgress(
                id = it.id, level = it.level, front = it.front, back = it.back,
                state = it.state, dueDate = it.dueDate, stability = it.stability, difficulty = it.difficulty,
                reps = it.reps, lapses = it.lapses, lastReview = it.lastReview,
                scheduledDays = it.scheduledDays, learningStepIndex = it.learningStepIndex,
            )
        }
        val newToday = newCardTodayDao.getAll().map { BackupNewToday(it.levelKey, it.day, it.cardId) }
        val kana = kanaCountDao.getAll().map { BackupKana(it.kana, it.script, it.count) }
        val s = prefs.snapshot()
        return BackupPayload(
            schemaVersion = 1,
            createdAt = System.currentTimeMillis(),
            deviceId = deviceId,
            progress = progress,
            streak = s.streak,
            lastStudyDayKey = s.lastStudyDayKey,
            lastResetDayKey = s.lastResetDayKey,
            newToday = newToday,
            kanaCounts = kana,
            resetAt = prefs.lastResetAt().takeIf { it > 0L },
            analytics = BackupAnalytics(
                totalReviews = s.analytics.totalReviews,
                again = s.analytics.againCount,
                hard = s.analytics.hardCount,
                good = s.analytics.goodCount,
                easy = s.analytics.easyCount,
                lastReviewedAt = s.analytics.lastReviewedAt,
            ),
            userName = s.userName,
            userEmail = s.userEmail,
            dailyTarget = s.dailyTarget,
            notifEnabled = s.notifEnabled,
            notifHour = s.notifHour,
            appearance = s.appearance,
        )
    }

    /**
     * Writes a (merged) payload back into the local database + preferences.
     *
     * If the payload carries a reset tombstone newer than the one this device
     * knows about, the local flashcard tables are cleared first. Without that
     * step a "Reset progress" performed on another device would never reach this
     * one: [apply] only upserts, so every old row would simply stay behind.
     * The payload has already been filtered by [BackupMerge], so what is written
     * back afterwards is exactly the post-reset state.
     */
    suspend fun apply(p: BackupPayload) {
        val incomingReset = p.resetAt ?: 0L
        if (incomingReset > prefs.lastResetAt()) {
            progressDao.deleteAll()
            newCardTodayDao.deleteAll()
            prefs.setLastResetAt(incomingReset)
        }
        p.progress.forEach {
            progressDao.upsert(
                ProgressEntity(
                    id = it.id, level = it.level, front = it.front, back = it.back,
                    state = it.state, dueDate = it.dueDate, stability = it.stability, difficulty = it.difficulty,
                    reps = it.reps, lapses = it.lapses, lastReview = it.lastReview,
                    scheduledDays = it.scheduledDays, learningStepIndex = it.learningStepIndex,
                ),
            )
        }
        p.newToday.forEach { newCardTodayDao.insertIgnore(NewCardTodayEntity(it.levelKey, it.day, it.cardId)) }
        p.kanaCounts.forEach { kanaCountDao.upsert(KanaCountEntity(it.kana, it.script, it.count)) }

        p.userName?.let { prefs.setUserName(it) }
        p.userEmail?.let { prefs.setUserEmail(it) }
        p.dailyTarget?.let { prefs.setDailyTarget(it) }
        p.notifEnabled?.let { prefs.setNotifEnabled(it) }
        p.notifHour?.let { prefs.setNotifHour(it) }
        p.appearance?.let { prefs.setAppearance(AppAppearance.from(it)) }
        prefs.setStreak(p.streak)
        p.lastStudyDayKey?.let { prefs.setLastStudyDayKey(it) }
        p.lastResetDayKey?.let { prefs.setLastResetDayKey(it) }
        prefs.setAnalytics(
            FlashcardAnalyticsSummary(
                totalReviews = p.analytics.totalReviews,
                againCount = p.analytics.again,
                hardCount = p.analytics.hard,
                goodCount = p.analytics.good,
                easyCount = p.analytics.easy,
                lastReviewedAt = p.analytics.lastReviewedAt,
            ),
        )
        flashcards.reloadFromDb()
    }
}
