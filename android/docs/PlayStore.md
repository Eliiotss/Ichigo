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
Sinkronisasi Google Drive kini **aktif** (opsional, dimatikan secara default),
jadi isian Data safety harus jujur menyebutkannya:

- **Apakah app mengumpulkan/membagikan data?** → **Ya, terbatas** — hanya bila
  pengguna memilih login Google.
  - **Alamat email** (dari Google Sign-In) → *Collected*. Tujuan: **App
    functionality** (menandai akun sync). Tidak dibagikan ke pihak ketiga.
    Bersifat **opsional** (hanya kalau pengguna login). Tidak dikirim ke server
    developer — developer tidak punya server.
  - **App activity / progres belajar** → disimpan di **Google Drive milik
    pengguna** (folder privat app `appDataFolder`), bukan ke server developer.
- Kalau pengguna **tidak** login Google → tidak ada data yang keluar dari
  perangkat sama sekali (murni lokal).
- **Dienkripsi saat transit?** → **Ya** (semua panggilan ke Google Drive lewat
  HTTPS).
- **Ada cara hapus data?** → Ya: "Reset Semua Progress" di app (menghapus lokal
  + menandai reset yang ikut ke Drive), Keluar dari akun, atau hapus berkas
  `ichigo-backup.json` dari Drive. Uninstall menghapus data lokal.

> Ringkas: kalau kamu ingin isian yang paling sederhana, kamu **boleh** merilis
> versi awal dengan sync tetap ada tapi jujur mendeklarasikan Email + aktivitas
> seperti di atas. Jangan menjawab "tidak mengumpulkan data" selama tombol login
> Google ada di app.

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

## 6b. ⚠️ WAJIB: daftarkan SHA-1 Play App Signing untuk Google Sign-In

Ini jebakan paling sering yang **mematikan sinkronisasi Google untuk semua
pengguna Play Store** kalau dilewati.

**Kenapa:** dengan Play App Signing, aplikasi yang benar-benar dipasang pengguna
**ditandatangani ulang oleh Google** memakai *app signing key* Google — BUKAN
upload key-mu. Jadi SHA-1 yang sudah kamu daftarkan (`B3:7E:…:98`, dari
`ichigo-upload.jks`) **tidak cocok** untuk APK hasil Play → Google Sign-In gagal
**kode 10** buat pengguna yang memasang dari Play, walau di APK langsung/testmu
sudah jalan.

**Solusi (lakukan setelah upload AAB pertama ke Play Console):**
1. Play Console → **Test and release → Setup → App integrity → App signing** →
   bagian **App signing key certificate** → salin **SHA-1**-nya.
2. Google Cloud Console → **Google Auth Platform → Clients → Create client →
   Android** → Package `com.ichigo.app`, tempel **SHA-1 Play App Signing** itu →
   Create. (Biarkan client upload-key yang lama tetap ada — boleh ada beberapa
   client Android sekaligus: satu untuk debug, satu upload key, satu Play.)
3. Tunggu propagasi, lalu uji lewat tautan **Internal testing** (bukan APK
   sideload) supaya kamu menguji jalur tanda tangan yang sama seperti pengguna
   asli.

> Ringkas SHA-1 yang perlu terdaftar sebagai OAuth Client (Android):
> • **debug** — untuk run dari Android Studio (opsional)
> • **upload key** `B3:7E:…:98` — untuk APK rilis yang kamu bagikan langsung
> • **Play App Signing** — WAJIB untuk versi yang dipasang dari Play Store

## 6c. Verifikasi OAuth untuk Production (agar sync jalan untuk publik)

Selama OAuth consent screen masih **Testing**, hanya Test user yang bisa login.
Untuk publik:
1. **Google Auth Platform → Audience → Publish app** (ubah ke *In production*).
2. Karena scope `drive.appdata` tergolong **sensitive**, Google meminta
   **verifikasi** agar layar peringatan "app belum diverifikasi" hilang dan tak
   ada batas ~100 pengguna. Syarat:
   - **Homepage** + **Privacy Policy** di **domain milikmu** yang diverifikasi
     di Google Search Console. Keduanya sudah disediakan di folder `web/`:
     `web/home.html` (homepage) + `web/privacy.html`. Setelah GitHub Pages aktif:
     Homepage `https://eliiotss.github.io/Ichigo/home.html`, Privacy
     `https://eliiotss.github.io/Ichigo/privacy.html`.
   - Branding lengkap (nama, logo, email).
   - Ajukan verifikasi → ditinjau Google (beberapa hari–minggu).
3. 💰 `drive.appdata` **sensitive, bukan restricted** → **tidak** perlu security
   assessment berbayar (CASA). Verifikasi gratis; yang diperlukan cuma website +
   privacy policy.

> Sebelum verifikasi selesai kamu tetap bisa rilis: pengguna melihat peringatan
> "belum diverifikasi" lalu **Advanced → Lanjutkan** (dibatasi ~100 pengguna).
> Untuk rilis serius, selesaikan verifikasi supaya mulus.

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
