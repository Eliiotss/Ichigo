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

    let isConfigured: Bool

    private let oauth: GoogleOAuthClient?
    private let drive: GoogleDriveClient
    private let defaults: UserDefaults
    private let lastBackupKey = "drive_last_backup_at"

    init(defaults: UserDefaults = .standard, drive: GoogleDriveClient = GoogleDriveClient()) {
        self.defaults = defaults
        self.drive = drive
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
    }

    var isBusy: Bool { if case .working = phase { return true } else { return false } }

    func signIn() async {
        guard let oauth else { return fail(.notConfigured) }
        phase = .working("Membuka Google…")
        do {
            try await oauth.signIn()
            isSignedIn = true
            phase = .idle
        } catch DriveBackupError.authCancelled {
            phase = .idle
        } catch {
            phase = .failure(error.localizedDescription)
        }
    }

    func signOut() {
        oauth?.signOut()
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
            phase = .success("Progres dipulihkan. Mulai ulang aplikasi untuk melihat perubahan.")
        } catch {
            phase = .failure(error.localizedDescription)
        }
    }

    func dismissMessage() {
        switch phase {
        case .success, .failure: phase = .idle
        default: break
        }
    }

    private func fail(_ error: DriveBackupError) {
        phase = .failure(error.localizedDescription)
    }
}
