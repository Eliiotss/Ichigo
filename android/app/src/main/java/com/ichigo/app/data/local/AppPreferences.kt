package com.ichigo.app.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.ichigo.app.data.flashcard.FlashcardAnalyticsSummary
import com.ichigo.app.data.flashcard.FlashcardGrade
import com.ichigo.app.data.model.AppAppearance
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "ichigo_prefs")

/**
 * DataStore wrapper for every scalar the iOS app kept in `UserDefaults` (see
 * BackupKeys.swift). Keys are preserved verbatim so the intent — and any future
 * cross-platform backup interop — stays aligned. Analytics counters are stored
 * as individual ints rather than a JSON blob, but the numbers (and the derived
 * accuracy) are identical to `FlashcardAnalyticsSummary`.
 */
@Singleton
class AppPreferences @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val ds get() = context.dataStore

    private object Keys {
        val userName = stringPreferencesKey("user_name")
        val userEmail = stringPreferencesKey("user_email")
        val dailyTarget = intPreferencesKey("daily_target")
        val notifEnabled = booleanPreferencesKey("notif_enabled")
        val notifHour = intPreferencesKey("notif_hour")
        val reminderSmart = booleanPreferencesKey("reminder_smart_v1")
        val appearance = stringPreferencesKey(AppAppearance.STORAGE_KEY)

        val streak = intPreferencesKey("flashcard_streak_v1")
        val lastStudyDayKey = stringPreferencesKey("flashcard_last_study_day_key_v1")
        val lastResetDayKey = stringPreferencesKey("flashcard_last_reset_day_key_v1")
        val lastStudyDate = longPreferencesKey("flashcard_last_study_date")
        val firstInstall = longPreferencesKey("first_install_date_v1")

        val googleEmail = stringPreferencesKey("google_account_email")
        val autoSync = booleanPreferencesKey("auto_sync_enabled")
        val driveLastSync = longPreferencesKey("drive_last_sync")
        val deviceId = stringPreferencesKey("drive_device_id")

        // analytics summary (flashcard_analytics_summary_v1) as scalar counters
        val anTotal = intPreferencesKey("analytics_total")
        val anAgain = intPreferencesKey("analytics_again")
        val anHard = intPreferencesKey("analytics_hard")
        val anGood = intPreferencesKey("analytics_good")
        val anEasy = intPreferencesKey("analytics_easy")
        val anLast = longPreferencesKey("analytics_last")

        // Grammar points the user has marked as learned (star). Set of GrammarItem.id.
        val learnedGrammar = stringSetPreferencesKey("learned_grammar_ids_v1")

        // First-run onboarding completed.
        val onboardingDone = booleanPreferencesKey("onboarding_done_v1")

        // Reviews-per-day, "yyyy-MM-dd" → count, as a small JSON map (for the chart).
        val dailyStudy = stringPreferencesKey("daily_study_v1")
    }

    private val mapJson = kotlinx.serialization.json.Json { ignoreUnknownKeys = true }
    private val dayCountSerializer = kotlinx.serialization.builtins.MapSerializer(
        kotlinx.serialization.serializer<String>(),
        kotlinx.serialization.serializer<Int>(),
    )

    private fun decodeDaily(raw: String?): Map<String, Int> =
        raw?.let { runCatching { mapJson.decodeFromString(dayCountSerializer, it) }.getOrNull() } ?: emptyMap()

    private fun dayKeyOf(millis: Long): String {
        val d = java.time.Instant.ofEpochMilli(millis).atZone(java.time.ZoneId.systemDefault()).toLocalDate()
        return "%04d-%02d-%02d".format(d.year, d.monthValue, d.dayOfMonth)
    }

    // --- Account / preferences (defaults match AccountStore + @AppStorage) ---
    val userName: Flow<String> = ds.data.map { it[Keys.userName] ?: "user123" }
    val userEmail: Flow<String> = ds.data.map { it[Keys.userEmail] ?: "" }
    val dailyTarget: Flow<Int> = ds.data.map { it[Keys.dailyTarget] ?: 20 }
    val notifEnabled: Flow<Boolean> = ds.data.map { it[Keys.notifEnabled] ?: false }
    val notifHour: Flow<Int> = ds.data.map { it[Keys.notifHour] ?: 20 }
    /** Reminder mode: false = Manual (always remind), true = Pintar (skip if already studied today). */
    val reminderSmart: Flow<Boolean> = ds.data.map { it[Keys.reminderSmart] ?: false }
    suspend fun setReminderSmart(value: Boolean) = ds.edit { it[Keys.reminderSmart] = value }
    suspend fun reminderSmartNow(): Boolean = reminderSmart.first()
    /** Reviews recorded today (used by the smart reminder to decide whether to skip). */
    suspend fun studiedTodayCount(): Int = dailyStudy.first()[dayKeyOf(System.currentTimeMillis())] ?: 0
    val appearance: Flow<AppAppearance> = ds.data.map { AppAppearance.from(it[Keys.appearance]) }
    val googleEmail: Flow<String?> = ds.data.map { it[Keys.googleEmail] }
    val autoSync: Flow<Boolean> = ds.data.map { it[Keys.autoSync] ?: false }
    val streak: Flow<Int> = ds.data.map { it[Keys.streak] ?: 0 }
    val driveLastSync: Flow<Long?> = ds.data.map { it[Keys.driveLastSync] }

    /** Grammar points marked as learned (star). Drives the "Total kartu" stat. */
    val learnedGrammarIds: Flow<Set<String>> = ds.data.map { it[Keys.learnedGrammar] ?: emptySet() }

    /** Toggle a grammar point's learned mark. */
    suspend fun setGrammarLearned(id: String, learned: Boolean) = ds.edit { p ->
        val current = (p[Keys.learnedGrammar] ?: emptySet()).toMutableSet()
        if (learned) current.add(id) else current.remove(id)
        p[Keys.learnedGrammar] = current
    }

    /** First-run onboarding (name + target). Defaults to not-done. */
    val onboardingDone: Flow<Boolean> = ds.data.map { it[Keys.onboardingDone] ?: false }
    suspend fun setOnboardingDone() = ds.edit { it[Keys.onboardingDone] = true }

    /** Reviews-per-day map ("yyyy-MM-dd" → count) for the Profile study chart. */
    val dailyStudy: Flow<Map<String, Int>> = ds.data.map { decodeDaily(it[Keys.dailyStudy]) }

    /** Counts one review on the day of [atMillis]; keeps only the most recent 40 days. */
    suspend fun recordStudyDay(atMillis: Long = System.currentTimeMillis()) = ds.edit { p ->
        val key = dayKeyOf(atMillis)
        val current = decodeDaily(p[Keys.dailyStudy]).toMutableMap()
        current[key] = (current[key] ?: 0) + 1
        val pruned = current.entries.sortedByDescending { it.key }.take(40).associate { it.key to it.value }
        p[Keys.dailyStudy] = mapJson.encodeToString(dayCountSerializer, pruned)
    }

    suspend fun setDriveLastSync(value: Long) = ds.edit { it[Keys.driveLastSync] = value }
    suspend fun driveLastSyncOrNull(): Long? = driveLastSync.first()
    suspend fun autoSyncNow(): Boolean = autoSync.first()

    /** Stable per-install id used to tag backups. Generated once, then reused. */
    suspend fun deviceId(): String {
        val existing = ds.data.map { it[Keys.deviceId] }.first()
        if (existing != null) return existing
        val id = java.util.UUID.randomUUID().toString()
        ds.edit { it[Keys.deviceId] = id }
        return id
    }

    suspend fun setUserName(value: String) = ds.edit { it[Keys.userName] = value }
    suspend fun setUserEmail(value: String) = ds.edit { it[Keys.userEmail] = value }
    suspend fun setDailyTarget(value: Int) = ds.edit { it[Keys.dailyTarget] = value.coerceIn(5, 200) }
    suspend fun setNotifEnabled(value: Boolean) = ds.edit { it[Keys.notifEnabled] = value }
    suspend fun setNotifHour(value: Int) = ds.edit { it[Keys.notifHour] = value.coerceIn(6, 23) }
    suspend fun setAppearance(value: AppAppearance) = ds.edit { it[Keys.appearance] = value.rawValue }
    suspend fun setGoogleEmail(value: String?) = ds.edit {
        if (value == null) it.remove(Keys.googleEmail) else it[Keys.googleEmail] = value
    }
    suspend fun setAutoSync(value: Boolean) = ds.edit { it[Keys.autoSync] = value }

    suspend fun dailyTargetNow(): Int = dailyTarget.first()

    // --- Streak / day boundary scalars ---
    suspend fun currentStreak(): Int = ds.data.map { it[Keys.streak] ?: 0 }.first()
    suspend fun lastStudyDayKey(): String? = ds.data.map { it[Keys.lastStudyDayKey] }.first()
    suspend fun lastResetDayKey(): String? = ds.data.map { it[Keys.lastResetDayKey] }.first()

    suspend fun setStreak(value: Int) = ds.edit { it[Keys.streak] = value }
    suspend fun setLastStudyDayKey(value: String) = ds.edit { it[Keys.lastStudyDayKey] = value }
    suspend fun setLastResetDayKey(value: String) = ds.edit { it[Keys.lastResetDayKey] = value }
    suspend fun setLastStudyDate(value: Long) = ds.edit { it[Keys.lastStudyDate] = value }

    suspend fun registerFirstInstallIfNeeded(now: Long) = ds.edit {
        if (it[Keys.firstInstall] == null) it[Keys.firstInstall] = now
    }

    // --- Analytics summary ---
    val analytics: Flow<FlashcardAnalyticsSummary> = ds.data.map {
        FlashcardAnalyticsSummary(
            totalReviews = it[Keys.anTotal] ?: 0,
            againCount = it[Keys.anAgain] ?: 0,
            hardCount = it[Keys.anHard] ?: 0,
            goodCount = it[Keys.anGood] ?: 0,
            easyCount = it[Keys.anEasy] ?: 0,
            lastReviewedAt = it[Keys.anLast],
        )
    }

    /** Overwrites the analytics summary (used when restoring a Drive backup). */
    suspend fun setAnalytics(summary: FlashcardAnalyticsSummary) = ds.edit { p ->
        p[Keys.anTotal] = summary.totalReviews
        p[Keys.anAgain] = summary.againCount
        p[Keys.anHard] = summary.hardCount
        p[Keys.anGood] = summary.goodCount
        p[Keys.anEasy] = summary.easyCount
        summary.lastReviewedAt?.let { p[Keys.anLast] = it }
    }

    /** Snapshot of all scalar preferences + day/streak keys for a backup. */
    data class Snapshot(
        val userName: String,
        val userEmail: String,
        val dailyTarget: Int,
        val notifEnabled: Boolean,
        val notifHour: Int,
        val appearance: String,
        val streak: Int,
        val lastStudyDayKey: String?,
        val lastResetDayKey: String?,
        val analytics: FlashcardAnalyticsSummary,
    )

    suspend fun snapshot(): Snapshot = ds.data.map { p ->
        Snapshot(
            userName = p[Keys.userName] ?: "user123",
            userEmail = p[Keys.userEmail] ?: "",
            dailyTarget = p[Keys.dailyTarget] ?: 20,
            notifEnabled = p[Keys.notifEnabled] ?: false,
            notifHour = p[Keys.notifHour] ?: 20,
            appearance = p[Keys.appearance] ?: AppAppearance.SYSTEM.rawValue,
            streak = p[Keys.streak] ?: 0,
            lastStudyDayKey = p[Keys.lastStudyDayKey],
            lastResetDayKey = p[Keys.lastResetDayKey],
            analytics = FlashcardAnalyticsSummary(
                totalReviews = p[Keys.anTotal] ?: 0,
                againCount = p[Keys.anAgain] ?: 0,
                hardCount = p[Keys.anHard] ?: 0,
                goodCount = p[Keys.anGood] ?: 0,
                easyCount = p[Keys.anEasy] ?: 0,
                lastReviewedAt = p[Keys.anLast],
            ),
        )
    }.first()

    /** Increments the summary for a graded review, matching `FlashcardAnalyticsStore.record`. */
    suspend fun recordAnalytics(grade: FlashcardGrade, reviewedAt: Long) = ds.edit { p ->
        p[Keys.anTotal] = (p[Keys.anTotal] ?: 0) + 1
        p[Keys.anLast] = reviewedAt
        when (grade) {
            FlashcardGrade.AGAIN -> p[Keys.anAgain] = (p[Keys.anAgain] ?: 0) + 1
            FlashcardGrade.HARD -> p[Keys.anHard] = (p[Keys.anHard] ?: 0) + 1
            FlashcardGrade.GOOD -> p[Keys.anGood] = (p[Keys.anGood] ?: 0) + 1
            FlashcardGrade.EASY -> p[Keys.anEasy] = (p[Keys.anEasy] ?: 0) + 1
        }
    }

    /**
     * Reset matching `FlashcardDataResetter.resetAll`: clears streak + last study
     * date only (progress/reviews are cleared via Room). Analytics and day-reset
     * keys are intentionally left untouched, exactly like the iOS resetAll.
     */
    suspend fun resetStudyScalars() = ds.edit {
        it.remove(Keys.streak)
        it.remove(Keys.lastStudyDate)
    }

    /** Clears the answer-summary analytics (used by a full progress reset). */
    suspend fun clearAnalytics() = ds.edit { p ->
        p.remove(Keys.anTotal); p.remove(Keys.anAgain); p.remove(Keys.anHard)
        p.remove(Keys.anGood); p.remove(Keys.anEasy); p.remove(Keys.anLast)
    }

    /** Clears the 7-day study chart data. */
    suspend fun clearDailyStudy() = ds.edit { it.remove(Keys.dailyStudy) }
}
