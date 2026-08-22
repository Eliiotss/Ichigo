# Keamanan Ichigo (Android)

Ringkasan audit keamanan aplikasi Android Ichigo dan langkah pengerasan
(*hardening*) yang sudah diterapkan. Fokusnya **defensif**: melindungi kode &
data aplikasi sendiri, bukan menyerang sistem lain.

## Ringkasan audit

| Area | Temuan | Status |
| --- | --- | --- |
| Rahasia di repo | Keystore (`*.jks`), `keystore.properties`, `local.properties`, OAuth client ID **tidak** pernah di-commit (di-`.gitignore`). | ✅ Aman |
| Logging | Tidak ada `Log.*` / `println` yang membocorkan data pengguna atau token. | ✅ Aman |
| Refleksi / lookup dinamis | Tidak ada `Class.forName` / `getIdentifier` — aman untuk R8 + resource shrinking. | ✅ Aman |
| WebView / JS bridge | Tidak dipakai (tidak ada permukaan serangan XSS/JS-interface). | ✅ Aman |
| Izin (permissions) | Hanya `INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS` — minimal & wajar. | ✅ Aman |
| Token OAuth (Drive) | Diambil saat runtime via `GoogleAuthUtil`, dipakai sebagai bearer per-permintaan, **tidak** disimpan di penyimpanan aplikasi. | ✅ Aman |
| Trafik jaringan | Semua ke API Google lewat **HTTPS**; cleartext (HTTP) diblokir. | ✅ Dikeraskan |
| Komponen ter-ekspor | Hanya `MainActivity` (launcher) yang `exported` — memang perlu; tidak ada Service/Receiver/Provider ter-ekspor. | ✅ Aman |
| Data lokal | Progres flashcard di Room + preferensi di DataStore. Tidak menyimpan kredensial/PII sensitif. | ✅ Wajar |
| Backup perangkat | `allowBackup` dimatikan agar data privat aplikasi tidak bisa ditarik lewat `adb backup`. | ✅ Dikeraskan |
| Build rilis | `debuggable=false` (default rilis) dan **di-obfuscate R8**. | ✅ Dikeraskan |

## Pengerasan yang diterapkan

### 1. Obfuscation + shrinking (R8)

Build rilis menjalankan R8 (`isMinifyEnabled = true`, `isShrinkResources = true`):

- Kode yang tidak terpakai dibuang; **ukuran APK turun drastis** (~14 MB → ~3 MB).
- Setiap kelas/metode/field yang tidak sengaja dipertahankan **diganti nama jadi
  simbol pendek tak bermakna** (`a`, `b`, `c`…). Kalau APK di-*decompile*, logika
  inti (FSRS, review engine, repository, view-model, Drive client) tampil sebagai
  kode acak, bukan kode yang mudah dibaca.
- Diverifikasi pada DEX: nama kelas logika (`FSRSMath`, `FlashcardReviewEngine`,
  `DriveSyncManager`, `FlashcardDeckQueueBuilder`, `BackupMerge`, …) **tidak lagi
  muncul**.

Yang **sengaja dipertahankan** (aman, karena cuma pemegang data, bukan logika):
kelas `@Serializable` (agar JSON di `assets/` dan cadangan Drive tetap ter-parse)
dan entitas Room. Aturan lengkap ada di `app/proguard-rules.pro`.

**Penting — `mapping.txt`.** Tiap build rilis menghasilkan
`app/build/outputs/mapping/release/mapping.txt`. Simpan berkas ini untuk setiap
rilis: itulah kunci untuk membaca ulang (de-obfuscate) laporan *crash*. AGP juga
menyertakannya otomatis di dalam AAB agar Play Console bisa menampilkan stack
trace yang terbaca.

### 2. Pengerasan manifest

- `android:allowBackup="false"` + `android:fullBackupContent="false"` — mematikan
  Android Auto Backup & `adb backup`, sehingga data privat aplikasi tidak bisa
  diekstrak lewat jalur itu. (Cadangan lintas-perangkat memakai sinkronisasi
  Google Drive / ekspor, bukan backup OS.)
- `android:usesCleartextTraffic="false"` — memblokir koneksi HTTP polos; semua
  jaringan wajib HTTPS.

## Yang TIDAK dijanjikan obfuscation

Obfuscation menaikkan *effort* untuk membongkar, **bukan** membuatnya mustahil.
Ia tidak mengenkripsi aset (mis. JSON di `assets/` tetap terbaca) dan bukan
proteksi anti-tamper/anti-root. Untuk aplikasi belajar seperti Ichigo, tingkat
ini sudah memadai. Kalau nanti perlu lebih:

- **Play App Signing + Play Integrity API** untuk mendeteksi APK yang dimodifikasi/
  di-*sideload*.
- Pindahkan data yang benar-benar rahasia ke server, jangan dibundel di APK.

## Catatan pengembang

- Jangan pernah commit `*.jks`, `keystore.properties`, `local.properties`, atau
  `GoogleOAuth`/client-ID. Semua sudah ada di `.gitignore`.
- Simpan `ichigo-upload.jks` + passwordnya baik-baik; kalau hilang, upload key
  bisa di-reset lewat Play Console, tapi lebih baik jangan sampai hilang.
