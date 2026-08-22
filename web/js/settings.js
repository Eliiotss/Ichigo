// Settings page, matching the iOS-native design: grouped rounded lists (AKUN:
// name + email; PREFERENSI: study reminder + language + daily target; DATA
// BELAJAR: reset; CADANGAN: Google Drive two-way sync + file backup). All
// behaviour preserved — presentation only.

import * as store from "./store.js";
import * as gsync from "./gsync.js";
import { GOOGLE_G } from "./icons.js";
import { checkReminder } from "./reminder.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

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

export function renderSettings(app) {
    const draw = () => {
        const username = store.getUsername();
        const email = store.getEmail();
        const target = store.getDailyTarget();
        const notif = store.getNotifEnabled();
        const configured = gsync.isConfigured();
        const signedIn = configured && gsync.isSignedIn();

        const driveFoot = !configured
            ? "Tambahkan Client ID Google (tipe Web) Anda untuk sinkron otomatis antar-perangkat lewat folder khusus aplikasi di Google Drive. Panduan di web/README.md."
            : signedIn
                ? `${gsync.linkedEmail() ? "Masuk sebagai " + esc(gsync.linkedEmail()) + ". " : ""}${store.getDriveLastSync() ? "Tersinkron " + esc(relTime(store.getDriveLastSync())) + "." : "Belum pernah tersinkron."} Progres tersinkron dua arah, otomatis saat aplikasi dibuka.`
                : "Masuk dengan Google agar progres flashcard tersinkron antar-perangkat.";

        app.innerHTML = `
            <section class="set-group">
                <div class="set-sec">AKUN</div>
                <div class="set-list">
                    <label class="set-row"><span class="lbl">Nama Pengguna</span><input id="uname" type="text" maxlength="40" placeholder="User123" value="${esc(username)}"></label>
                    <label class="set-row"><span class="lbl">Email</span><input id="email" type="email" maxlength="120" placeholder="email@contoh.com" value="${esc(email)}"></label>
                </div>
                <div class="set-foot">Nama akan tampil di halaman utama. Email opsional untuk identitas profil. Cadangan progres tersedia lewat Google Drive di bawah.</div>
            </section>

            <section class="set-group">
                <div class="set-sec">PREFERENSI</div>
                <div class="set-list">
                    <div class="set-row"><span class="lbl">Pengingat Belajar</span>
                        <button class="ios-toggle ${notif ? "on" : ""}" id="notifToggle" type="button" aria-label="Pengingat Belajar"><span class="knob"></span></button></div>
                    <div class="set-row"><span class="lbl">Bahasa</span><span class="val">Bahasa Indonesia</span></div>
                    <div class="set-row"><span class="lbl">Target Harian</span>
                        <span style="display:flex;align-items:center;gap:10px"><span class="val">${target} kartu</span>
                            <span class="stepper"><button id="tDown" type="button">−</button><button id="tUp" type="button">+</button></span></span></div>
                </div>
                <div class="set-foot">Pengingat akan mengirim notifikasi peramban kalau target belajar hari ini belum selesai.</div>
            </section>

            <section class="set-group">
                <div class="set-sec">DATA BELAJAR</div>
                <div class="set-list">
                    <button class="set-row danger" id="resetBtn" type="button"><span class="lbl">Reset Semua Progress Flashcard</span></button>
                </div>
                <div class="set-foot">Reset hanya menghapus progress lokal flashcard, review log, streak, jawaban, dan pengaturan FSRS.</div>
            </section>

            <section class="set-group">
                <div class="set-sec">CADANGAN (GOOGLE DRIVE)</div>
                <div class="set-list">
                    <label class="set-row"><span class="lbl">Client ID</span><input id="gClient" type="text" placeholder="xxxx.apps.googleusercontent.com" value="${esc(gsync.getClientId())}"></label>
                    ${signedIn ? `
                    <div class="set-row"><span class="lbl">Akun</span><span class="val">${esc(gsync.linkedEmail() || "Tersambung")}</span></div>
                    <div class="set-row"><span class="lbl">Sinkronisasi otomatis</span>
                        <button class="ios-toggle ${store.getAutoSync() ? "on" : ""}" id="gAuto" type="button" aria-label="Sinkronisasi otomatis"><span class="knob"></span></button></div>` : ""}
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
                <div class="set-foot">${driveFoot} Alternatif tanpa Google: Ekspor/Impor berkas — saat impor data digabung (review terbaru menang).</div>
            </section>`;

        const on = (id, ev, fn) => { const el = document.getElementById(id); if (el) el.addEventListener(ev, fn); };
        const msg = (text, isError = false) => { const el = document.getElementById("setMsg"); el.hidden = false; el.textContent = text; el.classList.toggle("error", isError); };

        const uname = document.getElementById("uname");
        uname.addEventListener("change", () => store.setUsername(uname.value.trim()));
        const emailEl = document.getElementById("email");
        emailEl.addEventListener("change", () => store.setEmail(emailEl.value.trim()));

        on("tDown", "click", () => { store.setDailyTarget(store.getDailyTarget() - 5); draw(); });
        on("tUp", "click", () => { store.setDailyTarget(store.getDailyTarget() + 5); draw(); });

        on("notifToggle", "click", async () => {
            if (!store.getNotifEnabled()) {
                let perm = ("Notification" in window) ? Notification.permission : "denied";
                if (perm === "default") { try { perm = await Notification.requestPermission(); } catch { perm = "denied"; } }
                if (perm !== "granted") { store.setNotifEnabled(false); draw(); msg("Izin notifikasi ditolak peramban. Aktifkan izin lalu coba lagi.", true); return; }
                store.setNotifEnabled(true); draw(); checkReminder();
            } else { store.setNotifEnabled(false); draw(); }
        });

        on("resetBtn", "click", () => {
            if (confirm("Reset semua progres flashcard, streak, jawaban, dan pengaturan di peramban ini?")) { store.resetAll(); draw(); }
        });

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

        on("gSaveId", "click", () => { gsync.setClientId(document.getElementById("gClient").value); draw(); msg(gsync.isConfigured() ? "Client ID disimpan." : "Client ID dikosongkan."); });
        on("gIn", "click", async () => { msg("Membuka Google…"); try { await gsync.signIn(); draw(); msg("Berhasil masuk."); } catch (e) { msg("Gagal masuk: " + e.message, true); } });
        on("gSync", "click", async () => { msg("Menyinkronkan…"); try { await gsync.syncNow({ interactive: true }); draw(); msg("Sinkronisasi selesai."); } catch (e) { msg("Gagal sinkron: " + e.message, true); } });
        on("gOut", "click", () => { gsync.signOut(); draw(); });
        on("gAuto", "click", () => { store.setAutoSync(!store.getAutoSync()); draw(); });
    };

    draw();
}
