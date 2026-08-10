package com.ichigo.app

import com.ichigo.app.data.flashcard.FlashcardCardState
import com.ichigo.app.data.flashcard.FlashcardDeckCard
import com.ichigo.app.data.flashcard.FlashcardDeckQueueBuilder
import com.ichigo.app.data.flashcard.FlashcardMode
import com.ichigo.app.data.flashcard.FlashcardProgress
import com.ichigo.app.data.flashcard.FlashcardSettings
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Locks the deck-queue rules: due cards (capped, most-overdue kept), then a
 * random subset of new cards within the remaining daily quota, de-duplicated by
 * id. Order is randomised, so assertions check membership/size, not sequence.
 * Pure JVM.
 */
class FlashcardDeckQueueBuilderTest {

    private val builder = FlashcardDeckQueueBuilder()
    private val now = 1_700_000_000_000L

    private fun card(id: String) = FlashcardDeckCard(
        id = id, mode = FlashcardMode.VOCABULARY, front = id,
        revealedTitle = id, revealedBody = id, revealedTag = "n",
    )

    private fun progress(id: String, dueDate: Long, lapses: Int = 0) = FlashcardProgress(
        id = id, level = "N5", front = id, back = id,
        state = FlashcardCardState.REVIEW, dueDate = dueDate, stability = 1.0,
        difficulty = 5.0, reps = 1, lapses = lapses, lastReview = now - 1,
        scheduledDays = 1, learningStepIndex = 0,
    )

    @Test
    fun newCards_limitedToDailyQuota() {
        val items = (1..10).map { card("n$it") }
        val q = builder.build("vocabulary_N5", items, emptyMap(), FlashcardSettings(newCardsPerDay = 4), now = now)
        assertEquals(4, q.size)
        assertTrue(q.all { it.id.startsWith("n") })
    }

    @Test
    fun newCards_reducedByAlreadyStudiedToday() {
        val items = (1..10).map { card("n$it") }
        val q = builder.build(
            "vocabulary_N5", items, emptyMap(),
            FlashcardSettings(newCardsPerDay = 5), newCardsAlreadyStudiedToday = 3, now = now,
        )
        assertEquals(2, q.size)
    }

    @Test
    fun newCards_zeroWhenQuotaAlreadyMet() {
        val items = (1..10).map { card("n$it") }
        val q = builder.build(
            "vocabulary_N5", items, emptyMap(),
            FlashcardSettings(newCardsPerDay = 5), newCardsAlreadyStudiedToday = 9, now = now,
        )
        assertTrue(q.isEmpty())
    }

    @Test
    fun onlyDueCardsAreIncluded() {
        val items = listOf(card("due"), card("future"))
        val prog = mapOf(
            "due" to progress("due", dueDate = now - 1000),
            "future" to progress("future", dueDate = now + 1_000_000),
        )
        val q = builder.build("vocabulary_N5", items, prog, FlashcardSettings(newCardsPerDay = 0), now = now)
        assertEquals(1, q.size)
        assertEquals("due", q.first().id)
        assertFalse(q.any { it.id == "future" })
    }

    @Test
    fun dueCap_keepsTheMostOverdue() {
        val items = (1..5).map { card("d$it") }
        val prog = items.associate { it.id to progress(it.id, dueDate = now - it.id.drop(1).toLong() * 1000) }
        // d5 is most overdue (dueDate = now-5000), d1 least (now-1000).
        val q = builder.build(
            "vocabulary_N5", items, prog,
            FlashcardSettings(newCardsPerDay = 0, maxReviewsPerDay = 2), now = now,
        )
        assertEquals(2, q.size)
        assertEquals(setOf("d5", "d4"), q.map { it.id }.toSet())
    }

    @Test
    fun dueThenNew_bothWithinLimits() {
        val items = listOf(card("due1"), card("due2")) + (1..10).map { card("n$it") }
        val prog = mapOf(
            "due1" to progress("due1", dueDate = now - 2000),
            "due2" to progress("due2", dueDate = now - 1000),
        )
        val q = builder.build("vocabulary_N5", items, prog, FlashcardSettings(newCardsPerDay = 3), now = now)
        assertEquals(5, q.size) // 2 due + 3 new
        assertTrue(q.any { it.id == "due1" } && q.any { it.id == "due2" })
        assertEquals(3, q.count { it.id.startsWith("n") })
    }

    @Test
    fun duplicateIds_areDeDuplicated() {
        val items = listOf(card("dup"), card("dup"))
        val prog = mapOf("dup" to progress("dup", dueDate = now - 1000))
        val q = builder.build("vocabulary_N5", items, prog, FlashcardSettings(newCardsPerDay = 0), now = now)
        assertEquals(1, q.size)
    }

    @Test
    fun emptyItems_yieldEmptyQueue() {
        val q = builder.build("vocabulary_N5", emptyList(), emptyMap(), FlashcardSettings(), now = now)
        assertTrue(q.isEmpty())
    }
}
