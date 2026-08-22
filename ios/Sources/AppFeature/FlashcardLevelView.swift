import SwiftUI

// MARK: - Pilihan Mode (Kosakata / Tata Bahasa)

/// Layar pemilih jenis flashcard: dua kotak besar berdampingan, lalu keterangan
/// singkat cara kerja penjadwalan ulangnya.
struct FlashcardTypeSelectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var store: FlashcardStore

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(FlashcardMode.allCases) { mode in
                        NavigationLink(destination: FlashcardLevelView(mode: mode, store: store)) {
                            FlashcardModeCard(mode: mode)
                        }
                        .buttonStyle(.plain)
                    }
                }

                reviewInfoCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .background(bgColor)
        .navigationTitle("Flashcard")
        .navigationBarTitleDisplayMode(.large)
    }

    /// Keterangan cara kerja review, sesuai desain.
    private var reviewInfoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(AppTheme.rounded(17, .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 34, height: 34)
                .background(AppTheme.surface(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("Cara kerja review")
                    .font(AppTheme.rounded(13, .bold))
                    .foregroundStyle(AppTheme.primaryText(colorScheme))

                Text("Kartu dijadwalkan ulang dengan FSRS. Tap kartu untuk melihat jawaban, lalu nilai seberapa mudah kamu mengingatnya.")
                    .font(AppTheme.rounded(12, .medium))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppTheme.softTint(AppTheme.accent, colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Kotak pilihan satu mode flashcard: ikon bergradien, judul, dan penjelasan.
struct FlashcardModeCard: View {
    let mode: FlashcardMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: mode.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: mode.gradient[1].opacity(0.34), radius: 9, x: 0, y: 5)

                Image(systemName: mode.icon)
                    .font(AppTheme.rounded(26, .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 14)

            Text(mode.title)
                .font(AppTheme.rounded(16, .bold))
                .foregroundStyle(AppTheme.primaryText(colorScheme))
                .padding(.bottom, 3)

            Text(mode.subtitle)
                .font(AppTheme.rounded(12, .medium))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(AppTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 9, x: 0, y: 6)
    }
}

// MARK: - Flashcard Level View (mode: vocab / grammar)
struct FlashcardLevelView: View {
    let mode: FlashcardMode
    @ObservedObject var store: FlashcardStore
    @Environment(\.colorScheme) var colorScheme

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(mode.levels()) { level in
                    if level.isLocked {
                        FlashcardLockedLevelCard(level: level)
                    } else {
                        NavigationLink(destination: FlashcardSessionView(mode: mode, level: level, store: store)) {
                            FlashcardUnlockedLevelCard(mode: mode, level: level, store: store)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(bgColor)
        .navigationTitle("Flashcard \(mode.title)")
        .navigationBarTitleDisplayMode(.large)
        .task { await preloadAllLevels() }
    }

    private func preloadAllLevels() async {
        for level in mode.levels() where !level.isLocked {
            await store.loadDeck(mode: mode, levelId: level.id, jsonFile: level.jsonFile)
        }
    }
}

// MARK: - Unlocked Level Card
struct FlashcardUnlockedLevelCard: View {
    let mode: FlashcardMode
    let level: FlashcardLevelInfo
    @ObservedObject var store: FlashcardStore
    @Environment(\.colorScheme) var colorScheme

    var cardColor: Color { AppTheme.surface(colorScheme) }

    var stats: FlashcardStore.LevelStats? { store.deckStats(mode: mode, levelId: level.id) }
    var totalText: String { stats.map { "\($0.total)" } ?? "-" }
    var due: Int { stats?.due ?? 0 }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(level.bgColor)
                    .frame(width: 52, height: 52)
                Text(level.id)
                    .font(AppTheme.rounded(18, .black))
                    .foregroundStyle(level.color)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(level.name)
                        .font(AppTheme.rounded(17, .bold))
                        .foregroundStyle(AppTheme.primaryText(colorScheme))
                    Spacer()
                    if due > 0 {
                        Text("\(due) due")
                            .font(AppTheme.rounded(11, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(level.color)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    Image(systemName: "chevron.right")
                        .font(AppTheme.rounded(13, .semibold))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }

                Text(level.description)
                    .font(AppTheme.rounded(13))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))

                Text("\(totalText) kartu • bebas pilih deck")
                    .font(AppTheme.rounded(11, .semibold))
                    .foregroundStyle(level.color)
            }
        }
        .padding(16)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 9, x: 0, y: 6)
    }
}

// MARK: - Locked Level Card
struct FlashcardLockedLevelCard: View {
    let level: FlashcardLevelInfo
    @Environment(\.colorScheme) var colorScheme

    var cardColor: Color { AppTheme.surface(colorScheme) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                Text(level.id)
                    .font(AppTheme.rounded(18, .black))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(level.name)
                        .font(AppTheme.rounded(17, .bold))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill").font(AppTheme.rounded(12))
                        Text("Terkunci").font(AppTheme.rounded(11, .semibold))
                    }
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }
                Text(level.description)
                    .font(AppTheme.rounded(13))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
        }
        .padding(16)
        .background(cardColor.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.gray.opacity(0.08), lineWidth: 1))
    }
}

#Preview {
    NavigationStack { FlashcardTypeSelectionView(store: FlashcardStore()) }
}

