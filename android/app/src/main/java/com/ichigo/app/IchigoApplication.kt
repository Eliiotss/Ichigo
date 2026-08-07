package com.ichigo.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Application entry point.
 *
 * The iOS app has no equivalent object — SwiftUI's `@main IchigoApp` just hosts
 * `RootView`. On Android the `Application` is where Hilt's dependency graph is
 * created, so every store/repository (the Kotlin equivalents of the iOS
 * `UserDefaults`-backed stores) is constructed once and shared.
 */
@HiltAndroidApp
class IchigoApplication : Application()
