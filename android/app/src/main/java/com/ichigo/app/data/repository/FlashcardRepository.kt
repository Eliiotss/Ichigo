package com.ichigo.app.data.repository

import com.ichigo.app.data.flashcard.DayBoundary
import com.ichigo.app.data.flashcard.FlashcardAnalyticsSummary
import com.ichigo.app.data.flashcard.FlashcardCardState
import com.ichigo.app.data.flashcard.FlashcardDayKey
import com.ichigo.app.data.flashcard.FlashcardDeckCard
import com.ichigo.app.data.flashcard.FlashcardDeckQueueBuilder
import com.ichigo.app.data.flashcard.FlashcardGrade
import com.ichigo.app.data.flashcard.FlashcardMode
import com.ichigo.app.data.flashcard.FlashcardProgress
import com.ichigo.app.data.flashcard.FlashcardReviewEngine
import com.ichigo.app.data.flashcard.FlashcardSettings
import com.ichigo.app.data.flashcard.flashcardLevelKey
import com.ichigo.app.data.local.AppPreferences
import com.ichigo.app.data.local.dao.NewCardTodayDao
import com.ichigo.app.data.local.dao.ProgressDao
import com.ichigo.app.data.local.dao.ReviewLogDao
import com.ichigo.app.data.local.entity.NewCardTodayEntity
import com.ichigo.app.data.local.entity.ProgressEntity
import com.ichigo.app.data.local.entity.ReviewLogEntity
import com.ichigo.app.data.resource.ResourceLoader
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

/**
 * The Kotlin counterpart of `FlashcardStore` plus the individual iOS stores
 * (progress / reviews / analytics / day-boundary / new-card tracker).
 *
 * As in Swift, the full progress map is held in memory (`progressMap`) so the
 * deck queue and per-level stats can be computed synchronously, while writes are
 * mirrored to Room. The scheduling, streak, quota and due-count logic all call
 * the verified engine ports, so behaviour matches iOS exactly.
 */
