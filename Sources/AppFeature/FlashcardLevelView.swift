import SwiftUI

// MARK: - Pilihan Mode (Vocabulary / Grammar)
struct FlashcardTypeSelectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var store: FlashcardStore

    var bgColor: Color {
        colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground)
    }
    var cardColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
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
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(mode.color)
            }
            VStack(spacing: 4) {
                Text(mode.title)
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(.primary)
                Text(mode.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(cardColor)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Flashcard Level View (mode: vocab / grammar)
struct FlashcardLevelView: View {
    let mode: FlashcardMode
    @ObservedObject var store: FlashcardStore
    @Environment(\.colorScheme) var colorScheme
    
    var bgColor: Color {
        colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground)
    }
    
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
    
    var cardColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
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
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(level.color)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(level.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    if due > 0 {
                        Text("\(due) due")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(level.color)
                            .cornerRadius(10)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Text(level.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text("\(totalText) kartu • bebas pilih deck")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(level.color)
            }
        }
        .padding(16)
        .background(cardColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Locked Level Card
struct FlashcardLockedLevelCard: View {
    let level: FlashcardLevelInfo
    @Environment(\.colorScheme) var colorScheme
    
    var cardColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                Text(level.id)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(level.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill").font(.system(size: 12))
                        Text("Terkunci").font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                }
                Text(level.description)
                    .font(.system(size: 13))
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

