import SwiftUI

// =============================================================================
// PANEL WARNA & TOKEN DESAIN — Ichigo
// -----------------------------------------------------------------------------
// INI SATU-SATUNYA TEMPAT untuk semua warna, font, dan ukuran desain aplikasi.
// Mau ganti warna di mana pun? Ubah nilainya DI SINI, satu kali, dan seluruh
// layar ikut berubah. Tiap warna diberi keterangan: dipakai di layar/bagian
// mana. Fungsi berakhiran `(scheme)` otomatis memilih versi terang/gelap.
//
// Cara membaca:
//   • `Color(hex: 0xRRGGBB)` = nilai warna. Ganti angka heksanya untuk ubah warna.
//   • Bagian 1–8 di bawah dikelompokkan per tujuan/layar.
//   • Bagian "Fungsi turunan" jangan diubah kecuali paham — itu logika, bukan nilai.
// =============================================================================
enum AppTheme {

    // MARK: - 1. Latar & Permukaan  (dipakai SEMUA layar)

    /// Latar utama seluruh layar saat mode TERANG — beige hangat khas Ichigo.
    static let pageLight = Color(hex: 0xE7E0DC)
    /// Warna kartu putih saat mode TERANG (kartu, tombol, baris pengaturan).
    static let cardLight = Color.white
    /// Jalur (track) bilah kemajuan saat mode TERANG.
    static let track = Color(hex: 0xF0E7E2)
    /// Warna tab bar bawah saat mode TERANG.
    static let tabBarLight = Color(hex: 0xFBF6F3)
    /// Garis pemisah tipis antar baris saat mode TERANG.
    static let hairline = Color(hex: 0xEFE6E0)

    // MARK: - 2. Teks

    /// Teks utama (judul, angka besar) saat mode TERANG — plum pekat.
    static let ink = Color(hex: 0x2B2029)
    /// Teks sekunder (keterangan, label) saat mode TERANG — taupe redup.
    static let muted = Color(hex: 0xB0A199)
    /// Teks placeholder di kolom isian (mis. "Cari kosakata").
    static let placeholder = Color(hex: 0xC4B8B1)

    // MARK: - 3. Aksen Biru & Gradien  (tombol utama, kartu hero, avatar)

    /// Warna aksen utama aplikasi. Dipakai tombol utama, tautan, ikon aktif.
    static let blue = Color(hex: 0x2E7BFF)
    /// Biru muda — ujung terang gradien aksen.
    static let blueLight = Color(hex: 0x4F97FF)
    /// Biru tua — dipakai bila perlu aksen lebih pekat.
    static let blueDeep = Color(hex: 0x1F63DB)
    static let indigo = Color(hex: 0x6E7BFF)
    static let indigoDeep = Color(hex: 0x4A55E8)
    /// Indigo lembut — kotak menu "Lainnya" di Beranda dan ikon "Akun" /
    /// "Sinkronisasi" di Pengaturan.
    static let indigoSoft = Color(hex: 0x7C93FF)
    /// Biru paling pekat pada tangga warna — ujung gradien katakana.
    static let navy = Color(hex: 0x3A45C4)
    static let sky = Color(hex: 0x29B6F0)
    static let skyDeep = Color(hex: 0x0E90D6)
    static let teal = Color(hex: 0x22C9DE)
    static let tealDeep = Color(hex: 0x0FA8BE)
    static let violet = Color(hex: 0x9A8BFF)
    static let violetDeep = Color(hex: 0x6E5CF0)

    /// Nama pendek untuk warna aksen utama (= `blue`).
    static let accent = blue

    /// Nada biru laut untuk keterangan cara baca (on'yomi / kun'yomi, jenis kata).
    static let ocean = skyDeep

