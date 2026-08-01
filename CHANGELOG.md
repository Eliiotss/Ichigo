# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Reference sources for the JLPT datasets** documented in
  `Sources/AppFeature/Resources/README.md`: Tanos.co.uk (vocabulary lists),
  JLPTsensei.com (grammar/vocab/kanji per level), Jisho.org (per-entry
  meaning/reading/level verification) and the official JLPT past papers — with a
  note that these are community references (no official list since 2010) to be
  used for verifying individual entries, not copied wholesale.
- **121 verified N3 kanji** (`KanjiN3.json`, `N3_215`–`N3_335`), added in themed
  clusters — economy/money (富, 貧, 貸, 貨, 貯, 販, 換, 略 …), nature/water (波, 岸,
  河, 岩, 砂, 灰, 煙, 湖, 沿, 傾, 沈, 浮, 潮), body/health (胸, 腹, 肩, 腰, 髪, 涙, 汗,
  呼, 眠, 疲, 痛, 症, 骨, 傷), emotion/mind (怒, 悲, 喜, 恐, 怖, 恥, 恋, 慣, 憶, 惑, 悩,
  忙, 忘, 慎) and society/government/finance (党, 律, 憲, 挙, 署, 域, 券, 州, 貿, 購,
  融, 株, 債, 僚) and action/hand-motion (押, 抜, 捨, 拾, 抱, 抵, 拒, 揺, 振, 握, 掘,
  撮, 描, 抑) and speech/thought (討, 詳, 譲, 訴, 誇, 詐, 誠, 誘, 誉, 訂, 謙, 詰, 該,
  諾) and industry/materials/food (織, 維, 綿, 網, 継, 縁, 緩, 咲, 枯, 耕, 菌, 粉, 粒,
  焼) — all common kanji not already in any level. Each carries accurate on'yomi /
  kun'yomi / meaning and five real compound-word examples (word, reading, rōmaji,
  meaning) rendered into the dataset's fixed sentence templates (sentence + furigana
  + Indonesian). The level count in `KanjiModel.swift` moves 214 → 335, enforced by
  `check_dataset_counts.py`.
- **Grammar N5–N3 completed to the common reference counts.** 22 verified N3
  patterns (`GrammarN3.json`, `N3_G161`–`N3_G182`) and one core N4 pattern
  (`GrammarN4.json`, `N4_G132`: 〜てもいい / 〜てはいけない) that were missing from
  the sets. The N3 additions — 〜として, 〜ば〜ほど, 〜さえ〜ば, 〜きり, 〜わりに(は),
  〜において/〜における, 〜向け/〜向き, 〜だけに, 〜ことだ, 〜っこない, 〜うちに,
  〜からには, 〜わけにはいかない, 〜ざるを得ない, 〜たとたん(に), 〜だけあって,
  〜かと思うと/〜かと思ったら, 〜最中に, 〜てはじめて, 〜からこそ, 〜にすぎない and
  〜ものか — each carry the full schema (structure, nuance, explanation, usage,
  common mistakes and four example sentences with rōmaji + Indonesian) and are
  deduplicated against both the N3 and N4 sets. The level counts in
  `GrammarModel.swift` move to 182 (N3) and 132 (N4), enforced by
  `check_dataset_counts.py`, bringing N5/N4/N3 to 84/132/182 — level with the
  widely-cited JLPT Sensei list counts.
- **64 verified N3 vocabulary entries** (`VocabN3.json`, `N3_V1111`–`N3_V1174`),
  hand-checked batches of common words not already in the set (経済-adjacent
  society/work/health/abstract nouns, suru-verbs, na-adjectives and adverbs — e.g.
  発揮する, 把握する, 募集する, 翻訳する, 手段, 対象, 患者, 医療, 預金, 損害, 明確,
  慎重, 主要, 妥当, 案外, 相変わらず). Each carries an accurate reading, Indonesian
  meaning and word type; the level count advertised in `VocabModel.swift` moves
  1.110 → 1.174 and stays enforced by `check_dataset_counts.py`. Every candidate
  was deduplicated against N5/N4/N3 before insertion — of ~100 candidates only ~27
  were genuinely new, confirming the set is already broad. Deliberately kept to
  genuinely-known words rather than bulk-generating the long tail, to avoid
  shipping unverified data.
- **Editable username in Settings.** A new **PROFIL** section carries a **Nama
  Pengguna** field bound to `AccountStore.displayName`; it persists automatically
  and syncs live to the Home greeting and the Profile header (both observe the
  shared `AccountStore`). Default is `user123`.
- **Time-of-day greeting on Home.** The static "Halo" line now reads *Selamat
  pagi / siang / sore / malam* by the device hour (`TimeGreeting`, unit-tested).
