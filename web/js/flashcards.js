// Flashcard learning, styled to match the iOS app: mode picker → level picker →
// review session (stats card, flip card, four grade buttons, finished summary).
// Scheduling uses the ported FSRS engine; progress persists in localStorage and
// each graded answer is tallied for the Profile summary.

import { loadJSON } from "./data.js";
import { LEVELS, MODES } from "./levels.js";
import { icon, GLYPH } from "./icons.js";
import { STATE, GRADE, newProgress, reviewCard, isDue, intervalPreview } from "./fsrs.js";
import * as store from "./store.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const route = (...parts) => "#/" + parts.filter(Boolean).join("/");

function screenHeader(title, backHref) {
    return `<div class="screen-header">
        <a class="back-btn" href="${backHref}" aria-label="Kembali">${icon("back")}</a>
        <h1 class="screen-title">${esc(title)}</h1>
    </div>`;
}

function modeTitle(type) { return (MODES.find((m) => m.type === type) || {}).title || "Flashcard"; }

function toCard(type, level, it) {
    if (type === "vocab") return { id: it.id, level, front: it.kanji, reading: it.hiragana, meaning: it.arti, sub: it.jenisKata || "" };
    if (type === "kanji") return { id: it.id, level, front: it.kanji, reading: it.onyomi || it.kunyomi || "", meaning: it.meaning, sub: "" };
    return { id: it.id, level, front: it.pattern, reading: it.romaji, meaning: it.meaning, sub: "" }; // grammar
}

// ---------- Entry ----------

export function renderFlashcard(app, modeType, levelId) {
    if (modeType && levelId) return startSession(app, modeType, levelId);
    if (modeType) return renderLevelPicker(app, modeType);
    return renderModeSelect(app);
}

// ---------- Mode select ----------

function renderModeSelect(app) {
    app.innerHTML =
        screenHeader("Flashcard", route("home")) +
        `<div class="mode-grid">
            ${MODES.map((m) => `
                <a class="mode-card" href="#/flashcard/${m.type}">
                    <span class="mode-icon" style="background:var(--grad-${m.grad})">${GLYPH[m.grad] || icon(m.icon)}</span>
                    <span class="mode-title">${esc(m.title)}</span>
                    <span class="mode-sub">${esc(m.sub)}</span>
                </a>`).join("")}
        </div>
        <div class="info-card">
            <span class="info-ic">${icon("info")}</span>
            <div>
                <div class="info-t">Cara kerja review</div>
                <div class="info-b">Kartu dijadwalkan ulang dengan FSRS. Tap kartu untuk melihat jawaban,
                    lalu nilai seberapa mudah kamu mengingatnya.</div>
            </div>
        </div>`;
}

// ---------- Level picker ----------

async function renderLevelPicker(app, type) {
    const levels = LEVELS[type] || [];
    app.innerHTML =
        screenHeader(`Flashcard ${modeTitle(type)}`, route("flashcard")) +
        `<div class="level-list" id="lvlBox"><div class="loading">Memuat…</div></div>`;

    // Preload unlocked datasets so each level card can show its due count.
    const stats = {};
    await Promise.all(levels.filter((l) => !l.locked).map(async (l) => {
        try {
            const data = await loadJSON(l.file);
            let due = 0;
            for (const it of data) {
                const p = store.getProgress(it.id);
                if (p && p.state !== STATE.new && isDue(p)) due++;
            }
            stats[l.id] = { total: data.length, due };
        } catch { stats[l.id] = { total: l.count || 0, due: 0 }; }
    }));

    document.getElementById("lvlBox").innerHTML = levels.map((l) => {
        if (l.locked) {
            return `<div class="level-card locked">
                <span class="level-chip" style="background:var(--soft-surface);color:var(--muted)">${l.id}</span>
                <span class="level-main">
                    <span class="level-row1">
                        <span class="level-name" style="color:var(--muted)">${esc(l.name)}</span>
                        <span class="lock-badge">🔒 Terkunci</span>
                    </span>
                    <span class="level-desc">${esc(l.desc)}</span>
                </span>
            </div>`;
        }
        const s = stats[l.id] || { total: l.count || 0, due: 0 };
        return `<a class="level-card" href="#/flashcard/${type}/${l.id}">
            <span class="level-chip" style="background:color-mix(in srgb, ${l.color} 15%, transparent);color:${l.color}">${l.id}</span>
            <span class="level-main">
                <span class="level-row1">
                    <span class="level-name">${esc(l.name)}</span>
                    ${s.due > 0 ? `<span class="due-badge" style="background:${l.color}">${s.due} due</span>` : ""}
                </span>
                <span class="level-desc">${esc(l.desc)}</span>
                <span class="level-count" style="color:${l.color}">${s.total.toLocaleString("id-ID")} kartu • bebas pilih deck</span>
            </span>
            <span class="chev">${icon("chev")}</span>
        </a>`;
    }).join("");
}

