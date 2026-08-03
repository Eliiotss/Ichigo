// Settings page, matching the Claude Design mockup: grouped rounded cards with a
// gradient icon chip per row (AKUN: name + email; PREFERENSI: study reminder +
// hour + language + daily target; DATA BELAJAR: reset; CADANGAN GOOGLE DRIVE:
// two-way sync + file backup). All behaviour is preserved — presentation only.

import * as store from "./store.js";
import * as gsync from "./gsync.js";
import { icon, GOOGLE_G } from "./icons.js";
import { checkReminder } from "./reminder.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const G = {
    blue: "var(--grad-huruf)",
    sky: "var(--grad-flashcard)",
    indigo: "var(--grad-kanji)",
    teal: "var(--grad-vocabulary)",
    violet: "var(--grad-grammar)",
    danger: "linear-gradient(135deg,#ff5a4e,#ff3b30)",
    gray: "linear-gradient(135deg,#b7ada6,#9a8e85)",
    isoft: "linear-gradient(135deg,#7c93ff,#4a55e8)",
};

const relFmt = new Intl.RelativeTimeFormat("id-ID", { numeric: "auto" });
function relTime(ts) {
    const mins = Math.round((ts - Date.now()) / 60000);
    if (Math.abs(mins) < 60) return relFmt.format(mins, "minute");
    const hrs = Math.round(mins / 60);
    if (Math.abs(hrs) < 24) return relFmt.format(hrs, "hour");
    return relFmt.format(Math.round(hrs / 24), "day");
}
function download(filename, text) {
    const blob = new Blob([text], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = filename;
    document.body.appendChild(a); a.click(); a.remove();
    URL.revokeObjectURL(url);
}
function dateStamp() {
    const d = new Date();
    return `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, "0")}${String(d.getDate()).padStart(2, "0")}`;
}
const chip = (grad, name) => `<span class="set-ic" style="background:${grad}">${icon(name)}</span>`;
const stepper = (minusId, plusId) =>
    `<span class="stepper"><button id="${minusId}" type="button" aria-label="kurangi">${icon("minus")}</button><button id="${plusId}" type="button" aria-label="tambah">${icon("plus")}</button></span>`;

export function renderSettings(app) {
    const draw = () => {
        const username = store.getUsername();
        const email = store.getEmail();
        const target = store.getDailyTarget();
        const notif = store.getNotifEnabled();
        const hour = store.getNotifHour();
        const configured = gsync.isConfigured();
        const signedIn = configured && gsync.isSignedIn();

        const driveFoot = !configured
            ? "Tambahkan Client ID Google (tipe Web) Anda untuk sinkron otomatis antar-perangkat lewat folder khusus aplikasi (appDataFolder) di Google Drive. Panduan di web/README.md."
            : signedIn
                ? `${gsync.linkedEmail() ? "Masuk sebagai " + esc(gsync.linkedEmail()) + ". " : ""}${store.getDriveLastSync() ? "Tersinkron " + esc(relTime(store.getDriveLastSync())) + "." : "Belum pernah tersinkron."} Progres tersinkron dua arah (mirip Anki), otomatis saat aplikasi dibuka.`
                : "Masuk dengan Google agar progres flashcard tersinkron antar-perangkat seperti Anki.";

        app.innerHTML = `
            <h1 class="settings-title">Pengaturan</h1>

            <div class="set-section-label">AKUN</div>
            <div class="set-card">
                <div class="set-row">
                    ${chip(G.blue, "user")}
                    <span class="set-body"><span class="set-label">Nama Pengguna</span>
                        <input id="uname" class="set-input" type="text" maxlength="40" placeholder="user123" value="${esc(username)}"></span>
                </div>
                <div class="set-row last">
                    ${chip(G.sky, "envelope")}
                    <span class="set-body"><span class="set-label">Email</span>
                        <input id="email" class="set-input" type="email" maxlength="120" placeholder="email@contoh.com" value="${esc(email)}"></span>
                </div>
            </div>
            <p class="set-foot">Nama akan tampil di halaman utama. Email bersifat opsional untuk identitas profil. Cadangan progres tersedia lewat Google Drive di bawah.</p>

            <div class="set-section-label">PREFERENSI</div>
            <div class="set-card">
                <div class="set-row ${notif ? "" : "last"}">
                    ${chip(G.indigo, "bell")}
                    <span class="set-body"><span class="set-label">Pengingat Belajar</span>
                        <label class="switch"><input type="checkbox" id="notifToggle" ${notif ? "checked" : ""}><span class="slider"></span></label></span>
                </div>
                ${notif ? `<div class="set-row">
                    <span class="set-ic gap"></span>
                    <span class="set-body"><span class="set-label" style="font-size:15px">Waktu pengingat: jam ${hour}:00</span>${stepper("hMinus", "hPlus")}</span>
                </div>` : ""}
                <div class="set-row">
                    ${chip(G.teal, "globe")}
                    <span class="set-body"><span class="set-label">Bahasa</span><span class="set-value">Bahasa Indonesia</span></span>
                </div>
                <div class="set-row last">
                    ${chip(G.violet, "target")}
                    <span class="set-body"><span class="set-label">Target Harian: ${target} kartu</span>${stepper("tMinus", "tPlus")}</span>
                </div>
            </div>
            <p class="set-foot">Pengingat akan mengirim notifikasi kalau target belajar hari ini belum selesai.</p>

            <div class="set-section-label">DATA BELAJAR</div>
            <div class="set-card">
                <button class="set-row tappable last" id="resetBtn" type="button">
                    ${chip(G.danger, "trash")}
                    <span class="set-body"><span class="set-label" style="color:var(--danger);font-weight:700">Reset Semua Progress Flashcard</span></span>
                </button>
            </div>
            <p class="set-foot">Reset hanya menghapus progress lokal flashcard, review log, streak, jawaban, dan pengaturan FSRS.</p>

            <div class="set-section-label">CADANGAN (GOOGLE DRIVE)</div>
            <div class="set-card">
                <div class="set-row ${signedIn ? "" : "last"}">
                    ${chip(configured ? G.teal : G.gray, "cloudTri")}
                    <span class="set-body" style="border-bottom:none;padding-bottom:0">
                        <input id="gClient" class="set-input" style="text-align:left" type="text" placeholder="Client ID (Web) — xxxx.apps.googleusercontent.com" value="${esc(gsync.getClientId())}"></span>
                </div>
                ${signedIn ? `
                <div class="set-row">
                    ${chip(G.blue, "user")}
                    <span class="set-body"><span class="set-label">Akun</span><span class="set-value">${esc(gsync.linkedEmail() || "Tersambung")}</span></span>
                </div>
                <div class="set-row last">
                    ${chip(G.isoft, "cloud")}
                    <span class="set-body"><span class="set-label">Sinkronisasi otomatis</span>
                        <label class="switch"><input type="checkbox" id="gAuto" ${store.getAutoSync() ? "checked" : ""}><span class="slider"></span></label></span>
                </div>` : ""}
            </div>
            <div class="set-actions">
                <button class="btn" id="gSaveId" type="button">Simpan Client ID</button>
                ${configured ? (signedIn
                    ? `<button class="btn btn-primary" id="gSync" type="button">Sinkronkan sekarang</button><button class="btn" id="gOut" type="button">Keluar</button>`
                    : `<button class="gbtn" id="gIn" type="button">${GOOGLE_G} Masuk dengan Google</button>`) : ""}
                <button class="btn" id="exportBtn" type="button">Ekspor berkas</button>
                <button class="btn" id="importBtn" type="button">Impor berkas</button>
                <input type="file" id="importFile" accept="application/json,.json" hidden>
            </div>
            <p class="set-msg" id="setMsg" hidden></p>
            <p class="set-foot">${driveFoot} Alternatif tanpa Google: Ekspor/Impor berkas — saat impor data digabung cerdas (review terbaru menang, mirip Anki).</p>`;

        // ---- Wiring ----
        const on = (id, ev, fn) => { const el = document.getElementById(id); if (el) el.addEventListener(ev, fn); };
        const msg = (text, isError = false) => {
            const el = document.getElementById("setMsg");
            el.hidden = false; el.textContent = text; el.classList.toggle("error", isError);
        };

        const uname = document.getElementById("uname");
        uname.addEventListener("change", () => store.setUsername(uname.value.trim()));
        const emailEl = document.getElementById("email");
        emailEl.addEventListener("change", () => store.setEmail(emailEl.value.trim()));

        // Daily target + reminder hour
        on("tMinus", "click", () => { store.setDailyTarget(store.getDailyTarget() - 5); draw(); });
        on("tPlus", "click", () => { store.setDailyTarget(store.getDailyTarget() + 5); draw(); });
        on("hMinus", "click", () => { store.setNotifHour(store.getNotifHour() - 1); draw(); });
        on("hPlus", "click", () => { store.setNotifHour(store.getNotifHour() + 1); draw(); });

        // Study reminder toggle (requests real notification permission)
        on("notifToggle", "change", async (e) => {
            if (e.target.checked) {
                let perm = ("Notification" in window) ? Notification.permission : "denied";
                if (perm === "default") { try { perm = await Notification.requestPermission(); } catch { perm = "denied"; } }
                if (perm !== "granted") {
                    store.setNotifEnabled(false); draw();
                    msg("Izin notifikasi ditolak peramban. Aktifkan izin notifikasi untuk situs ini lalu coba lagi.", true);
                    return;
                }
                store.setNotifEnabled(true); draw(); checkReminder();
            } else { store.setNotifEnabled(false); draw(); }
        });

        // Reset
        on("resetBtn", "click", () => {
            if (confirm("Reset semua progres flashcard, streak, jawaban, dan pengaturan di peramban ini?")) { store.resetAll(); draw(); }
        });

        // File backup
        on("exportBtn", "click", () => { download(`ichigo-backup-${dateStamp()}.json`, JSON.stringify(store.exportState(), null, 2)); msg("Cadangan berkas diunduh."); });
        const fileInput = document.getElementById("importFile");
        on("importBtn", "click", () => fileInput.click());
        fileInput.addEventListener("change", async () => {
            const file = fileInput.files && fileInput.files[0];
            if (!file) return;
            try { const res = store.importState(JSON.parse(await file.text())); msg(`Impor berhasil — ${res.progress} kartu (digabung).`); draw(); }
            catch (e) { msg("Gagal impor: " + e.message, true); }
            finally { fileInput.value = ""; }
        });

        // Google Drive
        on("gSaveId", "click", () => { gsync.setClientId(document.getElementById("gClient").value); draw(); msg(gsync.isConfigured() ? "Client ID disimpan." : "Client ID dikosongkan."); });
        on("gIn", "click", async () => { msg("Membuka Google…"); try { await gsync.signIn(); draw(); msg("Berhasil masuk."); } catch (e) { msg("Gagal masuk: " + e.message, true); } });
        on("gSync", "click", async () => { msg("Menyinkronkan…"); try { await gsync.syncNow({ interactive: true }); draw(); msg("Sinkronisasi selesai."); } catch (e) { msg("Gagal sinkron: " + e.message, true); } });
        on("gOut", "click", () => { gsync.signOut(); draw(); });
        on("gAuto", "change", (e) => store.setAutoSync(e.target.checked));
    };

    draw();
}
