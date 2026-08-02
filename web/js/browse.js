// Content browser, styled to match the iOS app: Home (greeting + hero progress
// + learning grid), level pickers, searchable lists, detail pages (blue hero +
// section cards) for Kanji / Vocab / Grammar, and the Hiragana/Katakana chart.

import { loadJSON } from "./data.js";
import { LEVELS, SECTION_META, MENU, findLevel } from "./levels.js";
import { icon, GLYPH } from "./icons.js";
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

function greetingText() {
    const h = new Date().getHours();
    if (h >= 5 && h < 11) return "Selamat pagi";
    if (h >= 11 && h < 15) return "Selamat siang";
    if (h >= 15 && h < 18) return "Selamat sore";
    return "Selamat malam";
}

function initials(name) {
    const words = String(name || "").trim().split(/\s+/).filter(Boolean);
    if (!words.length) return "🍓";
    const a = words[0][0] || "";
    const b = words.length > 1 ? words[words.length - 1][0] : "";
    return (a + b).toUpperCase();
}

// ---------- Home ----------

export function renderHome(app) {
    const name = store.getUsername() || "Teman";
    const target = store.getDailyTarget();
    const studied = store.studiedTodayTotal();
    const progress = target > 0 ? Math.min(studied / target, 1) : 0;
    const due = store.dueTodayTotal(target);
    const streak = store.getStreak().count;
    const mastered = store.masteredTotal();

    app.innerHTML = `
        <div class="greeting">
            <div class="greeting-text">
                <div class="greeting-kicker">Okaeri 🍓</div>
                <div class="greeting-name">${greetingText()}, ${esc(name)}</div>
            </div>
            <a class="avatar" href="${route("profile")}" aria-label="Buka profil">${esc(initials(name))}</a>
        </div>

        <div class="hero">
            <div class="hero-top">
                <span class="label">PROGRESS HARI INI</span>
                <span class="count">${studied}/${target}</span>
            </div>
            <div class="hero-bar"><span style="width:${Math.max(progress * 100, progress > 0 ? 4 : 0)}%"></span></div>
            <div class="hero-stats">
                <div class="hero-stat"><span class="v">${due}</span><span class="l">Due</span></div>
                <div class="hero-stat"><span class="v">🔥 ${streak}</span><span class="l">Streak</span></div>
                <div class="hero-stat"><span class="v">${mastered}</span><span class="l">Mastered</span></div>
            </div>
        </div>

        <div class="section-label">BELAJAR MANDIRI</div>
        <div class="menu-grid">
            ${MENU.map((m) => {
                const ic = m.id === "flashcard" ? icon("cards") : (GLYPH[m.id] || "");
                return `<a class="menu-card" href="${m.route}">
                    <span class="menu-icon ${m.id}">${ic}</span>
                    <span class="menu-label">${esc(m.label)}</span>
                    <span class="menu-sub">${esc(m.sub)}</span>
                </a>`;
            }).join("")}
        </div>`;
}

// ---------- Level picker ----------

export function renderLevels(app, section) {
    const meta = SECTION_META[section];
    const levels = LEVELS[section] || [];
    app.innerHTML =
        screenHeader(meta.title, route("home")) +
        `<div class="level-list">${levels.map((l) => levelCard(section, meta, l)).join("")}</div>`;
}

function levelCard(section, meta, l) {
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
    return `<a class="level-card" href="${route(section, l.id)}">
        <span class="level-chip" style="background:color-mix(in srgb, ${l.color} 15%, transparent);color:${l.color}">${l.id}</span>
        <span class="level-main">
            <span class="level-row1"><span class="level-name">${esc(l.name)}</span></span>
            <span class="level-desc">${esc(l.desc)}</span>
            <span class="level-count" style="color:${l.color}">${(l.count || 0).toLocaleString("id-ID")} ${esc(meta.unit)}</span>
        </span>
        <span class="chev">${icon("chev")}</span>
    </a>`;
}

// ---------- Lists (with live search) ----------

