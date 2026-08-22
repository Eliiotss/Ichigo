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
                        .font(AppTheme.rounded(42))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    Text("Grammar belum tersedia")
                        .font(AppTheme.rounded(18, .bold))
                    Text("Dataset grammar sedang dipersiapkan.")
                        .font(AppTheme.rounded(14))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
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

                    Image(systemName: "chevron.right")
                        .font(AppTheme.rounded(13, .semibold))
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }

                Text(level.description)
                    .font(AppTheme.rounded(13))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
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
                        Image(systemName: "lock.fill")
                            .font(AppTheme.rounded(12))
                        Text("Terkunci")
                            .font(AppTheme.rounded(11, .semibold))
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
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        GrammarView()
    }
}
