import SwiftUI
import Foundation

enum FlashcardLoadState: Equatable {
    case idle, loading, loaded, empty, comingSoon, failed(String)
}

enum FlashcardCardState: String, Codable {
    case new, learning, review, relearning
}

enum FlashcardGrade: Int, Codable, CaseIterable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var title: String {
        switch self {
        case .again: return "Ulang"
        case .hard: return "Susah"
        case .good: return "Bagus"
        case .easy: return "Mudah"
        }
    }
}

struct FlashcardSettings: Codable {
    var newCardsPerDay: Int = 35
    var maxReviewsPerDay: Int = 9999
    var learningStepsMinutes: [Double] = [1, 10]
    var relearningStepsMinutes: [Double] = [10]
    var desiredRetention: Double = 0.9
    var maximumIntervalDays: Int = 36500
    var graduatingIntervalDays: Int = 1
    var easyIntervalDays: Int = 4
    var leechThreshold: Int = 8
    // FSRS-6 default weights (21 parameter resmi Open Spaced Repetition)
    var fsrsWeights: [Double] = [
        0.2120, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.0010,
        1.8722, 0.1666, 0.7960, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014,
        1.8729, 0.5425, 0.0912, 0.0658, 0.1542
    ]
}

struct FlashcardProgress: Codable {
    let id: String
    let level: String
    let front: String
    let back: String
    var state: FlashcardCardState
    var dueDate: Date
    var stability: Double
    var difficulty: Double
    var reps: Int
    var lapses: Int
    var lastReview: Date?
    var scheduledDays: Int
    var learningStepIndex: Int

    init(id: String, level: String, front: String, back: String, state: FlashcardCardState, dueDate: Date, stability: Double, difficulty: Double, reps: Int, lapses: Int, lastReview: Date?, scheduledDays: Int, learningStepIndex: Int) {
        self.id = id
        self.level = level
        self.front = front
        self.back = back
        self.state = state
        self.dueDate = dueDate
        self.stability = stability
        self.difficulty = difficulty
        self.reps = reps
        self.lapses = lapses
        self.lastReview = lastReview
        self.scheduledDays = scheduledDays
        self.learningStepIndex = learningStepIndex
    }

    var isDue: Bool { dueDate <= Date() }
    var isMastered: Bool { state == .review && scheduledDays >= 21 }
}

struct FlashcardReviewLog: Codable, Identifiable {
    let id: UUID
    let cardId: String
    let levelId: String
    let grade: FlashcardGrade
    let reviewedAt: Date
    let nextDueDate: Date
    let state: FlashcardCardState
}

final class FlashcardProgressStore {
    private let key = "flashcard_progress_v1"
    private let legacyKey = "flashcardSRS_v2"
    private let corruptKey = "flashcard_progress_corrupt_backup_v1"

    func load() -> [String: FlashcardProgress] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [:] }
        do {
            return try JSONDecoder().decode([String: FlashcardProgress].self, from: data)
        } catch {
            UserDefaults.standard.set(data, forKey: corruptKey)
            UserDefaults.standard.removeObject(forKey: key)
            return [:]
        }
    }

    func save(_ progress: [String: FlashcardProgress]) {
        guard let encoded = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }

    func loadLegacy() -> [String: FlashcardProgress] {
        guard let data = UserDefaults.standard.data(forKey: legacyKey),
              let decoded = try? JSONDecoder().decode([String: FlashcardProgress].self, from: data) else {
            return [:]
        }
        return decoded
    }

    func clearLegacy() { UserDefaults.standard.removeObject(forKey: legacyKey) }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
}

final class FlashcardSettingsStore {
    private let key = "flashcard_settings_v1"

    func load() -> FlashcardSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(FlashcardSettings.self, from: data) else {
            return FlashcardSettings()
        }
        return decoded
    }

    func save(_ settings: FlashcardSettings) {
        guard let encoded = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }

    func reset() { UserDefaults.standard.removeObject(forKey: key) }
}

final class FlashcardReviewStore {
    private let key = "flashcard_reviews_v1"
    private let corruptKey = "flashcard_reviews_corrupt_backup_v1"
    private let maxStoredLogs = 20_000

