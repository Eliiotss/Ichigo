// Google Drive appDataFolder client for the web app. Auth via Google Identity
// Services (GIS) token flow; storage via the Drive v3 REST API over fetch. No
// third-party SDK — the GIS script is injected on demand so the app still works
// offline (the sync feature simply reports itself unavailable).
//
// Scope is limited to `drive.appdata`: the app can only see the single backup
// file it creates in its hidden per-app folder, never the user's other files.
// `email` is requested so the linked account can be shown in Settings.

const GIS_SRC = "https://accounts.google.com/gsi/client";
const SCOPE = "email https://www.googleapis.com/auth/drive.appdata";
const DRIVE = "https://www.googleapis.com/drive/v3";
const UPLOAD = "https://www.googleapis.com/upload/drive/v3";
export const BACKUP_NAME = "ichigo-web-backup.json";

let gisPromise = null;
export function loadGis() {
    if (window.google && window.google.accounts && window.google.accounts.oauth2) return Promise.resolve();
    if (gisPromise) return gisPromise;
    gisPromise = new Promise((resolve, reject) => {
        const s = document.createElement("script");
        s.src = GIS_SRC;
        s.async = true;
        s.defer = true;
        s.onload = () => resolve();
        s.onerror = () => {
            gisPromise = null;
            reject(new Error("Gagal memuat Google Identity Services (perlu koneksi internet)."));
        };
        document.head.appendChild(s);
    });
    return gisPromise;
}

let tokenClient = null;
let tokenClientId = null;

/// Requests an access token. `interactive:false` tries silently (prompt "none");
/// `true` shows the account/consent picker as needed.
export async function requestToken(clientId, { interactive = true } = {}) {
    await loadGis();
    return new Promise((resolve, reject) => {
        if (!tokenClient || tokenClientId !== clientId) {
            tokenClient = google.accounts.oauth2.initTokenClient({
                client_id: clientId,
                scope: SCOPE,
                callback: () => {},
            });
            tokenClientId = clientId;
        }
        tokenClient.callback = (resp) => {
            if (resp && resp.access_token) resolve(resp.access_token);
            else reject(new Error(resp && (resp.error_description || resp.error) || "Gagal mendapatkan token."));
        };
        tokenClient.error_callback = (err) => reject(new Error((err && err.message) || "Autentikasi dibatalkan."));
        try {
            tokenClient.requestAccessToken({ prompt: interactive ? "" : "none" });
        } catch (e) {
            reject(e);
        }
    });
}

async function driveFetch(url, token, opts = {}) {
    const res = await fetch(url, {
        ...opts,
        headers: { Authorization: `Bearer ${token}`, ...(opts.headers || {}) },
    });
    if (!res.ok) {
        const body = await res.text().catch(() => "");
        throw new Error(`Drive ${res.status}: ${body}`.slice(0, 200));
    }
    return res;
}

export async function userEmail(token) {
    try {
        const res = await fetch("https://www.googleapis.com/oauth2/v3/userinfo", {
            headers: { Authorization: `Bearer ${token}` },
        });
        if (!res.ok) return null;
        const d = await res.json();
        return d.email || null;
    } catch {
        return null;
    }
}

export async function findBackup(token) {
    const q = encodeURIComponent(`name='${BACKUP_NAME}'`);
    const url = `${DRIVE}/files?spaces=appDataFolder&q=${q}&fields=files(id,modifiedTime)`;
    const res = await driveFetch(url, token);
    const data = await res.json();
    return (data.files && data.files[0]) || null;
}

export async function download(token, id) {
    const res = await driveFetch(`${DRIVE}/files/${id}?alt=media`, token);
    return res.json();
}

/// Creates (id null) or updates the backup file via a multipart upload.
export async function upload(token, id, contentString) {
    const metadata = id ? {} : { name: BACKUP_NAME, parents: ["appDataFolder"] };
    const boundary = "ichigo" + Math.random().toString(16).slice(2);
    const body =
        `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n` +
        JSON.stringify(metadata) +
        `\r\n--${boundary}\r\nContent-Type: application/json\r\n\r\n` +
        contentString +
        `\r\n--${boundary}--`;
    const url = id
        ? `${UPLOAD}/files/${id}?uploadType=multipart`
        : `${UPLOAD}/files?uploadType=multipart`;
    const res = await driveFetch(url, token, {
        method: id ? "PATCH" : "POST",
        headers: { "Content-Type": `multipart/related; boundary=${boundary}` },
        body,
    });
    return res.json();
}
