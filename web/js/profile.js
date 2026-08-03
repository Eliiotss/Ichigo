// Profile tab, matching the Claude Design mockup: a blue gradient header (rounded
// bottom) with avatar + name + "JLPT Learner", a daily-target card, a 2×2 stats
// grid, and the overall answer summary. Numbers come from the same store helpers
// the Home hero uses, so they never disagree between screens.

import { icon } from "./icons.js";
import * as store from "./store.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

function initials(name) {
    const w = String(name || "").trim().split(/\s+/).filter(Boolean);
    if (!w.length) return "U";
    return (w.length > 1 ? w[0][0] + w[1][0] : w[0].slice(0, 2)).toUpperCase();
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

    const tile = (name_, chip, value, unit, caption) => `
        <div class="stat-tile">
            <span class="stat-ic" style="background:${chip}">${icon(name_)}</span>
            <div class="stat-val">${value} <small>${esc(unit)}</small></div>
            <div class="stat-cap">${esc(caption)}</div>
        </div>`;
    const ans = (cls, label, count) => `<div class="ans-pill ${cls}"><div class="v">${count}</div><div class="l">${esc(label)}</div></div>`;

    app.innerHTML = `
        <div class="profile-header">
            <div class="ph-title">Profile</div>
            <div class="profile-id">
                <div class="profile-avatar">${esc(initials(name))}</div>
                <div class="profile-name">${esc(name)}</div>
                <span class="profile-tag">JLPT Learner</span>
            </div>
        </div>

        <div class="card">
            <div class="tgt-row"><span class="l">Target Harian</span><span class="r">${studied}/${target}</span></div>
            <div class="tgt-bar"><span style="width:${Math.max(prog * 100, prog > 0 ? 4 : 0)}%"></span></div>
        </div>

        <div class="stat-grid">
            ${tile("clock", "#ebf3ff", due, "due", "hari ini")}
            ${tile("check", "#e7f8ed", studied, "kartu", "belajar")}
            ${tile("flame", "#fff1e4", streak, "hari", "streak")}
            ${tile("star", "#eaf0ff", mastered, "kartu", "mastered")}
        </div>

        <div class="card">
            <div class="card-title">Ringkasan Jawaban</div>
            <div class="ans-pills">
                ${ans("a", "Ulang", sum.again)}
                ${ans("h", "Susah", sum.hard)}
                ${ans("g", "Bagus", sum.good)}
                ${ans("e", "Mudah", sum.easy)}
            </div>
            <div class="ans-foot"><span class="lab">Akurasi keseluruhan</span><span class="val">${Math.round(sum.accuracy * 100)}%</span></div>
        </div>`;
}