    func load() -> [FlashcardReviewLog] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([FlashcardReviewLog].self, from: data)
        } catch {
            UserDefaults.standard.set(data, forKey: corruptKey)
            UserDefaults.standard.removeObject(forKey: key)
            return []
        }
    }

    func append(_ log: FlashcardReviewLog) {
        var logs = load()
        logs.append(log)
        if logs.count > maxStoredLogs { logs = Array(logs.suffix(maxStoredLogs)) }
        guard let encoded = try? JSONEncoder().encode(logs) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }

    func todayCount(levelId: String) -> Int {
        let calendar = Calendar.current
        let now = Date()
        return load().filter { $0.levelId == levelId && calendar.isDate($0.reviewedAt, inSameDayAs: now) }.count
    }

    func reset() { UserDefaults.standard.removeObject(forKey: key) }
}

struct FlashcardDataResetter {
    static func resetAll() {
        FlashcardProgressStore().reset()
        FlashcardSettingsStore().reset()
        FlashcardReviewStore().reset()
        UserDefaults.standard.removeObject(forKey: "flashcard_streak_v1")
        UserDefaults.standard.removeObject(forKey: "flashcard_last_study_date")
    }
}

// MARK: - FSRS Math (rumus resmi FSRS-6, dipakai Anki terbaru)
enum FSRSMath {
    // FSRS-6: decay & factor TIDAK lagi konstanta tetap seperti v4.5,
    // tapi diturunkan dari parameter w[20] (personal per-preset).
    // Formula resmi Open Spaced Repetition: factor = 0.9^(1/decay) - 1
    private static func decay(_ w: [Double]) -> Double {
        guard w.count > 20 else { return -0.5 } // fallback v4.5 kalau array kependekan
        return -max(w[20], 0.1)
    }

    private static func factor(_ w: [Double]) -> Double {
        let d = decay(w)
        return pow(0.9, 1.0 / d) - 1
    }

    // Retrievability: probabilitas kartu masih diingat setelah t hari
    static func retrievability(elapsedDays: Double, stability: Double, w: [Double]) -> Double {
        guard stability > 0 else { return 0 }
        return pow(1 + factor(w) * elapsedDays / stability, decay(w))
    }

    // Initial Stability - stability awal saat kartu baru pertama kali dinilai
    static func initialStability(grade: FlashcardGrade, w: [Double]) -> Double {
        max(w[grade.rawValue - 1], 0.1)
    }

    // Initial Difficulty - difficulty awal saat kartu baru pertama kali dinilai
    static func initialDifficulty(grade: FlashcardGrade, w: [Double]) -> Double {
        let d = w[4] - (exp(w[5] * Double(grade.rawValue - 1)) - 1)
        return clamp(d, min: 1, max: 10)
    }

    // Difficulty Update - dipakai tiap review.
    //
    // FSRS-6 memakai dua tahap yang sebelumnya belum lengkap di sini:
    //   1. linear damping - perubahan difficulty diperkecil saat difficulty
    //      sudah mendekati 10, memakai faktor (10 - D) / 9. Tanpa ini rumusnya
    //      masih pola FSRS-4.5.
    //   2. mean reversion - hasilnya ditarik sedikit ke arah difficulty awal
    //      untuk nilai "Easy", dengan bobot w[7].
    static func nextDifficulty(current: Double, grade: FlashcardGrade, w: [Double]) -> Double {
        let deltaDifficulty = -w[6] * (Double(grade.rawValue) - 3)
        let damped = current + deltaDifficulty * (10.0 - current) / 9.0
        let easyD0 = initialDifficulty(grade: .easy, w: w)
        let reverted = w[7] * easyD0 + (1 - w[7]) * damped
        return clamp(reverted, min: 1, max: 10)
    }

    // Stability after Recall - stability baru setelah berhasil ingat (grade Hard/Good/Easy)
    static func nextStabilityOnRecall(stability: Double, difficulty: Double, retrievability: Double, grade: FlashcardGrade, w: [Double]) -> Double {
        let hardPenalty = grade == .hard ? w[15] : 1.0
        let easyBonus = grade == .easy ? w[16] : 1.0
        let increase = exp(w[8]) * (11 - difficulty) * pow(stability, -w[9]) * (exp((1 - retrievability) * w[10]) - 1) * hardPenalty * easyBonus
        return max(stability * (1 + increase), 0.1)
    }

    // Stability after Forget - stability baru setelah lupa (grade Again, dari state review)
    static func nextStabilityOnForget(stability: Double, difficulty: Double, retrievability: Double, w: [Double]) -> Double {
        let s = w[11] * pow(difficulty, -w[12]) * (pow(stability + 1, w[13]) - 1) * exp((1 - retrievability) * w[14])
        return max(s, 0.1)
    }

