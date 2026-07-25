import SwiftUI

struct VocabularyView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    
    var filteredLevels: [VocabularyLevel] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return vocabularyLevels }
        return vocabularyLevels.filter {
            $0.id.localizedCaseInsensitiveContains(q)
            || $0.name.localizedCaseInsensitiveContains(q)
            || $0.description.localizedCaseInsensitiveContains(q)
        }
    }
    
    var body: some View {
        Group {
            if vocabularyLevels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 42))
                        .foregroundColor(.secondary)
                    Text("Vocabulary belum tersedia")
                        .font(.system(size: 18, weight: .bold))
                    Text("Dataset vocabulary sedang dipersiapkan.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgColor)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Cari level vocabulary...", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                        }
                        .padding(12)
                        .background(AppTheme.surface(colorScheme))
                        .cornerRadius(14)
                        
                        ForEach(filteredLevels) { level in
                            if level.isLocked {
                                VocabularyLockedCard(level: level)
                            } else {
                                NavigationLink(destination: VocabularyListView(level: level)) {
                                    VocabularyUnlockedCard(level: level)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(bgColor)
            }
        }
        .navigationTitle("Vocabulary")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct VocabularyUnlockedCard: View {
    let level: VocabularyLevel
    @Environment(\.colorScheme) var colorScheme
    
    var cardColor: Color { AppTheme.surface(colorScheme) }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(level.bgColor)
                    .frame(width: 54, height: 54)
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
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                Text(level.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Text("~\(level.totalWords) Kosakata")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(level.color)
            }
        }
        .padding(16)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 9, x: 0, y: 6)
    }
}

struct VocabularyLockedCard: View {
    let level: VocabularyLevel
    @Environment(\.colorScheme) var colorScheme
    
    var cardColor: Color { AppTheme.surface(colorScheme) }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 54, height: 54)
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
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                        Text("Terkunci")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                }
                Text(level.description)
                    .font(.system(size: 13))
                    .foregroundColor(Color.secondary.opacity(0.7))
            }
        }
        .padding(16)
        .background(cardColor.opacity(0.55))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.08), lineWidth: 1))
    }
}

#Preview {
    NavigationView { VocabularyView() }
}
