// Flashcard learning, matching the iOS-native design: mode picker → level picker
// → session (progress + 3 counters, flip card, four grade buttons, Berikutnya,
// finished summary). Scheduling uses the ported FSRS engine; answers are tallied
// for the Profile. Renderers fill #content; app.js draws the top bar.

import { loadJSON } from "./data.js";
import { LEVELS, MODES, alpha } from "./levels.js";
import { STATE, GRADE, newProgress, reviewCard, isDue } from "./fsrs.js";
import * as store from "./store.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const route = (...p) => "#/" + p.filter(Boolean).join("/");

function toCard(type, level, it) {
    if (type === "vocab") return { id: it.id, level, front: it.kanji, reading: it.hiragana, meaning: it.arti, tag: it.jenisKata || "JLPT " + level };
    if (type === "kanji") return { id: it.id, level, front: it.kanji, reading: it.onyomi || it.kunyomi || "", meaning: it.meaning, tag: "JLPT " + level };
    return { id: it.id, level, front: it.pattern, reading: it.romaji, meaning: it.meaning, tag: "JLPT " + level };
}

export function renderFlashcard(app, modeType, levelId) {
    if (modeType && levelId) return startSession(app, modeType, levelId);
    if (modeType) return renderLevelPicker(app, modeType);
    return renderModeSelect(app);
}

// ---------- Mode select ----------

function renderModeSelect(app) {
    app.innerHTML = `
        <div class="mode-grid">${MODES.map((m) => `
            <a class="mode-card" href="#/flashcard/${m.type}">
                <span class="mode-ic" style="background:${alpha(m.color, 0.15)};color:${m.color}">${esc(m.glyph)}</span>
                <span><span class="mode-title">${esc(m.title)}</span><span class="mode-sub">${esc(m.sub)}</span></span>
            </a>`).join("")}</div>
        <div class="info-card"><span class="i">ⓘ</span>
            <div><div class="it">Cara kerja review</div>
                <div class="ib">Kartu dijadwalkan ulang dengan FSRS. Tap kartu untuk melihat jawaban, lalu nilai seberapa mudah kamu mengingatnya.</div></div>
        </div>`;
}

// ---------- Level picker ----------

async function renderLevelPicker(app, type) {
    const levels = LEVELS[type] || [];
    app.innerHTML = `<div class="level-list" id="lvlBox"><div class="loading">Memuat…</div></div>`;
    const stats = {};
    await Promise.all(levels.filter((l) => !l.locked).map(async (l) => {
        try {
            const data = await loadJSON(l.file);
            let due = 0;
            for (const it of data) { const p = store.getProgress(it.id); if (p && p.state !== STATE.new && isDue(p)) due++; }
            stats[l.id] = { total: data.length, due };
        } catch { stats[l.id] = { total: l.count || 0, due: 0 }; }
    }));

    document.getElementById("lvlBox").innerHTML = levels.map((l) => {
        const tint = l.locked ? "rgba(142,142,147,0.1)" : alpha(l.color, 0.14);
        const fg = l.locked ? "var(--gray)" : l.color;
        if (l.locked) {
            return `<div class="level-card" style="opacity:.55">
                <span class="level-chip" style="background:${tint};color:${fg}">${l.id}</span>
                <span class="level-main"><span class="level-row1"><span class="level-name" style="color:var(--gray)">${esc(l.name)}</span><span class="level-trailing">🔒 Terkunci</span></span><span class="level-desc">Segera hadir</span></span>
            </div>`;
        }
        const s = stats[l.id] || { total: l.count || 0, due: 0 };
        return `<a class="level-card" href="#/flashcard/${type}/${l.id}">
            <span class="level-chip" style="background:${tint};color:${fg}">${l.id}</span>
            <span class="level-main">
                <span class="level-row1"><span class="level-name">${esc(l.name)}</span><span class="level-trailing">${s.due > 0 ? s.due + " due" : "›"}</span></span>
                <span class="level-desc">${esc(l.desc)}</span>
                <span class="level-meta" style="color:${fg}">${s.total.toLocaleString("id-ID")} kartu • bebas pilih deck</span>
            </span>
        </a>`;
    }).join("");
}

// ---------- Session ----------

async function startSession(app, type, levelId) {
    const level = (LEVELS[type] || []).find((l) => l.id === levelId);
    if (!level || level.locked) return renderLevelPicker(app, type);
    app.innerHTML = `<div class="loading">Menyiapkan sesi…</div>`;
    let raw;
    try { raw = await loadJSON(level.file); }
    catch (e) { app.innerHTML = `<div class="empty">${esc(e.message)}</div>`; return; }

    const deckKey = `${type}_${levelId}`;
    const deckById = new Map();
    const now = Date.now();
    const dueCards = [], newCandidates = [];
    for (const it of raw) {
        const card = toCard(type, levelId, it);
        deckById.set(card.id, card);
        const p = store.getProgress(card.id) || newProgress(card);
        if (p.state === STATE.new) newCandidates.push(p);
        else if (isDue(p, now)) dueCards.push(p);
    }
    const remaining = Math.max(0, store.getDailyTarget() - store.newTodayCount(deckKey));
    const newCards = newCandidates.slice(0, remaining);
    shuffle(dueCards);
    const queue = [...dueCards, ...newCards];
    const session = { app, type, levelId, level, deckKey, deckById, queue,
        countedNew: new Set(), reviewed: 0, correct: 0, wrong: 0, sessionTotal: queue.length,
        revealed: false, graded: false, updated: null };

    if (queue.length === 0) {
        app.innerHTML = `<div class="empty">${remaining === 0 ? "Kuota kartu baru hari ini sudah tercapai, dan tidak ada review yang jatuh tempo. 🎉" : "Tidak ada kartu yang perlu dipelajari sekarang. 🎉"}</div>
            <a class="big-btn" style="background:var(--green)" href="${route("flashcard", type)}">Pilih dek lain</a>`;
        return;
    }
    renderSession(session);
}

