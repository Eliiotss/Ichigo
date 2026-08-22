// FSRS-6 scheduler — a faithful JavaScript port of the iOS app's `FSRSMath` and
// `FlashcardReviewEngine` (see Sources/AppFeature/FlashcardModel.swift). Same
// official 21-parameter weights, same learning steps ("cara A"): the
// review math is identical so scheduling is consistent with the native app.

export const GRADE = { again: 1, hard: 2, good: 3, easy: 4 };
export const STATE = { new: "new", learning: "learning", review: "review", relearning: "relearning" };

const DAY_MS = 86_400_000;
const MIN_MS = 60_000;

export const SETTINGS = {
    newCardsPerDay: 20,          // daily target (matches the app's daily_target default)
    learningStepsMinutes: [1, 10],
    relearningStepsMinutes: [10],
    desiredRetention: 0.9,
    maximumIntervalDays: 36500,
    graduatingIntervalDays: 1,
    easyIntervalDays: 4,
    leechThreshold: 8,
    // FSRS-6 default weights (official Open Spaced Repetition, 21 parameters).
    fsrsWeights: [
        0.2120, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.0010,
        1.8722, 0.1666, 0.7960, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014,
        1.8729, 0.5425, 0.0912, 0.0658, 0.1542,
    ],
};

const clamp = (v, lo, hi) => Math.max(lo, Math.min(v, hi));

function decay(w) { return -Math.max(w[20] ?? 0.5, 0.1); }
function factor(w) { return Math.pow(0.9, 1 / decay(w)) - 1; }

const FSRS = {
    retrievability(elapsedDays, stability, w) {
        if (stability <= 0) return 0;
        return Math.pow(1 + factor(w) * elapsedDays / stability, decay(w));
    },
    initialStability(grade, w) { return Math.max(w[grade - 1], 0.1); },
    initialDifficulty(grade, w) {
        return clamp(w[4] - (Math.exp(w[5] * (grade - 1)) - 1), 1, 10);
    },
    nextDifficulty(current, grade, w) {
        const delta = -w[6] * (grade - 3);
        const damped = current + delta * (10 - current) / 9;
        const easyD0 = this.initialDifficulty(GRADE.easy, w);
        return clamp(w[7] * easyD0 + (1 - w[7]) * damped, 1, 10);
    },
    nextStabilityOnRecall(S, D, R, grade, w) {
        const hardPenalty = grade === GRADE.hard ? w[15] : 1;
        const easyBonus = grade === GRADE.easy ? w[16] : 1;
        const inc = Math.exp(w[8]) * (11 - D) * Math.pow(S, -w[9]) *
            (Math.exp((1 - R) * w[10]) - 1) * hardPenalty * easyBonus;
        return Math.max(S * (1 + inc), 0.1);
    },
    nextStabilityOnForget(S, D, R, w) {
        const s = w[11] * Math.pow(D, -w[12]) * (Math.pow(S + 1, w[13]) - 1) *
            Math.exp((1 - R) * w[14]);
        return Math.max(s, 0.1);
    },
    nextInterval(S, retention, maxDays, w) {
        const interval = (S / factor(w)) * (Math.pow(retention, 1 / decay(w)) - 1);
        return Math.min(Math.max(Math.round(interval), 1), maxDays);
    },
};

/// Creates a fresh (unreviewed) progress record for a deck card.
export function newProgress(card) {
    return {
        id: card.id, level: card.level, front: card.front, back: card.back,
        state: STATE.new, dueDate: Date.now(), stability: 0, difficulty: 0,
        reps: 0, lapses: 0, lastReview: null, scheduledDays: 0, learningStepIndex: 0,
    };
}

export function isDue(p, now = Date.now()) { return p.dueDate <= now; }
export function isMastered(p) { return p.state === STATE.review && p.scheduledDays >= 21; }

function elapsedReviewDays(lastReview, now) {
    if (!lastReview) return 0;
    return Math.max(0, Math.floor((now - lastReview) / DAY_MS));
}

