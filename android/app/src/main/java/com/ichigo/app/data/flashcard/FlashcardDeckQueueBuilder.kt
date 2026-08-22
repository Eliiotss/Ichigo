package com.ichigo.app.data.flashcard

/**
 * Direct port of `FlashcardDeckQueueBuilder.build`, with a randomised
 * presentation order so cards never appear in a fixed dataset sequence.
 *
 * Due reviews come first (ranked most-overdue → most lapses for the daily cap,
 * then shuffled for display); new cards follow — a RANDOM subset of the
 * still-new cards up to the remaining daily quota
 * (`newCardsPerDay − newCardsAlreadyStudiedToday`), also shuffled. De-duplicated
 * by id.
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
            .shuffled() // present due cards in a random order

        val queue = ArrayList<FlashcardDeckCard>()
        for (item in dueItems) if (seen.add(item.id)) queue.add(item)

        // New cards: a RANDOM subset (not the first N of the dataset), still
        // within the daily limit minus what was already studied elsewhere today.
        val newLimit = maxOf(0, settings.newCardsPerDay - newCardsAlreadyStudiedToday)
        val newItems = items.filter { progress[it.id] == null }.shuffled().take(newLimit)
        for (item in newItems) if (seen.add(item.id)) queue.add(item)

        return queue
    }
}