    // Same-day Review: kalau kartu direview lagi di HARI YANG SAMA (elapsedDays == 0),
    // retrievability dianggap 1 (baru saja diingat), jadi stability increase dari recall
    // formula tetap valid tanpa perlu cabang khusus - retrievability(0, S) = (1+0)^decay = 1 secara alami.
    // Fungsi ini disediakan eksplisit agar terbaca jelas di titik pemanggilan scheduler.
    static func isSameDayReview(elapsedDays: Double) -> Bool {
        elapsedDays <= 0
    }

    // Interval Calculation - interval berikutnya (hari) berdasarkan target retention
    static func nextInterval(stability: Double, desiredRetention: Double, maximumDays: Int, w: [Double]) -> Int {
        let d = decay(w)
        let f = factor(w)
        let interval = (stability / f) * (pow(desiredRetention, 1.0 / d) - 1)
        return min(max(Int(interval.rounded()), 1), maximumDays)
    }

    private static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(value, maxValue))
    }
}

final class FlashcardReviewEngine {
    func review(card: FlashcardProgress, grade: FlashcardGrade, settings: FlashcardSettings) -> (FlashcardProgress, FlashcardReviewLog) {
        var updated = card
        let now = Date()
        let w = settings.fsrsWeights
        let elapsedDays = Double(elapsedReviewDays(from: card.lastReview, to: now))

        updated.reps += 1
        updated.lastReview = now

        switch card.state {

            // MARK: Kartu baru - masuk learning steps (kecuali Easy = langsung lulus)
        case .new:
            updated.stability = FSRSMath.initialStability(grade: grade, w: w)
            updated.difficulty = FSRSMath.initialDifficulty(grade: grade, w: w)

            if grade == .easy {
                graduate(&updated, toInterval: settings.easyIntervalDays, settings: settings, now: now)
            } else {
                updated.state = .learning
                // -1 = belum pernah masuk step; treat sebagai awal
                advanceStep(&updated, currentIndex: -1, steps: settings.learningStepsMinutes, grade: grade, settings: settings, now: now)
            }

            // MARK: Kartu learning (sedang di Merah, step berjalan di background)
        case .learning:
            updated.stability = FSRSMath.initialStability(grade: grade, w: w)
            updated.difficulty = FSRSMath.initialDifficulty(grade: grade, w: w)

            if grade == .easy {
                graduate(&updated, toInterval: settings.easyIntervalDays, settings: settings, now: now)
            } else {
                advanceStep(&updated, currentIndex: card.learningStepIndex, steps: settings.learningStepsMinutes, grade: grade, settings: settings, now: now)
            }

            // MARK: Kartu review - FSRS penuh berlaku di sini
        case .review:
            let r = FSRSMath.retrievability(elapsedDays: elapsedDays, stability: card.stability, w: w)

            if grade == .again {
                updated.lapses += 1
                updated.stability = FSRSMath.nextStabilityOnForget(stability: card.stability, difficulty: card.difficulty, retrievability: r, w: w)
                updated.difficulty = FSRSMath.nextDifficulty(current: card.difficulty, grade: grade, w: w)
                updated.state = .relearning
                advanceStep(&updated, currentIndex: -1, steps: settings.relearningStepsMinutes, grade: grade, settings: settings, now: now)
            } else {
                updated.stability = FSRSMath.nextStabilityOnRecall(stability: card.stability, difficulty: card.difficulty, retrievability: r, grade: grade, w: w)
                updated.difficulty = FSRSMath.nextDifficulty(current: card.difficulty, grade: grade, w: w)
                // Tetap Hijau, interval baru dihitung ulang
                graduateWithStability(&updated, settings: settings, now: now)
            }

            // MARK: Kartu relearning (Merah setelah lupa dari Hijau)
        case .relearning:
            if grade == .easy {
                graduate(&updated, toInterval: settings.easyIntervalDays, settings: settings, now: now)
            } else {
                if grade == .again { updated.lapses += 1 }
                advanceStep(&updated, currentIndex: card.learningStepIndex, steps: settings.relearningStepsMinutes, grade: grade, settings: settings, now: now)
            }
        }

        if updated.lapses >= settings.leechThreshold {
            updated.difficulty = 10
        }

        let log = FlashcardReviewLog(
            id: UUID(),
            cardId: updated.id,
            levelId: updated.level,
            grade: grade,
            reviewedAt: now,
            nextDueDate: updated.dueDate,
            state: updated.state
        )

        return (updated, log)
    }

