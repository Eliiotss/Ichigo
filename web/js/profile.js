// Profile tab, matching the iOS ProfileView: a blue gradient header with the
// avatar + name + "JLPT Learner" badge, a daily-target card, a 2×2 stats grid,
// and the overall answer summary. All numbers come from the same store helpers
// the Home hero uses, so they never disagree between screens.

import { icon } from "./icons.js";
import * as store from "./store.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

function initials(name) {
    const words = String(name || "").trim().split(/\s+/).filter(Boolean);
    if (!words.length) return "🍓";
    const a = words[0][0] || "";
    const b = words.length > 1 ? words[words.length - 1][0] : "";
    return (a + b).toUpperCase();
}

export function renderProfile(app) {
    const name = store.getUsername() || "Teman";
    const target = store.getDailyTarget();
    const studied = store.studiedTodayTotal();
    const prog = target > 0 ? Math.min(studied / target, 1) : 0;
    const due = store.dueTodayTotal(target);
    const streak = store.getStreak().count;
    const mastered = store.masteredTotal();
    const sum = store.getAnswerSummary();

    const statTile = (name_, color, value, unit, caption) => `
        <div class="stat-tile">
            <span class="stat-ic" style="background:color-mix(in srgb, ${color} 14%, transparent);color:${color}">${icon(name_)}</span>
            <div class="stat-val">${value} <small>${esc(unit)}</small></div>
            <div class="stat-cap">${esc(caption)}</div>
        </div>`;

    const ansPill = (label, count, color) => `
        <div class="ans-pill" style="background:color-mix(in srgb, ${color} 12%, transparent)">
            <div class="v" style="color:${color}">${count}</div><div class="l">${esc(label)}</div>
        </div>`;

    app.innerHTML = `
        <div class="profile-header">
            <div class="ph-title">Profile</div>
            <div class="profile-avatar">${esc(initials(name))}</div>
            <div class="profile-name">${esc(name)}</div>
            <span class="profile-tag">JLPT Learner</span>
        </div>

        <div class="card">
            <div class="tgt-row"><span>Target Harian</span><span class="muted">${studied}/${target}</span></div>
            <div class="tgt-bar"><span style="width:${Math.max(prog * 100, prog > 0 ? 4 : 0)}%"></span></div>
        </div>

        <div class="stat-grid">
            ${statTile("clock", "var(--blue)", due, "due", "hari ini")}
            ${statTile("check", "var(--success)", studied, "kartu", "belajar")}
            ${statTile("flame", "var(--caution)", streak, "hari", "streak")}
            ${statTile("star", "var(--indigo-deep)", mastered, "kartu", "mastered")}
        </div>

        <div class="card">
            <div class="card-title">Ringkasan Jawaban</div>
            <div class="ans-pills">
                ${ansPill("Ulang", sum.again, "var(--danger)")}
                ${ansPill("Susah", sum.hard, "var(--caution)")}
                ${ansPill("Bagus", sum.good, "var(--accent)")}
                ${ansPill("Mudah", sum.easy, "var(--success)")}
            </div>
            <div class="summary-divider"></div>
            <div class="ans-foot">
                <span class="lab">Akurasi keseluruhan</span>
                <span class="val">${Math.round(sum.accuracy * 100)}%</span>
            </div>
        </div>`;
}
