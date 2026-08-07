package com.ichigo.app.data.flashcard

/**
 * Direct port of `FlashcardDeckQueueBuilder.build`.
 *
 * Due reviews come first (most-overdue first, then most lapses), capped at
 * `maxReviewsPerDay`; new cards follow up to the remaining daily quota
 * (`newCardsPerDay − newCardsAlreadyStudiedToday`). De-duplicated by id.
 */
class FlashcardDeckQueueBuilder {
    fun build(
        levelKey: String,
        items: List<FlashcardDeckCard>,
        progress: Map<String, FlashcardProgress>,
        settings: FlashcardSettings,
        newCardsAlreadyStudiedToday: Int = 0,
        now: Long = System.currentTimeMillis(),
    ): List<FlashcardDeckCard> {
        val seen = HashSet<String>()

        val dueItems = items
            .filter { item ->
                val card = progress[item.id] ?: return@filter false
                card.dueDate <= now
            }
            .sortedWith(
                compareByDescending<FlashcardDeckCard> { item ->
                    now - (progress[item.id]?.dueDate ?: now)   // most overdue first
                }.thenByDescending { item ->
                    progress[item.id]?.lapses ?: 0              // then most lapses
                },
            )
            .take(settings.maxReviewsPerDay)

        val queue = ArrayList<FlashcardDeckCard>()
        for (item in dueItems) if (seen.add(item.id)) queue.add(item)

        // New cards: strict daily limit minus what was already studied elsewhere today.
        val newLimit = maxOf(0, settings.newCardsPerDay - newCardsAlreadyStudiedToday)
        val newItems = items.filter { progress[it.id] == null }.take(newLimit)
        for (item in newItems) if (seen.add(item.id)) queue.add(item)

        return queue
    }
}
