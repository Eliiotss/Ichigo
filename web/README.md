# Ichigo — versi web

Port web dari aplikasi Ichigo (belajar bahasa Jepang JLPT). **Statis, tanpa
build**: HTML + CSS + JavaScript (ES modules) murni. Sepenuhnya terpisah dari
kode Swift di `Sources/` — mengubah web tidak menyentuh aplikasi iOS.

## Fitur

- **Penjelajah konten**: Kanji, Kosakata, dan Tata Bahasa untuk **N5–N3**
  (daftar + detail + pencarian langsung), serta bagan **Hiragana & Katakana**.
- **Flashcard dengan FSRS-6**: penjadwalan spaced-repetition yang **diport
  persis** dari mesin FSRS aplikasi iOS (bobot 21 parameter resmi + learning
  steps ala Anki). Progres tersimpan di `localStorage` peramban.
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

## Struktur

```
web/
  index.html          # kerangka SPA
  css/styles.css       # tema (terang/gelap), tata letak, komponen
  js/
    app.js             # router berbasis hash + navigasi + tema
    levels.js          # metadata level JLPT (jumlah, kunci, warna)
    data.js            # pemuat JSON + cache
    browse.js          # tampilan Kanji/Vocab/Grammar/Hiragana (daftar+detail)
    fsrs.js            # FSRS-6 (port setia dari FlashcardModel.swift)
    store.js           # progres/streak/kuota harian di localStorage
    flashcards.js      # pemilih dek + sesi review
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
di aplikasi iOS. (Sinkronisasi otomatis lewat Google Drive bisa ditambahkan
kemudian bila diinginkan.)

## Kesetaraan FSRS

`js/fsrs.js` memakai formula dan bobot yang identik dengan `FSRSMath` /
`FlashcardReviewEngine` di Swift: retrievability, initial/next stability &
difficulty, interval dari target retention 0,9, dan learning steps `[1, 10]`
menit ("cara A"). Jadi kartu baru yang dijawab **Mudah** langsung lulus ke
interval 4 hari, sementara **Bagus** masuk langkah pembelajaran — sama seperti
di aplikasi.
