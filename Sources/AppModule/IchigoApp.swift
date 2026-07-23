import SwiftUI

@main
struct IchigoApp: App {
    @StateObject private var loadingState = AppLoadingState()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(loadingState.isReady ? 1 : 0)
                    .animation(.easeOut(duration: 0.2), value: loadingState.isReady)
                
                if !loadingState.isReady {
                    SplashView(progressText: loadingState.statusText)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                await loadingState.prepare()
            }
        }
    }
}

@MainActor
final class AppLoadingState: ObservableObject {
    @Published var isReady = false
    @Published var statusText = "Menyiapkan aplikasi..."
    private var hasPrepared = false
    
    func prepare() async {
        guard !hasPrepared else { return }
        hasPrepared = true
        
        let start = Date()
        statusText = "Memuat data dasar..."
        
        await preloadCoreResources()
        
        statusText = "Hampir selesai..."
        let elapsed = Date().timeIntervalSince(start)
        let minimumSplashTime = 0.65
        if elapsed < minimumSplashTime {
            try? await Task.sleep(nanoseconds: UInt64((minimumSplashTime - elapsed) * 1_000_000_000))
        }
        
        withAnimation(.easeOut(duration: 0.25)) {
            isReady = true
        }
    }
    
    private func preloadCoreResources() async {
        await Task.detached(priority: .userInitiated) {
            _ = try? JSONResourceCache.shared.decode([KanjiItem].self, filename: "KanjiN5")
            _ = try? JSONResourceCache.shared.decode([VocabularyItem].self, filename: "VocabN5")
            _ = try? JSONResourceCache.shared.decode([GrammarItem].self, filename: "GrammarN5")
            _ = try? JSONResourceCache.shared.decode([KanaGroupJSON].self, filename: "Hiragana")
            _ = try? JSONResourceCache.shared.decode([KanaGroupJSON].self, filename: "Katakana")
        }.value
    }
}

private struct SplashView: View {
    let progressText: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.1, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("🇯🇵")
                    .font(.system(size: 58))
                
                VStack(spacing: 6) {
                    Text("Ichigo")
                        .font(.system(size: 29, weight: .black))
                        .foregroundColor(.white)
                    
                    Text(progressText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                }
                
                ProgressView()
                    .tint(.white)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
    }
}
