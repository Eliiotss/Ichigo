// Flashcard learning: deck picker + FSRS-6 review session. Decks are built from
// the Vocab / Kanji / Grammar datasets; scheduling uses the ported FSRS engine
// and progress persists in localStorage.

import { loadJSON } from "./data.js";
import { LEVELS } from "./levels.js";
import { SETTINGS, STATE, GRADE, newProgress, reviewCard, isDue, intervalPreview } from "./fsrs.js";
import * as store from "./store.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const DECKS = [
    { type: "vocab", label: "Kosakata", emoji: "📖" },
    { type: "kanji", label: "Kanji", emoji: "🈶" },
    { type: "grammar", label: "Tata Bahasa", emoji: "📝" },
];

function toCard(type, level, it) {
    if (type === "vocab") return { id: it.id, level, front: it.kanji, reading: it.hiragana, meaning: it.arti, sub: it.jenisKata || "" };
    if (type === "kanji") return { id: it.id, level, front: it.kanji, reading: it.onyomi || it.kunyomi || "", meaning: it.meaning, sub: "" };
    return { id: it.id, level, front: it.pattern, reading: it.romaji, meaning: it.meaning, sub: "" }; // grammar
}

// ---------- Entry: deck picker ----------

export function renderFlashcard(app) {
    const streak = store.getStreak();
    const target = store.getDailyTarget();
    app.innerHTML = `
        <h1 class="page-title">🎴 Flashcard</h1>
        <p class="page-sub">Belajar terjadwal dengan FSRS-6. Streak: <b>${streak.count}</b> hari ·
            target harian: <b>${target}</b> kartu baru.</p>
        ${DECKS.map(
            (d) => `
            <div class="section-h">${d.emoji} ${d.label}</div>
            <div class="level-grid" style="margin-bottom:18px">
                ${LEVELS[d.type]
                    .map((l) =>
                        l.locked
                            ? `<div class="level-card locked" style="--lv:${l.color}"><span class="level-badge">${l.id}</span><span class="level-count">🔒 segera</span></div>`
                            : `<a class="level-card" style="--lv:${l.color}" href="#" data-deck="${d.type}" data-level="${l.id}">
                                   <span class="level-badge">${l.id}</span>
                                   <span class="level-name">${esc(d.label)}</span>
                                   <span class="level-count">Mulai sesi →</span>
                               </a>`
                    )
                    .join("")}
            </div>`
        ).join("")}`;

    app.querySelectorAll("[data-deck]").forEach((a) =>
        a.addEventListener("click", (e) => {
            e.preventDefault();
            startSession(app, a.dataset.deck, a.dataset.level);
        })
    );
}

// ---------- Session ----------

async function startSession(app, type, levelId) {
    const level = LEVELS[type].find((l) => l.id === levelId);
    app.innerHTML = `<div class="loading">Menyiapkan sesi…</div>`;
    let raw;
    try {
        raw = await loadJSON(level.file);
    } catch (e) {
        app.innerHTML = `<div class="empty-state">${esc(e.message)}</div>`;
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
        const existing = store.getProgress(card.id);
        const p = existing || newProgress(card);
        if (p.state === STATE.new) newCandidates.push(p);
        else if (isDue(p, now)) dueCards.push(p);
    }

    const remaining = Math.max(0, store.getDailyTarget() - store.newTodayCount(deckKey));
    const newCards = newCandidates.slice(0, remaining);
    shuffle(dueCards);
    const queue = [...dueCards, ...newCards];
    const countedNew = new Set();

    const session = {
        app, type, levelId, level, deckKey, deckById, queue, countedNew,
        reviewed: 0, revealed: false,
    };

    if (queue.length === 0) {
        renderEmpty(session, remaining);
        return;
    }
    renderCard(session);
}

function renderEmpty(session, remaining) {
    const { app, level, type } = session;
    const msg = remaining === 0
        ? "Kuota kartu baru hari ini sudah tercapai, dan tidak ada review yang jatuh tempo. 🎉"
        : "Tidak ada kartu yang perlu dipelajari sekarang — semua terjadwal ke depan. 🎉";
    app.innerHTML = `
        <a class="crumb" href="#/flashcard">← Flashcard</a>
        <div class="fc-wrap"><div class="empty-state">${esc(msg)}</div>
        <div style="text-align:center"><a class="btn btn-primary" href="#/flashcard">Pilih dek lain</a></div></div>`;
}

function counts(session) {
    let nu = 0, learn = 0, due = 0;
    for (const p of session.queue) {
        if (p.state === STATE.new) nu++;
        else if (p.state === STATE.learning || p.state === STATE.relearning) learn++;
        else due++;
    }
    return { nu, learn, due };
}

function renderCard(session) {
    const { app, queue, deckById } = session;
    if (queue.length === 0) return renderDone(session);
    const p = queue[0];
    const card = deckById.get(p.id);
    const c = counts(session);
    session.revealed = false;

    app.innerHTML = `
        <a class="crumb" href="#/flashcard">← Flashcard</a>
        <div class="fc-wrap">
            <div class="fc-progress">
                <span class="new">Baru ${c.nu}</span>
                <span class="learn">Belajar ${c.learn}</span>
                <span class="due">Ulang ${c.due}</span>
            </div>
            <div class="fc-card" id="fcCard">
                <div class="fc-front">${esc(card.front)}</div>
                <div class="fc-hint">Ketuk untuk melihat jawaban (atau tekan Spasi)</div>
                <div class="fc-back" id="fcBack" hidden>
                    <div class="reading">${esc(card.reading)}</div>
                    <div class="meaning">${esc(card.meaning)}</div>
                    ${card.sub ? `<div class="fc-hint">${esc(card.sub)}</div>` : ""}
                </div>
            </div>
            <div id="fcControls"></div>
        </div>`;

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

function revealCard(session, p, card) {
    if (session.revealed) return;
    session.revealed = true;
    document.getElementById("fcBack").hidden = false;
    document.querySelector(".fc-hint").textContent = "Seberapa lancar Anda mengingatnya?";
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
    session.reviewed += 1;

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
    const { app, reviewed } = session;
    const streak = store.recordStudyToday();
    app.innerHTML = `
        <a class="crumb" href="#/flashcard">← Flashcard</a>
        <div class="fc-wrap">
            <div class="detail" style="text-align:center">
                <div class="detail-hero">🎉</div>
                <div class="detail-meaning">Sesi selesai!</div>
                <p class="page-sub" style="margin-top:12px">${reviewed} kartu ditinjau · streak ${streak} hari.</p>
                <a class="btn btn-primary" href="#/flashcard">Kembali</a>
            </div>
        </div>`;
}

function shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
}
