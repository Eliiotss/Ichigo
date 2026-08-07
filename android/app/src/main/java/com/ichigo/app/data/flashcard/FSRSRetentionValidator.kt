package com.ichigo.app.data.flashcard

/** Port of `FSRSRetentionValidationResult` / `FSRSRetentionValidator`. */
data class FSRSRetentionValidationResult(
    val isValid: Boolean,
    val issues: List<String>,
)

class FSRSRetentionValidator {
    fun validate(progress: FlashcardProgress, now: Long = System.currentTimeMillis()): FSRSRetentionValidationResult {
        val issues = mutableListOf<String>()

        if (progress.scheduledDays < 0) issues.add("scheduledDays negative")
        if (progress.stability < 0.1) issues.add("stability too low")
        if (progress.difficulty < 1 || progress.difficulty > 10) issues.add("difficulty out of range")
        if (progress.state == FlashcardCardState.REVIEW && progress.dueDate < (progress.lastReview ?: now)) {
            issues.add("review dueDate earlier than lastReview")
        }
        if (progress.reps < 0 || progress.lapses < 0) issues.add("counter negative")

        return FSRSRetentionValidationResult(issues.isEmpty(), issues)
    }
}