    // MARK: - Step Progression (persis mekanisme Anki: Again/Hard/Good/Easy)
    // currentIndex: -1 berarti kartu baru pertama kali masuk step
    private func advanceStep(_ updated: inout FlashcardProgress, currentIndex: Int, steps: [Double], grade: FlashcardGrade, settings: FlashcardSettings, now: Date) {
        switch grade {
        case .again:
            // Reset ke step paling awal (paling lambat)
            updated.learningStepIndex = 0
            updated.dueDate = now.addingTimeInterval((steps[safe: 0] ?? 1) * 60)
            updated.scheduledDays = 0

        case .hard:
            // Diam di step yang sama (kalau baru pertama kali, mulai dari step 0)
            let idx = max(currentIndex, 0)
            updated.learningStepIndex = idx
            updated.dueDate = now.addingTimeInterval((steps[safe: idx] ?? 1) * 60)
            updated.scheduledDays = 0

        case .good:
            // Maju satu step. Kalau sudah habis step -> lulus ke Hijau dengan
            // interval kelulusan tetap (graduatingIntervalDays), lalu FSRS-6
            // mengambil alih di review-review berikutnya.
            let nextIdx = currentIndex + 1
            if nextIdx >= steps.count {
                graduate(&updated, toInterval: settings.graduatingIntervalDays, settings: settings, now: now)
            } else {
                updated.learningStepIndex = nextIdx
                updated.dueDate = now.addingTimeInterval(steps[nextIdx] * 60)
                updated.scheduledDays = 0
            }

        case .easy:
            // Selalu langsung lulus (ditangani sebelum manggil fungsi ini, fallback jaga-jaga)
            graduate(&updated, toInterval: settings.easyIntervalDays, settings: settings, now: now)
        }
    }

    // Kelulusan PERTAMA dari learning/relearning ("cara A" ala Anki): pakai
    // interval kelulusan tetap — Bagus -> graduatingIntervalDays (1 hari, jadi
    // kartu hari-1 muncul lagi di hari-2), Mudah -> easyIntervalDays (4 hari).
    // Sesudah lulus, FSRS-6 penuh (graduateWithStability) yang menjadwalkan setiap
    // review berikutnya.
    private func graduate(_ updated: inout FlashcardProgress, toInterval days: Int, settings: FlashcardSettings, now: Date) {
        let clamped = min(max(days, 1), settings.maximumIntervalDays)
        updated.state = .review
        updated.learningStepIndex = 0
        updated.scheduledDays = clamped
        updated.dueDate = Calendar.current.date(byAdding: .day, value: clamped, to: now) ?? now
    }

    // Interval review dihitung ulang dari stability (rumus FSRS-6). Dipakai di
    // SETIAP review kartu Hijau, bukan untuk kelulusan pertama dari learning.
    private func graduateWithStability(_ updated: inout FlashcardProgress, settings: FlashcardSettings, now: Date) {
        let days = FSRSMath.nextInterval(stability: updated.stability, desiredRetention: settings.desiredRetention, maximumDays: settings.maximumIntervalDays, w: settings.fsrsWeights)
        updated.state = .review
        updated.learningStepIndex = 0
        updated.scheduledDays = days
        updated.dueDate = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
    }

    private func elapsedReviewDays(from lastReview: Date?, to now: Date) -> Int {
        guard let lastReview else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: lastReview, to: now).day ?? 0)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - FlashcardStore (Vocab + Grammar sebagai sumber)
@MainActor
final class FlashcardStore: ObservableObject {
    struct LevelStats { let total: Int; let mastered: Int; let due: Int; let progress: Double }

    // Decks built from the Vocabulary / Grammar datasets.
    @Published private(set) var deckItemsPerLevel: [String: [FlashcardDeckCard]] = [:]
    @Published private(set) var deckLevelStats: [String: LevelStats] = [:]
    @Published var deckStateByLevel: [String: FlashcardLoadState] = [:]

    @Published var lastError: String?

    let progressStore = FlashcardProgressStore()
    let reviewStore = FlashcardReviewStore()
    let settingsStore = FlashcardSettingsStore()
    let analyticsStore = FlashcardAnalyticsStore()
    let syncMetadataStore = FlashcardSyncMetadataStore()
    let dayBoundaryStore = FlashcardDayBoundaryStore()
    let newCardTracker = FlashcardDailyNewCardTracker()

    private let retentionValidator = FSRSRetentionValidator()
    private(set) var progressMap: [String: FlashcardProgress]
    var settings: FlashcardSettings

    init() {
        progressMap = progressStore.load()
        if progressMap.isEmpty {
            let legacy = progressStore.loadLegacy()
            if !legacy.isEmpty {
                progressMap = legacy
                progressStore.save(legacy)
                progressStore.clearLegacy()
            }
        }
        settings = settingsStore.load()
    }

