# Sinkronisasi Google Drive — cara mengaktifkan & menguji

Ichigo menyinkronkan progres flashcard lewat **folder privat aplikasi** di Google
Drive milik pengguna (scope `drive.appdata`) — Anki-style, dua arah (pull → merge
→ push). Kode aplikasinya sudah aktif; agar benar-benar jalan, perlu **sekali
setup** di Google Cloud Console. Semuanya **gratis**.

## Kenapa perlu setup ini?

Google Sign-In di Android hanya mengizinkan aplikasi yang identitasnya terdaftar.
Kalau SHA-1 + package belum didaftarkan, sign-in gagal dengan **kode 10**
(`DEVELOPER_ERROR`). Ini konfigurasi, bukan bug aplikasi.

Aplikasi ini **tidak** memakai `google-services.json` atau Web Client ID — sign-in
hanya meminta email + scope `drive.appdata` (tanpa ID token). Jadi cukup membuat
**OAuth Client ID tipe Android**.

## Data yang dibutuhkan

- **Package name:** `com.ichigo.app`
- **SHA-1 (upload/release key `ichigo-upload.jks`)** — untuk APK rilis yang dikirim:
  ```
  B3:7E:A7:FB:3C:66:2F:F6:BD:45:2E:D4:C3:23:BD:8D:E5:C5:7B:98
  ```
- **SHA-1 debug** (opsional, kalau menjalankan dari Android Studio):
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
    -storepass android -keypass android | grep SHA1
  ```
- **SHA-1 Play App Signing** (opsional, kalau nanti rilis lewat Play Store):
  ambil dari Play Console → *Setup → App integrity → App signing key certificate*.

## Langkah setup (satu kali)

1. Buka [Google Cloud Console](https://console.cloud.google.com/) → **buat project**
   baru (mis. "Ichigo").
2. **APIs & Services → Library** → cari **Google Drive API** → **Enable**.
3. **APIs & Services → OAuth consent screen**:
   - User type: **External** → Create.
   - Isi nama app, email support, email developer.
   - **Scopes** → Add → tambahkan `.../auth/drive.appdata`
     (ketik `drive.appdata` untuk memfilter).
   - **Test users** → Add users → masukkan **alamat Gmail yang akan kamu pakai
     login di app**. (Selama app belum di-*publish*, hanya test user yang boleh
     memberi izin — ini normal dan gratis.)
4. **APIs & Services → Credentials → Create Credentials → OAuth client ID**:
   - Application type: **Android**.
   - Package name: `com.ichigo.app`.
   - SHA-1: tempel nilai upload key di atas (dan SHA-1 debug bila perlu — buat
     satu OAuth client per SHA-1).
   - Create.
5. Tunggu beberapa menit agar konfigurasi menyebar.

## Menguji di aplikasi

1. Buka **Pengaturan → AKUN & SINKRONISASI → Masuk dengan Google**.
2. Pilih akun (yang sudah jadi Test user), setujui izin **Google Drive**.
3. Ketuk **Sinkronkan sekarang** → statusnya jadi "Sinkronisasi selesai".
4. Aktifkan **Sinkronisasi otomatis** agar sync jalan tiap app dibuka.

Backup tersimpan sebagai satu file `ichigo-backup.json` di *appDataFolder* Drive-mu
(tak terlihat di antara file Drive biasa, dan hanya app ini yang bisa membacanya).

## Kalau muncul error

| Pesan | Artinya | Solusi |
| --- | --- | --- |
| **kode 10** (DEVELOPER_ERROR) | SHA-1/package belum terdaftar | Ulangi langkah 4; pastikan SHA-1 & package tepat |
| **kode 12500** | Consent screen/scope belum siap | Ulangi langkah 2–3 (aktifkan Drive API + scope) |
| **kode 12501** | Masuk dibatalkan | Coba lagi, pilih akun |
| **kode 7** | Tidak ada internet | Cek koneksi |
| "Perlu izin Google Drive" | Scope belum disetujui | Ketuk lalu setujui layar izin |

## Biaya

Gratis. `drive.appdata` termasuk scope **"sensitive"** (perlu review gratis untuk
publik) — **bukan** "restricted" yang bisa menuntut *security assessment* berbayar.
Penyimpanan memakai kuota Drive 15 GB gratis pengguna; file backup hanya beberapa KB.
