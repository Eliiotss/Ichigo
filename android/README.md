# Ichigo — versi Android

Port **Android native** dari aplikasi Ichigo (belajar bahasa Jepang JLPT).
Dibangun sebagai **replika setia** aplikasi iOS/SwiftUI di `Sources/AppFeature/` —
UI, UX, alur, dan **seluruh business logic** (FSRS-6, antrean review, kuota kartu
baru, streak, statistik, pencarian, filter) dipertahankan persis. **Tidak
menyentuh kode Swift**: berdiri sendiri di folder `android/`.

Ditulis dengan **Kotlin + Jetpack Compose**, arsitektur **MVVM + Repository +
Clean layering**, **Room** untuk penyimpanan, **Navigation Compose**,
**Coroutines/Flow/StateFlow**, dan **Hilt** untuk dependency injection.

## Menjalankan

Buka folder `android/` di **Android Studio** (Ladybug / AGP 8.7+), lalu Run.
Atau dari terminal (butuh Android SDK terpasang):

```bash
cd android
./gradlew assembleDebug        # APK debug
./gradlew installDebug         # pasang ke perangkat/emulator
```

- **minSdk 24**, **targetSdk 35**, Kotlin 2.0, Compose BOM 2024.12.
- Tidak butuh kunci/kredensial apa pun untuk menjalankan fitur inti.

## Arsitektur & struktur

```
android/app/src/main/
  assets/data/*.json          # SALINAN dataset dari Sources/AppFeature/Resources
  res/font/baloo2.ttf         # font Baloo 2 (OFL) — padanan SF Pro Rounded iOS
  java/com/ichigo/app/
    IchigoApplication.kt      # @HiltAndroidApp
    MainActivity.kt           # host single-activity + SplashScreen API
    data/
      model/                  # KanjiItem, VocabularyItem, GrammarItem, Kana…, ContentLevel, AppAppearance
      flashcard/              # FSRS-6: FSRSMath, ReviewEngine, DeckQueueBuilder, DayKey, Validator, models
      resource/               # ResourceLoader (baca JSON assets, cache) — port JSONResourceCache
      local/                  # Room (entity/dao/db) + AppPreferences (DataStore)
      repository/             # Content / Flashcard / Kana / Account repositories
    di/                       # Hilt module (Room + DAO)
    ui/
      theme/                  # port AppTheme.swift → Color/Theme/Type/Dimens/Modifiers
      components/             # port DesignComponents.swift (ScreenHeader, SearchField, hero, chips, toggle…)
      navigation/             # Routes + MainScaffold (tab bar bawah) + NavHost
      splash/ home/ browse/ flashcard/ hiragana/ profile/ settings/   # layar + ViewModel per fitur
    util/SpeechHelper.kt      # TTS Jepang — port AudioSpeechHelper
```

**Aliran data**: `Screen` (Compose) → `ViewModel` (StateFlow) → `Repository` →
`Room`/`DataStore`/`ResourceLoader`. Peta progres flashcard di-*cache* di memori
(seperti `progressMap` di Swift) agar antrean & statistik dihitung sinkron,
sementara penulisan dicerminkan ke Room.

## Pemetaan Swift → Kotlin

| iOS (SwiftUI) | Android (Compose) |
| --- | --- |
| `AppTheme.swift` (warna, level, gradien, radius) | `ui/theme/Color.kt`, `Theme.kt`, `Dimens.kt` |
| `.system(design: .rounded)` (SF Pro Rounded) | Baloo 2 (variable font, `Type.kt`) |
| `DesignComponents.swift` | `ui/components/DesignComponents.kt` |
| `RootView` / `SplashView` | `ui/IchigoApp.kt` + `ui/splash/SplashScreen.kt` |
| `ContentView` (TabView + Home) | `ui/navigation/MainScaffold.kt` + `ui/home/HomeScreen.kt` |
| `FlashcardModel.swift` (FSRS-6, stores) | `data/flashcard/*` + `data/repository/FlashcardRepository.kt` |
| `UserDefaults` stores | Room (`data/local`) + DataStore (`AppPreferences`) |
| `KanjiListView`/`VocabularyListView`/`GrammarListView` | `ui/browse/*Screens.kt` + `*ViewModel` |
| `KanjiDetailView`/`GrammarDetailView` | `ui/browse/DetailContent.kt` |
| `HiraganaView`/`HiraganaFlashcardView` + `HiraganaStore` | `ui/hiragana/*` + `KanaRepository` |
| `FlashcardSessionView` + `FlashcardDeckSessionViewModel` | `ui/flashcard/*` + `FlashcardSessionViewModel` |
| `ProfileView` / `SettingsView` | `ui/profile/ProfileScreen.kt` / `ui/settings/SettingsScreen.kt` |
| `AudioSpeechHelper` (AVSpeech) | `util/SpeechHelper.kt` (`TextToSpeech`) |
| `NotificationManager` (UNUserNotification) | izin `POST_NOTIFICATIONS` (penjadwalan → menyusul) |

## Kesetaraan FSRS

`data/flashcard/` memakai formula dan bobot yang **identik** dengan `FSRSMath` /
`FlashcardReviewEngine` di Swift (21 bobot resmi FSRS-6, learning steps `[1, 10]`
menit "cara A", `graduatingInterval=1`, `easyInterval=4`, retensi `0,9`,
`leechThreshold=8`). Port ini **diuji terhadap dataset asli** lewat harness JVM
mandiri — 30/30 cek lolos: parsing dataset (120/181/367 Kanji · 800/700/1.800
Vocab · 84/132/182 Grammar), penjadwalan (Baru+Mudah = 4 hari, langkah belajar
1→10 menit → lulus 1 hari, interval review 7 hari), leech, antrean dek, dan
streak.

