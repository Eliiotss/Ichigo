// Profile tab, matching the iOS-native design: gradient avatar + name + "JLPT
// Learner", a daily-target card, a 2×2 stats grid, and the answer summary. All
// numbers come from the same store helpers the Home progress card uses.

import * as store from "./store.js";
import { alpha } from "./levels.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

function initials(name) {
    const w = String(name || "").trim().split(/\s+/).filter(Boolean);
    if (!w.length) return "US";
    return (w.length > 1 ? w[0][0] + w[1][0] : w[0].slice(0, 2)).toUpperCase();
}

export function renderProfile(app) {
    const name = store.getUsername() || "User";
    const target = store.getDailyTarget();
    const studied = store.studiedTodayTotal();
    const pct = target > 0 ? Math.min(studied / target, 1) * 100 : 0;
    const due = store.dueTodayTotal(target);
    const streak = store.getStreak().count;
    const mastered = store.masteredTotal();
    const sum = store.getAnswerSummary();

    const stats = [
        { title: "DUE", value: due, sub: "hari ini", color: "#2E7BFF", icon: "◷" },
        { title: "BELAJAR", value: studied, sub: "kartu", color: "#34C759", icon: "✓" },
        { title: "STREAK", value: streak, sub: "hari", color: "#FF9500", icon: "✦" },
        { title: "MASTERED", value: mastered, sub: "kartu", color: "#AF52DE", icon: "★" },
    ];
    const acc = [
        { label: "Ulang", count: sum.again, color: "#FF3B30" },
        { label: "Susah", count: sum.hard, color: "#FF9500" },
        { label: "Bagus", count: sum.good, color: "#2E7BFF" },
        { label: "Mudah", count: sum.easy, color: "#34C759" },
    ];

    app.innerHTML = `
        <div class="prof-head">
            <div class="prof-avatar">${esc(initials(name))}</div>
            <div style="display:flex;flex-direction:column;align-items:center;gap:6px">
                <div class="prof-name">${esc(name)}</div>
                <div class="prof-tag">JLPT Learner</div>
            </div>
        </div>

        <div class="prof-target">
            <div class="r"><span>Target Harian</span><span>${studied}/${target}</span></div>
            <div class="bar"><span style="width:${Math.max(pct, pct > 0 ? 4 : 0)}%"></span></div>
        </div>

        <div class="stat-grid">${stats.map((s) => `
            <div class="stat-tile" style="background:${alpha(s.color, 0.1)}">
                <div class="top"><span class="ic" style="color:${s.color}">${s.icon}</span><span class="ttl">${s.title}</span></div>
                <div class="num"><b>${s.value}</b><span>${esc(s.sub)}</span></div>
            </div>`).join("")}</div>

        <div class="acc-card">
            <div class="h">Ringkasan Jawaban</div>
            <div class="acc-grid">${acc.map((a) => `
                <div class="acc-cell" style="background:${alpha(a.color, 0.1)}"><div class="n" style="color:${a.color}">${a.count}</div><div class="l">${a.label}</div></div>`).join("")}</div>
            <div class="acc-foot"><span class="l">Akurasi keseluruhan</span><span class="v">${Math.round(sum.accuracy * 100)}%</span></div>
        </div>`;
}
