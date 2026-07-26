import SwiftUI

// MARK: - Pilihan Tampilan

/// Mode tampilan aplikasi.
///
/// Nilainya disimpan sebagai teks mentah di `UserDefaults` lewat `@AppStorage`,
/// jadi pilihan ini bertahan antar-peluncuran dan ikut tersalin ke cadangan
/// Google Drive bersama preferensi lain.
///
/// Sakelar geser di Pengaturan hanya beralih antara ``light`` dan ``dark``.
/// ``system`` adalah keadaan awal sebelum pengguna pernah menggeser: aplikasi
/// mengikuti tampilan perangkat sampai geseran pertama membuatnya eksplisit.
/// Nilai ini juga muncul saat memulihkan cadangan lama.
enum AppAppearance: String, CaseIterable {
    /// Mengikuti pengaturan tampilan perangkat.
    case system
    case light
    case dark

    /// Kunci `UserDefaults` tempat pilihan ini disimpan. Ditulis sebagai literal
    /// di sini — bukan mengacu ke `BackupKeys` — supaya berkas ini berdiri
    /// sendiri dan tidak gagal kompilasi bila berkas lain belum ikut diperbarui.
    /// `BackupKeys.appearance` mengacu balik ke nilai ini agar tetap satu sumber.
    static let storageKey = "app_appearance"

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
