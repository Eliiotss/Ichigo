import SwiftUI

struct VocabularyView: View {
    @Environment(\.colorScheme) var colorScheme

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }

    var body: some View {
        Group {
            if vocabularyLevels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.book.closed")
                        .font(AppTheme.rounded(42))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                    Text("Vocabulary belum tersedia")
                        .font(AppTheme.rounded(18, .bold))
                    Text("Dataset vocabulary sedang dipersiapkan.")
                        .font(AppTheme.rounded(14))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgColor)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vocabularyLevels) { level in
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

                    Image(systemName: "chevron.right")
                        .font(AppTheme.rounded(13, .semibold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }

                Text(level.description)
                    .font(AppTheme.rounded(13))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
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
                        Image(systemName: "lock.fill")
                            .font(AppTheme.rounded(12))
                        Text("Terkunci")
                            .font(AppTheme.rounded(11, .semibold))
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView { VocabularyView() }
}
