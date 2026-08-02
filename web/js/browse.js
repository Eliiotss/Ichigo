// Content browser: home, level pickers, searchable lists, and detail pages for
// Kanji / Vocab / Grammar, plus the Hiragana/Katakana chart.

import { loadJSON } from "./data.js";
import { LEVELS, SECTION_META, findLevel } from "./levels.js";
import { getUsername } from "./store.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const route = (...parts) => "#/" + parts.filter(Boolean).join("/");

// ---------- Home ----------

export function renderHome(app) {
    const tiles = [
        ["kanji", "🈶", "Kanji", "N5–N3 · 668 kanji"],
        ["vocab", "📖", "Kosakata", "N5–N3 · 3.300 kata"],
        ["grammar", "📝", "Tata Bahasa", "N5–N3 · 398 pola"],
        ["hiragana", "あ", "Hiragana & Katakana", "Dasar aksara kana"],
        ["flashcard", "🎴", "Flashcard", "Belajar terjadwal (FSRS-6)"],
    ];
    const name = getUsername();
    app.innerHTML = `
        <section class="hero">
            <h1>${name ? `Selamat datang, ${esc(name)} 🍓` : "Selamat datang di Ichigo 🍓"}</h1>
            <p>Belajar bahasa Jepang untuk JLPT: jelajahi kanji, kosakata, dan tata bahasa,
               lalu kuatkan ingatan dengan flashcard berjadwal FSRS-6.</p>
        </section>
        <div class="tile-grid">
            ${tiles
                .map(
                    ([key, emoji, title, sub]) => `
                <a class="tile" href="${route(key)}">
                    <div class="tile-emoji">${emoji}</div>
                    <div class="tile-title">${title}</div>
                    <div class="tile-sub">${sub}</div>
                </a>`
                )
                .join("")}
        </div>`;
}

// ---------- Level picker ----------

export function renderLevels(app, section) {
    const meta = SECTION_META[section];
    const levels = LEVELS[section] || [];
    app.innerHTML = `
        <a class="crumb" href="${route("home")}">← Beranda</a>
        <h1 class="page-title">${meta.emoji} ${meta.label}</h1>
        <p class="page-sub">Pilih level JLPT.</p>
        <div class="level-grid">
            ${levels
                .map((l) => {
                    const inner = `
                        <span class="level-badge">${l.id}</span>
                        <span class="level-name">${esc(l.name)}</span>
                        <span class="level-count">${
                            l.locked ? "🔒 segera" : `${l.count.toLocaleString("id-ID")} ${meta.unit}`
                        }</span>`;
                    return l.locked
                        ? `<div class="level-card locked" style="--lv:${l.color}">${inner}</div>`
                        : `<a class="level-card" style="--lv:${l.color}" href="${route(section, l.id)}">${inner}</a>`;
                })
                .join("")}
        </div>`;
}

// ---------- Lists (with live search) ----------

export async function renderList(app, section, levelId) {
    const level = findLevel(section, levelId);
    if (!level || level.locked) return renderLevels(app, section);
    const meta = SECTION_META[section];
    app.innerHTML = `
        <a class="crumb" href="${route(section)}">← ${meta.label}</a>
        <h1 class="page-title" style="color:${level.color}">${level.id} · ${esc(meta.label)}</h1>
        <div class="toolbar">
            <input class="search" id="search" type="search" placeholder="Cari ${esc(meta.unit)}…"
                   autocomplete="off" spellcheck="false">
        </div>
        <p class="result-count" id="count"></p>
        <div id="listBox"><div class="loading">Memuat…</div></div>`;

    let items;
    try {
        items = await loadJSON(level.file);
    } catch (e) {
        document.getElementById("listBox").innerHTML =
            `<div class="empty-state">${esc(e.message)}<br>Jalankan lewat server (mis. <code>python3 -m http.server</code>).</div>`;
        return;
    }

    const box = document.getElementById("listBox");
    const count = document.getElementById("count");
    const search = document.getElementById("search");
    const renderer = { kanji: kanjiCards, vocab: vocabRows, grammar: grammarRows }[section];
    const matcher = { kanji: kanjiMatch, vocab: vocabMatch, grammar: grammarMatch }[section];

    const draw = (q) => {
        const query = q.trim().toLowerCase();
        const shown = query ? items.filter((it) => matcher(it, query)) : items;
        count.textContent = `${shown.length.toLocaleString("id-ID")} ${meta.unit}`;
        box.innerHTML = shown.length
            ? renderer(shown, section, level.id)
            : `<div class="empty-state">Tidak ada hasil untuk “${esc(q)}”.</div>`;
    };
    draw("");
    let t;
    search.addEventListener("input", () => {
        clearTimeout(t);
        t = setTimeout(() => draw(search.value), 120);
    });
    search.focus();
}

