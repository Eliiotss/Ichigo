import Foundation

/// Coordinates manual backup and restore between local `UserDefaults` progress and
/// a single JSON file in the user's Google Drive appDataFolder. Drives the
/// Settings UI via `@Published` state.
@MainActor
final class DriveBackupManager: ObservableObject {
    enum Phase: Equatable {
        case idle
        case working(String)
        case success(String)
        case failure(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var isSignedIn = false
    @Published private(set) var lastBackupDate: Date?
    @Published private(set) var lastSyncDate: Date?
    /// When on, the app syncs automatically on foreground and after each study
    /// session. Persisted so the choice survives relaunches.
    @Published var autoSyncEnabled: Bool {
        didSet { defaults.set(autoSyncEnabled, forKey: autoSyncKey) }
    }

    let isConfigured: Bool

    private let oauth: GoogleOAuthClient?
    private let drive: GoogleDriveClient
    private let defaults: UserDefaults
    private let account: AccountStore
    private let lastBackupKey = "drive_last_backup_at"
    private let lastSyncKey = "drive_last_sync_at"
    private let autoSyncKey = "drive_auto_sync_enabled"

    /// `AccountStore.shared` is main-actor isolated, so it cannot be a default
    /// argument (those are evaluated in a nonisolated context — an error under
    /// the Swift 6 language mode). Resolve it inside the isolated initialiser
    /// instead, keeping the store injectable for tests.
    init(defaults: UserDefaults = .standard,
         drive: GoogleDriveClient = GoogleDriveClient(),
         account: AccountStore? = nil) {
        self.defaults = defaults
        self.drive = drive
        self.account = account ?? AccountStore.shared
        if let config = GoogleDriveConfig.load() {
            self.oauth = GoogleOAuthClient(config: config)
            self.isConfigured = true
        } else {
            self.oauth = nil
            self.isConfigured = false
        }
        self.isSignedIn = oauth?.isSignedIn ?? false
        let stored = defaults.double(forKey: lastBackupKey)
        self.lastBackupDate = stored > 0 ? Date(timeIntervalSince1970: stored) : nil
        let syncStored = defaults.double(forKey: lastSyncKey)
        self.lastSyncDate = syncStored > 0 ? Date(timeIntervalSince1970: syncStored) : nil
        // Auto-sync defaults on; an explicit stored `false` disables it.
        self.autoSyncEnabled = defaults.object(forKey: autoSyncKey) as? Bool ?? true
    }

    var isBusy: Bool { if case .working = phase { return true } else { return false } }

    /// Google address currently linked for backup, shown in Settings.
    var linkedAccountEmail: String? { account.linkedGoogleEmail }

    func signIn() async {
        guard let oauth else { return fail(.notConfigured) }
        phase = .working("Membuka Google…")
        do {
            try await oauth.signIn()
            isSignedIn = true
            if let email = await oauth.fetchAccountEmail() {
                account.linkGoogleAccount(email: email)
            }
            phase = .idle
        } catch DriveBackupError.authCancelled {
            phase = .idle
        } catch {
            phase = .failure(error.localizedDescription)
        }
    }

    func signOut() {
        oauth?.signOut()
        account.unlinkGoogleAccount()
        isSignedIn = false
        phase = .idle
    }

    func backupNow() async {
        guard let oauth else { return fail(.notConfigured) }
        phase = .working("Mencadangkan ke Google Drive…")
        do {
            let token = try await oauth.validAccessToken()
            let payload = BackupService.makePayload(from: defaults)
            let data = try BackupService.encode(payload)
            if let existing = try await drive.findBackup(named: BackupService.fileName, accessToken: token) {
                try await drive.update(fileID: existing.id, content: data, accessToken: token)
            } else {
                try await drive.create(named: BackupService.fileName, content: data, accessToken: token)
            }
            let now = Date()
            defaults.set(now.timeIntervalSince1970, forKey: lastBackupKey)
            lastBackupDate = now
            phase = .success("Cadangan tersimpan ke Google Drive.")
        } catch {
            phase = .failure(error.localizedDescription)
        }
    }

    func restoreNow() async {
        guard let oauth else { return fail(.notConfigured) }
        phase = .working("Memulihkan dari Google Drive…")
        do {
            let token = try await oauth.validAccessToken()
            guard let existing = try await drive.findBackup(named: BackupService.fileName, accessToken: token) else {
                throw DriveBackupError.noBackupFound
            }
            let data = try await drive.download(fileID: existing.id, accessToken: token)
            let payload = try BackupService.decode(data)
            BackupService.restore(payload, into: defaults)
            account.reload()
            phase = .success("Progres dipulihkan. Mulai ulang aplikasi untuk melihat perubahan.")
        } catch {
            phase = .failure(error.localizedDescription)
        }
    }

    /// Bidirectional, Anki-style sync: pull the remote snapshot, merge it with the
    /// local one via ``BackupMerge`` (never losing progress), write the merged
    /// result back to local storage, then push it to Drive. When no remote exists
    /// yet this is just a first upload.
    ///
    /// - Parameter auto: when triggered by the app lifecycle rather than a button,
    ///   the flow stays quiet — no success toast, and network failures are
    ///   swallowed (the next foreground will retry) instead of surfacing an error.
    func syncNow(auto: Bool = false) async {
        guard let oauth else { if !auto { fail(.notConfigured) }; return }
        guard isSignedIn else { if !auto { fail(.notSignedIn) }; return }
        if isBusy { return }
        phase = .working("Menyinkronkan…")
        do {
            let token = try await oauth.validAccessToken()
            let local = BackupService.makePayload(from: defaults)
            var appliedRemote = false
            if let existing = try await drive.findBackup(named: BackupService.fileName, accessToken: token) {
                let remoteData = try await drive.download(fileID: existing.id, accessToken: token)
                let remote = try BackupService.decode(remoteData)
                let merged = BackupMerge.merge(local: local, remote: remote)
                BackupService.restore(merged, into: defaults)
                account.reload()
                let mergedData = try BackupService.encode(merged)
                try await drive.update(fileID: existing.id, content: mergedData, accessToken: token)
                appliedRemote = true
            } else {
                let data = try BackupService.encode(local)
                _ = try await drive.create(named: BackupService.fileName, content: data, accessToken: token)
            }
            stampSync()
            if appliedRemote {
                NotificationCenter.default.post(name: .ichigoDidApplyRemoteSync, object: nil)
            }
            phase = auto ? .idle : .success("Sinkronisasi selesai.")
        } catch DriveBackupError.authCancelled {
            phase = .idle
        } catch {
            phase = auto ? .idle : .failure(error.localizedDescription)
        }
    }

    /// Runs a sync only when auto-sync is on and an account is linked. Safe to call
    /// from the app lifecycle without checking state first.
    func autoSyncIfEnabled() async {
        guard isConfigured, isSignedIn, autoSyncEnabled else { return }
        await syncNow(auto: true)
    }

    func dismissMessage() {
        switch phase {
        case .success, .failure: phase = .idle
        default: break
        }
    }

    private func stampSync() {
        let now = Date()
        defaults.set(now.timeIntervalSince1970, forKey: lastSyncKey)
        defaults.set(now.timeIntervalSince1970, forKey: lastBackupKey)
        lastSyncDate = now
        lastBackupDate = now
    }

    private func fail(_ error: DriveBackupError) {
        phase = .failure(error.localizedDescription)
    }
}

extension Notification.Name {
    /// Posted after a sync applies merged remote data into local storage, so
    /// in-memory view models (e.g. `FlashcardStore`) can reload from disk.
    static let ichigoDidApplyRemoteSync = Notification.Name("ichigo.didApplyRemoteSync")
}