export async function renderList(app, section, levelId) {
    const level = findLevel(section, levelId);
    if (!level || level.locked) return renderLevels(app, section);
    const meta = SECTION_META[section];
    app.innerHTML =
        screenHeader(`${level.id} · ${meta.title}`, route(section)) +
        `<div class="search-field">${icon("search")}
            <input id="search" type="search" placeholder="Cari ${esc(meta.unit)}…" autocomplete="off" spellcheck="false"></div>
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
}

function kanjiCards(items, section, lvl) {
    return `<div class="card-grid">${items
        .map((it) => `
        <a class="kentry" href="${route(section, lvl, it.id)}">
            <span class="jp">${esc(it.kanji)}</span>
            <span class="reading">${esc(it.onyomi || it.kunyomi || "")}</span>
            <span class="meaning">${esc(it.meaning)}</span>
        </a>`)
        .join("")}</div>`;
}
const kanjiMatch = (it, q) =>
    (it.kanji || "").includes(q) ||
    (it.meaning || "").toLowerCase().includes(q) ||
    (it.romaji || "").toLowerCase().includes(q) ||
    (it.onyomi || "").toLowerCase().includes(q) ||
    (it.kunyomi || "").toLowerCase().includes(q);

function vocabRows(items, section, lvl) {
    return `<div class="rows">${items
        .map((it) => `
        <a class="row" href="${route(section, lvl, it.id)}">
            <span class="jp">${esc(it.kanji)}</span>
            <span class="row-main">
                <span class="row-reading">${esc(it.hiragana)}</span>
                <span class="row-meaning"> — ${esc(it.arti)}</span>
            </span>
            ${it.jenisKata ? `<span class="row-tag">${esc(it.jenisKata)}</span>` : ""}
        </a>`)
        .join("")}</div>`;
}
const vocabMatch = (it, q) =>
    (it.kanji || "").includes(q) ||
    (it.hiragana || "").includes(q) ||
    (it.arti || "").toLowerCase().includes(q);

function grammarRows(items, section, lvl) {
    return `<div class="rows">${items
        .map((it) => `
        <a class="row" href="${route(section, lvl, it.id)}">
            <span class="row-main">
                <span class="jp small">${esc(it.pattern)}</span>
                <span class="row-meaning"> — ${esc(it.meaning)}</span>
            </span>
        </a>`)
        .join("")}</div>`;
}
const grammarMatch = (it, q) =>
    (it.pattern || "").includes(q) ||
    (it.romaji || "").toLowerCase().includes(q) ||
    (it.meaning || "").toLowerCase().includes(q);

// ---------- Detail ----------

const DETAIL_TITLE = { kanji: "Detail Kanji", vocab: "Detail Kosakata", grammar: "Detail Tata Bahasa" };

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
    const header = screenHeader(DETAIL_TITLE[section], route(section, levelId));
    const body = { kanji: kanjiDetail, vocab: vocabDetail, grammar: grammarDetail }[section](it, level);
    app.innerHTML = header + `<div class="detail-stack">${body}</div>`;
}

function heroBadge(level) { return `<span class="hero-badge">JLPT ${level.id}</span>`; }

function sectionCard(title, iconName, inner) {
    return `<div class="section-card">
        <div class="section-card-head"><span class="section-card-icon">${icon(iconName)}</span><span class="section-card-title">${esc(title)}</span></div>
        ${inner}
    </div>`;
}

function factGrid(facts) {
    const cells = facts.filter(([, v]) => v)
        .map(([l, v]) => `<div class="fact"><div class="fact-label">${esc(l)}</div><div class="fact-value">${esc(v)}</div></div>`)
        .join("");
    return cells ? `<div class="fact-grid">${cells}</div>` : "";
}

function kanjiDetail(it, level) {
    const examples = (it.examples || []).map((ex) => `
        <div class="example">
            <div class="ex-word">${esc(ex.word)} <span class="ex-reading">（${esc(ex.reading)}）</span></div>
            <div class="ex-gloss">${esc(ex.romaji)} — ${esc(ex.meaning)}</div>
            ${(ex.sentenceFurigana || ex.sentence)
                ? `<div class="ex-sentence">${esc(ex.sentenceFurigana || ex.sentence)}</div>
                   ${ex.sentenceMeaning ? `<div class="ex-trans">${esc(ex.sentenceMeaning)}</div>` : ""}`
                : ""}
        </div>`).join("");

    return `
        <div class="detail-hero">
            <div class="hero-badges">${heroBadge(level)}</div>
            <div class="hero-glyph">${esc(it.kanji)}</div>
            <div class="hero-romaji">${esc(it.romaji)}</div>
            <div class="hero-sub">${esc(it.meaning)}</div>
        </div>
        <div class="reading-cards">
            <div class="reading-card"><span class="rc-label">ONYOMI</span><span class="rc-value">${esc(it.onyomi || "—")}</span></div>
            <div class="reading-card"><span class="rc-label">KUNYOMI</span><span class="rc-value">${esc(it.kunyomi || "—")}</span></div>
        </div>
        ${examples ? sectionCard("Contoh Kata & Kalimat", "book", examples) : ""}`;
}

function vocabDetail(it, level) {
    return `
        <div class="detail-hero">
            <div class="hero-badges">${heroBadge(level)}</div>
            <div class="hero-glyph" style="font-size:clamp(40px,12vw,64px)">${esc(it.kanji)}</div>
            <div class="hero-romaji">${esc(it.hiragana)}</div>
            <div class="hero-sub">${esc(it.arti)}</div>
        </div>
        ${factGrid([["Jenis kata", it.jenisKata], ["Level", it.level || level.id]])}`;
}

function grammarDetail(it, level) {
    const list = (title, iconName, arr) =>
        arr && arr.length
            ? sectionCard(title, iconName, arr.map((x) => `<div class="bullet">• ${esc(x)}</div>`).join(""))
            : "";
    const examples = (it.examples || []).map((ex) => `
        <div class="example">
            <div class="ex-sentence" style="margin-top:0">${esc(ex.japanese)}</div>
            <div class="ex-gloss">${esc(ex.romaji)}</div>
            <div class="ex-trans">${esc(ex.translation)}</div>
        </div>`).join("");

    return `
        <div class="detail-hero">
            <div class="hero-badges">${heroBadge(level)}</div>
            <div class="hero-glyph" style="font-size:clamp(28px,8vw,44px)">${esc(it.pattern)}</div>
            <div class="hero-romaji">${esc(it.romaji)}</div>
            <div class="hero-sub">${esc(it.meaning)}</div>
        </div>
        ${factGrid([["Struktur", it.structure], ["Kategori", it.treeCategory], ["Frekuensi", it.frequency]])}
        ${it.nuance ? sectionCard("Nuansa", "info", `<p class="prose">${esc(it.nuance)}</p>`) : ""}
        ${it.explanation ? sectionCard("Penjelasan", "book", `<p class="prose">${esc(it.explanation)}</p>`) : ""}
        ${list("Penggunaan", "check", it.usage)}
        ${examples ? sectionCard("Contoh Kalimat", "cards", examples) : ""}
        ${list("Kesalahan Umum", "info", it.commonMistakes)}`;
}

// ---------- Hiragana / Katakana ----------

const isKatakana = (ch) => ch && ch.codePointAt(0) >= 0x30a0 && ch.codePointAt(0) <= 0x30ff;

export async function renderHiragana(app) {
    let groups;
    try {
        groups = await loadJSON("Hiragana");
    } catch (e) {
        app.innerHTML = screenHeader("Hiragana & Katakana", route("home")) + `<div class="empty-state">${esc(e.message)}</div>`;
        return;
    }
    const firstKana = (g) => {
        for (const row of g.rows || []) for (const c of row) if (c && c.kana) return c.kana;
        return "";
    };
    const hira = groups.filter((g) => !isKatakana(firstKana(g)));
    const kata = groups.filter((g) => isKatakana(firstKana(g)));

    const table = (g) => `
        <div class="kana-title">${esc(g.title || "")}${g.subtitle ? ` <span>${esc(g.subtitle)}</span>` : ""}</div>
        <table class="kana-table"><tbody>${(g.rows || [])
            .map((row) => `<tr>${row
                .map((c) => c && c.kana
                    ? `<td class="kana-cell"><div class="k">${esc(c.kana)}</div><div class="r">${esc(c.romaji || "")}</div></td>`
                    : `<td class="kana-cell empty"></td>`)
                .join("")}</tr>`)
            .join("")}</tbody></table>`;

    app.innerHTML =
        screenHeader("Hiragana & Katakana", route("home")) +
        `<div class="chip-row">
            <button class="chip active" id="tabHira">Hiragana</button>
            <button class="chip" id="tabKata">Katakana</button>
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

// ---------- Coming soon (Home "Lainnya") ----------

export function renderComingSoon(app, name) {
    app.innerHTML =
        screenHeader(name ? name : "Lainnya", route("home")) +
        `<div class="empty-state">🔨<br><br><b>Segera Hadir</b><br>Fitur ini sedang dikembangkan.</div>`;
}
