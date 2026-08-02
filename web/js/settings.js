// Settings page, styled like the iOS SettingsView: uppercase section labels,
// rounded cards, rows with a gradient icon chip, a sun/moon slide toggle for the
// theme, a stepper for the daily target, the Google Drive sync rows, and reset.
// All existing behaviour (name, target, theme, file backup, Drive sync, reset)
// is preserved — only the presentation changed.

import * as store from "./store.js";
import * as gsync from "./gsync.js";
import { setTheme, effectiveIsDark } from "./theme.js";
import { icon, GOOGLE_G } from "./icons.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

// Gradient chips matching the iOS row icons.
const G = {
    blue: "var(--grad-huruf)",
    teal: "var(--grad-vocabulary)",
    violet: "var(--grad-grammar)",
    sky: "var(--grad-flashcard)",
    indigo: "linear-gradient(135deg,var(--indigo-soft),var(--indigo-deep))",
    globe: "linear-gradient(135deg,var(--blue),var(--indigo-deep))",
    danger: "linear-gradient(135deg,var(--danger-soft),var(--danger))",
    flame: "linear-gradient(135deg,#ffb23e,var(--caution))",
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
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
}

function dateStamp() {
    const d = new Date();
    return `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, "0")}${String(d.getDate()).padStart(2, "0")}`;
}

function chip(grad, name) { return `<span class="set-ic" style="background:${grad}">${icon(name)}</span>`; }