// ---------- Session ----------

async function startSession(app, type, levelId) {
    const level = (LEVELS[type] || []).find((l) => l.id === levelId);
    if (!level || level.locked) return renderLevelPicker(app, type);
    app.innerHTML = screenHeader(`Flashcard ${modeTitle(type)}`, route("flashcard", type)) +
        `<div class="loading">Menyiapkan sesi…</div>`;
    let raw;
    try {
        raw = await loadJSON(level.file);
    } catch (e) {
        app.querySelector(".loading").outerHTML = `<div class="empty-state">${esc(e.message)}</div>`;
        return;
    }

    const deckKey = `${type}_${levelId}`;
    const deckById = new Map();
    const now = Date.now();
    const dueCards = [];
    const newCandidates = [];
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

    const session = {
        app, type, levelId, level, deckKey, deckById, queue,
        countedNew: new Set(), reviewed: 0, correct: 0, wrong: 0,
        sessionTotal: queue.length, revealed: false,
    };

    if (queue.length === 0) return renderEmpty(session, remaining);
    renderCard(session);
}

function renderEmpty(session, remaining) {
    const { app, type } = session;
    const msg = remaining === 0
        ? "Kuota kartu baru hari ini sudah tercapai, dan tidak ada review yang jatuh tempo. 🎉"
        : "Tidak ada kartu yang perlu dipelajari sekarang — semua terjadwal ke depan. 🎉";
    app.innerHTML = screenHeader(`Flashcard ${modeTitle(type)}`, route("flashcard")) +
        `<div class="empty-state">${esc(msg)}</div>
        <a class="btn btn-primary btn-block" href="${route("flashcard", type)}">Pilih dek lain</a>`;
}

function counts(session) {
    let nu = 0, learn = 0, review = 0;
    for (const p of session.queue) {
        if (p.state === STATE.new) nu++;
        else if (p.state === STATE.learning || p.state === STATE.relearning) learn++;
        else review++;
    }
    return { nu, learn, review };
}

function renderCard(session) {
    const { app, queue, deckById, level } = session;
    if (queue.length === 0) return renderDone(session);
    const p = queue[0];
    const card = deckById.get(p.id);
    const c = counts(session);
    const pos = Math.min(session.reviewed + 1, session.sessionTotal);
    const prog = session.sessionTotal ? Math.min(session.reviewed / session.sessionTotal, 1) : 0;
    session.revealed = false;

    app.innerHTML = screenHeader(`Flashcard ${modeTitle(session.type)}`, route("flashcard", session.type)) + `
        <div class="fc-stats">
            <div class="fc-stats-top">
                <span class="lv">JLPT ${esc(level.id)}</span>
                <span class="pos">Kartu ${pos} / ${session.sessionTotal}</span>
            </div>
            <div class="fc-track"><span style="width:${prog * 100}%"></span></div>
            <div class="fc-pills">
                ${pill(c.nu, "due", "var(--accent)")}
                ${pill(c.learn, "ulang", "var(--danger)")}
                ${pill(c.review, "hafal", "var(--success)")}
            </div>
        </div>
        <div class="fc-card" id="fcCard">
            <div class="fc-front">${esc(card.front)}</div>
            <div id="fcBack" hidden>
                ${card.reading ? `<div class="fc-rtitle">${esc(card.reading)}</div>` : ""}
                <div class="fc-rbody">${esc(card.meaning)}</div>
                ${card.sub ? `<div class="fc-tag">${esc(card.sub)}</div>` : ""}
            </div>
            <div class="fc-hint" id="fcHint">Tap kartu untuk melihat jawaban</div>
        </div>
        <div id="fcControls"></div>`;

    const reveal = () => revealCard(session, p, card);
    document.getElementById("fcCard").addEventListener("click", reveal);
    session._key = (e) => {
        if (e.code === "Space") { e.preventDefault(); if (!session.revealed) reveal(); }
        else if (session.revealed && ["Digit1", "Digit2", "Digit3", "Digit4"].includes(e.code)) {
            grade(session, p, Number(e.code.slice(-1)));
        }
    };
    document.addEventListener("keydown", session._key);
}