    // MARK: - Deck loading (Vocabulary / Grammar)
    func loadDeck(mode: FlashcardMode, levelId: String, jsonFile: String) async {
        _ = dayBoundaryStore.markDailyResetIfNeeded()
        let key = flashcardLevelKey(mode: mode, levelId: levelId)
        if deckItemsPerLevel[key] != nil { return }
        deckStateByLevel[key] = .loading
        let items = await Task.detached(priority: .userInitiated) {
            FlashcardDeckLoader.load(mode: mode, jsonFile: jsonFile)
        }.value
        deckItemsPerLevel[key] = items
        deckStateByLevel[key] = items.isEmpty ? .empty : .loaded
        refreshDeckStats(key: key)
    }

    func deckStats(mode: FlashcardMode, levelId: String) -> LevelStats? {
        deckLevelStats[flashcardLevelKey(mode: mode, levelId: levelId)]
    }

    func refreshDeckStats(key: String) {
        guard let items = deckItemsPerLevel[key] else { return }
        let total = items.count
        let mastered = items.filter { (progressMap[$0.id] ?? FlashcardProgress(deckCard: $0, levelKey: key)).isMastered }.count
        let due = items.filter { (progressMap[$0.id] ?? FlashcardProgress(deckCard: $0, levelKey: key)).isDue }.count
        deckLevelStats[key] = LevelStats(total: total, mastered: mastered, due: due, progress: total == 0 ? 0 : Double(mastered) / Double(total))
    }

    func deckProgress(for card: FlashcardDeckCard, levelKey: String) -> FlashcardProgress {
        progressMap[card.id] ?? FlashcardProgress(deckCard: card, levelKey: levelKey)
    }

    // MARK: - Shared progress logic
    func saveProgress(_ progress: FlashcardProgress) {
        let validation = retentionValidator.validate(progress: progress)
        if !validation.isValid { lastError = validation.issues.joined(separator: ", ") }
        progressMap[progress.id] = progress
        progressStore.save(progressMap)
        syncMetadataStore.markUpdated(cardId: progress.id, levelId: progress.level)
    }

    func appendReviewLog(_ log: FlashcardReviewLog) {
        reviewStore.append(log)
        analyticsStore.record(log)
    }

    func updateStreakIfNeeded() { dayBoundaryStore.registerStudy() }
    var currentStreak: Int { dayBoundaryStore.currentStreak }
    var analyticsSummary: FlashcardAnalyticsSummary { analyticsStore.loadSummary() }
    var masteredTotal: Int { progressMap.values.filter(\.isMastered).count }

    var studiedTodayTotal: Int {
        FlashcardMode.allCases.reduce(0) { total, mode in
            total + mode.levels().reduce(0) { $0 + reviewStore.todayCount(levelId: flashcardLevelKey(mode: mode, levelId: $1.id)) }
        }
    }

    func dueTodayTotal(mode: FlashcardMode, levelId: String) -> Int {
        deckStats(mode: mode, levelId: levelId)?.due ?? 0
    }

    /// Beban kartu untuk hari ini, dijumlahkan semua dek yang sudah dimuat.
    ///
    /// Ini mencerminkan persis apa yang akan disajikan sesi belajar (lihat
    /// `FlashcardDeckQueueBuilder.build`): kartu pengulangan yang jatuh tempo,
    /// ditambah sisa kartu baru hari ini. Jatah kartu baru dihitung per dek —
    /// tiap level punya jatah `target` sendiri — jadi angka ini bisa lebih besar
    /// dari `target` karena pengulangan menumpuk di atas kartu baru. `target`
    /// datang dari "daily_target" yang dipilih pengguna di Pengaturan.
    func dailyDueTotal(target: Int) -> Int {
        let now = Date()
        return FlashcardMode.allCases.reduce(0) { total, mode in
            total + mode.levels().reduce(0) { sub, level in
                let key = flashcardLevelKey(mode: mode, levelId: level.id)
                guard let items = deckItemsPerLevel[key] else { return sub }
                // Pengulangan: kartu yang SUDAH pernah dipelajari dan kini jatuh tempo.
                let dueReviews = items.filter { item in
                    guard let progress = progressMap[item.id] else { return false }
                    return progress.dueDate <= now
                }.count
                // Sisa kartu baru hari ini untuk dek ini (jatah per dek = target).
                let untouched = items.filter { progressMap[$0.id] == nil }.count
                let newStudied = newCardTracker.studiedTodayCount(levelKey: key)
                let newRemaining = min(untouched, max(0, target - newStudied))
                return sub + dueReviews + newRemaining
            }
        }
    }
}

