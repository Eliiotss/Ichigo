# Google Drive backup & sync

Ichigo keeps your local learning progress in sync across devices through a single
JSON file in your Google Drive **appDataFolder** — a hidden, per-app folder that
only this app can read. Sync is **two-way and automatic**, like Anki: no
third-party SDK is used — sign-in is OAuth 2.0 + PKCE via
`ASWebAuthenticationSession`, and Drive access is plain `URLSession` REST.

The feature is **off until you provide an OAuth client ID**. When unconfigured,
Settings shows a short "not configured" note and the rest of the app is
unaffected.

## What gets backed up

A snapshot of the app's `UserDefaults` progress: flashcard SRS state, review
logs, analytics, streak/day-boundary data, kana mastery counts, FSRS settings,
and user preferences (name, email, daily target, reminder). Bundled content
(kanji/vocab/grammar/kana JSON) is **not** backed up — it ships with the app.

## One-time setup

1. **Create a Google Cloud project** at <https://console.cloud.google.com/>.
2. **Enable the Google Drive API** (APIs & Services → Library → Google Drive API → Enable).
3. **Configure the OAuth consent screen** (External is fine for personal use). Add
   the scope `.../auth/drive.appdata`. While the app is in "Testing", add your
   Google account under *Test users*.
4. **Create an OAuth client ID** of type **iOS**:
   - Bundle ID: `com.ichigo.app` (must match `bundleIdentifier` in `Package.swift`).
   - Copy the generated client ID, e.g. `1234567890-abcdef.apps.googleusercontent.com`.
5. **Add the client ID to the app**:
   - Copy `docs/GoogleOAuth.example.plist` to `Sources/AppFeature/Resources/GoogleOAuth.plist`.
   - Replace the `CLIENT_ID` value with your client ID.
   - This file is git-ignored, so it never lands in the repository.

No custom URL scheme needs to be registered in Info.plist:
`ASWebAuthenticationSession` intercepts the reversed-client-id redirect directly
using its `callbackURLScheme`.

## Using it

In **Settings → Akun & Sinkronisasi**:

- **Masuk dengan Google** — sign in and grant appData access.
- **Sinkronisasi otomatis** — when on (default), the app syncs on its own each
  time it enters the foreground (pull + merge) and when it goes to the background
  (push), so progress made on one device shows up on the next.
- **Sinkronkan sekarang** — run a sync immediately; the row also shows how long
  ago the last sync ran.
- **Keluar** — remove the stored tokens from the Keychain.

## How sync merges (never loses progress)

A sync downloads the cloud snapshot, merges it with the local one via
`BackupMerge`, writes the result back locally, then uploads it. The merge is
designed so no review progress is ever lost:

- **Per flashcard** — the copy whose `lastReview` is more recent wins (ties break
  toward more repetitions). Study a card on your phone, then open your tablet, and
  that card keeps the latest schedule.
- **Review history** — the union of both devices' logs, keyed by log UUID.
- **Streak** — the larger of the two.
- **Preferences** (daily target, username, theme, reminder) — the newer snapshot
  wins, falling back to the other side when a field is absent.

This is last-writer-wins per card by review time — the common "one device at a
time" case is always consistent. There is no live conflict resolution for the
same card edited on two devices simultaneously; the later review simply wins.

## Security notes

- The iOS OAuth client ID is not a secret; it is protected by PKCE and the
  appData scope.
- Tokens are stored in the Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- The app can only see files it created in `appDataFolder`, never your other
  Drive files.
