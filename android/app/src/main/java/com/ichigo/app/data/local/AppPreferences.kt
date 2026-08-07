package com.ichigo.app.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
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
        val appearance = stringPreferencesKey(AppAppearance.STORAGE_KEY)

        val streak = intPreferencesKey("flashcard_streak_v1")
        val lastStudyDayKey = stringPreferencesKey("flashcard_last_study_day_key_v1")
        val lastResetDayKey = stringPreferencesKey("flashcard_last_reset_day_key_v1")
        val lastStudyDate = longPreferencesKey("flashcard_last_study_date")
        val firstInstall = longPreferencesKey("first_install_date_v1")

        val googleEmail = stringPreferencesKey("google_account_email")
        val autoSync = booleanPreferencesKey("auto_sync_enabled")

        // analytics summary (flashcard_analytics_summary_v1) as scalar counters
        val anTotal = intPreferencesKey("analytics_total")
        val anAgain = intPreferencesKey("analytics_again")
        val anHard = intPreferencesKey("analytics_hard")
        val anGood = intPreferencesKey("analytics_good")
        val anEasy = intPreferencesKey("analytics_easy")
        val anLast = longPreferencesKey("analytics_last")
    }

    // --- Account / preferences (defaults match AccountStore + @AppStorage) ---
    val userName: Flow<String> = ds.data.map { it[Keys.userName] ?: "user123" }
    val userEmail: Flow<String> = ds.data.map { it[Keys.userEmail] ?: "" }
    val dailyTarget: Flow<Int> = ds.data.map { it[Keys.dailyTarget] ?: 20 }
    val notifEnabled: Flow<Boolean> = ds.data.map { it[Keys.notifEnabled] ?: false }
    val notifHour: Flow<Int> = ds.data.map { it[Keys.notifHour] ?: 20 }
    val appearance: Flow<AppAppearance> = ds.data.map { AppAppearance.from(it[Keys.appearance]) }
    val googleEmail: Flow<String?> = ds.data.map { it[Keys.googleEmail] }
    val autoSync: Flow<Boolean> = ds.data.map { it[Keys.autoSync] ?: false }
    val streak: Flow<Int> = ds.data.map { it[Keys.streak] ?: 0 }

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
}