function kanjiCards(items, section, lvl) {
    return `<div class="card-grid">${items
        .map(
            (it) => `
        <a class="entry" href="${route(section, lvl, it.id)}">
            <span class="entry-jp">${esc(it.kanji)}</span>
            <span class="entry-reading">${esc(it.onyomi || it.kunyomi || "")}</span>
            <span class="entry-meaning">${esc(it.meaning)}</span>
        </a>`
        )
        .join("")}</div>`;
}
const kanjiMatch = (it, q) =>
    (it.kanji || "").includes(q) ||
    (it.meaning || "").toLowerCase().includes(q) ||
    (it.romaji || "").toLowerCase().includes(q) ||
    (it.onyomi || "").toLowerCase().includes(q) ||
    (it.kunyomi || "").toLowerCase().includes(q);

function vocabRows(items, section, lvl) {
    return `<div class="list-rows">${items
        .map(
            (it) => `
        <a class="row" href="${route(section, lvl, it.id)}">
            <span class="row-jp">${esc(it.kanji)}</span>
            <span class="row-main">
                <span class="row-reading">${esc(it.hiragana)}</span>
                <span class="row-meaning"> — ${esc(it.arti)}</span>
            </span>
            <span class="entry-tag">${esc(it.jenisKata || "")}</span>
        </a>`
        )
        .join("")}</div>`;
}
const vocabMatch = (it, q) =>
    (it.kanji || "").includes(q) ||
    (it.hiragana || "").includes(q) ||
    (it.arti || "").toLowerCase().includes(q);

function grammarRows(items, section, lvl) {
    return `<div class="list-rows">${items
        .map(
            (it) => `
        <a class="row" href="${route(section, lvl, it.id)}">
            <span class="row-main">
                <span class="entry-jp small">${esc(it.pattern)}</span>
                <span class="row-meaning"> — ${esc(it.meaning)}</span>
            </span>
        </a>`
        )
        .join("")}</div>`;
}
const grammarMatch = (it, q) =>
    (it.pattern || "").includes(q) ||
    (it.romaji || "").toLowerCase().includes(q) ||
    (it.meaning || "").toLowerCase().includes(q);

// ---------- Detail ----------

export async function renderDetail(app, section, levelId, id) {
    const level = findLevel(section, levelId);
    if (!level) return renderLevels(app, section);
    let items;
    try {
        items = await loadJSON(level.file);
    } catch (e) {
        app.innerHTML = `<div class="empty-state">${esc(e.message)}</div>`;
        return;
    }
    const it = items.find((x) => x.id === id);
    if (!it) return renderList(app, section, levelId);
    const back = `<a class="crumb" href="${route(section, levelId)}">← ${level.id} ${esc(SECTION_META[section].label)}</a>`;
    app.innerHTML = back + ({ kanji: kanjiDetail, vocab: vocabDetail, grammar: grammarDetail }[section])(it, level);
}

function fact(label, value) {
    if (!value) return "";
    return `<div class="fact"><div class="fact-label">${esc(label)}</div><div class="fact-value">${esc(value)}</div></div>`;
}

function kanjiDetail(it, level) {
    const examples = (it.examples || [])
        .map(
            (ex) => `
        <div class="example">
            <div class="example-jp">${esc(ex.word)} <span class="entry-reading">${esc(ex.reading)}</span></div>
            <div class="example-romaji">${esc(ex.romaji)} · ${esc(ex.meaning)}</div>
            ${ex.sentence ? `<div class="example-jp" style="margin-top:8px">${esc(ex.sentenceFurigana || ex.sentence)}</div>
            <div class="example-tr">${esc(ex.sentenceMeaning || "")}</div>` : ""}
        </div>`
        )
        .join("");
    return `
        <div class="detail">
            <div class="detail-hero" style="color:${level.color}">${esc(it.kanji)}</div>
            <div class="detail-meaning">${esc(it.meaning)}</div>
            <div class="detail-grid">
                ${fact("On'yomi", it.onyomi)}
                ${fact("Kun'yomi", it.kunyomi)}
                ${fact("Romaji", it.romaji)}
            </div>
            ${examples ? `<div class="section-h">Contoh kata</div>${examples}` : ""}
        </div>`;
}