@Singleton
class FlashcardRepository @Inject constructor(
    private val progressDao: ProgressDao,
    private val reviewLogDao: ReviewLogDao,
    private val newCardTodayDao: NewCardTodayDao,
    private val prefs: AppPreferences,
    private val loader: ResourceLoader,
) {
    data class LevelStats(val total: Int, val mastered: Int, val due: Int, val progress: Double)

    private val engine = FlashcardReviewEngine()
    private val builder = FlashcardDeckQueueBuilder()

    /** FSRS settings — defaults, matching that the iOS UI never edits them. */
    val settings = FlashcardSettings()

    private val mutex = Mutex()
    private val _progress = MutableStateFlow<Map<String, FlashcardProgress>>(emptyMap())
    val progress: StateFlow<Map<String, FlashcardProgress>> = _progress.asStateFlow()

    private val deckCache = HashMap<String, List<FlashcardDeckCard>>()

    @Volatile private var loaded = false

    /** Loads the persisted progress map into memory once (Swift `progressStore.load()`). */
    suspend fun ensureLoaded() {
        if (loaded) return
        mutex.withLock {
            if (loaded) return
            _progress.value = progressDao.getAll().associate { it.id to it.toDomain() }
            loaded = true
        }
    }

    // MARK: - Deck loading

    suspend fun loadDeck(mode: FlashcardMode, levelId: String, jsonFile: String): List<FlashcardDeckCard> {
        markDailyResetIfNeeded()
        val key = flashcardLevelKey(mode, levelId)
        deckCache[key]?.let { return it }
        val items = withContext(Dispatchers.IO) {
            when (mode) {
                FlashcardMode.VOCABULARY -> loader.loadVocabOrEmpty(jsonFile).map { FlashcardDeckCard.fromVocab(it) }
                FlashcardMode.GRAMMAR -> loader.loadGrammarOrEmpty(jsonFile).map { FlashcardDeckCard.fromGrammar(it) }
            }
        }
        deckCache[key] = items
        return items
    }

    fun cachedDeck(key: String): List<FlashcardDeckCard>? = deckCache[key]

    fun deckProgress(card: FlashcardDeckCard, levelKey: String): FlashcardProgress =
        _progress.value[card.id] ?: FlashcardProgress.newProgress(card, levelKey)

    /** Per-level stats (total / mastered / due), Swift `refreshDeckStats`. */
    fun deckStats(mode: FlashcardMode, levelId: String): LevelStats? {
        val key = flashcardLevelKey(mode, levelId)
        val items = deckCache[key] ?: return null
        val map = _progress.value
        val now = System.currentTimeMillis()
        val total = items.size
        val mastered = items.count { (map[it.id] ?: FlashcardProgress.newProgress(it, key, now)).isMastered }
        val due = items.count { (map[it.id] ?: FlashcardProgress.newProgress(it, key, now)).isDue(now) }
        return LevelStats(total, mastered, due, if (total == 0) 0.0 else mastered.toDouble() / total)
    }

    /** Builds the review queue for a session (Swift `FlashcardDeckQueueBuilder`). */
    suspend fun buildQueue(
        mode: FlashcardMode,
        levelId: String,
        items: List<FlashcardDeckCard>,
        dailyTarget: Int,
    ): List<FlashcardDeckCard> {
        val key = flashcardLevelKey(mode, levelId)
        val usedToday = newCardStudiedToday(key)
        val sessionSettings = settings.copy(newCardsPerDay = maxOf(1, dailyTarget))
        return builder.build(key, items, _progress.value, sessionSettings, usedToday)
    }

    // MARK: - Reviewing

    /** Runs the scheduler for a grade and persists everything (Swift `submit`). */
    suspend fun review(card: FlashcardDeckCard, levelKey: String, grade: FlashcardGrade) {
        ensureLoaded()
        val current = deckProgress(card, levelKey)
        val stateBefore = current.state
        val now = System.currentTimeMillis()
        val (updated, log) = engine.review(current, grade, settings, now)

        if (stateBefore == FlashcardCardState.NEW) {
            val day = FlashcardDayKey.today(now).compact
            newCardTodayDao.insertIgnore(NewCardTodayEntity(levelKey, day, card.id))
        }
        saveProgress(updated)
        reviewLogDao.insert(ReviewLogEntity.from(log))
        reviewLogDao.trimTo(MAX_LOGS)
        prefs.recordAnalytics(log.grade, log.reviewedAt)
        updateStreak(now)
    }

    private suspend fun saveProgress(p: FlashcardProgress) {
        progressDao.upsert(ProgressEntity.from(p))
        mutex.withLock {
            _progress.value = _progress.value.toMutableMap().apply { put(p.id, p) }
        }
    }

    private suspend fun updateStreak(now: Long) {
        val today = FlashcardDayKey.today(now)
        val newStreak = DayBoundary.nextStreak(prefs.lastStudyDayKey(), prefs.currentStreak(), today) ?: return
        prefs.setStreak(newStreak)
        prefs.setLastStudyDayKey(today.compact)
        prefs.setLastStudyDate(now)
    }

    private suspend fun markDailyResetIfNeeded(now: Long = System.currentTimeMillis()) {
        val today = FlashcardDayKey.today(now).compact
        if (prefs.lastResetDayKey() != today) {
            prefs.setLastResetDayKey(today)
            newCardTodayDao.deleteOtherDays(today)
        }
    }

    suspend fun newCardStudiedToday(levelKey: String, now: Long = System.currentTimeMillis()): Int {
        val day = FlashcardDayKey.today(now).compact
        return newCardTodayDao.countByLevelDay(levelKey, day)
    }

    // MARK: - Aggregate stats (Home / Profile)

    val masteredTotal: Int get() = _progress.value.values.count { it.isMastered }

    suspend fun studiedTodayTotal(now: Long = System.currentTimeMillis()): Int {
        val (start, end) = dayRange(now)
        return reviewLogDao.countAllBetween(start, end)
    }

    val currentStreak: Flow<Int> get() = prefs.streak
    val analyticsSummary: Flow<FlashcardAnalyticsSummary> get() = prefs.analytics

    /**
     * Today's total card load across all loaded decks, port of `dailyDueTotal`:
     * due reviews plus the remaining new-card quota per deck.
     */
    suspend fun dailyDueTotal(target: Int, now: Long = System.currentTimeMillis()): Int {
        val map = _progress.value
        var total = 0
        for ((key, items) in deckCache) {
            val dueReviews = items.count { map[it.id]?.let { p -> p.dueDate <= now } ?: false }
            val untouched = items.count { map[it.id] == null }
            val newStudied = newCardStudiedToday(key, now)
            val newRemaining = minOf(untouched, maxOf(0, target - newStudied))
            total += dueReviews + newRemaining
        }
        return total
    }

    /** Preloads all unlocked decks so Home/Profile totals are ready (Swift `preloadHomeStats`). */
    suspend fun preloadAllDecks() {
        ensureLoaded()
        for (mode in FlashcardMode.allCases) {
            for (level in mode.levels()) {
                if (!level.isLocked) loadDeck(mode, level.id, level.jsonFile)
            }
        }
    }

    // MARK: - Reset (Swift FlashcardDataResetter.resetAll)

    suspend fun resetAll() {
        progressDao.deleteAll()
        reviewLogDao.deleteAll()
        prefs.resetStudyScalars()
        mutex.withLock { _progress.value = emptyMap() }
        // Note: analytics summary and per-day new-card lists are intentionally NOT
        // cleared here, matching the iOS `resetAll` exactly.
    }

    private fun dayRange(now: Long, zone: ZoneId = ZoneId.systemDefault()): Pair<Long, Long> {
        val date = Instant.ofEpochMilli(now).atZone(zone).toLocalDate()
        val start = date.atStartOfDay(zone).toInstant().toEpochMilli()
        val end = date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
        return start to end
    }

    companion object {
        private const val MAX_LOGS = 20_000
    }
}
