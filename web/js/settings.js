// Settings page: profile name, daily target, theme, backup export/import (with
// merge), study stats, and reset.

import * as store from "./store.js";
import * as gsync from "./gsync.js";
import { setTheme, currentTheme } from "./theme.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const relFmt = new Intl.RelativeTimeFormat("id-ID", { numeric: "auto" });
function relTime(ts) {
    const diff = ts - Date.now();
    const mins = Math.round(diff / 60000);
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

export function renderSettings(app) {
    const draw = () => {
        const username = store.getUsername();
        const target = store.getDailyTarget();
        const streak = store.getStreak();
        const learned = Object.keys(store.allProgress()).length;
        const theme = currentTheme();
        const themeBtn = (val, label) =>
            `<button class="seg ${theme === val ? "active" : ""}" data-theme-set="${val}">${label}</button>`;

        app.innerHTML = `
            <h1 class="page-title">⚙️ Pengaturan</h1>

            <div class="set-group">
                <div class="set-title">Profil</div>
                <div class="set-row">
                    <label class="set-label" for="uname">Nama pengguna</label>
                    <input class="search set-input" id="uname" type="text" maxlength="40"
                           placeholder="mis. Budi" value="${esc(username)}">
                </div>
                <p class="set-note">Ditampilkan pada sapaan di Beranda.</p>
            </div>

            <div class="set-group">
                <div class="set-title">Belajar</div>
                <div class="set-row">
                    <span class="set-label">Target kartu baru / hari</span>
                    <span class="stepper">
                        <button class="btn" id="tMinus" aria-label="kurangi">−</button>
                        <b id="tVal">${target}</b>
                        <button class="btn" id="tPlus" aria-label="tambah">+</button>
                    </span>
                </div>
            </div>

            <div class="set-group">
                <div class="set-title">Tampilan</div>
                <div class="set-row">
                    <span class="set-label">Tema</span>
                    <span class="segmented">
                        ${themeBtn("auto", "Sistem")}${themeBtn("light", "Terang")}${themeBtn("dark", "Gelap")}
                    </span>
                </div>
            </div>

            <div class="set-group">
                <div class="set-title">Cadangan & sinkronisasi</div>
                <p class="set-note">Pindahkan progres antar-perangkat/peramban lewat berkas.
                    Saat <b>impor</b>, data digabung cerdas — untuk tiap kartu, review
                    terbaru yang menang, jadi progres tidak hilang (mirip Anki).</p>
                <div class="set-actions">
                    <button class="btn btn-primary" id="exportBtn">⬇️ Ekspor cadangan</button>
                    <button class="btn" id="importBtn">⬆️ Impor cadangan</button>
                    <input type="file" id="importFile" accept="application/json,.json" hidden>
                </div>
                <p class="set-msg" id="backupMsg" hidden></p>
            </div>

            <div class="set-group">
                <div class="set-title">Sinkronisasi Google Drive</div>
                <p class="set-note">Sinkron otomatis antar-perangkat lewat folder privat
                    aplikasi di Google Drive (web ↔ web). Butuh <b>Client ID Google</b> Anda
                    sendiri — panduan di <code>web/README.md</code>. Data tetap privat: hanya
                    folder aplikasi yang diakses.</p>
                <div class="set-row">
                    <label class="set-label" for="gClient">Client ID (Web)</label>
                    <input class="search set-input" id="gClient" type="text"
                           placeholder="xxxx.apps.googleusercontent.com" value="${esc(gsync.getClientId())}">
                </div>
                <div class="set-actions">
                    <button class="btn" id="gSaveId">Simpan Client ID</button>
                    ${gsync.isConfigured()
                        ? (gsync.isSignedIn()
                            ? `<button class="btn btn-primary" id="gSync">🔄 Sinkronkan sekarang</button>
                               <button class="btn" id="gOut">Keluar</button>`
                            : `<button class="btn btn-primary" id="gIn">Masuk dengan Google</button>`)
                        : ""}
                </div>
                ${gsync.isConfigured() && gsync.isSignedIn()
                    ? `<div class="set-row" style="margin-top:12px">
                           <span class="set-label">Sinkronisasi otomatis</span>
                           <span class="segmented">
                               <button class="seg ${store.getAutoSync() ? "active" : ""}" id="gAutoOn">Nyala</button>
                               <button class="seg ${!store.getAutoSync() ? "active" : ""}" id="gAutoOff">Mati</button>
                           </span>
                       </div>
                       <p class="set-note">${gsync.linkedEmail() ? "Masuk sebagai " + esc(gsync.linkedEmail()) + ". " : ""}${
                           store.getDriveLastSync() ? "Tersinkron " + esc(relTime(store.getDriveLastSync())) + "." : "Belum pernah tersinkron."
                       }</p>`
                    : ""}
                <p class="set-msg" id="gMsg" hidden></p>
            </div>

            <div class="set-group">
                <div class="set-title">Statistik</div>
                <div class="detail-grid" style="margin:6px 0 0">
                    <div class="fact"><div class="fact-label">Streak</div><div class="fact-value">${streak.count} hari</div></div>
                    <div class="fact"><div class="fact-label">Kartu dipelajari</div><div class="fact-value">${learned}</div></div>
                </div>
            </div>

            <div class="set-group danger">
                <div class="set-title">Zona bahaya</div>
                <div class="set-actions">
                    <button class="btn btn-danger" id="resetBtn">🗑️ Reset semua progres</button>
                </div>
                <p class="set-note">Menghapus progres flashcard, streak, dan pengaturan di peramban ini. Tidak bisa dibatalkan.</p>
            </div>`;

        // Username
        const uname = document.getElementById("uname");
        uname.addEventListener("change", () => store.setUsername(uname.value.trim()));

        // Daily target
        const setT = (delta) => {
            const next = Math.max(1, Math.min(200, store.getDailyTarget() + delta));
            store.setDailyTarget(next);
            document.getElementById("tVal").textContent = next;
        };
        document.getElementById("tMinus").addEventListener("click", () => setT(-5));
        document.getElementById("tPlus").addEventListener("click", () => setT(+5));

        // Theme
        app.querySelectorAll("[data-theme-set]").forEach((b) =>
            b.addEventListener("click", () => { setTheme(b.dataset.themeSet); draw(); })
        );

        // Backup
        const msg = (text, isError = false) => {
            const el = document.getElementById("backupMsg");
            el.hidden = false;
            el.textContent = text;
            el.classList.toggle("error", isError);
        };
        document.getElementById("exportBtn").addEventListener("click", () => {
            download(`ichigo-backup-${dateStamp()}.json`, JSON.stringify(store.exportState(), null, 2));
            msg("Cadangan diunduh.");
        });
        const fileInput = document.getElementById("importFile");
        document.getElementById("importBtn").addEventListener("click", () => fileInput.click());
        fileInput.addEventListener("change", async () => {
            const file = fileInput.files && fileInput.files[0];
            if (!file) return;
            try {
                const data = JSON.parse(await file.text());
                const res = store.importState(data);
                msg(`Impor berhasil — ${res.progress} kartu tersimpan (digabung).`);
                draw();
            } catch (e) {
                msg("Gagal impor: " + e.message, true);
            } finally {
                fileInput.value = "";
            }
        });

        // Reset
        document.getElementById("resetBtn").addEventListener("click", () => {
            if (confirm("Reset semua progres flashcard, streak, dan pengaturan di peramban ini?")) {
                store.resetAll();
                draw();
            }
        });

        // Google Drive sync
        const gmsg = (text, isError = false) => {
            const el = document.getElementById("gMsg");
            el.hidden = false;
            el.textContent = text;
            el.classList.toggle("error", isError);
        };
        const on = (id, fn) => { const el = document.getElementById(id); if (el) el.addEventListener("click", fn); };
        on("gSaveId", () => {
            gsync.setClientId(document.getElementById("gClient").value);
            draw();
            gmsg(gsync.isConfigured() ? "Client ID disimpan." : "Client ID dikosongkan.");
        });
        on("gIn", async () => {
            gmsg("Membuka Google…");
            try { await gsync.signIn(); draw(); gmsg("Berhasil masuk."); }
            catch (e) { gmsg("Gagal masuk: " + e.message, true); }
        });
        on("gSync", async () => {
            gmsg("Menyinkronkan…");
            try { await gsync.syncNow({ interactive: true }); draw(); gmsg("Sinkronisasi selesai."); }
            catch (e) { gmsg("Gagal sinkron: " + e.message, true); }
        });
        on("gOut", () => { gsync.signOut(); draw(); });
        on("gAutoOn", () => { store.setAutoSync(true); draw(); });
        on("gAutoOff", () => { store.setAutoSync(false); draw(); });
    };

    draw();
}