// MARK: - Flashcard Mode (Vocabulary / Grammar)
enum FlashcardMode: String, CaseIterable, Identifiable {
    case vocabulary
    case grammar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vocabulary: return "Vocabulary"
        case .grammar: return "Grammar"
        }
    }

    var subtitle: String {
        switch self {
        case .vocabulary: return "Hafalkan kosakata"
        case .grammar: return "Hafalkan pola kalimat"
        }
    }

    var icon: String {
        switch self {
        case .vocabulary: return "book.fill"
        case .grammar: return "text.book.closed.fill"
        }
    }

    var color: Color {
        switch self {
        case .vocabulary: return AppTheme.blue
        case .grammar: return AppTheme.violetDeep
        }
    }

    /// Gradien ikon di layar pemilih, nilainya persis dari desain.
    var gradient: [Color] {
        switch self {
        case .vocabulary: return [AppTheme.blueLight, AppTheme.blue]
        case .grammar: return [AppTheme.violet, AppTheme.violetDeep]
        }
    }

    func levels() -> [FlashcardLevelInfo] {
        switch self {
        case .vocabulary:
            return vocabularyLevels.map {
                FlashcardLevelInfo(id: $0.id, name: $0.name, description: $0.description,
                                   color: $0.color, bgColor: $0.bgColor,
                                   isLocked: $0.isLocked, jsonFile: $0.jsonFile)
            }
        case .grammar:
            return grammarLevels.map {
                FlashcardLevelInfo(id: $0.id, name: $0.name, description: $0.description,
                                   color: $0.color, bgColor: $0.bgColor,
                                   isLocked: $0.isLocked, jsonFile: $0.jsonFile)
            }
        }
    }
}

struct FlashcardLevelInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let color: Color
    let bgColor: Color
    let isLocked: Bool
    let jsonFile: String
}

func flashcardLevelKey(mode: FlashcardMode, levelId: String) -> String {
    "\(mode.rawValue)_\(levelId)"
}

// MARK: - Kartu generik untuk sesi flashcard
struct FlashcardDeckCard: Identifiable, Hashable {
    let id: String
    let mode: FlashcardMode
    let front: String          // Kanji (vocab) / Pola (grammar) - selalu tampil
    let revealedTitle: String  // Hiragana (vocab) / Arti singkat (grammar)
    let revealedBody: String   // Arti (vocab) / Penjelasan (grammar)
    let revealedTag: String    // Jenis kata (vocab) / Struktur (grammar)

    init(vocab item: VocabularyItem) {
        id = item.id
        mode = .vocabulary
        front = item.kanji
        revealedTitle = item.hiragana
        revealedBody = item.arti
        revealedTag = item.jenisKata
    }

    init(grammar item: GrammarItem) {
        id = item.id
        mode = .grammar
        front = item.pattern
        revealedTitle = item.meaning
        revealedBody = item.explanation.isEmpty ? item.meaning : item.explanation
        revealedTag = item.structure.isEmpty ? item.tags.joined(separator: " · ") : item.structure
    }
}

enum FlashcardDeckLoader {
    /// A deck that cannot be read is reported to the caller as an empty deck: the
    /// review screen already has a state for "nothing to review", and the reason
    /// is logged by `ResourceLoader`. Browsing screens, which must distinguish a
    /// missing file from an empty level, use the throwing loaders directly.
    static func load(mode: FlashcardMode, jsonFile: String) -> [FlashcardDeckCard] {
        switch mode {
        case .vocabulary:
            return ResourceLoader.loadArrayOrEmpty(VocabularyItem.self, from: jsonFile)
                .map { FlashcardDeckCard(vocab: $0) }
        case .grammar:
            return ResourceLoader.loadArrayOrEmpty(GrammarItem.self, from: jsonFile)
                .map { FlashcardDeckCard(grammar: $0) }
        }
    }
}

extension FlashcardProgress {
    init(deckCard: FlashcardDeckCard, levelKey: String) {
        self.init(
            id: deckCard.id,
            level: levelKey,
            front: deckCard.front,
            back: deckCard.revealedBody,
            state: .new,
            dueDate: Date(),
            stability: 0.1,
            difficulty: 5.0,
            reps: 0,
            lapses: 0,
            lastReview: nil,
            scheduledDays: 0,
            learningStepIndex: 0
        )
    }
}

