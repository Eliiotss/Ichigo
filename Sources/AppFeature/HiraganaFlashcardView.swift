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
    
    var cardBgColors: [Color] {
        if isKatakana {
            return colorScheme == .dark
            ? [AppTheme.indigo.opacity(0.28), Color(red: 0.08, green: 0.09, blue: 0.24)]
            : [Color(red: 0.95, green: 0.92, blue: 1.0), Color(red: 0.88, green: 0.82, blue: 1.0)]
        } else {
            return colorScheme == .dark
            ? [AppTheme.blue.opacity(0.28), Color(red: 0.05, green: 0.10, blue: 0.28)]
            : [Color(red: 0.92, green: 0.96, blue: 1.0), Color(red: 0.8, green: 0.9, blue: 1.0)]
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if finished {
                    finishedView
                } else if deckFlat.isEmpty {
                    emptyStateView
                } else if deck.isEmpty || currentQuestion == nil {
                    ProgressView("Memuat...")
                } else {
                    questionContent
                }
            }
            .navigationTitle("Flashcard \(isKatakana ? "Katakana" : "Hiragana")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
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
    
    // MARK: - Question Content
    var questionContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                HStack {
                    Text("Kartu \(currentIndex + 1) / \(deck.count)")
                        .font(AppTheme.rounded(11, .semibold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                    Spacer()
                    Text("\(sessionCorrect) benar")
                        .font(AppTheme.rounded(11, .semibold))
                        .foregroundColor(accentColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(progressValue), height: 6)
                            .animation(.easeInOut(duration: 0.3), value: progressValue)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("Total Hafalan")
                        .font(AppTheme.rounded(10, .semibold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                    Spacer()
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.green)
                            .frame(width: geo.size.width * CGFloat(totalProgress), height: 4)
                            .animation(.easeInOut(duration: 0.5), value: totalProgress)
                    }
                }
                .frame(height: 4)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            if let question = currentQuestion {
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(
                        colors: cardBgColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(accentColor.opacity(0.15), lineWidth: 1.5))
                    .frame(height: 180)
                    .overlay(
                        Text(question.card.kana)
                            .font(AppTheme.rounded(90, .medium))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                    )
                    .padding(.horizontal, 24)
                
                Text("Pilih bacaan yang benar")
                    .font(AppTheme.rounded(13))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(question.choices, id: \.self) { choice in
                        ChoiceButton(
                            label: choice,
                            correct: question.correctAnswer,
                            selected: selectedAnswer,
                            isAnswered: isAnswered,
                            accentColor: accentColor
                        ) {
                            handleAnswer(choice, correct: question.correctAnswer, card: question.card)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                if isAnswered {
                    Button(action: nextCard) {
                        Text(currentIndex + 1 >= deck.count ? "Selesai" : "Lanjut →")
                            .font(AppTheme.rounded(15, .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accentColor)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
            }
            
            Spacer()
        }
        .padding(.top, 12)
        .background(Color(UIColor.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: isAnswered)
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
                        RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.15)).frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [accentColor, Color.green], startPoint: .leading, endPoint: .trailing))
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
        .background(Color(UIColor.systemBackground))
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

// MARK: - Choice Button
struct ChoiceButton: View {
    let label: String
    let correct: String
    let selected: String?
    let isAnswered: Bool
    let accentColor: Color
    let action: () -> Void
    
    var isCorrect: Bool { label == correct }
    var isSelected: Bool { label == selected }
    var isWrongSelected: Bool { isSelected && !isCorrect }
    
    var bgColor: Color {
        guard isAnswered else { return Color(UIColor.secondarySystemBackground) }
        if isCorrect { return Color.green }
        if isWrongSelected { return Color.red }
        return Color(UIColor.secondarySystemBackground)
    }
    
    var textColor: Color {
        guard isAnswered else { return .primary }
        if isCorrect { return .white }
        if isWrongSelected { return .white }
        return .secondary
    }
    
    var borderColor: Color {
        guard isAnswered else { return Color.gray.opacity(0.2) }
        if isCorrect { return Color.green }
        if isWrongSelected { return Color.red }
        return Color.gray.opacity(0.1)
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.rounded(18, .bold))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(bgColor)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1.5))
        }
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
