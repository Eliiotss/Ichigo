import Foundation
import os

/// Centralised, privacy-aware logging for the app.
///
/// Built on top of Apple's unified logging system (`os.Logger`). Messages are
/// grouped by category so they can be filtered in Console.app / Instruments.
/// Unlike `print`, unified logging is effectively free in release builds and
/// never leaks to the standard output of shipping apps.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.ichigo.app"

    /// Loading and decoding of bundled JSON resources.
    static let resources = Logger(subsystem: subsystem, category: "resources")

    /// Spaced-repetition scheduling and persistence.
    static let flashcards = Logger(subsystem: subsystem, category: "flashcards")

    /// Local notification scheduling.
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
}