## Catatan data

Berkas di `assets/data/` adalah **salinan** dari `Sources/AppFeature/Resources/`.
Bila dataset iOS diperbarui, salin ulang:

```bash
cp Sources/AppFeature/Resources/*.json android/app/src/main/assets/data/
```

N2/N1 terkunci (belum ada dataset), sama seperti aplikasi iOS.

## Status & yang menyusul (bertahap)

- **Cadangan data (file)**: **aktif** di Pengaturan → "CADANGAN DATA". Ekspor
  progres ke satu berkas `.json` lewat file picker (bisa diunggah manual ke Google
  Drive / dipindah ke HP lain), lalu Impor untuk memulihkan — di-*merge* pakai
  `BackupMerge` (tak ada yang hilang). **Tanpa setup Google apa pun.**
- **Sinkronisasi Google Drive**: **aktif** di Pengaturan → "AKUN & SINKRONISASI".
  Masuk dengan Google (scope `drive.appdata` saja — folder privat aplikasi, bukan
  file Drive lain), lalu progres flashcard + hiragana/katakana tersinkron dua arah
  (pull → merge → push) ke satu berkas `ichigo-backup.json`. Ada sakelar
  **Sinkronisasi otomatis** (berjalan saat aplikasi dibuka) dan **Sinkronkan
  sekarang** manual. Token akses tidak pernah disimpan (diambil segar tiap sync
  via `GoogleAuthUtil`). Butuh setup satu kali di Google Cloud Console (SHA-1 +
  package + Test user) — langkahnya: [`docs/GoogleDriveSync.md`](docs/GoogleDriveSync.md).
  Kalau muncul "kode 10", itu berarti setup OAuth belum lengkap (bukan bug app).
- **Penjadwalan notifikasi harian**: sakelar pengingat + izin sudah ada;
  penjadwalan latar (WorkManager) menyusul.
- Dataset N2/N1 belum disertakan (mengikuti iOS).

## Rilis ke Play Store (AAB bertanda tangan)

Build rilis memakai **signing config** yang dibaca dari `keystore.properties`
(TIDAK di-commit — lihat `.gitignore`). Isi berkasnya:

```properties
storeFile=keystore/ichigo-upload.jks
storePassword=****
keyAlias=ichigo-upload
keyPassword=****
```

### Versi (naikkan tiap update)

Versi diatur di **satu tempat** di `app/build.gradle.kts`:

```kotlin
val appVersionMajor = 1
val appVersionMinor = 0
val appVersionPatch = 0
```

Sebelum build rilis baru, naikkan angkanya:

- **perbaikan kecil / konten** → `patch` (mis. `1.0.0` → `1.0.1`)
- **fitur baru** → `minor` (`1.0.1` → `1.1.0`, patch balik ke `0`)
- **perubahan besar** → `major` (`1.9.0` → `2.0.0`, minor & patch ke `0`)

`versionName` (mis. `1.0.0`) tampil di Play Store dan di **Pengaturan → Tentang →
Versi**. `versionCode` dihitung otomatis (`major*10000 + minor*100 + patch`),
jadi **selalu naik** — Google mewajibkan `versionCode` lebih besar dari upload
sebelumnya untuk tiap rilis. Tidak perlu ubah `versionCode` manual.

Build:

```bash
cd android
./gradlew bundleRelease     # → app/build/outputs/bundle/release/app-release.aab  (unggah ke Play Console)
./gradlew assembleRelease   # → app/build/outputs/apk/release/app-release.apk    (uji langsung di HP)
```

Build rilis **di-obfuscate dengan R8** (`isMinifyEnabled`/`isShrinkResources`):
kode yang tidak terpakai dibuang dan simbol logika diganti nama jadi acak, jadi
APK yang di-*decompile* sulit dibaca. Tiap build menghasilkan
`app/build/outputs/mapping/release/mapping.txt` — **simpan** berkas ini per rilis
untuk membaca ulang laporan *crash*. Detail keamanan & pengerasan: lihat
[`docs/SECURITY.md`](docs/SECURITY.md).

Langkah publikasi (ringkas):
1. Buat akun **Google Play Console** (biaya pendaftaran satu kali $25).
2. **Create app** → isi nama, bahasa, kategori (Education).
3. **App integrity → Play App Signing**: aktif (Google memegang app signing key;
   kamu mengunggah AAB yang ditandatangani dengan **upload key** di
   `ichigo-upload.jks`). Kalau upload key hilang, bisa di-reset lewat Play.
4. Unggah `app-release.aab` ke track **Internal testing** dulu, lalu Production.
5. Lengkapi **Data safety**, **Privacy policy**, ikon toko **512×512**
   (`ichigo_playstore_icon_512.png`), screenshot, dsb.
6. `applicationId` saat ini `com.ichigo.app` — pastikan unik/milikmu sebelum rilis.

**Penting:** simpan `ichigo-upload.jks` + passwordnya baik-baik (untuk update
aplikasi berikutnya). Jangan pernah commit keystore/password ke repo.

## Ikon & splash

- **Launcher icon**: adaptive icon (foreground konten logo + background krem
  `#FCF9F4`) di `res/mipmap-*` + `res/drawable-*/ic_launcher_foreground.png`.
- **Splash**: wordmark "IchiGo" (`res/drawable-nodpi/ic_splash_logo.png`) di atas
  latar krem, dengan bilah progres pemuatan dataset.

## Font

Baloo 2 (`res/font/baloo2.ttf`) disertakan di bawah **SIL Open Font License 1.1**
(lisensi di `res/raw/baloo2_license.txt`) sebagai padanan tampilan membulat
SF Pro Rounded pada iOS.
