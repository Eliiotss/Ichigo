import Foundation

/// A portable snapshot of all locally-stored learning progress.
///
/// Every store in the app persists to `UserDefaults`, so a backup is simply the
/// relevant keys captured into one `Codable` value. `Data`-backed stores (which
/// already hold JSON) are copied verbatim as opaque blobs (encoded as base64 by
/// `JSONEncoder`), which keeps the backup format stable even if a store's internal
/// shape changes later.
struct BackupPayload: Codable, Equatable {
    /// Bumped when the backup format itself changes.
    var schemaVersion: Int
    var createdAt: Date
    var appVersion: String

    // Data-backed stores (verbatim JSON blobs).
    var flashcardProgress: Data?
    var flashcardSettings: Data?
    var flashcardReviews: Data?
    var flashcardAnalyticsSummary: Data?
    var flashcardSyncMetadata: Data?
    var hiraganaCount: Data?
    var katakanaCount: Data?

    // Day boundary / streak scalars.
    var streak: Int?
    var lastStudyDayKey: String?
    var lastResetDayKey: String?
    var lastStudyDate: Date?

    // Dynamic per-day keys.
    var newTodayLists: [String: [String]]
    var dailyAnalytics: [String: Data]

    // User preferences (AppStorage).
    var userName: String?
    var userEmail: String?
    var dailyTarget: Int?
    var notifEnabled: Bool?
    var notifHour: Int?
}

/// Canonical `UserDefaults` keys used across the app's stores. Kept in one place
/// so the backup service and the individual stores stay in agreement.
enum BackupKeys {
    static let flashcardProgress = "flashcard_progress_v1"
    static let flashcardSettings = "flashcard_settings_v1"
    static let flashcardReviews = "flashcard_reviews_v1"
    static let flashcardAnalyticsSummary = "flashcard_analytics_summary_v1"
    static let flashcardSyncMetadata = "flashcard_sync_metadata_v1"
    static let hiraganaCount = "hiraganaCount"
    static let katakanaCount = "katakanaCount"

    static let streak = "flashcard_streak_v1"
    static let lastStudyDayKey = "flashcard_last_study_day_key_v1"
    static let lastResetDayKey = "flashcard_last_reset_day_key_v1"
    static let lastStudyDate = "flashcard_last_study_date"

    static let newTodayPrefix = "flashcard_new_today_"
    static let dailyAnalyticsPrefix = "flashcard_analytics_daily_v1_"

    static let userName = "user_name"
    static let userEmail = "user_email"
    static let dailyTarget = "daily_target"
    static let notifEnabled = "notif_enabled"
    static let notifHour = "notif_hour"
}
