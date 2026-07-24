# Google Drive backup (manual)

Ichigo can back up and restore your local learning progress to a single JSON file
in your Google Drive **appDataFolder** — a hidden, per-app folder that only this
app can read. No third-party SDK is used: sign-in is OAuth 2.0 + PKCE via
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

In **Settings → Cadangan (Google Drive)**:

- **Masuk dengan Google** — sign in and grant appData access.
- **Backup sekarang** — upload/overwrite the backup file (`ichigo-backup.json`).
- **Pulihkan dari Drive** — download and overwrite local progress (confirmation
  required). Restart the app afterwards so the in-memory stores reload.
- **Keluar dari Google** — remove the stored tokens from the Keychain.

## Security notes

- The iOS OAuth client ID is not a secret; it is protected by PKCE and the
  appData scope.
- Tokens are stored in the Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- The app can only see files it created in `appDataFolder`, never your other
  Drive files.
