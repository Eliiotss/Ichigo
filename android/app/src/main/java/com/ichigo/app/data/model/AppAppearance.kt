package com.ichigo.app.data.model

/**
 * Port of `AppAppearance.swift`.
 *
 * Persisted as a raw string ("system"/"light"/"dark") like the iOS `@AppStorage`
 * value. The Settings slide toggle only flips between [LIGHT] and [DARK];
 * [SYSTEM] is the initial state that follows the device until the first toggle.
 */
enum class AppAppearance(val rawValue: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark");

    companion object {
        const val STORAGE_KEY = "app_appearance"

        fun from(storedValue: String?): AppAppearance =
            entries.firstOrNull { it.rawValue == storedValue } ?: SYSTEM
    }
}