function vocabDetail(it, level) {
    return `
        <div class="detail">
            <div class="detail-hero" style="font-size:clamp(36px,10vw,64px);color:${level.color}">${esc(it.kanji)}</div>
            <div class="detail-reading">${esc(it.hiragana)}</div>
            <div class="detail-meaning">${esc(it.arti)}</div>
            <div class="detail-grid">${fact("Jenis kata", it.jenisKata)}${fact("Level", it.level || level.id)}</div>
        </div>`;
}

function grammarDetail(it, level) {
    const list = (title, arr) =>
        arr && arr.length
            ? `<div class="section-h">${title}</div>${arr.map((x) => `<div class="bullet">• ${esc(x)}</div>`).join("")}`
            : "";
    const examples = (it.examples || [])
        .map(
            (ex) => `
        <div class="example">
            <div class="example-jp">${esc(ex.japanese)}</div>
            <div class="example-romaji">${esc(ex.romaji)}</div>
            <div class="example-tr">${esc(ex.translation)}</div>
        </div>`
        )
        .join("");
    return `
        <div class="detail">
            <div class="detail-hero" style="font-size:clamp(30px,8vw,52px);color:${level.color}">${esc(it.pattern)}</div>
            <div class="detail-reading">${esc(it.romaji)}</div>
            <div class="detail-meaning">${esc(it.meaning)}</div>
            <div class="detail-grid">${fact("Struktur", it.structure)}${fact("Kategori", it.treeCategory)}${fact("Frekuensi", it.frequency)}</div>
            ${it.nuance ? `<div class="section-h">Nuansa</div><p>${esc(it.nuance)}</p>` : ""}
            ${it.explanation ? `<div class="section-h">Penjelasan</div><p>${esc(it.explanation)}</p>` : ""}
            ${list("Penggunaan", it.usage)}
            ${examples ? `<div class="section-h">Contoh kalimat</div>${examples}` : ""}
            ${list("Kesalahan umum", it.commonMistakes)}
        </div>`;
}

// ---------- Hiragana / Katakana ----------

const isKatakana = (ch) => ch && ch.codePointAt(0) >= 0x30a0 && ch.codePointAt(0) <= 0x30ff;

export async function renderHiragana(app) {
    let groups;
    try {
        groups = await loadJSON("Hiragana");
    } catch (e) {
        app.innerHTML = `<div class="empty-state">${esc(e.message)}</div>`;
        return;
    }
    const firstKana = (g) => {
        for (const row of g.rows || []) for (const c of row) if (c && c.kana) return c.kana;
        return "";
    };
    const hira = groups.filter((g) => !isKatakana(firstKana(g)));
    const kata = groups.filter((g) => isKatakana(firstKana(g)));

    const table = (g) => `
        <h2 class="section-h">${esc(g.title || "")}${g.subtitle ? ` <span class="page-sub" style="font-weight:400">${esc(g.subtitle)}</span>` : ""}</h2>
        <table class="kana-table"><tbody>${(g.rows || [])
            .map(
                (row) =>
                    `<tr>${row
                        .map((c) =>
                            c && c.kana
                                ? `<td class="kana-cell"><div class="k">${esc(c.kana)}</div><div class="r">${esc(c.romaji || "")}</div></td>`
                                : `<td class="kana-cell empty"></td>`
                        )
                        .join("")}</tr>`
            )
            .join("")}</tbody></table>`;

    app.innerHTML = `
        <a class="crumb" href="${route("home")}">← Beranda</a>
        <h1 class="page-title">あ Hiragana & Katakana</h1>
        <div class="kana-tabs">
            <button class="tab active" id="tabHira">Hiragana</button>
            <button class="tab" id="tabKata">Katakana</button>
        </div>
        <div id="kanaBox">${hira.map(table).join("")}</div>`;

    const box = document.getElementById("kanaBox");
    const th = document.getElementById("tabHira");
    const tk = document.getElementById("tabKata");
    th.addEventListener("click", () => {
        th.classList.add("active"); tk.classList.remove("active");
        box.innerHTML = hira.map(table).join("");
    });
    tk.addEventListener("click", () => {
        tk.classList.add("active"); th.classList.remove("active");
        box.innerHTML = kata.map(table).join("");
    });
}
