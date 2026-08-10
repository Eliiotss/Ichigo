# Rilis IchiGo ke Google Play — panduan lengkap

Checklist + teks siap-tempel untuk mempublikasikan IchiGo. Kode & bundle sudah
siap (AAB bertanda tangan, R8, targetSdk 35). Yang tersisa kebanyakan mengisi
form di Play Console.

> **Email developer:** `ichigogo1708@gmail.com` (dipakai untuk kontak listing,
> Data safety, content rating, dan halaman privacy).

## 0. Prasyarat
- Akun **Google Play Console** (biaya pendaftaran satu kali **$25**).
- Berkas rilis: **`IchiGo-release.aab`** (dari `./gradlew bundleRelease`).
- **`applicationId`** = `com.ichigo.app` — pastikan unik/milikmu.

## 1. Aset toko
| Aset | Ukuran | Status |
| --- | --- | --- |
| Ikon aplikasi | 512×512 PNG | ✅ `android/design/ichigo-playstore-icon-512.png` |
| Feature graphic | 1024×500 PNG | ✅ `android/design/feature-graphic-1024x500.png` |
| Screenshot ponsel | min. 2 (mis. 1080×1920) | ⬜ **ambil dari HP** (Home, Kanji, Flashcard, Profil, Pengaturan) |
| Privacy policy | URL publik | ✅ `web/privacy.html` → host (lihat §5) |

Cara screenshot: buka app di HP → tombol power+volume-down → ambil 3–5 layar
terbaik. Tak perlu diedit.

## 2. Teks listing (siap tempel)

**Nama aplikasi:** `IchiGo`

**Deskripsi singkat** (maks 80 karakter):
```
Belajar bahasa Jepang JLPT: Kanji, Kosakata, Grammar, Kana dengan flashcard.
```

**Deskripsi lengkap** (maks 4000 karakter):
```
IchiGo membantu kamu belajar bahasa Jepang untuk JLPT secara mandiri — Kanji,
Kosakata, Tata Bahasa, dan huruf Kana (Hiragana & Katakana) — dalam satu aplikasi
yang ringan dan rapi.

FITUR:
• Flashcard dengan penjadwalan cerdas (algoritme FSRS) — kartu muncul kembali
  tepat sebelum kamu lupa, jadi belajar lebih efisien.
• Materi JLPT N5–N2: kanji beserta on'yomi/kun'yomi, contoh kata, dan contoh
  kalimat; kosakata; serta tata bahasa dengan penjelasan dan contoh.
• Latihan Hiragana & Katakana.
• Target harian, streak, dan statistik untuk menjaga motivasi.
• Pencarian global lintas semua level.
• Tandai tata bahasa yang sudah dikuasai.
• Pengingat belajar harian.
• Mode terang & gelap.

PRIVASI:
Semua progresmu tersimpan di perangkat. IchiGo tidak memiliki server dan tidak
mengumpulkan data pribadi. Kamu bisa mencadangkan progres ke sebuah berkas kapan
saja dan memulihkannya di perangkat lain.

Cocok untuk pemula sampai menengah yang ingin belajar bahasa Jepang setiap hari.
```

**Kategori:** Education · **Tag:** pendidikan, bahasa
**Email kontak:** `ichigogo1708@gmail.com`
**Situs (opsional):** URL GitHub Pages / privacy (lihat §5)

## 3. Data safety (jawaban form Play Console)
- Apakah aplikasi mengumpulkan atau membagikan data pengguna? → **Tidak.**
  (Semua data disimpan lokal; tidak dikirim ke server mana pun.)
- Data dienkripsi saat transit? → tidak relevan (tak ada pengiriman data).
- Ada cara meminta hapus data? → data ada di perangkat; hapus dengan
  uninstall / "Reset Progress" di app.
- Jika nanti sinkronisasi Google Drive diaktifkan: data disimpan di **Google
  Drive milik pengguna** (folder privat app), bukan ke server developer —
  deklarasikan hanya bila fitur itu benar-benar dinyalakan.

## 4. Content rating (kuesioner IARC)
- Kekerasan/seksual/narkoba/judi → **Tidak** untuk semua.
- Hasil yang diharapkan: **Rated for Everyone / 3+.**
- Email untuk kuesioner: `ichigogo1708@gmail.com`.

## 5. Privacy policy URL
Play mewajibkan **tautan web publik**. Pilihan:
- **GitHub Pages** (repo sudah punya workflow `pages.yml` untuk folder `web/`):
  aktifkan Settings → Pages → Source "GitHub Actions", jalankan workflow, lalu
  URL-nya `https://eliiotss.github.io/Ichigo/privacy.html` (repo harus publik).
- Atau host `web/privacy.html` di Netlify/Vercel/Cloudflare Pages/Google Sites.
- Email kontak privasi di `web/privacy.html` sudah diisi
  (`ichigogo1708@gmail.com`).

## 6. Signing
- **Play App Signing** aktif: Google memegang app signing key; kamu mengunggah
  AAB yang ditandatangani dengan **upload key** (`android/keystore/ichigo-upload.jks`).
- Simpan keystore + password baik-baik. Jangan pernah commit ke repo.

## 7. Langkah publikasi (ringkas)
1. Play Console → **Create app** (nama IchiGo, bahasa Indonesia, App, Free).
2. **Store listing**: tempel teks §2, unggah ikon + feature graphic + screenshot.
3. **Privacy policy**: tempel URL §5.
4. **App content**: isi Data safety (§3), Content rating (§4), Target audience,
   Ads (tidak ada iklan), Government app (tidak).
5. **Release → Testing → Internal testing**: buat rilis, unggah
   `IchiGo-release.aab`, tambahkan email penguji, kirim.
6. Uji dari tautan internal testing. Kalau oke → **Production**.
7. Pengiriman pertama biasanya ditinjau Google beberapa hari.

## 8. Untuk update berikutnya
Naikkan versi di `app/build.gradle.kts` (`appVersionPatch/Minor/Major`),
`./gradlew bundleRelease`, unggah AAB baru. `versionCode` naik otomatis.
