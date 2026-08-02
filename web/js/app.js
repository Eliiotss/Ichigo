// Router + shell: hash-based navigation, nav tabs, theme toggle, and dispatch to
// the browse/flashcard views. No build step — plain ES modules.

import { SECTIONS } from "./levels.js";
import { renderHome, renderLevels, renderList, renderDetail, renderHiragana } from "./browse.js";
import { initTheme } from "./theme.js";

const app = document.getElementById("app");
const tabsEl = document.getElementById("tabs");

// ---------- Nav ----------

function buildTabs() {
    tabsEl.innerHTML = SECTIONS.map(
        (s) => `<a class="tab" data-section="${s.key}" href="#/${s.key}">${s.label}</a>`
    ).join("");
}
function setActiveTab(section) {
    tabsEl.querySelectorAll(".tab").forEach((t) =>
        t.classList.toggle("active", t.dataset.section === section)
    );
}

// ---------- Router ----------

function parseHash() {
    const raw = (location.hash || "#/home").replace(/^#\/?/, "");
    return raw.split("/").filter(Boolean); // e.g. ["kanji","N5","N5_001"]
}

async function router() {
    const [section = "home", level, id] = parseHash();
    setActiveTab(section === "home" ? "home" : section);
    window.scrollTo(0, 0);
    // Retrigger the page-enter animation on every navigation.
    app.classList.remove("page-enter");
    void app.offsetWidth;
    app.classList.add("page-enter");

    try {
        switch (section) {
            case "home":
                return renderHome(app);
            case "kanji":
            case "vocab":
            case "grammar":
                if (id) return await renderDetail(app, section, level, id);
                if (level) return await renderList(app, section, level);
                return renderLevels(app, section);
            case "hiragana":
                return await renderHiragana(app);
            case "flashcard":
                return await renderFlashcard(app);
            case "settings": {
                const mod = await import("./settings.js");
                return mod.renderSettings(app);
            }
            default:
                return renderHome(app);
        }
    } catch (err) {
        app.innerHTML = `<div class="empty-state">Terjadi kesalahan: ${err.message}</div>`;
    }
}

// Flashcard view is wired in the next increment; keep a friendly placeholder so
// the tab is never a dead end.
async function renderFlashcard(container) {
    const mod = await import("./flashcards.js").catch(() => null);
    if (mod && mod.renderFlashcard) return mod.renderFlashcard(container);
    container.innerHTML = `
        <h1 class="page-title">🎴 Flashcard</h1>
        <p class="page-sub">Sesi belajar berjadwal FSRS-6 sedang disiapkan untuk versi web.</p>`;
}

// ---------- Init ----------

initTheme();
buildTabs();
window.addEventListener("hashchange", router);
router();