function graduate(p, days, s, now) {
    const clamped = clamp(days, 1, s.maximumIntervalDays);
    p.state = STATE.review;
    p.learningStepIndex = 0;
    p.scheduledDays = clamped;
    p.dueDate = now + clamped * DAY_MS;
}
function graduateWithStability(p, s, now) {
    const days = FSRS.nextInterval(p.stability, s.desiredRetention, s.maximumIntervalDays, s.fsrsWeights);
    p.state = STATE.review;
    p.learningStepIndex = 0;
    p.scheduledDays = days;
    p.dueDate = now + days * DAY_MS;
}
function advanceStep(p, currentIndex, steps, grade, s, now) {
    if (grade === GRADE.again) {
        p.learningStepIndex = 0;
        p.dueDate = now + (steps[0] ?? 1) * MIN_MS;
        p.scheduledDays = 0;
    } else if (grade === GRADE.hard) {
        const idx = Math.max(currentIndex, 0);
        p.learningStepIndex = idx;
        p.dueDate = now + (steps[idx] ?? 1) * MIN_MS;
        p.scheduledDays = 0;
    } else if (grade === GRADE.good) {
        const nextIdx = currentIndex + 1;
        if (nextIdx >= steps.length) {
            graduate(p, s.graduatingIntervalDays, s, now);
        } else {
            p.learningStepIndex = nextIdx;
            p.dueDate = now + steps[nextIdx] * MIN_MS;
            p.scheduledDays = 0;
        }
    } else { // easy
        graduate(p, s.easyIntervalDays, s, now);
    }
}

/// Applies a grade to a card and returns the updated progress (mutating a copy).
export function reviewCard(card, grade, s = SETTINGS, now = Date.now()) {
    const p = { ...card };
    const w = s.fsrsWeights;
    const elapsed = elapsedReviewDays(card.lastReview, now);
    p.reps += 1;
    p.lastReview = now;

    switch (card.state) {
        case STATE.new:
            p.stability = FSRS.initialStability(grade, w);
            p.difficulty = FSRS.initialDifficulty(grade, w);
            if (grade === GRADE.easy) graduate(p, s.easyIntervalDays, s, now);
            else { p.state = STATE.learning; advanceStep(p, -1, s.learningStepsMinutes, grade, s, now); }
            break;
        case STATE.learning:
            p.stability = FSRS.initialStability(grade, w);
            p.difficulty = FSRS.initialDifficulty(grade, w);
            if (grade === GRADE.easy) graduate(p, s.easyIntervalDays, s, now);
            else advanceStep(p, card.learningStepIndex, s.learningStepsMinutes, grade, s, now);
            break;
        case STATE.review: {
            const R = FSRS.retrievability(elapsed, card.stability, w);
            if (grade === GRADE.again) {
                p.lapses += 1;
                p.stability = FSRS.nextStabilityOnForget(card.stability, card.difficulty, R, w);
                p.difficulty = FSRS.nextDifficulty(card.difficulty, grade, w);
                p.state = STATE.relearning;
                advanceStep(p, -1, s.relearningStepsMinutes, grade, s, now);
            } else {
                p.stability = FSRS.nextStabilityOnRecall(card.stability, card.difficulty, R, grade, w);
                p.difficulty = FSRS.nextDifficulty(card.difficulty, grade, w);
                graduateWithStability(p, s, now);
            }
            break;
        }
        case STATE.relearning:
            if (grade === GRADE.easy) graduate(p, s.easyIntervalDays, s, now);
            else {
                if (grade === GRADE.again) p.lapses += 1;
                advanceStep(p, card.learningStepIndex, s.relearningStepsMinutes, grade, s, now);
            }
            break;
    }

    if (p.lapses >= s.leechThreshold) p.difficulty = 10;
    return p;
}

/// Preview of the next interval for each grade, for the buttons' captions.
export function intervalPreview(card, s = SETTINGS, now = Date.now()) {
    const label = (p) => {
        const ms = p.dueDate - now;
        if (ms < DAY_MS) {
            const mins = Math.max(1, Math.round(ms / MIN_MS));
            return mins < 60 ? `${mins} mnt` : `${Math.round(mins / 60)} jam`;
        }
        const days = Math.round(ms / DAY_MS);
        return days < 30 ? `${days} hr` : days < 365 ? `${Math.round(days / 30)} bln` : `${(days / 365).toFixed(1)} thn`;
    };
    return {
        again: label(reviewCard(card, GRADE.again, s, now)),
        hard: label(reviewCard(card, GRADE.hard, s, now)),
        good: label(reviewCard(card, GRADE.good, s, now)),
        easy: label(reviewCard(card, GRADE.easy, s, now)),
    };
}
