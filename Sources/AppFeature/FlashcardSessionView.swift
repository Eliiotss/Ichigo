import SwiftUI

// MARK: - Kategori Bucket UI (per-sesi, terpisah dari state SRS asli)
enum SessionBucket {
    case new, learning, review
}

// MARK: - ViewModel
@MainActor
final class FlashcardDeckSessionViewModel: ObservableObject {
    @Published private(set) var loadState: FlashcardLoadState = .idle
    @Published private(set) var queue: [FlashcardDeckCard] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var sessionTotal = 0
    @Published private(set) var remainingNew = 0
    @Published private(set) var remainingLearning = 0
    @Published private(set) var remainingReview = 0
    @Published var isRevealed = false
    @Published private(set) var isGraded = false
    @Published private(set) var finished = false
    @Published private(set) var sessionCorrect = 0
    @Published private(set) var sessionWrong = 0
    @Published private(set) var isSubmitting = false
    
    let mode: FlashcardMode
    let level: FlashcardLevelInfo
    let levelKey: String
    private let store: FlashcardStore
    private let engine = FlashcardReviewEngine()
    private let builder = FlashcardDeckQueueBuilder()
    private var retryCardIds: Set<String> = []
    
    // Bucket asal tiap kartu untuk SESI HARI INI (bukan state SRS global).
    // Begitu kartu keluar dari peta ini, dia dianggap "selesai" untuk hari ini.
    private var cardBucket: [String: SessionBucket] = [:]
    
    init(mode: FlashcardMode, level: FlashcardLevelInfo, store: FlashcardStore) {
        self.mode = mode
        self.level = level
        self.levelKey = flashcardLevelKey(mode: mode, levelId: level.id)
        self.store = store
    }
    
    var currentCard: FlashcardDeckCard? { currentIndex < queue.count ? queue[currentIndex] : nil }
    var progressText: String { sessionTotal == 0 ? "0/0" : "\(min(currentIndex + 1, sessionTotal))/\(sessionTotal)" }
    var progressValue: Double { sessionTotal == 0 ? 0 : Double(min(currentIndex + 1, sessionTotal)) / Double(sessionTotal) }
    
    func loadDeck() async {
        if case .loaded = loadState { return }
        loadState = .loading
        await store.loadDeck(mode: mode, levelId: level.id, jsonFile: level.jsonFile)
        guard let items = store.deckItemsPerLevel[levelKey] else {
            loadState = .failed("Data tidak ditemukan"); return
        }
        if items.isEmpty { loadState = .empty; return }
        
        let progressSnapshot = store.progressMap
        let settingsSnapshot = store.settings
        let usedToday = store.newCardTracker.studiedTodayCount(levelKey: levelKey)
        
        let built = builder.build(
            levelKey: levelKey,
            items: items,
            progress: progressSnapshot,
            settings: settingsSnapshot,
            newCardsAlreadyStudiedToday: usedToday
        )
        
        queue = built
        sessionTotal = queue.count
        
        // Assign bucket AWAL per kartu untuk sesi hari ini (sekali saja, saat deck dibangun)
        cardBucket.removeAll()
        remainingNew = 0
        remainingLearning = 0
        remainingReview = 0
        for card in queue {
            let bucket: SessionBucket
            switch store.deckProgress(for: card, levelKey: levelKey).state {
            case .new:
                bucket = .new
                remainingNew += 1
            case .learning, .relearning:
                bucket = .learning
                remainingLearning += 1
            case .review:
                bucket = .review
                remainingReview += 1
            }
            cardBucket[card.id] = bucket
        }
        
        retryCardIds.removeAll()
        currentIndex = 0
        sessionCorrect = 0
        sessionWrong = 0
        isSubmitting = false
        isRevealed = false
        isGraded = false
        finished = queue.isEmpty
        loadState = queue.isEmpty ? .empty : .loaded
    }
    
    func reveal() {
        guard !isRevealed else { return }
        withAnimation(.easeInOut(duration: 0.2)) { isRevealed = true }
    }
    
    func submit(grade: FlashcardGrade) {
        guard !isSubmitting, isRevealed, !isGraded, let cardItem = currentCard else { return }
        isSubmitting = true
        
        let current = store.deckProgress(for: cardItem, levelKey: levelKey)
        let stateBefore = current.state

        // Run the FSRS scheduler for this grade.
        let result = engine.review(card: current, grade: grade, settings: store.settings)
        let stateAfter = result.0.state

        // Update the per-session bucket counters synchronously so the UI reflects
        // the new state immediately, before the card is persisted.
        applyBucketDelta(cardId: cardItem.id, stateAfter: stateAfter)

        switch grade {
        case .again:
            sessionWrong += 1
            if retryCardIds.insert(cardItem.id).inserted { queue.append(cardItem) }
        case .hard, .good, .easy:
            sessionCorrect += 1
        }
        isGraded = true

        // Persist progress, review log and streak.
        if stateBefore == .new {
            store.newCardTracker.markStudied(cardId: cardItem.id, levelKey: levelKey)
        }
        store.saveProgress(result.0)
        store.appendReviewLog(result.1)
        store.updateStreakIfNeeded()
        store.refreshDeckStats(key: levelKey)
    }
    