function counts(session) {
    let nu = 0, learn = 0, review = 0;
    for (const p of session.queue) {
        if (p.state === STATE.new) nu++;
        else if (p.state === STATE.learning || p.state === STATE.relearning) learn++;
        else review++;
    }
    return [{ n: nu, c: "#2E7BFF" }, { n: learn, c: "#FF3B30" }, { n: review, c: "#34C759" }];
}

function renderSession(session) {
    if (session.queue.length === 0) return renderDone(session);
    const p = session.queue[0];
    const card = session.deckById.get(p.id);
    const pos = Math.min(session.reviewed + 1, session.sessionTotal);
    const prog = session.sessionTotal ? Math.min(session.reviewed / session.sessionTotal, 1) * 100 : 0;
    const grades = [["again", "Ulang", "#FF3B30"], ["hard", "Susah", "#FF9500"], ["good", "Bagus", "#2E7BFF"], ["easy", "Mudah", "#34C759"]];

    session.app.innerHTML = `
        <div class="fc-top"><span class="lv">${esc(session.level.id)}</span><span class="pos">${pos}/${session.sessionTotal}</span></div>
        <div class="fc-bar"><span style="width:${prog}%"></span></div>
        <div class="fc-counters">${counts(session).map((c) => `<span class="fc-counter"><span class="d" style="background:${c.c}"></span><span class="n" style="color:${c.c}">${c.n}</span></span>`).join("")}</div>
        <button class="fc-card" id="fcCard" type="button">
            <span class="fc-front">${esc(card.front)}</span>
            ${session.revealed ? `<span class="fc-reveal">
                ${card.reading ? `<span class="fc-reading">${esc(card.reading)}</span>` : ""}
                <span class="fc-meaning">${esc(card.meaning)}</span>
                ${card.tag ? `<span class="fc-tag">${esc(card.tag)}</span>` : ""}
            </span>` : `<span class="fc-hint">Tap kartu untuk melihat jawaban</span>`}
        </button>
        ${session.revealed && !session.graded
            ? `<div class="fc-grades">${grades.map(([k, l, c]) => `<button class="grade" data-grade="${k}" style="background:${c}">${l}</button>`).join("")}</div>`
            : ""}
        ${session.graded ? `<button class="fc-next" id="fcNext" type="button">Berikutnya</button>` : ""}`;

    document.getElementById("fcCard").addEventListener("click", () => {
        if (!session.revealed) { session.revealed = true; renderSession(session); }
    });
    document.querySelectorAll("[data-grade]").forEach((b) =>
        b.addEventListener("click", () => grade(session, p, b.dataset.grade)));
    const nx = document.getElementById("fcNext");
    if (nx) nx.addEventListener("click", () => advance(session));

    session._key = (e) => {
        if (e.code === "Space") { e.preventDefault(); if (!session.revealed) { session.revealed = true; renderSession(session); } else if (session.graded) advance(session); }
        else if (session.revealed && !session.graded && ["Digit1", "Digit2", "Digit3", "Digit4"].includes(e.code)) {
            grade(session, p, ["again", "hard", "good", "easy"][Number(e.code.slice(-1)) - 1]);
        }
    };
    document.removeEventListener("keydown", session._prevKey || (() => {}));
    document.addEventListener("keydown", session._key);
    session._prevKey = session._key;
}

const GVAL = { again: GRADE.again, hard: GRADE.hard, good: GRADE.good, easy: GRADE.easy };
function grade(session, p, kind) {
    if (session.graded) return;
    const gradeValue = GVAL[kind];
    const wasNew = p.state === STATE.new;
    const updated = reviewCard(p, gradeValue);
    store.saveProgress(updated);
    store.recordAnswer(gradeValue);
    if (gradeValue === GRADE.again) session.wrong += 1; else session.correct += 1;
    if (wasNew && !session.countedNew.has(updated.id)) { session.countedNew.add(updated.id); store.incrementNewToday(session.deckKey, 1); }
    session.updated = updated;
    session.graded = true;
    renderSession(session);
}

function advance(session) {
    const updated = session.updated;
    session.queue.shift();
    if (updated && (updated.state === STATE.learning || updated.state === STATE.relearning)) session.queue.push(updated);
    session.reviewed += 1;
    session.revealed = false; session.graded = false; session.updated = null;
    renderSession(session);
}

function renderDone(session) {
    document.removeEventListener("keydown", session._key || (() => {}));
    store.recordStudyToday();
    window.dispatchEvent(new CustomEvent("ichigo-session-done"));
    session.app.innerHTML = `
        <div class="fc-done">
            <div class="t">Sesi Selesai</div>
            <div class="s">Benar: ${session.correct} — Ulang: ${session.wrong}</div>
            <a class="fc-next" style="min-width:220px;text-align:center;display:flex;align-items:center;justify-content:center;margin-top:8px" href="${route("flashcard")}">Kembali</a>
        </div>`;
}

function shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
    return a;
}
