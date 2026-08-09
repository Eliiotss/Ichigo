# Ichigo — versi web

Port web dari aplikasi Ichigo (belajar bahasa Jepang JLPT). **Statis, tanpa
build**: HTML + CSS + JavaScript (ES modules) murni. Sepenuhnya terpisah dari
kode Swift di `Sources/` — mengubah web tidak menyentuh aplikasi iOS.

**Tampilan iOS-native, responsif** (mengikuti mockup Claude Design
`Ichigo App.dc.html`): font sistem (SF Pro / Segoe / Roboto), latar abu-abu
`#F2F2F7`, kartu putih membulat berbayang lembut, aksen biru `#2E7BFF` dengan
warna per-level (N5 hijau … N1 merah). **Desktop**: sidebar kiri yang bisa
dilipat (logo 苺 Ichigo + navigasi lengkap + kartu Target Harian). **Mobile**:
tab bar di bawah (Home · Profil · Pengaturan), menu belajar dibuka dari grid
Beranda. Tidak butuh font eksternal.

## Fitur

- **Penjelajah konten**: Kanji, Kosakata, dan Tata Bahasa untuk **N5–N3**
  (daftar + detail + pencarian langsung), serta bagan **Hiragana & Katakana**.
- **Flashcard dengan FSRS-6**: penjadwalan spaced-repetition yang **diport
  persis** dari mesin FSRS aplikasi iOS (bobot 21 parameter resmi + learning
  steps "cara A"). Progres tersimpan di `localStorage` peramban.
- **Tema terang/gelap** (ikuti sistem + tombol ganti), responsif untuk ponsel.

## Menjalankan

Karena data dimuat lewat `fetch`, situs harus **dilayani lewat HTTP** (bukan
dibuka sebagai `file://`). Dari dalam folder `web/`:

```bash
python3 -m http.server 8000
# lalu buka http://localhost:8000
```

Atau host statis mana pun (GitHub Pages, Netlify, dsb.) — arahkan ke folder
`web/` sebagai root.

### GitHub Pages

Repo ini punya workflow `.github/workflows/pages.yml` (jalankan manual dari tab
**Actions → Run workflow**) yang menyebarkan folder `web/`. **Prasyarat:**

- **Aktifkan Pages sekali:** Settings → Pages → Build and deployment →
  Source: **"GitHub Actions"**.
- **Repo harus publik** pada paket gratis. **GitHub Pages untuk repo privat butuh
  paket berbayar** (Pro/Team/Enterprise). Token Actions **tidak bisa** mengaktifkan
  Pages otomatis. Jika repo tetap privat & paket gratis, pakai host alternatif di
  bawah.

Bila aktif, URL situs: `https://eliiotss.github.io/Ichigo/`, dan **origin** untuk
OAuth client ID (Authorized JavaScript origins): `https://eliiotss.github.io`.

### Alternatif hosting (mendukung repo privat, gratis)

- **Netlify / Vercel / Cloudflare Pages** — sambungkan repo, set *base/publish
  directory* ke `web`, tanpa build command. Daftarkan origin yang diberikan
  (mis. `https://ichigo.netlify.app`) di OAuth client ID.
- **Uji lokal** — `cd web && python3 -m http.server 8000`, origin
  `http://localhost:8000`. Paling cepat untuk mencoba login Google.

## Struktur

```
web/
  index.html          # kerangka SPA + tab bar bawah + muat font Baloo 2
  css/styles.css       # token warna iOS (terang/gelap), komponen, tab bar, kartu hero
  js/
    app.js             # router hash + tab bar bawah (Home/Profil/Pengaturan)
    levels.js          # metadata: tab, menu Beranda, level JLPT, mode flashcard
    icons.js           # ikon SVG inline bersama + glyph Jepang untuk tile
    data.js            # pemuat JSON + cache
    browse.js          # Beranda + Kanji/Vocab/Grammar/Hiragana (daftar + detail)
    profile.js         # tab Profil (header gradien, stat, ringkasan jawaban)
    fsrs.js            # FSRS-6 (port setia dari FlashcardModel.swift)
    store.js           # progres/streak/kuota/statistik/jawaban di localStorage
    flashcards.js      # pemilih mode + level + sesi review (gaya iOS)
    settings.js        # Pengaturan (gaya iOS) + ekspor/impor + sync Drive
    theme.js           # tema terang/gelap/auto
    drive.js, gsync.js # klien Google Drive (GIS) + orkestrasi sync
  data/*.json          # SALINAN dataset dari Sources/AppFeature/Resources
```