    // MARK: - Aturan Universal Counter (sama untuk semua kategori, seperti Anki)
    // Kalau kartu LULUS ke review (selesai untuk hari ini) -> keluar dari bucket asalnya, tidak masuk ke mana pun.
    // Kalau kartu MASIH perlu diulang hari ini (learning/relearning) -> pindah/menetap di bucket "Learning".
    private func applyBucketDelta(cardId: String, stateAfter: FlashcardCardState) {
        guard let bucket = cardBucket[cardId] else { return }
        
        if stateAfter == .review {
            // Selesai untuk hari ini, keluar dari bucket manapun dia berasal
            decrement(bucket)
            cardBucket[cardId] = nil
        } else {
            // Masih perlu diulang hari ini (.learning / .relearning)
            if bucket != .learning {
                decrement(bucket)
                remainingLearning += 1
                cardBucket[cardId] = .learning
            }
            // Kalau sudah di .learning sebelumnya -> tidak ada perubahan angka (masih siklus di bucket sama)
        }
    }
    
    private func decrement(_ bucket: SessionBucket) {
        switch bucket {
        case .new: remainingNew = max(0, remainingNew - 1)
        case .learning: remainingLearning = max(0, remainingLearning - 1)
        case .review: remainingReview = max(0, remainingReview - 1)
        }
    }
    
    func next() {
        guard isGraded else { return }
        isSubmitting = false
        if currentIndex + 1 >= queue.count { finished = true; return }
        currentIndex += 1
        isRevealed = false
        isGraded = false
    }
}

// MARK: - Session View
struct FlashcardSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var vm: FlashcardDeckSessionViewModel
    
    init(mode: FlashcardMode, level: FlashcardLevelInfo, store: FlashcardStore) {
        _vm = StateObject(wrappedValue: FlashcardDeckSessionViewModel(mode: mode, level: level, store: store))
    }
    
    private var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    private var cardColor: Color { AppTheme.surface(colorScheme) }
    
    var body: some View {
        Group {
            switch vm.loadState {
            case .idle, .loading: ProgressView("Memuat sesi belajar...")
            case .empty: emptyState("Belum ada kartu", "Semua kartu sudah selesai atau belum ada kartu due.")
            case .comingSoon: emptyState("Konten belum tersedia", "Dataset level ini belum siap.")
            case .failed(let msg): emptyState("Gagal memuat", msg)
            case .loaded:
                if vm.finished { finishedView }
                else if let item = vm.currentCard { reviewView(item) }
                else { emptyState("Kartu tidak ditemukan", "Silakan buka ulang sesi.") }
            }
        }
        .task { await vm.loadDeck() }
        .navigationTitle("Flashcard \(vm.mode.title)")
        .navigationBarTitleDisplayMode(.inline)
        .background(bgColor.ignoresSafeArea())
    }
    
    // MARK: - Review (tap kartu untuk reveal, seperti versi sebelumnya)
    private func reviewView(_ item: FlashcardDeckCard) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                HStack {
                    Text(vm.level.id).font(.system(size: 13, weight: .black)).foregroundColor(vm.level.color)
                    Spacer()
                }
                ProgressView(value: vm.progressValue).tint(vm.level.color)
                
                // Counter 3 bagian ala Anki: Baru / Belajar-Ulang / Review
                HStack(spacing: 0) {
                    Spacer()
                    counterBadge(count: vm.remainingNew, color: .blue)
                    Spacer()
                    counterBadge(count: vm.remainingLearning, color: .red)
                    Spacer()
                    counterBadge(count: vm.remainingReview, color: .green)
                    Spacer()
                }
                .padding(.top, 4)
            }.padding(.horizontal, 20)
            
            Spacer()
            
            VStack(spacing: 16) {
                Text(item.front)
                    .font(.system(size: 40, weight: .black))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                if vm.isRevealed {
                    if !item.revealedTitle.isEmpty {
                        Text(item.revealedTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    Text(item.revealedBody)
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if !item.revealedTag.isEmpty {
                        Text(item.revealedTag)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(vm.mode.color)
                            .cornerRadius(10)
                    }
                } else {
                    Text("Tap kartu untuk melihat jawaban")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(cardColor)
            .cornerRadius(24)
            .contentShape(Rectangle())
            .onTapGesture { vm.reveal() }
            .padding(.horizontal, 20)
            
            Spacer()
            
            if vm.isRevealed && !vm.isGraded {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(FlashcardGrade.allCases, id: \.self) { grade in
                        Button {
                            vm.submit(grade: grade)
                        } label: {
                            Text(grade.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(color(for: grade))
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isSubmitting)
                    }
                }
                .padding(.horizontal, 20)
            } else if vm.isGraded {
                Button {
                    vm.next()
                } label: {
                    Text("Berikutnya")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(vm.level.color)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.horizontal, 20)
            } else {
                // Belum revealed - placeholder kosong agar layout tidak lompat
                Color.clear.frame(height: 52)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func counterBadge(count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
    }
    
    private func color(for grade: FlashcardGrade) -> Color {
        switch grade {
        case .again: return .red
        case .hard: return .orange
        case .good: return .blue
        case .easy: return .green
        }
    }
    
    private var finishedView: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("Sesi Selesai").font(.system(size: 28, weight: .black))
            Text("Benar: \(vm.sessionCorrect) - Ulang: \(vm.sessionWrong)").foregroundColor(.secondary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Kembali")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(vm.level.color)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    
    private func emptyState(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "tray").font(.system(size: 42)).foregroundColor(.secondary)
            Text(title).font(.system(size: 18, weight: .bold))
            Text(subtitle).font(.system(size: 13)).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
