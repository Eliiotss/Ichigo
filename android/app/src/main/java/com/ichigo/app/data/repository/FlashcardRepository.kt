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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.ZoneId
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
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

    // ConcurrentHashMap: the deck cache is read/written from several coroutines
    // (splash preload, level list, an open session), so a plain HashMap would be
    // one dispatcher change away from a corrupted map.
    private val deckCache = ConcurrentHashMap<String, List<FlashcardDeckCard>>()

    @Volatile private var loaded = false

    // Deck warming runs here, not in a ViewModel scope: the splash screen that
    // used to trigger it is destroyed as soon as it fades out, which would
    // cancel the work half-way.
    private val warmScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val warmStarted = AtomicBoolean(false)

    private val _deckCatalogVersion = MutableStateFlow(0)

    /**
     * Bumps each time another deck finishes loading. Home/Profile observe it so
     * their totals fill in as the background warm-up progresses, instead of the
     * splash having to block until every deck is decoded.
     */
    val deckCatalogVersion: StateFlow<Int> = _deckCatalogVersion.asStateFlow()

    /** Loads the persisted progress map into memory once (Swift `progressStore.load()`). */
    suspend fun ensureLoaded() {
        if (loaded) return
        mutex.withLock {
            if (loaded) return
            _progress.value = progressDao.getAll().associate { it.id to it.toDomain() }
            loaded = true
        }
    }

    /** Re-reads progress from the database, e.g. after a Drive backup is restored. */
    suspend fun reloadFromDb() {
        mutex.withLock {
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

    /**
     * Builds the review queue for a session (Swift `FlashcardDeckQueueBuilder`).
     *
     * The new-card quota is **per deck** (mode + JLPT level): "Target Harian" is
     * how many new cards each deck may introduce per day, not a single budget
     * shared by every deck.
     *
     * This is the fix for N5–N1 blocking one another: with a shared budget,
     * finishing the day's target in one level left every other level with a
     * quota of zero, so an untouched deck rendered as "Belum ada kartu". Each
     * level now schedules independently; its progress was already stored
     * separately (`new_card_today.levelKey`), so no existing data changes shape.
     */
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

    /**
     * Runs the scheduler for a grade and persists everything (Swift `submit`).
     * Returns the resulting card state so the session view can update its
     * per-card bucket counters from the same single computation.
     */
    suspend fun review(card: FlashcardDeckCard, levelKey: String, grade: FlashcardGrade): FlashcardCardState {
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
        prefs.recordStudyDay(log.reviewedAt)
        updateStreak(now)
        return updated.state
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

    /**
     * Cards the FSRS scheduler considers mastered — counted in SQL rather than
     * by scanning the in-memory map, so it is correct before the decks (or even
     * the progress map) have finished loading.
     */
    suspend fun masteredTotal(): Int =
        progressDao.countMastered(FlashcardProgress.MASTERED_MIN_SCHEDULED_DAYS)

    suspend fun studiedTodayTotal(now: Long = System.currentTimeMillis()): Int {
        val (start, end) = dayRange(now)
        return reviewLogDao.countAllBetween(start, end)
    }

    val currentStreak: Flow<Int> get() = prefs.streak
    val analyticsSummary: Flow<FlashcardAnalyticsSummary> get() = prefs.analytics

    /**
     * Today's total card load across all loaded decks: due reviews plus the
     * new cards still available today.
     *
     * The new-card part is summed **per deck** (`target − new studied today in
     * that deck`) so this number agrees with what [buildQueue] will actually
     * hand out. With independent decks the figure is naturally larger than the
     * daily target — that is the honest count of cards waiting, not a bug.
     */
    suspend fun dailyDueTotal(target: Int, now: Long = System.currentTimeMillis()): Int {
        // Due reviews: one COUNT in SQL. This used to scan every cached deck on
        // the main thread after each graded card, and it silently reported 0 for
        // decks that had not been decoded yet.
        val dueReviews = progressDao.countDue(now)
        val map = _progress.value
        val usedPerDeck = newCardTodayDao
            .countByDayGrouped(FlashcardDayKey.today(now).compact)
            .associate { it.levelKey to it.total }
        val newRemaining = withContext(Dispatchers.Default) {
            var remaining = 0
            for ((levelKey, items) in deckCache) {
                val untouched = items.count { map[it.id] == null }
                val used = usedPerDeck[levelKey] ?: 0
                remaining += minOf(untouched, maxOf(0, target - used))
            }
            remaining
        }
        return dueReviews + newRemaining
    }

    /**
     * Warms every unlocked deck **in the background**, once per process.
     *
     * The splash screen used to await this: ~8 400 cards decoded before the app
     * became usable. Home/Profile now get their due count straight from SQL and
     * refine the new-card part as [deckCatalogVersion] ticks, so the warm-up no
     * longer sits on the cold-start path.
     */
    fun warmDecksInBackground() {
        if (!warmStarted.compareAndSet(false, true)) return
        warmScope.launch {
            ensureLoaded()
            for (mode in FlashcardMode.allCases) {
                for (level in mode.levels()) {
                    if (level.isLocked) continue
                    runCatching { loadDeck(mode, level.id, level.jsonFile) }
                    _deckCatalogVersion.value += 1
                }
            }
        }
    }

    // MARK: - Reset (Swift FlashcardDataResetter.resetAll)

    suspend fun resetAll(now: Long = System.currentTimeMillis()) {
        // Stamp the reset FIRST. This tombstone travels in the Drive backup and
        // is what stops the next sync from pulling every deleted card back down
        // (the merge is a union, so without it "Reset" was undone on next sync).
        prefs.setLastResetAt(now)
        // Full reset: every visible progress stat goes back to zero.
        progressDao.deleteAll()
        reviewLogDao.deleteAll()
        newCardTodayDao.deleteAll()      // "kartu belajar" today → 0
        prefs.resetStudyScalars()        // streak → 0
        prefs.clearAnalytics()           // Ringkasan Jawaban → 0
        prefs.clearDailyStudy()          // grafik 7 hari → kosong
        mutex.withLock { _progress.value = emptyMap() }
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
