// Content browser, matching the iOS-native Claude Design mockup. Renderers fill
// #content only — the top bar (back/title) is handled by app.js. Audio uses the
// browser's speech synthesis (ja-JP). Real datasets + search preserved.

import { loadJSON } from "./data.js";
import { LEVELS, SECTION_META, MENU, findLevel, alpha } from "./levels.js";
import * as store from "./store.js";

const esc = (s) =>
    String(s ?? "").replace(/[&<>"']/g, (c) =>
        ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const route = (...p) => "#/" + p.filter(Boolean).join("/");

export function speak(text) {
    try {
        if (!window.speechSynthesis) return;
        const u = new SpeechSynthesisUtterance(String(text || ""));
        u.lang = "ja-JP";
        speechSynthesis.cancel(); speechSynthesis.speak(u);
    } catch { /* unsupported */ }
}
document.addEventListener("click", (e) => {
    const b = e.target.closest("[data-speak]");
    if (b) { e.preventDefault(); e.stopPropagation(); speak(b.getAttribute("data-speak")); }
});

// ---------- Home ----------

export function renderHome(app) {
    const name = store.getUsername() || "User";
    const target = store.getDailyTarget();
    const studied = store.studiedTodayTotal();
    const pct = target > 0 ? Math.min(studied / target, 1) * 100 : 0;
    const due = store.dueTodayTotal(target);
    const streak = store.getStreak().count;
    const mastered = store.masteredTotal();

    app.innerHTML = `
        <header class="home-header">
            <div><div class="greet-kicker">こんにちは</div><h1 class="greet-title">Ichigo</h1></div>
            <a class="profile-pill" href="${route("profile")}"><span class="dot">◍</span><span class="nm">${esc(name)}</span></a>
        </header>

        <section class="progress-card">
            <div class="pc-top"><span class="lab">PROGRESS HARI INI</span><span class="val">${studied}/${target}</span></div>
            <div class="pc-bar"><span style="width:${Math.max(pct, pct > 0 ? 4 : 0)}%"></span></div>
            <div class="pc-stats">
                <div class="pc-stat"><span class="d" style="background:#2E7BFF"></span><span class="k">Due</span><span class="v">${due}</span></div>
                <div class="pc-stat"><span class="d" style="background:#FF9500"></span><span class="k">Streak</span><span class="v">${streak}</span></div>
                <div class="pc-stat"><span class="d" style="background:#AF52DE"></span><span class="k">Mastered</span><span class="v">${mastered}</span></div>
            </div>
        </section>

        <div class="section-label">BELAJAR MANDIRI</div>
        <div class="menu-grid">
            ${MENU.map((m) => `<a class="menu-card" href="${m.route}">
                <span class="menu-ic" style="background:${m.grad}">${esc(m.glyph)}</span>
                <span><span class="menu-label">${esc(m.label)}</span><span class="menu-sub">${esc(m.sub)}</span></span>
            </a>`).join("")}
        </div>`;
}

// ---------- Level picker ----------

export function renderLevels(app, section) {
    const levels = LEVELS[section] || [];
    const meta = SECTION_META[section];
    app.innerHTML = `<div class="level-list">${levels.map((l) => {
        const tint = l.locked ? "rgba(142,142,147,0.1)" : alpha(l.color, 0.14);
        const fg = l.locked ? "var(--gray)" : l.color;
        const metaText = l.locked ? "" : `${(l.count || 0).toLocaleString("id-ID")} ${meta.unit}`;
        const inner = `
            <span class="level-chip" style="background:${tint};color:${fg}">${l.id}</span>
            <span class="level-main">
                <span class="level-row1"><span class="level-name" style="color:${l.locked ? "var(--gray)" : "var(--ink)"}">${esc(l.name)}</span>
                    <span class="level-trailing">${l.locked ? "🔒 Terkunci" : "›"}</span></span>
                <span class="level-desc">${esc(l.desc)}</span>
                ${metaText ? `<span class="level-meta" style="color:${fg}">${metaText}</span>` : ""}
            </span>`;
        return l.locked
            ? `<div class="level-card" style="opacity:.55">${inner}</div>`
            : `<a class="level-card" href="${route(section, l.id)}">${inner}</a>`;
    }).join("")}</div>`;
}

// ---------- Lists ----------

export async function renderList(app, section, levelId) {
    const level = findLevel(section, levelId);
    if (!level || level.locked) return renderLevels(app, section);
    const meta = SECTION_META[section];
    app.innerHTML = `
        <div class="search"><span class="mag">⌕</span><input id="search" type="text" placeholder="${esc(meta.searchHint)}" autocomplete="off"></div>
        <div id="filterRow"></div>
        <div id="listBox"><div class="loading">Memuat…</div></div>`;

    let items;
    try { items = await loadJSON(level.file); }
    catch (e) { document.getElementById("listBox").innerHTML = `<div class="empty">${esc(e.message)}</div>`; return; }

    const box = document.getElementById("listBox");
    const search = document.getElementById("search");
    let filter = "Semua";

    if (section === "vocab") {
        const types = ["Semua", ...Array.from(new Set(items.map((it) => it.jenisKata).filter(Boolean)))];
        const drawChips = () => {
            document.getElementById("filterRow").innerHTML =
                `<div class="filter-row">${types.map((t) =>
                    `<button class="filter-chip ${t === filter ? "active" : ""}" data-filter="${esc(t)}">${esc(t)}</button>`).join("")}</div>`;
            document.querySelectorAll("[data-filter]").forEach((b) =>
                b.addEventListener("click", () => { filter = b.dataset.filter; drawChips(); draw(search.value); }));
        };
        drawChips();
    }

    const renderer = { kanji: kanjiCards, vocab: vocabCards, grammar: grammarRows }[section];
    const matcher = { kanji: kanjiMatch, vocab: vocabMatch, grammar: grammarMatch }[section];
    const draw = (q) => {
        const query = q.trim().toLowerCase();
        let shown = query ? items.filter((it) => matcher(it, query)) : items;
        if (section === "vocab" && filter !== "Semua") shown = shown.filter((it) => it.jenisKata === filter);
        box.innerHTML = shown.length ? renderer(shown, section, level.id) : `<div class="empty">Tidak ditemukan</div>`;
    };
    draw("");
    let t;
    search.addEventListener("input", () => { clearTimeout(t); t = setTimeout(() => draw(search.value), 120); });
}

function kanjiCards(items, section, lvl) {
    return `<div class="kanji-grid">${items.map((it) => {
        const rd = [it.onyomi, it.kunyomi].filter(Boolean).join(" / ");
        return `<a class="kanji-card" href="${route(section, lvl, it.id)}">
            <span class="jp">${esc(it.kanji)}</span>
            <span class="rd">${esc(rd)}</span>
            <span class="mn">${esc(it.meaning)}</span>
        </a>`;
    }).join("")}</div>`;
}
const kanjiMatch = (it, q) =>
    (it.kanji || "").includes(q) || (it.meaning || "").toLowerCase().includes(q) ||
    (it.romaji || "").toLowerCase().includes(q) || (it.onyomi || "").toLowerCase().includes(q) || (it.kunyomi || "").toLowerCase().includes(q);

function vocabCards(items, section, lvl) {
    return `<div class="vocab-grid">${items.map((it) => `
        <div class="vocab-card">
            <div class="vc-top"><span class="vc-badge">JLPT ${esc(lvl)}</span>
                <button class="speak-btn" style="background:rgba(46,123,255,0.12);color:#2E7BFF" data-speak="${esc(it.kanji || it.hiragana)}" aria-label="Dengarkan">🔊</button></div>
            <div class="vc-kanji">${esc(it.kanji)}</div>
            <div class="vc-hira">${esc(it.hiragana)}</div>
            ${it.jenisKata ? `<div class="vc-jenis">${esc(it.jenisKata)}</div>` : ""}
            <div class="vc-arti">${esc(it.arti)}</div>
        </div>`).join("")}</div>`;
}
const vocabMatch = (it, q) =>
    (it.kanji || "").includes(q) || (it.hiragana || "").includes(q) || (it.arti || "").toLowerCase().includes(q) || (it.jenisKata || "").toLowerCase().includes(q);

function grammarRows(items, section, lvl) {
    return `<div style="display:flex;flex-direction:column;gap:10px">${items.map((it) => `
        <a class="grammar-row" href="${route(section, lvl, it.id)}">
            <span class="m"><span class="p">${esc(it.pattern)}</span><span class="r">${esc(it.romaji)}</span><span class="g">${esc(it.meaning)}</span></span>
            <span class="chev">›</span>
        </a>`).join("")}</div>`;
}
const grammarMatch = (it, q) =>
    (it.pattern || "").includes(q) || (it.romaji || "").toLowerCase().includes(q) || (it.meaning || "").toLowerCase().includes(q);

// ---------- Detail ----------

const LEVEL_BADGE = { N5: "#34C759", N4: "#2E7BFF", N3: "#FF9500", N2: "#AF52DE", N1: "#FF3B30" };

export async function renderDetail(app, section, levelId, id) {
    const level = findLevel(section, levelId);
    if (!level) return renderLevels(app, section);
    let items;
    try { items = await loadJSON(level.file); }
    catch (e) { app.innerHTML = `<div class="empty">${esc(e.message)}</div>`; return; }
    const it = items.find((x) => x.id === id);
    if (!it) return renderList(app, section, levelId);
    app.innerHTML = { kanji: kanjiDetail, vocab: vocabDetail, grammar: grammarDetail }[section](it, level);
}

function kanjiDetail(it, level) {
    const badge = LEVEL_BADGE[level.id] || "#FF9500";
    const rows = (it.examples || []).map((ex) => `
        <div class="ex-row">
            <span class="m"><span class="w">${esc(ex.word)} <small>(${esc(ex.reading)})</small></span>
                <span class="g">${esc(ex.romaji)} — ${esc(ex.meaning)}</span></span>
            <button class="speak-btn" style="width:auto;height:auto;background:none;color:rgba(142,142,147,0.7);font-size:15px" data-speak="${esc(ex.sentence || ex.word)}" aria-label="Dengarkan">🔊</button>
        </div>`).join("");
    return `
        <div class="detail-hero">
            <span class="jlpt-badge" style="background:${badge}">JLPT ${esc(level.id)}</span>
            <div class="detail-kanji">${esc(it.kanji)}</div>
            <button class="speak-btn" style="background:${alpha(badge, 0.12)};color:${badge}" data-speak="${esc(it.kanji)}" aria-label="Dengarkan">🔊</button>
        </div>
        <div class="detail-cap"><div class="detail-romaji">${esc(it.romaji)}</div><div class="detail-meaning">${esc(it.meaning)}</div></div>
        <div class="read-cards">
            <div class="read-card"><div class="lab">ONYOMI</div><div class="val">${esc(it.onyomi || "—")}</div></div>
            <div class="read-card"><div class="lab">KUNYOMI</div><div class="val">${esc(it.kunyomi || "—")}</div></div>
        </div>
        ${rows ? `<div class="section-title">Contoh Kata</div><div class="rows-card">${rows}</div>` : ""}`;
}

function vocabDetail(it, level) {
    const badge = LEVEL_BADGE[level.id] || "#2E7BFF";
    return `
        <div class="detail-hero">
            <span class="jlpt-badge" style="background:${badge}">JLPT ${esc(level.id)}</span>
            <div class="detail-kanji" style="font-size:clamp(56px,9vw,88px)">${esc(it.kanji)}</div>
            <button class="speak-btn" style="background:${alpha(badge, 0.12)};color:${badge}" data-speak="${esc(it.kanji || it.hiragana)}" aria-label="Dengarkan">🔊</button>
        </div>
        <div class="detail-cap"><div class="detail-romaji" style="font-size:22px">${esc(it.hiragana)}</div><div class="detail-meaning">${esc(it.arti)}</div></div>
        <div class="read-cards">
            <div class="read-card"><div class="lab">JENIS KATA</div><div class="val">${esc(it.jenisKata || "—")}</div></div>
            <div class="read-card"><div class="lab">LEVEL</div><div class="val">${esc(it.level || level.id)}</div></div>
        </div>`;
}

function grammarDetail(it, level) {
    const tags = (it.tags && it.tags.length ? it.tags : [level.id, it.treeCategory].filter(Boolean));
    const usage = (it.usage || []).map((u) => `<div class="gd-usage"><span class="d"></span><span class="t">${esc(u)}</span></div>`).join("");
    const examples = (it.examples || []).map((ex, i) => `
        <div class="gd-ex">
            <div class="gd-ex-head"><span class="gd-ex-n">${i + 1}</span><span class="gd-ex-jp">${esc(ex.japanese)}</span></div>
            <div class="gd-ex-ro">${esc(ex.romaji)}</div><div class="gd-ex-tr">${esc(ex.translation)}</div>
        </div>`).join("");
    return `
        <div class="gd-hero">
            <div class="gd-top"><span class="gd-badge">JLPT ${esc(level.id)}</span>${it.structure ? `<span class="gd-structure">${esc(it.structure)}</span>` : ""}</div>
            <div><div class="gd-pattern">${esc(it.pattern)}</div><div class="gd-romaji">${esc(it.romaji)}</div><div class="gd-meaning">${esc(it.meaning)}</div></div>
            ${tags.length ? `<div class="gd-tags">${tags.map((t) => `<span class="gd-tag">${esc(t)}</span>`).join("")}</div>` : ""}
        </div>
        ${(it.nuance || it.frequency) ? `<div class="gd-info" style="grid-template-columns:1fr 1fr">
            <div class="gd-info-card"><div class="lab">NUANCE</div><div class="val">${esc(it.nuance || "—")}</div></div>
            <div class="gd-info-card"><div class="lab">FREQUENCY</div><div class="val">${esc(it.frequency || "—")}</div></div></div>` : ""}
        ${(it.explanation || it.meaning) ? `<section class="gd-section">
            <div class="gd-sec-head"><span class="gd-sec-ic">文</span><span class="gd-sec-title">Arti</span></div>
            <div style="font-size:15px;line-height:1.6">${esc(it.explanation || it.meaning)}</div></section>` : ""}
        ${usage ? `<section class="gd-section">
            <div class="gd-sec-head"><span class="gd-sec-ic">≔</span><span class="gd-sec-title">Penggunaan</span></div>
            <div style="display:flex;flex-direction:column;gap:10px">${usage}</div></section>` : ""}
        ${examples ? `<section class="gd-section">
            <div class="gd-sec-head"><span class="gd-sec-ic">❝</span><span class="gd-sec-title">Contoh Kalimat</span><span class="gd-sec-count">${it.examples.length} kalimat</span></div>
            <div style="display:flex;flex-direction:column;gap:10px">${examples}</div></section>` : ""}`;
}

// ---------- Hiragana / Katakana ----------

const isKatakana = (ch) => ch && ch.codePointAt(0) >= 0x30a0 && ch.codePointAt(0) <= 0x30ff;

export async function renderHiragana(app) {
    let groups;
    try { groups = await loadJSON("Hiragana"); }
    catch (e) { app.innerHTML = `<div class="empty">${esc(e.message)}</div>`; return; }

    const cells = (kata) => {
        const out = [];
        for (const g of groups) {
            const first = (() => { for (const row of g.rows || []) for (const c of row) if (c && c.kana) return c.kana; return ""; })();
            if (isKatakana(first) !== kata) continue;
            for (const row of g.rows || []) for (const c of row) if (c && c.kana) out.push({ k: c.kana, r: (c.romaji || "").toUpperCase() });
        }
        return out;
    };

    const paint = (kata) => {
        const list = cells(kata);
        const name = kata ? "Katakana" : "Hiragana";
        const grad = kata ? "linear-gradient(90deg,#801AE6,#AF52DE)" : "linear-gradient(90deg,#3399FF,#2E7BFF)";
        const accent = kata ? "#AF52DE" : "#2E7BFF";
        document.getElementById("hiraTab").className = "seg-btn" + (kata ? "" : " active");
        document.getElementById("kataTab").className = "seg-btn" + (kata ? " active" : "");
        document.getElementById("kanaBody").innerHTML = `
            <div class="kana-prog">
                <div class="t">Progres Hafalan</div>
                <div class="bar"><span style="width:0%;background:${grad}"></span></div>
                <div class="sub">0 dari ${list.length} huruf dikuasai</div>
            </div>
            <div class="kana-grid">${list.map((c) => `
                <div class="kana-cell"><span class="k">${esc(c.k)}</span><span class="r">${esc(c.r)}</span>
                    <span class="b"><span style="width:0%;background:${accent}"></span></span></div>`).join("")}</div>
            <a class="big-btn" style="background:${accent}" href="${route("flashcard")}">Flashcard ${name}</a>`;
    };

    app.innerHTML = `
        <div class="seg"><button class="seg-btn active" id="hiraTab" type="button">Hiragana</button><button class="seg-btn" id="kataTab" type="button">Katakana</button></div>
        <div id="kanaBody"></div>`;
    document.getElementById("hiraTab").addEventListener("click", () => paint(false));
    document.getElementById("kataTab").addEventListener("click", () => paint(true));
    paint(false);
}

// ---------- Coming soon ----------

export function renderComingSoon(app) {
    app.innerHTML = `<div class="empty">🔨<br><br><b>Segera Hadir</b><br>Fitur ini sedang dikembangkan.</div>`;
}