function pill(n, label, color) {
    return `<span class="fc-pill" style="background:color-mix(in srgb, ${color} 14%, transparent);color:${color}">
        <span class="dot" style="background:${color}"></span>
        <span class="n">${n}</span><span class="lab">${label}</span></span>`;
}

function revealCard(session, p, card) {
    if (session.revealed) return;
    session.revealed = true;
    const back = document.getElementById("fcBack");
    back.hidden = false;
    back.classList.add("revealed");
    document.getElementById("fcHint").remove();
    const iv = intervalPreview(p);
    const g = [
        ["again", "Ulang", iv.again, GRADE.again],
        ["hard", "Susah", iv.hard, GRADE.hard],
        ["good", "Bagus", iv.good, GRADE.good],
        ["easy", "Mudah", iv.easy, GRADE.easy],
    ];
    document.getElementById("fcControls").innerHTML = `
        <div class="fc-grades">
            ${g.map(([cls, label, ivl, val]) =>
                `<button class="grade ${cls}" data-grade="${val}">${label}<small>${esc(ivl)}</small></button>`
            ).join("")}
        </div>`;
    document.querySelectorAll("[data-grade]").forEach((b) =>
        b.addEventListener("click", () => grade(session, p, Number(b.dataset.grade)))
    );
}

function grade(session, p, gradeValue) {
    document.removeEventListener("keydown", session._key);
    const wasNew = p.state === STATE.new;
    const updated = reviewCard(p, gradeValue);
    store.saveProgress(updated);
    store.recordAnswer(gradeValue);
    session.reviewed += 1;
    if (gradeValue === GRADE.again) session.wrong += 1; else session.correct += 1;

    if (wasNew && !session.countedNew.has(updated.id)) {
        session.countedNew.add(updated.id);
        store.incrementNewToday(session.deckKey, 1);
    }

    session.queue.shift();
    // Cards still in learning/relearning (short, minute-scale steps) come back
    // around within this session, mirroring Anki's learning queue.
    if (updated.state === STATE.learning || updated.state === STATE.relearning) {
        session.queue.push(updated);
    }
    renderCard(session);
}

function renderDone(session) {
    const { app, type, level } = session;
    const answered = session.correct + session.wrong;
    const accuracy = answered ? Math.round((session.correct / answered) * 100) : 0;
    const streak = store.recordStudyToday();
    // Let the app push progress to Drive in the background (if auto-sync is on).
    window.dispatchEvent(new CustomEvent("ichigo-session-done"));

    const stat = (v, l, color) =>
        `<div class="summary-stat" style="background:color-mix(in srgb, ${color} 12%, transparent)">
            <span class="v" style="color:${color}">${v}</span><span class="l">${l}</span></div>`;

    app.innerHTML = screenHeader(`Flashcard ${modeTitle(type)}`, route("flashcard")) + `
        <div class="fc-done">
            <div>
                <div class="fc-done-emoji">${accuracy >= 80 ? "🎉" : "💪"}</div>
                <div class="fc-done-title">Sesi Selesai!</div>
                <div class="fc-done-sub">JLPT ${esc(level.id)} • ${esc(modeTitle(type))}</div>
            </div>
            <div class="summary-card">
                <div class="summary-acc">${accuracy}%</div>
                <div class="summary-acc-lab">Akurasi sesi ini</div>
                <div class="summary-divider"></div>
                <div class="summary-stats">
                    ${stat(session.correct, "Benar", "var(--success)")}
                    ${stat(session.wrong, "Ulang", "var(--danger)")}
                    ${stat(session.sessionTotal, "Kartu", "var(--accent)")}
                </div>
            </div>
            <div class="streak-banner">
                <span class="em">🔥</span>
                <div>
                    <div class="st-t">Streak ${streak} hari</div>
                    <div class="st-b">Belajar setiap hari agar runtutannya tidak putus.</div>
                </div>
            </div>
            <a class="btn btn-primary btn-block" href="${route("flashcard")}">Kembali</a>
        </div>`;
}

function shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
}