    /// Gradien biru utama — kartu hero Beranda, avatar, dan tombol utama.
    static let accentGradient = LinearGradient(
        colors: [blueLight, blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - 4. Skala Warna Level JLPT  (N5 termuda → N1 terpekat)
    //
    // Dipakai di kartu daftar level Kanji, Kosakata, dan Grammar, serta lencana
    // "JLPT N5" di kartu detail. Ubah pemetaan di `levelColor` untuk mengganti
    // warna sebuah level di ketiga layar sekaligus.

    /// Warna utama sebuah level (teks angka level + hitungan pada kartu).
    static func levelColor(_ id: String) -> Color {
        switch id {
        case "N5": return blueLight
        case "N4": return blue
        case "N3": return sky
        case "N2": return indigo
        case "N1": return indigoDeep
        default:   return blue
        }
    }

    /// Latar chip level (kotak kecil di kiri kartu) — versi tembus pandang dari
    /// `levelColor`.
    static func levelBackground(_ id: String) -> Color {
        levelColor(id).opacity(0.15)
    }

    // MARK: - 5. Gradien Kotak Menu Beranda
    //
    // Tiap kotak menu di Beranda ("BELAJAR MANDIRI") punya gradiennya sendiri.
    // Ubah pasangan warna di sini untuk mengganti warna kotak yang bersangkutan.

    static func tileGradient(_ id: String) -> [Color] {
        switch id {
        case "huruf":      return [blueLight, blue]      // Kotak "Huruf" (Kana)
        case "kanji":      return [indigo, indigoDeep]   // Kotak "Kanji"
        case "flashcard":  return [sky, skyDeep]         // Kotak "Flashcard"
        case "vocabulary": return [teal, tealDeep]       // Kotak "Vocabulary"
        case "grammar":    return [violet, violetDeep]   // Kotak "Grammar"
        default:           return [indigoSoft, indigoDeep] // Kotak "Lainnya"
        }
    }

    // MARK: - 6. Warna Makna  (benar / salah / streak) — Flashcard & Profil
    //
    // Nilainya persis dari desain. Dipakai di tombol nilai flashcard
    // (Ulang/Susah/Bagus/Mudah), pil hitungan sesi, ringkasan jawaban Profil,
    // dan bagian "Kesalahan Umum" di Detail Grammar.

    /// Merah — kesalahan dan nilai "Ulang".
    static let danger = Color(hex: 0xFF3B30)
    /// Merah muda — ujung terang gradien tombol "Reset" di Pengaturan.
    static let dangerSoft = Color(hex: 0xFF7A70)
    /// Oranye — nilai "Susah" dan penanda streak.
    static let caution = Color(hex: 0xFF9500)
    /// Hijau — sudah dikuasai dan nilai "Mudah".
    static let success = Color(hex: 0x22B981)

    // MARK: - 7. Bayangan Kartu

    /// Bayangan lembut kartu — `0 6px 18px rgba(43,32,41,.06)` di desain.
    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.3) : ink.opacity(0.06)
    }

    /// Alias bayangan lembut (nilai sama dengan `cardShadow`).
    static func softShadow(_ scheme: ColorScheme) -> Color { cardShadow(scheme) }

    // MARK: - Fungsi turunan  (pilih otomatis versi terang / gelap)
    //
    // Bagian ini LOGIKA, bukan nilai warna mentah. Semua layar memanggilnya agar
    // ikut berubah saat mode gelap/terang. Umumnya tak perlu diubah — cukup ganti
    // nilai mentah di Bagian 1–6 di atas.

    /// Latar layar: beige saat terang, gelap sistem saat gelap.
    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.systemBackground) : pageLight
    }

    /// Permukaan kartu: putih saat terang, abu gelap saat gelap.
    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.secondarySystemBackground) : cardLight
    }

    /// Permukaan lembut untuk kotak di dalam kartu (baris penggunaan, contoh
    /// kalimat, kalimat contoh kanji).
    static func softSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : pageLight.opacity(0.55)
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .primary : ink
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .secondary : muted
    }

    /// Jalur bilah kemajuan.
    static func trackColor(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.15) : track
    }

    /// Latar lembut bernuansa sebuah warna, mis. pil hitungan sesi flashcard dan
    /// chip statistik di Profil. Sedikit lebih pekat di mode gelap agar terbaca.
    static func softTint(_ color: Color, _ scheme: ColorScheme) -> Color {
        color.opacity(scheme == .dark ? 0.20 : 0.10)
    }

    // MARK: - Tipografi

    /// Desain memakai Baloo 2 / Nunito; padanan bawaan iOS-nya SF Pro Rounded.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // MARK: - Ukuran

    static let cardRadius: CGFloat = 22
    static let heroRadius: CGFloat = 26
    static let tileIconRadius: CGFloat = 15

    /// Ruang bawah pada layar bertab (Beranda, Profil, Pengaturan). Ditambahkan
    /// di atas sisipan aman yang sudah otomatis diberi `TabView` untuk tab bar
    /// dan home indicator, sehingga isi terakhir tidak mepet tab bar dan jaraknya
    /// sama di semua perangkat — dari iPhone SE sampai iPad.
    static let screenBottomPadding: CGFloat = 28
}

extension Color {
    /// Membentuk warna dari literal 0xRRGGBB agar nilai heksa desain tetap terbaca.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
