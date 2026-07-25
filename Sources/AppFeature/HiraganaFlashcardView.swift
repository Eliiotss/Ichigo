import SwiftUI

// MARK: - Progress Store (25x mastery)
class HiraganaStore: ObservableObject {
    @Published var hiraganaCount: [String: Int] = [:]
    @Published var katakanaCount: [String: Int] = [:]

    private let hiraganaKey = "hiraganaCount"
    private let katakanaKey = "katakanaCount"
    static let masteryThreshold = 25
    private let wrongPenalty = 2

    init() { load() }

    func addCorrect(_ kana: String, isKatakana: Bool) {
        if isKatakana {
            katakanaCount[kana] = min(Self.masteryThreshold, katakanaCount[kana, default: 0] + 1)
        } else {
            hiraganaCount[kana] = min(Self.masteryThreshold, hiraganaCount[kana, default: 0] + 1)
        }
        save()
    }

    func addWrong(_ kana: String, isKatakana: Bool) {
        if isKatakana {
            katakanaCount[kana] = max(0, katakanaCount[kana, default: 0] - wrongPenalty)
        } else {
            hiraganaCount[kana] = max(0, hiraganaCount[kana, default: 0] - wrongPenalty)
        }
        save()
    }

    func correctCount(_ kana: String, isKatakana: Bool) -> Int {
        let dict = isKatakana ? katakanaCount : hiraganaCount
        return min(dict[kana, default: 0], Self.masteryThreshold)
    }

    func barProgress(_ kana: String, isKatakana: Bool) -> Double {
        Double(correctCount(kana, isKatakana: isKatakana)) / Double(Self.masteryThreshold)
    }

    func isMastered(_ kana: String, isKatakana: Bool) -> Bool {
        correctCount(kana, isKatakana: isKatakana) >= Self.masteryThreshold
    }

    func masteredCount(flat: [KanaItem], isKatakana: Bool) -> Int {
        flat.filter { isMastered($0.kana, isKatakana: isKatakana) }.count
    }

    func progressPercent(flat: [KanaItem], isKatakana: Bool) -> Double {
        guard !flat.isEmpty else { return 0 }
        return Double(masteredCount(flat: flat, isKatakana: isKatakana)) / Double(flat.count)
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(hiraganaCount) {
            UserDefaults.standard.set(encoded, forKey: hiraganaKey)
        }
        if let encoded = try? JSONEncoder().encode(katakanaCount) {
            UserDefaults.standard.set(encoded, forKey: katakanaKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: hiraganaKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            hiraganaCount = decoded
        }
        if let data = UserDefaults.standard.data(forKey: katakanaKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            katakanaCount = decoded
        }
    }
}

// MARK: - Flash Question
struct FlashQuestion {
    let card: KanaItem
    let choices: [String]
    let correctAnswer: String
}

// MARK: - Flashcard View
struct HiraganaFlashcardView: View {
    @ObservedObject var store: HiraganaStore
    let isKatakana: Bool
    let deckFlat: [KanaItem]
    let progressFlat: [KanaItem]
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var deck: [KanaItem] = []
    @State private var currentIndex: Int = 0
    @State private var sessionCorrect: Int = 0
    @State private var finished: Bool = false
    @State private var selectedAnswer: String? = nil
    @State private var isAnswered: Bool = false
    @State private var currentQuestion: FlashQuestion? = nil

    let sessionSize = 25

    var accentColor: Color { isKatakana ? AppTheme.indigo : AppTheme.blue }

    var progressValue: Double {
        guard !deck.isEmpty else { return 0 }
        return Double(currentIndex) / Double(deck.count)
    }

    var totalProgress: Double {
        store.progressPercent(flat: progressFlat, isKatakana: isKatakana)
    }

    /// Gradien kartu soal: biru untuk hiragana, indigo untuk katakana.
    var cardBgColors: [Color] {
        isKatakana ? [AppTheme.indigo, AppTheme.indigoDeep] : [AppTheme.blueLight, AppTheme.blue]
    }

