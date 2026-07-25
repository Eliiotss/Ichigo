import SwiftUI

// MARK: - Grammar Level View
struct GrammarView: View {
    @Environment(\.colorScheme) var colorScheme

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }

    var body: some View {
        Group {
            if grammarLevels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 42))
                        .foregroundColor(.secondary)
                    Text("Grammar belum tersedia")
                        .font(.system(size: 18, weight: .bold))
                    Text("Dataset grammar sedang dipersiapkan.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgColor)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(grammarLevels) { level in
                            if level.isLocked {
                                GrammarLockedLevelCard(level: level)
                            } else {
                                NavigationLink(destination: GrammarListView(level: level)) {
                                    GrammarLevelCard(level: level)
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
        .navigationTitle("Grammar")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Grammar Level Card
struct GrammarLevelCard: View {
    let level: GrammarLevel
    @Environment(\.colorScheme) var colorScheme
    
    var cardColor: Color { AppTheme.surface(colorScheme) }
    
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
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Text(level.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 9, x: 0, y: 6)
    }
}

// MARK: - Locked Grammar Level Card
struct GrammarLockedLevelCard: View {
    let level: GrammarLevel
    @Environment(\.colorScheme) var colorScheme
    
    var cardColor: Color { AppTheme.surface(colorScheme) }
    
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
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                        Text("Terkunci")
                            .font(.system(size: 11, weight: .semibold))
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        GrammarView()
    }
}
