# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Ichigo v2 visual design** across the app: a central `AppTheme` carrying the
  design's exact tokens (warm beige `#E7E0DC` page, white cards, plum `#2B2029`
  ink, muted `#B0A199`, blue `#2E7BFF` accent with its gradient pairs) and a
  rounded type ramp.
  - **Home**: "Okaeri 🍓" greeting, tappable gradient avatar, blue hero card
    (daily progress + Due / Streak / Mastered) and a tile grid with per-tile
    gradients.
  - **Profile**: rounded gradient header with ringed avatar and "JLPT Learner"
    badge, daily-target card, 2×2 stat grid and the answer-summary pills.
  - **Settings**: sectioned white cards with gradient icon chips and inset
    dividers; native controls retained.
  - **Browsing screens** (Vocabulary / Kanji / Grammar): pinned `ScreenHeader`,
    pill `SearchField` and `FilterChipRow` that stay fixed while content scrolls.
  - **Level lists** (Vocabulary / Kanji / Grammar) now use one card layout —
    52pt level chip, bold name with chevron, and a single grey subtitle
    carrying the count ("120 Essential Kanji", "800 Kosakata Dasar", "84 Pola
    Tata Bahasa Dasar") — plus the same locked-card treatment. The unlocked and
    locked cards are byte-identical across the three screens apart from their
    level type.
  - **App-wide type ramp**: every screen now draws its fonts from
    `AppTheme.rounded(...)` and its text colours, surfaces and shadows from the
    theme tokens, so the flashcard, kana, kanji, vocabulary and grammar screens
    match Home/Profile/Settings.
- **Light / dark mode setting.** Settings → PREFERENSI now carries a **Mode
  Tampilan** row offering *Ikuti Sistem*, *Terang* and *Gelap*. The choice is
  applied once at the root via `preferredColorScheme`, so every screen and sheet
  follows it, and it is persisted and included in the backup payload alongside
  the other preferences (older backups without the field restore as *Ikuti
  Sistem*).
- **Google Drive backup & restore implementation** (`Sources/AppFeature/Backup/`):
  dependency-free OAuth 2.0 + PKCE via `ASWebAuthenticationSession`, tokens in the
  Keychain, and `URLSession` REST scoped to the Drive `appDataFolder`, plus the
  local progress snapshot (`BackupService`/`BackupPayload`). **Parked for a later
  release** — Settings advertises Akun, Cadangkan & Pulihkan and Sinkronisasi
  otomatis under "SEGERA HADIR" rather than exposing the controls. Setup notes for
  when it ships: `docs/GoogleDriveBackup.md`.

- **Swift package manifest** (`Package.swift`) defining the single-target iOS
  application — the project now has a canonical, buildable structure.
- **Unit test suite** (`Tests/AppFeatureTests`) covering the FSRS-6 math, the
  review-engine state machine, the session queue builder, day-boundary/streak
  accounting, the retention validator, analytics, deck-card mapping, the backup
  round-trip, PKCE and the account store.
- **Datasets folder** (`Sources/AppFeature/Resources/`) documented as the drop-in
  location for the maintainer's JSON datasets (kana, kanji, vocabulary, grammar),
  with the expected schemas in its `README.md`. The datasets themselves are
  supplied separately by the maintainer.
- **Unified logging** via `os.Logger` (`Log` with `resources`, `flashcards` and
  `notifications` categories).
- **Shared `ResourceLoader`** that centralises JSON array decoding and error
  handling for all loaders.
- **Documentation:** `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, this
  changelog, and a `.swiftlint.yml` configuration.

### Changed
- **Project restructured** from a flat pile of files at the repository root into
  a single `Sources/AppFeature/` app target (all logic, UI, `@main` entry and the
  `Resources/` datasets). A single target is required by Swift Playgrounds, which
  cannot link `@main` when the app is split into a separate library and executable.
- **CI** now builds the app with `xcodebuild` against an iOS Simulator
  destination (`-sdk iphonesimulator`) instead of the previous `swift build`,
  which could not compile a UIKit/SwiftUI iOS app.
- **Consistent branding:** the app entry point was renamed `MyApp` → `IchigoApp`
  and stray "NihongoMaster" / "Nihongo Master" strings are now "Ichigo".
- **Consistent filenames:** `ProfilView.swift` → `ProfileView.swift`,
  `SetingsView.swift` → `SettingsView.swift`.
- **Single source of truth for flashcards:** the flashcard flow now receives the
  shared `FlashcardStore` from the app root via dependency injection instead of
  creating a second, divergent store instance.
- **`GrammarListView`** loads its data with structured concurrency
  (`Task.detached`) to match the other list screens, replacing nested
  `DispatchQueue` calls.
- **Kana quiz** now builds answer choices from distinct distractors only.
- Loaders (`KanjiLoader`, `VocabularyLoader`, `GrammarLoader`, `KanaLoader`) are
  now stateless enums routed through `ResourceLoader`.

### Fixed
- **Dataset failures were swallowed.** `ResourceLoader` caught every error and
  returned an empty array, so a missing or corrupt JSON file was reported to the
  user as "Coming soon — konten level ini belum tersedia" and the `.failed`
  state was never assigned, leaving `ErrorStateView` unreachable. The kanji,
  vocabulary and grammar loaders now throw and their screens surface the real
  reason; callers with a genuine fallback use the explicit `loadArrayOrEmpty`.
- **Grammar list built every card eagerly**, constructing all 160 N3 rows on
  open where the kanji and vocabulary lists build only what is on screen; it is
  now a `LazyVStack` and shares the same load-state branches and 20pt inset.
- **Level counts contradicted the bundled datasets.** Kanji N3 advertised "580
  Essential Kanji" against a 214-entry dataset, Vocabulary N4 claimed ~1500
  words against 700, and Vocabulary N3 claimed ~3750 against 1110. Every count
  is now the real number of entries in the shipped JSON (Kanji 120/181/214,
  Vocabulary 800/700/1110, Grammar 84/131/160); levels whose data has not
  shipped are the only ones allowed an approximate "1.000+" figure.
  `scripts/check_dataset_counts.py` enforces both rules in CI.
- **`trailing_whitespace` was in SwiftLint's `disabled_rules`**, silencing 361
  violations across 20 files instead of fixing them. The whitespace is gone and
  the rule is on, leaving no rule switched off. The config's `excluded` path
  also still pointed at the pre-restructure `Sources/AppModule/Resources` and
  so matched nothing; it now points at `Sources/AppFeature/Resources`.
- **Level cards** for Kanji, Vocabulary and Grammar had duplicated SwiftUI
  modifiers that silently overrode the description styling; the intended
  two-line layout (name + count-bearing subtitle) is restored.
- **Kana flashcard** could render multiple "correct" answer buttons and emit
  duplicate `ForEach` identifiers when the distractor pool was small; choices are
  now guaranteed distinct.
- **Notification scheduling** now logs failures from `UNUserNotificationCenter`.

### Removed
- **Level search field on the Vocabulary screen.** It filtered a fixed list of
  five levels, which the Kanji and Grammar screens never had; the three level
  lists are now identical. Search remains where it does work — inside a level,
  over that level's actual entries.
- Dead code: the unused `AppState` observable object, the legacy `FlashcardItem`
  type and its initializer, the unused `itemsPerLevel` storage, and the no-op
  `NotificationManager.skipTodayIfTargetMet` method.
- Debug `print` statements across the loaders (replaced by unified logging).
- Artificial fixed-delay spinners on the static Kanji/Grammar/Vocabulary level
  lists, improving perceived navigation speed.
- Leftover review-note comments in the source.

### Known limitations / next steps
- Content covers JLPT **N5–N3** plus kana; N2/N1 datasets are the recommended
  next expansion (those levels stay gated until their data is added).
- Some deprecated SwiftUI APIs (`NavigationView`, `foregroundColor`,
  `accentColor`) are still in use; migrating to `NavigationStack` /
  `foregroundStyle` / `tint` is a recommended follow-up that needs on-device
  verification.
- User-facing strings are inline; extracting them into `Localizable.strings`
  would enable full localisation.
