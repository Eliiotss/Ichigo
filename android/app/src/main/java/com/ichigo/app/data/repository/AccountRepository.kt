package com.ichigo.app.data.repository

import com.ichigo.app.data.local.AppPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Port of `AccountStore` — the single source of truth for the user's profile
 * name/email and the linked Google account. Backed by [AppPreferences] (the same
 * keys the iOS backup captures).
 */
@Singleton
class AccountRepository @Inject constructor(
    private val prefs: AppPreferences,
) {
    val displayName: Flow<String> = prefs.userName
    val email: Flow<String> = prefs.userEmail
    val linkedGoogleEmail: Flow<String?> = prefs.googleEmail

    suspend fun setDisplayName(value: String) = prefs.setUserName(value)
    suspend fun setEmail(value: String) = prefs.setUserEmail(value)

    /** Adopts the Google address as the profile email when none is set (Swift `linkGoogleAccount`). */
    suspend fun linkGoogleAccount(googleEmail: String) {
        prefs.setGoogleEmail(googleEmail)
        if (prefs.userEmail.first().isBlank()) prefs.setUserEmail(googleEmail)
    }

    suspend fun unlinkGoogleAccount() = prefs.setGoogleEmail(null)

    companion object {
        /** Two-letter avatar initials, port of `AccountStore.initials`. */
        fun initials(displayName: String): String {
            val trimmed = displayName.trim()
            if (trimmed.isEmpty()) return "U"
            val parts = trimmed.split(Regex("\\s+")).filter { it.isNotEmpty() }
            return if (parts.size >= 2) {
                (parts[0].take(1) + parts[1].take(1)).uppercase()
            } else {
                trimmed.take(2).uppercase()
            }
        }
    }
}