    var body: some View {
        VStack(spacing: 14) {
            // Header sendiri, bukan navigation bar, supaya judul dan tombol
            // Tutup tetap diam di tempat.
            HStack {
                Text("Flashcard \(isKatakana ? "Katakana" : "Hiragana")")
                    .font(AppTheme.rounded(22, .heavy))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Spacer()

                Button { dismiss() } label: {
                    Text("Tutup")
                        .font(AppTheme.rounded(15, .semibold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                        .padding(.horizontal, 20)
                        .frame(height: 40)
                        .background(AppTheme.surface(colorScheme))
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.softShadow(colorScheme), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Group {
                if finished {
                    finishedView
                } else if deckFlat.isEmpty {
                    emptyStateView
                } else if deck.isEmpty || currentQuestion == nil {
                    ProgressView("Memuat...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    questionContent
                }
            }
        }
        .background(AppTheme.screenBackground(colorScheme).ignoresSafeArea())
        .onAppear { buildDeck() }
    }

    // MARK: - Empty State
    var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(AppTheme.rounded(42, .semibold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
            Text("Belum ada data huruf")
                .font(AppTheme.rounded(18, .bold))
            Text("Cek file JSON Hiragana/Katakana atau sumber deck flashcard.")
                .font(AppTheme.rounded(13))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
    }

    // MARK: - Isi Soal
    var questionContent: some View {
        VStack(spacing: 16) {
            statsCard

            if let question = currentQuestion {
                // Kartu soal: gradien biru dengan hurufnya berwarna putih.
                ZStack {
                    LinearGradient(colors: cardBgColors, startPoint: .topLeading, endPoint: .bottomTrailing)

                    GeometryReader { geo in
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 170, height: 170)
                            .offset(x: geo.size.width - 95, y: -55)

                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 150, height: 150)
                            .offset(x: -55, y: geo.size.height - 80)
                    }

                    Text(question.card.kana)
                        .font(AppTheme.rounded(120, .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous))
                .shadow(color: accentColor.opacity(0.28), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 20)

                Text("Pilih bacaan yang benar")
                    .font(AppTheme.rounded(14))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(question.choices, id: \.self) { choice in
                        ChoiceButton(
                            label: choice,
                            correct: question.correctAnswer,
                            selected: selectedAnswer,
                            isAnswered: isAnswered
                        ) {
                            handleAnswer(choice, correct: question.correctAnswer, card: question.card)
                        }
                    }
                }
                .padding(.horizontal, 20)

                if isAnswered {
                    Button(action: nextCard) {
                        Text(currentIndex + 1 >= deck.count ? "Selesai" : "Lanjut →")
                            .font(AppTheme.rounded(16, .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: accentColor.opacity(0.35), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
            }

            Spacer(minLength: 12)
        }
        .animation(.easeInOut(duration: 0.2), value: isAnswered)
    }

    /// Kartu putih berisi kemajuan sesi dan kemajuan hafalan keseluruhan.
    private var statsCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Kartu \(currentIndex + 1) / \(deck.count)")
                    .font(AppTheme.rounded(15, .bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Spacer()

                Text("\(sessionCorrect) benar")
                    .font(AppTheme.rounded(15, .bold))
                    .foregroundColor(accentColor)
            }

            progressBar(value: progressValue, color: accentColor, height: 6)

            HStack {
                Text("Total Hafalan")
                    .font(AppTheme.rounded(13))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))

                Spacer()

                Text("\(store.masteredCount(flat: progressFlat, isKatakana: isKatakana)) dari \(progressFlat.count) huruf")
                    .font(AppTheme.rounded(13))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
            .padding(.top, 2)

            progressBar(value: totalProgress, color: AppTheme.success, height: 6)
        }
        .padding(16)
        .background(AppTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 20)
    }

    /// Bilah kemajuan sederhana dengan jalur dan isian membulat.
    private func progressBar(value: Double, color: Color, height: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.trackColor(colorScheme))
                    .frame(height: height)

                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)), height: height)
                    .animation(.easeInOut(duration: 0.35), value: value)
            }
        }
        .frame(height: height)
    }

