package com.ichigo.app.data.flashcard

import java.time.Duration
import java.time.Instant
import java.time.ZoneId

/**
 * Calendar helpers that reproduce the `Calendar.current` arithmetic the Swift
 * scheduler relies on, so day/second maths lands on the same instants.
 */
object FlashcardTime {
    /** `date.addingTimeInterval(seconds)`. */
    fun addSeconds(nowMillis: Long, seconds: Double): Long =
        nowMillis + (seconds * 1000.0).toLong()

    /** `date.addingTimeInterval(minutes * 60)`. */
    fun addMinutes(nowMillis: Long, minutes: Double): Long =
        addSeconds(nowMillis, minutes * 60.0)

    /** `Calendar.current.date(byAdding: .day, value: days, to: now)` in the system zone. */
    fun addDays(nowMillis: Long, days: Int, zone: ZoneId = ZoneId.systemDefault()): Long =
        Instant.ofEpochMilli(nowMillis).atZone(zone).plusDays(days.toLong()).toInstant().toEpochMilli()

    /** `max(0, Calendar.current.dateComponents([.day], from: last, to: now).day)`. */
    fun elapsedDays(from: Long?, to: Long): Int {
        if (from == null) return 0
        val days = Duration.between(Instant.ofEpochMilli(from), Instant.ofEpochMilli(to)).toDays()
        return maxOf(0, days.toInt())
    }
}