final class FlashcardDeckQueueBuilder {
    func build(levelKey: String, items: [FlashcardDeckCard], progress: [String: FlashcardProgress], settings: FlashcardSettings, newCardsAlreadyStudiedToday: Int = 0) -> [FlashcardDeckCard] {
        let now = Date()
        var seen = Set<String>()

        let dueItems = items
            .filter { item in
                guard let card = progress[item.id] else { return false }
                return card.dueDate <= now
            }
            .sorted { lhs, rhs in
                let left = progress[lhs.id]
                let right = progress[rhs.id]
                let leftOverdue = now.timeIntervalSince(left?.dueDate ?? now)
                let rightOverdue = now.timeIntervalSince(right?.dueDate ?? now)
                if leftOverdue != rightOverdue { return leftOverdue > rightOverdue }
                return (left?.lapses ?? 0) > (right?.lapses ?? 0)
            }
            .prefix(settings.maxReviewsPerDay)

        var queue: [FlashcardDeckCard] = []
        for item in dueItems where seen.insert(item.id).inserted { queue.append(item) }

        // Limit KARTU BARU strict 35/hari, dikurangi yang sudah dipelajari hari ini di sesi lain
        let newLimit = max(0, settings.newCardsPerDay - newCardsAlreadyStudiedToday)
        let newItems = items.filter { progress[$0.id] == nil }.prefix(newLimit)
        for item in newItems where seen.insert(item.id).inserted { queue.append(item) }

        return queue
    }
}

// MARK: - Day Boundary & Streak
struct FlashcardDayKey: Codable, Equatable, Hashable {
    let year: Int
    let month: Int
    let day: Int
    let timezoneIdentifier: String

    static func today(calendar: Calendar = .current, date: Date = Date()) -> FlashcardDayKey {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return FlashcardDayKey(
            year: components.year ?? 1970,
            month: components.month ?? 1,
            day: components.day ?? 1,
            timezoneIdentifier: calendar.timeZone.identifier
        )
    }

    var compact: String {
        let m = String(format: "%02d", month)
        let d = String(format: "%02d", day)
        return "\(year)-\(m)-\(d)-\(timezoneIdentifier)"
    }
}

final class FlashcardDayBoundaryStore {
    private let lastStudyDayKey = "flashcard_last_study_day_key_v1"
    private let lastResetDayKey = "flashcard_last_reset_day_key_v1"
    private let streakKey = "flashcard_streak_v1"

    func registerStudy(date: Date = Date(), calendar: Calendar = .current) {
        let today = FlashcardDayKey.today(calendar: calendar, date: date)
        let previous = UserDefaults.standard.string(forKey: lastStudyDayKey)

        if previous == today.compact { return }

        if let previous, isYesterday(previousKey: previous, today: today, calendar: calendar) {
            UserDefaults.standard.set(currentStreak + 1, forKey: streakKey)
        } else {
            UserDefaults.standard.set(1, forKey: streakKey)
        }

        UserDefaults.standard.set(today.compact, forKey: lastStudyDayKey)
        UserDefaults.standard.set(date, forKey: "flashcard_last_study_date")
    }

    func markDailyResetIfNeeded(date: Date = Date(), calendar: Calendar = .current) -> Bool {
        let today = FlashcardDayKey.today(calendar: calendar, date: date)
        let lastReset = UserDefaults.standard.string(forKey: lastResetDayKey)
        guard lastReset != today.compact else { return false }
        UserDefaults.standard.set(today.compact, forKey: lastResetDayKey)
        return true
    }

    var currentStreak: Int {
        UserDefaults.standard.integer(forKey: streakKey)
    }

    private func isYesterday(previousKey: String, today: FlashcardDayKey, calendar: Calendar) -> Bool {
        let parts = previousKey.split(separator: "-")
        guard parts.count >= 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return false
        }

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        guard let previousDate = calendar.date(from: dateComponents),
              let todayDate = calendar.date(from: DateComponents(year: today.year, month: today.month, day: today.day)),
              let yesterday = calendar.date(byAdding: .day, value: -1, to: todayDate) else {
            return false
        }

        return calendar.isDate(previousDate, inSameDayAs: yesterday)
    }
}

// MARK: - Analytics
struct FlashcardAnalyticsSummary: Codable {
    var totalReviews: Int
    var againCount: Int
    var hardCount: Int
    var goodCount: Int
    var easyCount: Int
    var lastReviewedAt: Date?

    var accuracy: Double {
        guard totalReviews > 0 else { return 0 }
        let success = hardCount + goodCount + easyCount
        return Double(success) / Double(totalReviews)
    }
}