export function renderSettings(app) {
    const draw = () => {
        const username = store.getUsername();
        const target = store.getDailyTarget();
        const streak = store.getStreak().count;
        const learned = Object.keys(store.allProgress()).length;
        const isDark = effectiveIsDark();
        const configured = gsync.isConfigured();
        const signedIn = configured && gsync.isSignedIn();

        const syncFoot = !configured
            ? "Tambahkan Client ID Google (tipe Web) Anda untuk sinkron otomatis antar-perangkat lewat folder privat aplikasi di Drive. Panduan di web/README.md."
            : signedIn
                ? `${gsync.linkedEmail() ? "Masuk sebagai " + esc(gsync.linkedEmail()) + ". " : ""}${
                    store.getDriveLastSync() ? "Tersinkron " + esc(relTime(store.getDriveLastSync())) + "." : "Belum pernah tersinkron."
                } Progres tersinkron dua arah (mirip Anki), otomatis saat aplikasi dibuka.`
                : "Masuk dengan Google agar progres flashcard tersinkron antar-perangkat seperti Anki.";

        app.innerHTML = `
            <h1 class="settings-title">Pengaturan</h1>

            <div class="set-section-label">PROFIL</div>
            <div class="set-card">
                <div class="set-row">
                    ${chip(G.blue, "person")}
                    <span class="set-label">Nama Pengguna</span>
                    <span class="set-trailing"><input id="uname" class="set-input" type="text" maxlength="40" placeholder="user123" value="${esc(username)}"></span>
                </div>
            </div>
            <p class="set-foot">Nama pengguna tampil di Beranda dan halaman Profil.</p>

            <div class="set-section-label">PREFERENSI</div>
            <div class="set-card">
                <div class="set-row">
                    ${chip(G.indigo, "moon")}
                    <span class="set-label">Mode Tampilan</span>
                    <span class="set-trailing">
                        <button class="slide-toggle ${isDark ? "dark" : ""}" id="themeSlide" type="button" aria-label="Mode tampilan">
                            <span class="knob">${isDark ? "🌙" : "☀️"}</span>
                        </button>
                    </span>
                </div>
                <div class="set-row">
                    ${chip(G.violet, "target")}
                    <span class="set-label">Target Harian</span>
                    <span class="set-trailing">
                        <span class="stepper">
                            <button id="tMinus" type="button" aria-label="kurangi">−</button>
                            <b id="tVal">${target}</b>
                            <button id="tPlus" type="button" aria-label="tambah">+</button>
                        </span>
                    </span>
                </div>
                <div class="set-row">
                    ${chip(G.globe, "globe")}
                    <span class="set-label">Bahasa</span>
                    <span class="set-trailing">Bahasa Indonesia</span>
                </div>
            </div>

            <div class="set-section-label">AKUN & SINKRONISASI</div>
            <div class="set-card">
                <div class="set-row">
                    ${chip(G.teal, "cloud")}
                    <input id="gClient" class="set-input wide" type="text"
                        placeholder="Client ID (Web) — xxxx.apps.googleusercontent.com" value="${esc(gsync.getClientId())}">
                </div>
                ${signedIn ? `
                <div class="set-row">
                    ${chip(G.blue, "person")}
                    <span class="set-label">Akun</span>
                    <span class="set-trailing">${esc(gsync.linkedEmail() || "Tersambung")}</span>
                </div>
                <div class="set-row">
                    ${chip(G.indigo, "sync")}
                    <span class="set-label">Sinkronisasi otomatis</span>
                    <span class="set-trailing"><label class="switch"><input type="checkbox" id="gAuto" ${store.getAutoSync() ? "checked" : ""}><span class="slider"></span></label></span>
                </div>` : ""}
            </div>
            <div class="set-actions">
                <button class="btn" id="gSaveId" type="button">Simpan Client ID</button>
                ${configured
                    ? (signedIn
                        ? `<button class="btn btn-primary" id="gSync" type="button">Sinkronkan sekarang</button>
                           <button class="btn" id="gOut" type="button">Keluar</button>`
                        : `<button class="gbtn" id="gIn" type="button">${GOOGLE_G} Masuk dengan Google</button>`)
                    : ""}
            </div>
            <p class="set-msg" id="gMsg" hidden></p>
            <p class="set-foot">${syncFoot}</p>

            <div class="set-section-label">CADANGAN BERKAS</div>
            <div class="set-actions" style="margin-top:0">
                <button class="btn btn-primary" id="exportBtn" type="button">Ekspor cadangan</button>
                <button class="btn" id="importBtn" type="button">Impor cadangan</button>
                <input type="file" id="importFile" accept="application/json,.json" hidden>
            </div>
            <p class="set-msg" id="backupMsg" hidden></p>
            <p class="set-foot">Pindahkan progres antar-perangkat lewat berkas. Saat impor, data digabung
                cerdas — untuk tiap kartu review terbaru yang menang, jadi progres tidak hilang (mirip Anki).</p>

            <div class="set-section-label">STATISTIK</div>
            <div class="set-card">
                <div class="set-row">${chip(G.flame, "flame")}<span class="set-label">Streak</span><span class="set-trailing">${streak} hari</span></div>
                <div class="set-row">${chip(G.sky, "cards")}<span class="set-label">Kartu dipelajari</span><span class="set-trailing">${learned}</span></div>
            </div>

            <div class="set-section-label">DATA BELAJAR</div>
            <div class="set-card">
                <button class="set-row tappable" id="resetBtn" type="button">
                    ${chip(G.danger, "trash")}
                    <span class="set-label" style="color:var(--danger)">Reset Semua Progress</span>
                </button>
            </div>
            <p class="set-foot">Menghapus progres flashcard, streak, jawaban, dan pengaturan di peramban ini. Tidak bisa dibatalkan.</p>`;

        // ---- Wiring ----
        const on = (id, ev, fn) => { const el = document.getElementById(id); if (el) el.addEventListener(ev, fn); };

        // Username
        const uname = document.getElementById("uname");
        uname.addEventListener("change", () => store.setUsername(uname.value.trim()));

        // Theme (sun/moon slide toggle)
        on("themeSlide", "click", () => { setTheme(effectiveIsDark() ? "light" : "dark"); draw(); });

        // Daily target
        const setT = (delta) => {
            const next = Math.max(1, Math.min(200, store.getDailyTarget() + delta));
            store.setDailyTarget(next);
            document.getElementById("tVal").textContent = next;
        };
        on("tMinus", "click", () => setT(-5));
        on("tPlus", "click", () => setT(+5));

        // File backup
        const bmsg = (text, isError = false) => {
            const el = document.getElementById("backupMsg");
            el.hidden = false; el.textContent = text; el.classList.toggle("error", isError);
        };
        on("exportBtn", "click", () => {
            download(`ichigo-backup-${dateStamp()}.json`, JSON.stringify(store.exportState(), null, 2));
            bmsg("Cadangan diunduh.");
        });
        const fileInput = document.getElementById("importFile");
        on("importBtn", "click", () => fileInput.click());
        fileInput.addEventListener("change", async () => {
            const file = fileInput.files && fileInput.files[0];
            if (!file) return;
            try {
                const res = store.importState(JSON.parse(await file.text()));
                bmsg(`Impor berhasil — ${res.progress} kartu tersimpan (digabung).`);
                draw();
            } catch (e) {
                bmsg("Gagal impor: " + e.message, true);
            } finally { fileInput.value = ""; }
        });

        // Reset
        on("resetBtn", "click", () => {
            if (confirm("Reset semua progres flashcard, streak, jawaban, dan pengaturan di peramban ini?")) {
                store.resetAll(); draw();
            }
        });

        // Google Drive sync
        const gmsg = (text, isError = false) => {
            const el = document.getElementById("gMsg");
            el.hidden = false; el.textContent = text; el.classList.toggle("error", isError);
        };
        on("gSaveId", "click", () => {
            gsync.setClientId(document.getElementById("gClient").value);
            draw();
            gmsg(gsync.isConfigured() ? "Client ID disimpan." : "Client ID dikosongkan.");
        });
        on("gIn", "click", async () => {
            gmsg("Membuka Google…");
            try { await gsync.signIn(); draw(); gmsg("Berhasil masuk."); }
            catch (e) { gmsg("Gagal masuk: " + e.message, true); }
        });
        on("gSync", "click", async () => {
            gmsg("Menyinkronkan…");
            try { await gsync.syncNow({ interactive: true }); draw(); gmsg("Sinkronisasi selesai."); }
            catch (e) { gmsg("Gagal sinkron: " + e.message, true); }
        });
        on("gOut", "click", () => { gsync.signOut(); draw(); });
        on("gAuto", "change", (e) => { store.setAutoSync(e.target.checked); });
    };

    draw();
}
