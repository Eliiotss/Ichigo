import SwiftUI

// MARK: - Kana Data
struct KanaItem: Identifiable, Hashable {
    let id = UUID()
    let kana: String
    let romaji: String
}

struct KanaGroup: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let items: [[KanaItem?]]
    let columns: [String]
}

// MARK: - JSON Codable Model (untuk load dari file)
struct KanaItemJSON: Codable {
    let kana: String
    let romaji: String
}

struct KanaGroupJSON: Codable {
    let title: String
    let subtitle: String
    let columns: [String]
    let rows: [[KanaItemJSON?]]
}

// MARK: - Kana Loader
class KanaLoader {
    static func load(from filename: String) -> [KanaGroup] {
        do {
            let decoded = try JSONResourceCache.shared.decode([KanaGroupJSON].self, filename: filename)
            return decoded.map { group in
                KanaGroup(
                    title: group.title,
                    subtitle: group.subtitle,
                    items: group.rows.map { row in row.map { item in item.map { KanaItem(kana: $0.kana, romaji: $0.romaji) } } },
                    columns: group.columns
                )
            }
        } catch {
            print("❌ Gagal decode \(filename).json: \(error)")
            return []
        }
    }
    
    static func flatItems(from groups: [KanaGroup]) -> [KanaItem] {
        groups.flatMap { $0.items.flatMap { $0.compactMap { $0 } } }
    }
}

// MARK: - Main View
struct HiraganaView: View {
    @StateObject private var store = HiraganaStore()
    @State private var selectedTab: Int = 0
    @State private var showFlashcard = false
    @State private var hiraganaGroups: [KanaGroup] = []
    @State private var katakanaGroups: [KanaGroup] = []
    @State private var isLoading = true
    @Environment(\.colorScheme) var colorScheme
    
    var isKatakana: Bool { selectedTab == 1 }
    var currentGroups: [KanaGroup] { isKatakana ? katakanaGroups : hiraganaGroups }
    var currentFlat: [KanaItem] { KanaLoader.flatItems(from: currentGroups) }
    
    var mainGroups: [KanaGroup] {
        currentGroups.filter { group in
            !group.title.localizedCaseInsensitiveContains("Yōon") &&
            !group.title.localizedCaseInsensitiveContains("Gabungan")
        }
    }
    
    var mainFlat: [KanaItem] {
        KanaLoader.flatItems(from: mainGroups)
    }
    
    var yoonUnlockThreshold: Int {
        Int((Double(mainFlat.count) * 0.5).rounded(.up))
    }
    
    var masteredMainCount: Int {
        store.masteredCount(flat: mainFlat, isKatakana: isKatakana)
    }
    
    var isYoonUnlocked: Bool {
        masteredMainCount >= yoonUnlockThreshold
    }
    
    var flashcardFlat: [KanaItem] {
        isYoonUnlocked ? currentFlat : mainFlat
    }
    
    var bgColor: Color {
        colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground)
    }
    
    var cardColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
    var masteredCount: Int {
        store.masteredCount(flat: currentFlat, isKatakana: isKatakana)
    }
    
    var progressValue: Double {
        store.progressPercent(flat: currentFlat, isKatakana: isKatakana)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Hiragana").tag(0)
                    Text("Katakana").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(bgColor)
                
                if isLoading {
                    Spacer()
                    ProgressView("Memuat huruf...")
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Progres Hafalan")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    colors: isKatakana
                                                    ? [Color(red: 0.5, green: 0.1, blue: 0.9), Color.purple]
                                                    : [Color(red: 0.2, green: 0.6, blue: 1.0), Color.blue],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geo.size.width * CGFloat(progressValue), height: 8)
                                            .animation(.easeInOut(duration: 0.5), value: progressValue)
                                    }
                                }
                                .frame(height: 8)
                                
                                Text("\(masteredCount) dari \(currentFlat.count) huruf dikuasai")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            ForEach(currentGroups) { group in
                                KanaGroupSection(
                                    group: group,
                                    store: store,
                                    isKatakana: isKatakana,
                                    cardColor: cardColor
                                )
                            }
                            
                            Spacer().frame(height: 90)
                        }
                    }
                    .background(bgColor)
                }
            }
            
            if !isLoading {
                Button(action: { showFlashcard = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Flashcard \(isKatakana ? "Katakana" : "Hiragana")")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isKatakana ? Color.purple : Color.blue)
                    .cornerRadius(16)
                    .shadow(color: (isKatakana ? Color.purple : Color.blue).opacity(0.4), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Huruf")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showFlashcard) {
            HiraganaFlashcardView(
                store: store,
                isKatakana: isKatakana,
                deckFlat: flashcardFlat,
                progressFlat: currentFlat
            )
        }
        .task {
            guard hiraganaGroups.isEmpty else { return }
            
            let result = await Task.detached(priority: .userInitiated) {
                (
                    KanaLoader.load(from: "Hiragana"),
                    KanaLoader.load(from: "Katakana")
                )
            }.value
            
            await MainActor.run {
                hiraganaGroups = result.0
                katakanaGroups = result.1
                isLoading = false
            }
        }
    }
}

// MARK: - Kana Group Section
struct KanaGroupSection: View {
    let group: KanaGroup
    let store: HiraganaStore
    let isKatakana: Bool
    let cardColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                
                if !group.subtitle.isEmpty {
                    Text(group.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                }
            }
            
            HStack(spacing: 0) {
                ForEach(group.columns, id: \.self) { col in
                    Text(col)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 4) {
                ForEach(0..<group.items.count, id: \.self) { rowIdx in
                    HStack(spacing: 4) {
                        ForEach(0..<group.items[rowIdx].count, id: \.self) { colIdx in
                            if let item = group.items[rowIdx][colIdx] {
                                KanaCellView(
                                    item: item,
                                    barProgress: store.barProgress(item.kana, isKatakana: isKatakana),
                                    isMastered: store.isMastered(item.kana, isKatakana: isKatakana),
                                    isKatakana: isKatakana,
                                    cardColor: cardColor
                                )
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 68)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }
}

// MARK: - Kana Cell View
struct KanaCellView: View {
    let item: KanaItem
    let barProgress: Double
    let isMastered: Bool
    let isKatakana: Bool
    let cardColor: Color
    
    var accentColor: Color {
        isKatakana ? .purple : .blue
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(item.kana)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.primary)
            
            Text(item.romaji)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .kerning(0.5)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 3)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isMastered ? Color.green : accentColor)
                        .frame(width: geo.size.width * CGFloat(barProgress), height: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 6)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(cardColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isMastered ? Color.green.opacity(0.6) : Color.gray.opacity(0.15),
                    lineWidth: 1.5
                )
        )
    }
}

#Preview {
    NavigationView {
        HiraganaView()
    }
}
