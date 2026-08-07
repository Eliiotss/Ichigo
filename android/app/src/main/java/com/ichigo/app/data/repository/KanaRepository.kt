package com.ichigo.app.data.repository

import com.ichigo.app.data.local.dao.KanaCountDao
import com.ichigo.app.data.local.entity.KanaCountEntity
import com.ichigo.app.data.model.KanaItem
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Port of `HiraganaStore` (the 25× mastery tracker for kana). Same thresholds and
 * penalties: a correct answer adds 1 up to 25, a wrong answer subtracts 2 down to
 * 0, and a kana is "mastered" at 25. Backed by the `kana_count` Room table
 * instead of two `UserDefaults` JSON dictionaries.
 */
@Singleton
class KanaRepository @Inject constructor(
    private val dao: KanaCountDao,
) {
    /** Reactive map of (kana, script) → count for the kana grid + progress bars. */
    val counts: Flow<Map<Pair<String, String>, Int>> =
        dao.observeAll().map { list -> list.associate { (it.kana to it.script) to it.count } }

    suspend fun addCorrect(kana: String, isKatakana: Boolean) {
        val script = script(isKatakana)
        val current = dao.getCount(kana, script) ?: 0
        dao.upsert(KanaCountEntity(kana, script, minOf(MASTERY_THRESHOLD, current + 1)))
    }

    suspend fun addWrong(kana: String, isKatakana: Boolean) {
        val script = script(isKatakana)
        val current = dao.getCount(kana, script) ?: 0
        dao.upsert(KanaCountEntity(kana, script, maxOf(0, current - WRONG_PENALTY)))
    }

    companion object {
        const val MASTERY_THRESHOLD = 25
        private const val WRONG_PENALTY = 2

        fun script(isKatakana: Boolean): String = if (isKatakana) "kata" else "hira"

        fun correctCount(counts: Map<Pair<String, String>, Int>, kana: String, isKatakana: Boolean): Int =
            minOf(counts[kana to script(isKatakana)] ?: 0, MASTERY_THRESHOLD)

        fun barProgress(counts: Map<Pair<String, String>, Int>, kana: String, isKatakana: Boolean): Double =
            correctCount(counts, kana, isKatakana).toDouble() / MASTERY_THRESHOLD

        fun isMastered(counts: Map<Pair<String, String>, Int>, kana: String, isKatakana: Boolean): Boolean =
            correctCount(counts, kana, isKatakana) >= MASTERY_THRESHOLD

        fun masteredCount(counts: Map<Pair<String, String>, Int>, flat: List<KanaItem>, isKatakana: Boolean): Int =
            flat.count { isMastered(counts, it.kana, isKatakana) }

        fun progressPercent(counts: Map<Pair<String, String>, Int>, flat: List<KanaItem>, isKatakana: Boolean): Double =
            if (flat.isEmpty()) 0.0 else masteredCount(counts, flat, isKatakana).toDouble() / flat.size
    }
}
