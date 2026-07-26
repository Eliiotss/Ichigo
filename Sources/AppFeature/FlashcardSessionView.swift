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
    /// Posisi kartu yang sedang dibuka, mis. "Kartu 3 / 25".
    var positionText: String {
        sessionTotal == 0 ? "Kartu 0 / 0" : "Kartu \(min(currentIndex + 1, sessionTotal)) / \(sessionTotal)"
    }
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

    // MARK: - Review (tap kartu untuk melihat jawaban, lalu nilai)
    private func reviewView(_ item: FlashcardDeckCard) -> some View {
        VStack(spacing: 0) {
            statsCard
                .padding(.horizontal, 18)

            flipCard(item)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)

            gradeArea
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
        }
    }

    /// Kartu ringkasan di atas: level, posisi kartu, bilah kemajuan, dan tiga
    /// pil hitungan (due / ulang / hafal).
    private var statsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("JLPT \(vm.level.id)")
                    .font(AppTheme.rounded(12, .bold))
                    .foregroundColor(AppTheme.accent)
                    .kerning(0.5)

                Spacer()

                Text(vm.positionText)
                    .font(AppTheme.rounded(12, .semibold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
            .padding(.bottom, 8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.trackColor(colorScheme))
                        .frame(height: 7)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.blueLight, AppTheme.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(max(vm.progressValue, 0), 1)), height: 7)
                        .animation(.easeInOut(duration: 0.3), value: vm.progressValue)
                }
            }
            .frame(height: 7)
            .padding(.bottom, 11)

            HStack(spacing: 8) {
                countPill(count: vm.remainingNew, label: "due", color: AppTheme.accent)
                countPill(count: vm.remainingLearning, label: "ulang", color: AppTheme.danger)
                countPill(count: vm.remainingReview, label: "hafal", color: AppTheme.success)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }

    private func countPill(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text("\(count)")
                .font(AppTheme.rounded(15, .bold))
                .foregroundColor(color)

            Text(label)
                .font(AppTheme.rounded(10, .bold))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.softTint(color, colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    /// Kartu soal. Sebelum diketuk hanya menampilkan sisi depan; setelah
    /// diketuk memperlihatkan cara baca, artinya, dan jenis katanya.
    private func flipCard(_ item: FlashcardDeckCard) -> some View {
        VStack(spacing: 6) {
            Text(item.front)
                .font(AppTheme.rounded(46, .bold))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if vm.isRevealed {
                if !item.revealedTitle.isEmpty {
                    Text(item.revealedTitle)
                        .font(AppTheme.rounded(17, .bold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }

                Text(item.revealedBody)
                    .font(AppTheme.rounded(24, .bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)

                if !item.revealedTag.isEmpty {
                    Text(item.revealedTag)
                        .font(AppTheme.rounded(12, .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.blueLight, AppTheme.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .padding(.top, 10)
                }
            } else {
                Text("Tap kartu untuk melihat jawaban")
                    .font(AppTheme.rounded(13, .medium))
                    .foregroundColor(AppTheme.placeholder)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(cardColor)
        .overlay(alignment: .top) {
            // Garis aksen tipis di bibir atas kartu, sesuai desain.
            LinearGradient(
                colors: [AppTheme.blueLight, AppTheme.blue],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 13, x: 0, y: 10)
        .contentShape(Rectangle())
        .onTapGesture { vm.reveal() }
    }

    /// Empat tombol nilai muncul setelah jawaban terlihat; setelah dinilai
    /// digantikan tombol lanjut. Tingginya dijaga tetap supaya kartu di atasnya
    /// tidak melompat.
    @ViewBuilder
    private var gradeArea: some View {
        if vm.isRevealed && !vm.isGraded {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(FlashcardGrade.allCases, id: \.self) { grade in
                    Button {
                        vm.submit(grade: grade)
                    } label: {
                        Text(grade.title)
                            .font(AppTheme.rounded(15, .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(color(for: grade))
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .shadow(color: color(for: grade).opacity(0.3), radius: 8, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isSubmitting)
                }
            }
        } else if vm.isGraded {
            Button {
                vm.next()
            } label: {
                Text("Berikutnya")
                    .font(AppTheme.rounded(16, .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(height: 48)
        }
    }

    /// Warna tombol nilai, nilainya persis dari desain.
    private func color(for grade: FlashcardGrade) -> Color {
        switch grade {
        case .again: return AppTheme.danger
        case .hard: return AppTheme.caution
        case .good: return AppTheme.accent
        case .easy: return AppTheme.success
        }
    }

    private var finishedView: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("Sesi Selesai").font(AppTheme.rounded(28, .black))
            Text("Benar: \(vm.sessionCorrect) - Ulang: \(vm.sessionWrong)").foregroundColor(AppTheme.secondaryText(colorScheme))
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Kembali")
                    .font(AppTheme.rounded(16, .bold))
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
            Image(systemName: "tray").font(AppTheme.rounded(42)).foregroundColor(AppTheme.secondaryText(colorScheme))
            Text(title).font(AppTheme.rounded(18, .bold))
            Text(subtitle).font(AppTheme.rounded(13)).foregroundColor(AppTheme.secondaryText(colorScheme)).multilineTextAlignment(.center).padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
