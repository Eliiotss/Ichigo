import SwiftUI

// MARK: - Pilihan Mode (Vocabulary / Grammar)
struct FlashcardTypeSelectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var store: FlashcardStore

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    var cardColor: Color { AppTheme.surface(colorScheme) }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(FlashcardMode.allCases) { mode in
                    NavigationLink(destination: FlashcardLevelView(mode: mode, store: store)) {
                        FlashcardModeCard(mode: mode, cardColor: cardColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(bgColor)
        .navigationTitle("Flashcard")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct FlashcardModeCard: View {
    let mode: FlashcardMode
    let cardColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(mode.color.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: mode.icon)
                    .font(AppTheme.rounded(28, .bold))
                    .foregroundColor(mode.color)
            }
            VStack(spacing: 4) {
                Text(mode.title)
                    .font(AppTheme.rounded(17, .black))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                Text(mode.subtitle)
                    .font(AppTheme.rounded(12))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(cardColor)
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(level.bgColor)
                    .frame(width: 52, height: 52)
                Text(level.id)
                    .font(AppTheme.rounded(18, .black))
                    .foregroundColor(level.color)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(level.name)
                        .font(AppTheme.rounded(17, .bold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                    Spacer()
                    if due > 0 {
                        Text("\(due) due")
                            .font(AppTheme.rounded(11, .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(level.color)
                            .cornerRadius(10)
                    }
                    Image(systemName: "chevron.right")
                        .font(AppTheme.rounded(13, .semibold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                
                Text(level.description)
                    .font(AppTheme.rounded(13))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                
                Text("\(totalText) kartu • bebas pilih deck")
                    .font(AppTheme.rounded(11, .semibold))
                    .foregroundColor(level.color)
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                Text(level.id)
                    .font(AppTheme.rounded(18, .black))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(level.name)
                        .font(AppTheme.rounded(17, .bold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill").font(AppTheme.rounded(12))
                        Text("Terkunci").font(AppTheme.rounded(11, .semibold))
                    }
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                Text(level.description)
                    .font(AppTheme.rounded(13))
                    .foregroundColor(Color.secondary.opacity(0.6))
            }
        }
        .padding(16)
        .background(cardColor.opacity(0.5))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.08), lineWidth: 1))
    }
}

#Preview {
    NavigationView { FlashcardTypeSelectionView(store: FlashcardStore()) }
}