- **First-install date is recorded** (`AppInstallInfo`) as the origin for the
  per-day counts, stamped once during the splash preload.
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
- **Light / dark mode setting.** Settings → PREFERENSI carries a **Mode
  Tampilan** row with a slide toggle — drag or tap left for light, right for
  dark (`ThemeSlideToggle`). The choice is applied once at the root via
  `preferredColorScheme`, so every screen and sheet follows it, and it is
  persisted and included in the backup payload alongside the other preferences.
  Before the first drag the app follows the device (`system`); older backups
  without the field restore the same way. Every screen already draws its
  colours from the colour-scheme-aware `AppTheme` tokens, so nothing is left
  stranded in light styling when dark is selected.
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
- **Flashcard new-card quota follows the daily target.** The session builder's
  per-deck new-card limit is now the **Target Harian** value from Settings instead
  of a fixed 35, so setting e.g. 45/day gives 45 new cards per deck each day; due
  repetitions still stack on top as they come due. The `FlashcardSettings` default
  is unchanged so the pure builder tests keep asserting against a known value.
- **Home "Due" / Profile "hari ini" now show the day's real workload.** They read
  `FlashcardStore.dailyDueTotal(target:)` — remaining new cards for today plus the
  reviews that have come due — instead of counting every un-mastered card. The
  figure resets each day from the install date.
- **Light and dark palette tuned for comfort.** Light mode moves to a slightly
  brighter warm cream (`#F1EAE3`, with matching track/hairline) and dark mode moves
  off pure black to a soft navy (`#12161F` page, `#1C2231` cards). All values live
  in the single `AppTheme` colour panel, so every screen follows in both modes.
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
- **Placeholder kanji examples in `KanjiN5.json`.** 51 kanji carried a bogus
  fifth example whose word was the kanji with `語` appended (`水語`, `木語`, `山語`
  …) and whose `reading`/`romaji` were blank — auto-generated filler that never
  read as real Japanese. Each is now the standalone kanji with its primary
  on'yomi (`水` → スイ/sui, `木` → モク/moku), derived from the entry's existing
  `onyomi` field and a deterministic katakana→rōmaji conversion validated against
  the 69 already-correct entries. Item count is unchanged and every reading/rōmaji
  is now filled.
- **Empty example translation in `GrammarN4.json`.** Item `N4_G125` (〜どうしても)
  had one example with a blank Indonesian translation; it is now filled.
- **Graduating-interval settings were dead code.** `FlashcardSettings`
  carried `graduatingIntervalDays` (1) and `easyIntervalDays` (4) but the review
  engine ignored them and graduated every learning card straight off its FSRS
  stability (≈2 days for Good), so a new card first reappeared on day 3 rather
  than day 2. The learning/relearning graduation now uses the fixed graduating
  interval ("cara A": Anki-style learning steps + graduating interval), so a
  Good graduation is due the next day and an Easy graduation in four; FSRS-6
  then schedules every subsequent review from the card's stability, unchanged.
  Regression tests assert the graduating intervals.
- **FSRS-6 difficulty update was missing linear damping.** `nextDifficulty`
  applied the FSRS-4.5 form (`D − w6·(G−3)`), omitting the `(10 − D)/9` damping
  introduced in FSRS-5/6 that shrinks difficulty changes as a card approaches
  the maximum. The mean-reversion step was already present; the damping is now
  applied before it, matching the reference algorithm. New tests assert the
  direction (Again harder, Easy easier) and that the change shrinks near the
  ceiling.
- **Flashcard session summary was bare.** After a deck session ended the screen
  showed only "Benar: X - Ulang: Y". It now presents a full summary — session
  accuracy, the number correct / needing another round / total cards, and the
  current day streak — all read from the same `FlashcardStore` that feeds the
  Home hero card and Profile, so the figures agree across every screen.
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
- Dead code: `FlashcardStore.dueTodayGrandTotal`, which summed every un-mastered
  card across all decks and is superseded by `dailyDueTotal(target:)`.
- Debug `print` statements across the loaders (replaced by unified logging).
- Artificial fixed-delay spinners on the static Kanji/Grammar/Vocabulary level
  lists, improving perceived navigation speed.
- Leftover review-note comments in the source.

### Changed (continued)
- **Deprecated SwiftUI APIs migrated.** `NavigationView` → `NavigationStack`
  (dropping the now-unnecessary `.navigationViewStyle(.stack)`) and every
  `foregroundColor(_:)` → `foregroundStyle(_:)` across the app. The minimum
  target is iOS 17, so both replacements are available; behaviour is unchanged.

### Design decisions
- **Typography stays on SF Pro Rounded**, the system's rounded face, as the
  native stand-in for the design's Baloo 2 / Nunito. This keeps the app binary
  small and avoids bundling and registering font files; the shapes are a close
  match.
- **Indonesian-only, strings inline.** The app ships in Indonesian and there is
  no second language planned, so user-facing text stays in the views. SwiftUI's
  `Text` already treats those literals as localised keys with the Indonesian
  text as the fallback, so the app remains translation-ready without a
  `Localizable.strings` file — which in the Swift Playgrounds package would add
  bundle-resolution risk for no benefit while the app has one language.

### Known limitations / next steps
- Content covers JLPT **N5–N3** plus kana; N2/N1 datasets are the recommended
  next expansion (those levels stay gated until their data is added).
- Account, backup and sync are implemented under `Backup/` but parked behind
  "Segera hadir"; wiring them to the UI is the largest remaining piece.
