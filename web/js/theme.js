// Shared theme helper (light / dark / auto). Kept separate so both the app shell
// and the settings page can drive it without a circular import.

export const THEME_KEY = "ichigo_theme";

export function currentTheme() {
    return document.documentElement.getAttribute("data-theme") || "auto";
}

export function effectiveIsDark() {
    const t = currentTheme();
    return t === "dark" || (t === "auto" && window.matchMedia("(prefers-color-scheme: dark)").matches);
}

export function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    const icon = document.querySelector("#themeToggle .theme-icon");
    if (icon) icon.textContent = effectiveIsDark() ? "☀️" : "🌙";
}

export function setTheme(theme) {
    localStorage.setItem(THEME_KEY, theme);
    applyTheme(theme);
}

export function initTheme() {
    applyTheme(localStorage.getItem(THEME_KEY) || "auto");
    const btn = document.getElementById("themeToggle");
    if (btn) btn.addEventListener("click", () => setTheme(effectiveIsDark() ? "light" : "dark"));
    // Keep the icon in sync when the OS theme changes while on "auto".
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
        if (currentTheme() === "auto") applyTheme("auto");
    });
}
