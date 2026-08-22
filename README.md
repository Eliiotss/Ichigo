# Ichigo 🍓

**Ichigo** is a Japanese-learning app for the JLPT — kana practice, kanji,
vocabulary and grammar references, and a flashcard trainer driven by the
**FSRS-6** spaced-repetition algorithm. The interface is in Bahasa Indonesia.

> The name *Ichigo* (いちご) means "strawberry" — and doubles as a play on
> *ichi-go* ("one word / one point") for language study.

The same app is implemented on **three platforms**, each in its own folder:

| Platform | Folder | Stack | Notes |
| --- | --- | --- | --- |
| 🍎 **iOS** | [`ios/`](ios/) | SwiftUI · Swift Package | The original app. FSRS-6, kana/kanji/vocab/grammar, Google Drive backup. |
| 🤖 **Android** | [`android/`](android/) | Kotlin · Jetpack Compose · Hilt · Room | Faithful native port with two-way Google Drive **sync** (`drive.appdata`). |
| 🌐 **Web** | [`web/`](web/) | Static HTML/CSS/JS (no build) | Browser port — same content, FSRS-6, file backup + Google Drive sync. |

Each platform is self-contained and builds independently; the three share the
**same datasets and the same FSRS-6 logic**, ported per platform.

---

## Repository layout

```
Ichigo/
├─ ios/            # SwiftUI app (Sources/, Tests/, Package.swift, docs, scripts)
├─ android/        # Kotlin + Jetpack Compose app (Gradle)
├─ web/            # Static web port (open web/index.html) + privacy.html + home.html
├─ materials/      # Shared study-material source (materi.md)
├─ CHANGELOG.md    # Project-wide change history
├─ REFERENCES.md   # Dataset sources & references
└─ .github/        # CI workflows: swift.yml (iOS) · android.yml · pages.yml (web)
```

---

## Quick start per platform

| | Command |
| --- | --- |
| **iOS** | `cd ios && open Package.swift` → Run in Xcode (see [`ios/README.md`](ios/README.md)) |
| **Android** | `cd android && ./gradlew installDebug` (see [`android/README.md`](android/README.md)) |
| **Web** | serve the `web/` folder statically, open `index.html` (see [`web/README.md`](web/README.md)) |

---

## Features (all platforms)

- **Huruf (Kana)** — Hiragana & Katakana tables with a flashcard drill and
  per-character mastery.
- **Kanji / Vocabulary / Grammar** — JLPT-levelled browsers with search, readings,
  examples, and text-to-speech (native platforms).
- **Flashcard** — a full **FSRS-6** scheduler over the Vocabulary and Grammar
  decks: learning steps, due queues, daily new-card limits, streaks, analytics.
- **Profile & Settings** — daily target, streak, mastery/accuracy stats, study
  reminder, and progress reset.
- **Backup & sync** — export/import a backup file (no account needed) and, on
  Android/Web, optional two-way **Google Drive** sync scoped to the app's own
  private folder (`drive.appdata`) — the app never touches your other Drive files.

---

## Documentation

- iOS app: [`ios/README.md`](ios/README.md) · design & data model in
  [`ios/ARCHITECTURE.md`](ios/ARCHITECTURE.md) · contributing in
  [`ios/CONTRIBUTING.md`](ios/CONTRIBUTING.md)
- Android app: [`android/README.md`](android/README.md) · Play Store release in
  [`android/docs/PlayStore.md`](android/docs/PlayStore.md) · Drive sync setup in
  [`android/docs/GoogleDriveSync.md`](android/docs/GoogleDriveSync.md)
- Web app: [`web/README.md`](web/README.md)
- Change history: [`CHANGELOG.md`](CHANGELOG.md) · sources: [`REFERENCES.md`](REFERENCES.md)

---

## License

No license file is currently provided. Until one is added, all rights are
reserved by the repository owner.
