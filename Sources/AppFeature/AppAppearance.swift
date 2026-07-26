import SwiftUI

// MARK: - Pilihan Tampilan

/// Mode tampilan yang dipilih pengguna di Pengaturan.
///
/// Nilainya disimpan sebagai teks mentah di `UserDefaults` lewat `@AppStorage`,
/// jadi pilihan ini bertahan antar-peluncuran dan ikut tersalin ke cadangan
/// Google Drive bersama preferensi lain.
enum AppAppearance: String, CaseIterable, Identifiable {
    /// Mengikuti pengaturan tampilan perangkat.
    case system
    case light
    case dark

    /// Kunci `UserDefaults` tempat pilihan ini disimpan.
    static let storageKey = BackupKeys.appearance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Ikuti Sistem"
        case .light: return "Terang"
        case .dark: return "Gelap"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    /// Skema warna yang dipaksakan ke seluruh aplikasi. `nil` berarti menyerah
    /// pada pengaturan perangkat.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Membaca pilihan dari teks tersimpan; kembali ke ``system`` bila nilainya
    /// kosong atau tidak dikenali, misalnya setelah memulihkan cadangan lama.
    static func from(storedValue: String) -> AppAppearance {
        AppAppearance(rawValue: storedValue) ?? .system
    }
}
