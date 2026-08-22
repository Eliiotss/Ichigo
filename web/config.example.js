// OPTIONAL config for the web version's Google Drive sync.
//
// The OAuth *Web* client ID is project-specific but not a secret (it is protected
// by the origin allow-list you set in Google Cloud). You can either:
//   1. Enter it in the app under Pengaturan → Sinkronisasi Google Drive, OR
//   2. Preset it here:
//        - copy this file to `web/config.js` (git-ignored),
//        - fill in your client ID below,
//        - and add this line to `web/index.html` <head>, BEFORE js/app.js:
//              <script src="config.js"></script>
//
// See web/README.md for the Google Cloud setup steps.
window.ICHIGO_CONFIG = {
    googleClientId: "YOUR_CLIENT_ID.apps.googleusercontent.com",
};
