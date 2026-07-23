import SwiftUI

// MARK: - App State
final class AppState: ObservableObject {
    @Published var completedCards: Int = 0
    @Published var totalCards: Int = 0
    @Published var dueToday: Int = 0
    
    @MainActor
    func sync(from store: FlashcardStore) {
        completedCards = store.masteredTotal
        dueToday = store.dueTodayGrandTotal
        totalCards = store.deckItemsPerLevel.values.reduce(0) { $0 + $1.count }
    }
}

// MARK: - MenuItem
struct MenuItem {
    let id: String
    let label: String
    let sub: String
    let icon: String
    let gradientColors: [Color]
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var flashcardStore = FlashcardStore()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, flashcardStore: flashcardStore)
                .environmentObject(appState)
                .tabItem { Image(systemName: "house.fill"); Text("Home") }
                .tag(0)
            
            ProfileView(flashcardStore: flashcardStore)
                .tabItem { Image(systemName: "person.fill"); Text("Profile") }
                .tag(1)
            
            SettingsView()
                .tabItem { Image(systemName: "gearshape.fill"); Text("Pengaturan") }
                .tag(2)
        }
        .accentColor(.blue)
        .task { await preloadHomeStats() }
    }
    
    private func preloadHomeStats() async {
        for mode in FlashcardMode.allCases {
            for level in mode.levels() where !level.isLocked {
                await flashcardStore.loadDeck(mode: mode, levelId: level.id, jsonFile: level.jsonFile)
            }
        }
        appState.sync(from: flashcardStore)
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    @ObservedObject var flashcardStore: FlashcardStore
    @Environment(\.colorScheme) var colorScheme
    
    // WAJIB pakai key yang sama persis dengan SettingsView: "user_name"
    @AppStorage("user_name") private var userName = "User123"
    @AppStorage("daily_target") private var dailyTarget = 20
    
    let menuItems: [MenuItem] = [
        MenuItem(id: "huruf", label: "Huruf", sub: "Kana", icon: "character", gradientColors: [.orange, Color(red: 0.9, green: 0.4, blue: 0.1)]),
        MenuItem(id: "kanji", label: "Kanji", sub: "Aksara", icon: "character.book.closed", gradientColors: [.purple, Color(red: 0.5, green: 0.1, blue: 0.9)]),
        MenuItem(id: "flashcard", label: "Flashcard", sub: "Review Cepat", icon: "rectangle.stack.fill", gradientColors: [.pink, Color(red: 0.9, green: 0.2, blue: 0.4)]),
        MenuItem(id: "vocabulary", label: "Vocabulary", sub: "Kosakata", icon: "book.fill", gradientColors: [.blue, Color(red: 0.1, green: 0.5, blue: 0.9)]),
        MenuItem(id: "grammar", label: "Grammar", sub: "Tata Bahasa", icon: "text.book.closed.fill", gradientColors: [.green, Color(red: 0.1, green: 0.7, blue: 0.5)]),
        MenuItem(id: "lainnya", label: "Lainnya", sub: "Fitur Lain", icon: "square.grid.2x2.fill", gradientColors: [.gray, Color(red: 0.3, green: 0.3, blue: 0.4)])
    ]
    
    var bgColor: Color { colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground) }
    var cardColor: Color { colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white }
    var softCardColor: Color { colorScheme == .dark ? Color(UIColor.tertiarySystemBackground) : Color(UIColor.secondarySystemGroupedBackground) }
    var shadowOpacity: Double { colorScheme == .dark ? 0.3 : 0.05 }
    var dueTodayTotal: Int { flashcardStore.dueTodayGrandTotal }
    
    var body: some View {
        GeometryReader { geo in
            let isIPad = geo.size.width > 600
            let horizontalPadding: CGFloat = isIPad ? 32 : 16
            let titleSize: CGFloat = isIPad ? 28 : 20
            let columns = isIPad ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())] : [GridItem(.flexible()), GridItem(.flexible())]
            
            NavigationView {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("NihongoMaster")
                                .font(.system(size: titleSize, weight: .black))
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill").foregroundColor(.blue)
                                // BENAR - pakai binding userName, bukan teks statis
                                Text(userName)
                                    .font(.system(size: isIPad ? 15 : 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(cardColor)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(shadowOpacity), radius: 4, x: 0, y: 2)
                        }
                        
                        HomeStatsCard(
                            dueToday: dueTodayTotal,
                            studiedToday: flashcardStore.studiedTodayTotal,
                            streak: flashcardStore.currentStreak,
                            mastered: flashcardStore.masteredTotal,
                            dailyTarget: dailyTarget,
                            isIPad: isIPad,
                            cardColor: cardColor,
                            softCardColor: softCardColor,
                            shadowOpacity: shadowOpacity
                        )
                        
                        HStack {
                            Text("BELAJAR MANDIRI")
                                .font(.system(size: isIPad ? 12 : 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .kerning(1.5)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 24 : 16)
                    .padding(.bottom, 8)
                    .background(bgColor)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: isIPad ? 16 : 12) {
                            ForEach(menuItems, id: \.id) { item in
                                menuDestination(for: item, isIPad: isIPad)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 12)
                    }
                    .background(bgColor)
                }
                .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
        }
    }
    
    @ViewBuilder
    func menuDestination(for item: MenuItem, isIPad: Bool) -> some View {
        switch item.id {
        case "huruf":
            NavigationLink(destination: HiraganaView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        case "kanji":
            NavigationLink(destination: KanjiView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        case "flashcard":
            NavigationLink(destination: FlashcardTypeSelectionView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        case "vocabulary":
            NavigationLink(destination: VocabularyView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        case "grammar":
            NavigationLink(destination: GrammarView()) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        default:
            NavigationLink(destination: ComingSoonView(featureName: item.label)) { MenuCardView(item: item, isIPad: isIPad) }.buttonStyle(.plain)
        }
    }
}

// MARK: - Menu Card View
struct MenuCardView: View {
    let item: MenuItem
    var isIPad = false
    @Environment(\.colorScheme) var colorScheme
    var cardColor: Color { colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white }
    var shadowOpacity: Double { colorScheme == .dark ? 0.3 : 0.05 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isIPad ? 14 : 10) {
            ZStack {
                RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                    .fill(LinearGradient(colors: item.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: isIPad ? 56 : 44, height: isIPad ? 56 : 44)
                Image(systemName: item.icon)
                    .font(.system(size: isIPad ? 24 : 19, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.label).font(.system(size: isIPad ? 17 : 14, weight: .bold))
                Text(item.sub).font(.system(size: isIPad ? 13 : 11)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isIPad ? 20 : 16)
        .background(cardColor)
        .cornerRadius(isIPad ? 22 : 18)
        .shadow(color: .black.opacity(shadowOpacity), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview { ContentView() }

struct ComingSoonView: View {
    let featureName: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "hammer.fill").font(.system(size: 48)).foregroundColor(.secondary)
            Text("\(featureName) Segera Hadir").font(.system(size: 22, weight: .bold))
            Text("Fitur ini sedang dikembangkan.").font(.system(size: 14)).foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle(featureName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