    // MARK: - Finished View
    var finishedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎉").font(AppTheme.rounded(72))
            Text("Sesi Selesai!")
                .font(AppTheme.rounded(28, .black))
            Text("Kamu menjawab benar \(sessionCorrect) dari \(deck.count) soal.")
                .font(AppTheme.rounded(15))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                Text("Total Huruf Dikuasai")
                    .font(AppTheme.rounded(12, .semibold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.trackColor(colorScheme)).frame(height: 10)
                        Capsule()
                            .fill(LinearGradient(colors: [accentColor, AppTheme.success], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(totalProgress), height: 10)
                            .animation(.easeInOut(duration: 0.8), value: totalProgress)
                    }
                }
                .frame(height: 10)
                Text("\(store.masteredCount(flat: progressFlat, isKatakana: isKatakana)) dari \(progressFlat.count) huruf dikuasai")
                    .font(AppTheme.rounded(12))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: { dismiss() }) {
                Text("Kembali ke Huruf")
                    .font(AppTheme.rounded(16, .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accentColor)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Logic
    func makeQuestion(for card: KanaItem) -> FlashQuestion {
        let correct = card.romaji
        // Distinct distractors only: padding with copies of `correct` would create
        // duplicate identifiers in the answer grid and render several "correct"
        // buttons. With fewer than three distractors we simply show fewer choices.
        let wrongPool = Set(deckFlat.map(\.romaji)).subtracting([correct])
        let distractors = wrongPool.shuffled().prefix(3)
        let choices = (distractors + [correct]).shuffled()
        return FlashQuestion(card: card, choices: choices, correctAnswer: correct)
    }

    func handleAnswer(_ answer: String, correct: String, card: KanaItem) {
        guard !isAnswered else { return }
        selectedAnswer = answer
        isAnswered = true
        if answer == correct {
            store.addCorrect(card.kana, isKatakana: isKatakana)
            sessionCorrect += 1
        } else {
            store.addWrong(card.kana, isKatakana: isKatakana)
        }
    }

    func nextCard() {
        if currentIndex + 1 >= deck.count {
            finished = true
        } else {
            currentIndex += 1
            selectedAnswer = nil
            isAnswered = false
            currentQuestion = makeQuestion(for: deck[currentIndex])
        }
    }

    func buildDeck() {
        guard !deckFlat.isEmpty else {
            deck = []
            currentQuestion = nil
            return
        }

        let notMastered = deckFlat.filter { !store.isMastered($0.kana, isKatakana: isKatakana) }
        let mastered = deckFlat.filter { store.isMastered($0.kana, isKatakana: isKatakana) }
        var result = notMastered.shuffled()
        if result.count < sessionSize {
            result += mastered.shuffled().prefix(sessionSize - result.count)
        }
        deck = Array(result.prefix(sessionSize))
        currentIndex = 0
        sessionCorrect = 0
        selectedAnswer = nil
        isAnswered = false
        finished = false
        if let first = deck.first {
            currentQuestion = makeQuestion(for: first)
        }
    }
}

// MARK: - Tombol Pilihan

/// Satu tombol jawaban. Sebelum dijawab tampil sebagai kartu putih; setelah
/// dijawab, jawaban benar menjadi hijau dan pilihan yang salah menjadi merah.
struct ChoiceButton: View {
    let label: String
    let correct: String
    let selected: String?
    let isAnswered: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var isCorrect: Bool { label == correct }
    var isSelected: Bool { label == selected }
    var isWrongSelected: Bool { isSelected && !isCorrect }

    var bgColor: Color {
        guard isAnswered else { return AppTheme.surface(colorScheme) }
        if isCorrect { return AppTheme.success }
        if isWrongSelected { return AppTheme.warning }
        return AppTheme.surface(colorScheme)
    }

    var textColor: Color {
        guard isAnswered else { return AppTheme.primaryText(colorScheme) }
        if isCorrect || isWrongSelected { return .white }
        return AppTheme.secondaryText(colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(AppTheme.rounded(18, .bold))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isAnswered)
    }
}

// MARK: - Preview
#Preview {
    HiraganaFlashcardView(
        store: HiraganaStore(),
        isKatakana: false,
        deckFlat: [],
        progressFlat: []
    )
}
