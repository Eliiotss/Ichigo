// Orchestrates Google Drive sync for the web app — the browser analogue of the
// iOS `DriveBackupManager`. Pull the remote snapshot, merge it into local storage
// (via `store.importState`, the same Anki-style rule), then push the merged
// result back. The access token lives only in memory.

import * as drive from "./drive.js";
import * as store from "./store.js";

const CID_KEY = "ichigo_google_client_id";

export function getClientId() {
    const stored = localStorage.getItem(CID_KEY);
    const fromConfig = window.ICHIGO_CONFIG && window.ICHIGO_CONFIG.googleClientId;
    return String(stored || fromConfig || "").trim();
}
export function setClientId(id) {
    const v = String(id || "").trim();
    if (v) localStorage.setItem(CID_KEY, v);
    else localStorage.removeItem(CID_KEY);
}
export function isConfigured() { return !!getClientId(); }

let accessToken = null;
let signedInEmail = null;
export function isSignedIn() { return !!accessToken; }
export function linkedEmail() { return signedInEmail; }

async function ensureToken({ interactive }) {
    const cid = getClientId();
    if (!cid) throw new Error("Client ID Google belum diisi.");
    if (!accessToken) {
        accessToken = await drive.requestToken(cid, { interactive });
    }
    if (!signedInEmail) signedInEmail = await drive.userEmail(accessToken);
    return accessToken;
}

export async function signIn() {
    accessToken = null;
    signedInEmail = null;
    await ensureToken({ interactive: true });
    return signedInEmail;
}

export function signOut() {
    accessToken = null;
    signedInEmail = null;
}

/// Full sync cycle: download → merge into local → upload merged (or first upload).
export async function syncNow({ interactive = true } = {}) {
    const token = await ensureToken({ interactive });
    const existing = await drive.findBackup(token);
    if (existing) {
        const remote = await drive.download(token, existing.id);
        try {
            store.importState(remote); // merges remote into local, non-destructive
        } catch {
            // Remote file is unreadable/foreign — keep local and overwrite it below.
        }
        await drive.upload(token, existing.id, JSON.stringify(store.exportState()));
    } else {
        await drive.upload(token, null, JSON.stringify(store.exportState()));
    }
    store.setDriveLastSync(Date.now());
    return store.getDriveLastSync();
}

/// Fires on app load and after a study session. Stays silent: if consent hasn't
/// been granted in this browser session (or we're offline), it just does nothing
/// and leaves the manual "Sinkronkan sekarang" button as the entry point.
export async function autoSyncIfEnabled() {
    if (!isConfigured() || !store.getAutoSync()) return;
    try {
        await syncNow({ interactive: false });
        window.dispatchEvent(new CustomEvent("ichigo-synced"));
    } catch {
        /* needs interactive consent, or offline — silent */
    }
}
