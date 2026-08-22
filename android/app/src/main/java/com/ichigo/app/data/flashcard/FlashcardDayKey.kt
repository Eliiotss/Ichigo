package com.ichigo.app.data.flashcard

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Port of `FlashcardDayKey` + the day-boundary/streak decision logic from
 * `FlashcardDayBoundaryStore`. Kept pure: the persistence (streak count, last
 * study/reset keys, per-day new-card lists) lives in the repository, but the
 * rules for what counts as "today", "yesterday" and how the streak advances are
 * exactly the Swift ones so a streak never drifts between platforms.
 */
data class FlashcardDayKey(
    val year: Int,
    val month: Int,
    val day: Int,
    val timezoneIdentifier: String,
) {
    /** "yyyy-MM-dd-<tzid>", months/days zero-padded (Swift `compact`). */
    val compact: String
        get() = "%d-%02d-%02d-%s".format(year, month, day, timezoneIdentifier)

    companion object {
        fun today(now: Long = System.currentTimeMillis(), zone: ZoneId = ZoneId.systemDefault()): FlashcardDayKey {
            val date = Instant.ofEpochMilli(now).atZone(zone).toLocalDate()
            return FlashcardDayKey(date.year, date.monthValue, date.dayOfMonth, zone.id)
        }
    }
}

object DayBoundary {
    /**
     * True when [previousKey] denotes the calendar day immediately before [today].
     * Port of `FlashcardDayBoundaryStore.isYesterday`.
     */
    fun isYesterday(previousKey: String, today: FlashcardDayKey): Boolean {
        val parts = previousKey.split("-")
        if (parts.size < 3) return false
        val year = parts[0].toIntOrNull() ?: return false
        val month = parts[1].toIntOrNull() ?: return false
        val day = parts[2].toIntOrNull() ?: return false
        val previousDate = runCatching { LocalDate.of(year, month, day) }.getOrNull() ?: return false
        val todayDate = runCatching { LocalDate.of(today.year, today.month, today.day) }.getOrNull() ?: return false
        return previousDate == todayDate.minusDays(1)
    }

    /**
     * Computes the streak after a study event, port of `registerStudy`. Returns
     * `null` when the same day has already been registered (no change); otherwise
     * the new streak count to persist alongside `today.compact`.
     */
    fun nextStreak(previousKey: String?, currentStreak: Int, today: FlashcardDayKey): Int? {
        if (previousKey == today.compact) return null
        return if (previousKey != null && isYesterday(previousKey, today)) currentStreak + 1 else 1
    }
}
