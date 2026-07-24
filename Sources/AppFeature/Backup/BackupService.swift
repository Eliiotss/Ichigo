import Foundation

/// Builds a ``BackupPayload`` from `UserDefaults` and restores one back into it.
/// Pure and side-effect-scoped to the injected defaults, so it is unit-testable.
enum BackupService {
    static let schemaVersion = 1
    /// Name of the single backup file kept in the Drive appDataFolder.
    static let fileName = "ichigo-backup.json"

    static func makePayload(from defaults: UserDefaults = .standard, date: Date = Date()) -> BackupPayload {
        let all = defaults.dictionaryRepresentation()

        var newToday: [String: [String]] = [:]
        var daily: [String: Data] = [:]
        for key in all.keys {
            if key.hasPrefix(BackupKeys.newTodayPrefix) {
                if let ids = defaults.stringArray(forKey: key) { newToday[key] = ids }
            } else if key.hasPrefix(BackupKeys.dailyAnalyticsPrefix) {
                if let data = defaults.data(forKey: key) { daily[key] = data }
            }
        }

        return BackupPayload(
            schemaVersion: schemaVersion,
            createdAt: date,
            appVersion: appVersion(),
            flashcardProgress: defaults.data(forKey: BackupKeys.flashcardProgress),
            flashcardSettings: defaults.data(forKey: BackupKeys.flashcardSettings),
            flashcardReviews: defaults.data(forKey: BackupKeys.flashcardReviews),
            flashcardAnalyticsSummary: defaults.data(forKey: BackupKeys.flashcardAnalyticsSummary),
            flashcardSyncMetadata: defaults.data(forKey: BackupKeys.flashcardSyncMetadata),
            hiraganaCount: defaults.data(forKey: BackupKeys.hiraganaCount),
            katakanaCount: defaults.data(forKey: BackupKeys.katakanaCount),
            streak: intIfPresent(defaults, BackupKeys.streak),
            lastStudyDayKey: defaults.string(forKey: BackupKeys.lastStudyDayKey),
            lastResetDayKey: defaults.string(forKey: BackupKeys.lastResetDayKey),
            lastStudyDate: defaults.object(forKey: BackupKeys.lastStudyDate) as? Date,
            newTodayLists: newToday,
            dailyAnalytics: daily,
            userName: defaults.string(forKey: BackupKeys.userName),
            userEmail: defaults.string(forKey: BackupKeys.userEmail),
            dailyTarget: intIfPresent(defaults, BackupKeys.dailyTarget),
            notifEnabled: boolIfPresent(defaults, BackupKeys.notifEnabled),
            notifHour: intIfPresent(defaults, BackupKeys.notifHour)
        )
    }

    static func restore(_ payload: BackupPayload, into defaults: UserDefaults = .standard) {
        setOrRemove(defaults, BackupKeys.flashcardProgress, payload.flashcardProgress)
        setOrRemove(defaults, BackupKeys.flashcardSettings, payload.flashcardSettings)
        setOrRemove(defaults, BackupKeys.flashcardReviews, payload.flashcardReviews)
        setOrRemove(defaults, BackupKeys.flashcardAnalyticsSummary, payload.flashcardAnalyticsSummary)
        setOrRemove(defaults, BackupKeys.flashcardSyncMetadata, payload.flashcardSyncMetadata)
        setOrRemove(defaults, BackupKeys.hiraganaCount, payload.hiraganaCount)
        setOrRemove(defaults, BackupKeys.katakanaCount, payload.katakanaCount)

        setOrRemove(defaults, BackupKeys.streak, payload.streak)
        setOrRemove(defaults, BackupKeys.lastStudyDayKey, payload.lastStudyDayKey)
        setOrRemove(defaults, BackupKeys.lastResetDayKey, payload.lastResetDayKey)
        setOrRemove(defaults, BackupKeys.lastStudyDate, payload.lastStudyDate)

        for (key, ids) in payload.newTodayLists { defaults.set(ids, forKey: key) }
        for (key, data) in payload.dailyAnalytics { defaults.set(data, forKey: key) }

        setOrRemove(defaults, BackupKeys.userName, payload.userName)
        setOrRemove(defaults, BackupKeys.userEmail, payload.userEmail)
        setOrRemove(defaults, BackupKeys.dailyTarget, payload.dailyTarget)
        setOrRemove(defaults, BackupKeys.notifEnabled, payload.notifEnabled)
        setOrRemove(defaults, BackupKeys.notifHour, payload.notifHour)
    }

    static func encode(_ payload: BackupPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(payload)
    }

    static func decode(_ data: Data) throws -> BackupPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupPayload.self, from: data)
    }

    // MARK: - Helpers

    private static func appVersion() -> String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    private static func intIfPresent(_ defaults: UserDefaults, _ key: String) -> Int? {
        defaults.object(forKey: key) == nil ? nil : defaults.integer(forKey: key)
    }

    private static func boolIfPresent(_ defaults: UserDefaults, _ key: String) -> Bool? {
        defaults.object(forKey: key) == nil ? nil : defaults.bool(forKey: key)
    }

    private static func setOrRemove(_ defaults: UserDefaults, _ key: String, _ value: Any?) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
