// Study reminder via the browser Notification API. Honest and best-effort: when
// enabled and permission is granted, it shows one reminder per day, after the
// chosen hour, if today's target isn't met yet — while the app/tab is open (web
// can't schedule notifications with the tab fully closed without a push server).

import * as store from "./store.js";

export function checkReminder() {
    try {
        if (!store.getNotifEnabled()) return;
        if (!("Notification" in window) || Notification.permission !== "granted") return;
        const now = new Date();
        if (now.getHours() < store.getNotifHour()) return;
        const day = `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
        if (store.getReminderShownDay() === day) return;
        const target = store.getDailyTarget();
        const studied = store.studiedTodayTotal();
        if (studied >= target) return;
        store.setReminderShownDay(day);
        new Notification("IchiGo", {
            body: `Target belajar hari ini belum selesai (${studied}/${target}). Ayo lanjut belajar!`,
        });
    } catch { /* ignore */ }
}
