import Foundation

/// User-facing errors for the Google Drive backup feature (messages in Indonesian
/// to match the app UI).
enum DriveBackupError: LocalizedError {
    case notConfigured
    case notSignedIn
    case authCancelled
    case authFailed(String)
    case network(String)
    case noBackupFound

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Backup Google Drive belum dikonfigurasi. Tambahkan GoogleOAuth.plist dengan CLIENT_ID Anda."
        case .notSignedIn:
            return "Belum masuk ke Google. Silakan masuk terlebih dahulu."
        case .authCancelled:
            return "Proses masuk dibatalkan."
        case .authFailed(let reason):
            return "Gagal masuk ke Google: \(reason)"
        case .network(let reason):
            return "Kesalahan jaringan: \(reason)"
        case .noBackupFound:
            return "Tidak ada cadangan yang ditemukan di Google Drive."
        }
    }
}