## Catatan data

Berkas di `web/data/` adalah **salinan** dari `Sources/AppFeature/Resources/`.
Bila dataset iOS diperbarui, salin ulang agar web ikut mutakhir:

```bash
cp Sources/AppFeature/Resources/*.json web/data/
```

N2/N1 belum disertakan (levelnya terkunci), sama seperti aplikasi iOS.

## Pengaturan & cadangan (⚙️)

Halaman **Pengaturan** (ikon gigi di kanan atas) menyediakan: nama pengguna
(dipakai pada sapaan Beranda), target kartu baru harian, pilihan tema
(Sistem/Terang/Gelap), statistik (streak, jumlah kartu dipelajari), dan reset.

**Sinkronisasi antar-perangkat** memakai **Ekspor/Impor berkas** (situs statis,
tanpa server): *Ekspor* mengunduh `ichigo-backup-YYYYMMDD.json`; *Impor* di
perangkat/peramban lain **menggabung** data secara cerdas — untuk tiap kartu,
salinan dengan review terbaru yang menang (streak diambil yang tertinggi), jadi
progres tidak pernah hilang. Aturan merge ini mengikuti filosofi `BackupMerge`
di aplikasi iOS.

### Sinkronisasi otomatis via Google Drive

Selain berkas, tersedia **sync otomatis** ke folder privat aplikasi di Google
Drive (`appDataFolder` — hanya berkas milik app ini yang terlihat, bukan berkas
Drive Anda yang lain). Autentikasi memakai **Google Identity Services** langsung
di peramban; tidak ada server maupun SDK. Saat aktif, app menyinkron **saat
dibuka** (tarik + merge) dan **setelah sesi flashcard** (dorong).

Ini butuh **Client ID OAuth (tipe Web)** milik Anda — bukan rahasia, dan **tidak
disimpan di repo**. Menyiapkannya sekali:

1. Buat proyek di <https://console.cloud.google.com/> dan **aktifkan Google Drive API**.
2. **OAuth consent screen** (External boleh untuk pribadi); tambahkan diri Anda
   sebagai *Test user*. Scope cukup `.../auth/drive.appdata` + `email`.
3. **Credentials → Create OAuth client ID → Web application**. Pada
   *Authorized JavaScript origins*, tambahkan origin tempat situs di-host
   (mis. `https://USERNAME.github.io` untuk GitHub Pages, atau
   `http://localhost:8000` untuk uji lokal).
4. Salin Client ID (`...apps.googleusercontent.com`) dan isikan di app pada
   **Pengaturan → Sinkronisasi Google Drive → Client ID**, lalu **Masuk dengan
   Google**. (Alternatif: pakai `web/config.js` — lihat `web/config.example.js`.)

**Catatan:** format cadangan web berbeda dari aplikasi iOS, jadi sync ini bekerja
**web ↔ web** (antar-peramban/perangkat). Interop iOS ↔ web bisa ditambahkan
kemudian. Bila situs dibuka offline atau tanpa Client ID, fitur ini menonaktifkan
diri dengan anggun dan ekspor/impor berkas tetap tersedia.

## Kesetaraan FSRS

`js/fsrs.js` memakai formula dan bobot yang identik dengan `FSRSMath` /
`FlashcardReviewEngine` di Swift: retrievability, initial/next stability &
difficulty, interval dari target retention 0,9, dan learning steps `[1, 10]`
menit ("cara A"). Jadi kartu baru yang dijawab **Mudah** langsung lulus ke
interval 4 hari, sementara **Bagus** masuk langkah pembelajaran — sama seperti
di aplikasi.
