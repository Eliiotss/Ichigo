import Foundation
import Combine

/// Single source of truth for the user's account details.
///
/// The profile name/email and the linked Google account used for Drive backup
/// were previously read as loose `@AppStorage` values in several views, so they
/// could drift apart. Everything account-related now goes through this store,
/// which persists to the same `UserDefaults` keys the backup snapshot captures.
@MainActor
final class AccountStore: ObservableObject {
    static let shared = AccountStore()

    @Published var displayName: String {
        didSet { defaults.set(displayName, forKey: BackupKeys.userName) }
    }

    @Published var email: String {
        didSet { defaults.set(email, forKey: BackupKeys.userEmail) }
    }

    /// Google account currently linked for Drive backup, if any.
    @Published private(set) var linkedGoogleEmail: String? {
        didSet {
            if let linkedGoogleEmail {
                defaults.set(linkedGoogleEmail, forKey: Self.googleEmailKey)
            } else {
                defaults.removeObject(forKey: Self.googleEmailKey)
            }
        }
    }

    private static let googleEmailKey = "google_account_email"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.displayName = defaults.string(forKey: BackupKeys.userName) ?? "user123"
        self.email = defaults.string(forKey: BackupKeys.userEmail) ?? ""
        self.linkedGoogleEmail = defaults.string(forKey: Self.googleEmailKey)
    }

    var isLinkedToGoogle: Bool { linkedGoogleEmail != nil }

    /// Two-letter avatar initials derived from the display name.
    var initials: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "U" }
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }

    /// Called after a successful Google sign-in. Adopts the Google address as the
    /// profile email when the user has not set one themselves, so the Account
    /// section and the backup account stay consistent.
    func linkGoogleAccount(email googleEmail: String) {
        linkedGoogleEmail = googleEmail
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            email = googleEmail
        }
    }

    func unlinkGoogleAccount() {
        linkedGoogleEmail = nil
    }

    /// Re-reads persisted values, e.g. after restoring a backup.
    func reload() {
        displayName = defaults.string(forKey: BackupKeys.userName) ?? "user123"
        email = defaults.string(forKey: BackupKeys.userEmail) ?? ""
        linkedGoogleEmail = defaults.string(forKey: Self.googleEmailKey)
    }
}