final class FlashcardAnalyticsStore {
    private let summaryKey = "flashcard_analytics_summary_v1"
    private let dailyPrefix = "flashcard_analytics_daily_v1_"

    func record(_ log: FlashcardReviewLog) {
        var summary = loadSummary()
        summary.totalReviews += 1
        summary.lastReviewedAt = log.reviewedAt

        switch log.grade {
        case .again: summary.againCount += 1
        case .hard: summary.hardCount += 1
        case .good: summary.goodCount += 1
        case .easy: summary.easyCount += 1
        }

        saveSummary(summary)
        saveDaily(log)
    }

    func loadSummary() -> FlashcardAnalyticsSummary {
        guard let data = UserDefaults.standard.data(forKey: summaryKey),
              let decoded = try? JSONDecoder().decode(FlashcardAnalyticsSummary.self, from: data) else {
            return FlashcardAnalyticsSummary(totalReviews: 0, againCount: 0, hardCount: 0, goodCount: 0, easyCount: 0, lastReviewedAt: nil)
        }
        return decoded
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: summaryKey)
    }

    private func saveSummary(_ summary: FlashcardAnalyticsSummary) {
        guard let data = try? JSONEncoder().encode(summary) else { return }
        UserDefaults.standard.set(data, forKey: summaryKey)
    }

    private func saveDaily(_ log: FlashcardReviewLog) {
        let key = dailyPrefix + FlashcardDayKey.today(date: log.reviewedAt).compact
        var logs = loadDaily(key: key)
        logs.append(log)
        if logs.count > 2_000 { logs = Array(logs.suffix(2_000)) }
        guard let data = try? JSONEncoder().encode(logs) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func loadDaily(key: String) -> [FlashcardReviewLog] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FlashcardReviewLog].self, from: data) else {
            return []
        }
        return decoded
    }
}

// MARK: - Validator
struct FSRSRetentionValidationResult {
    let isValid: Bool
    let issues: [String]
}

struct FSRSRetentionValidator {
    func validate(progress: FlashcardProgress, now: Date = Date()) -> FSRSRetentionValidationResult {
        var issues: [String] = []

        if progress.scheduledDays < 0 { issues.append("scheduledDays negative") }
        if progress.stability < 0.1 { issues.append("stability too low") }
        if progress.difficulty < 1 || progress.difficulty > 10 { issues.append("difficulty out of range") }
        if progress.state == .review && progress.dueDate < (progress.lastReview ?? now) { issues.append("review dueDate earlier than lastReview") }
        if progress.reps < 0 || progress.lapses < 0 { issues.append("counter negative") }

        return FSRSRetentionValidationResult(isValid: issues.isEmpty, issues: issues)
    }
}

// MARK: - Sync Metadata
struct FlashcardSyncRecord: Codable, Identifiable {
    let id: String
    let levelId: String
    let localUpdatedAt: Date
    let version: Int
    let deleted: Bool
}

final class FlashcardSyncMetadataStore {
    private let key = "flashcard_sync_metadata_v1"

    func load() -> [String: FlashcardSyncRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: FlashcardSyncRecord].self, from: data) else {
            return [:]
        }
        return decoded
    }

    func markUpdated(cardId: String, levelId: String, date: Date = Date()) {
        var records = load()
        let currentVersion = records[cardId]?.version ?? 0
        records[cardId] = FlashcardSyncRecord(id: cardId, levelId: levelId, localUpdatedAt: date, version: currentVersion + 1, deleted: false)
        save(records)
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func save(_ records: [String: FlashcardSyncRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}


// MARK: - Daily New Card Tracker (strict limit lintas sesi)
final class FlashcardDailyNewCardTracker {
    private let prefix = "flashcard_new_today_"

    private func key(levelKey: String, day: String) -> String { "\(prefix)\(levelKey)_\(day)" }

    func studiedTodayCount(levelKey: String) -> Int {
        let day = FlashcardDayKey.today().compact
        let ids = UserDefaults.standard.stringArray(forKey: key(levelKey: levelKey, day: day)) ?? []
        return ids.count
    }

    func markStudied(cardId: String, levelKey: String) {
        let day = FlashcardDayKey.today().compact
        let k = key(levelKey: levelKey, day: day)
        var ids = Set(UserDefaults.standard.stringArray(forKey: k) ?? [])
        guard ids.insert(cardId).inserted else { return }
        UserDefaults.standard.set(Array(ids), forKey: k)
    }
}
