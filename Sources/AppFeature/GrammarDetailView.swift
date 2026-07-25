import SwiftUI

// MARK: - Grammar Detail View
struct GrammarDetailView: View {
    let item: GrammarItem
    @Environment(\.colorScheme) var colorScheme
    
    var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    
    var cardColor: Color { AppTheme.surface(colorScheme) }
    
    var softCardColor: Color {
        colorScheme == .dark ? Color(UIColor.tertiarySystemBackground) : Color(UIColor.secondarySystemGroupedBackground)
    }
    
    var accentColor: Color { AppTheme.indigo }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard
                
                if !item.nuance.isEmpty || !item.frequency.isEmpty {
                    infoGrid
                }
                
                if !item.explanation.isEmpty {
                    GrammarInfoSection(title: "Arti", systemImage: "character.book.closed", accentColor: accentColor) {
                        Text(item.explanation)
                            .font(AppTheme.rounded(15))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                if !item.usage.isEmpty {
                    GrammarInfoSection(title: "Penggunaan", systemImage: "list.bullet", accentColor: accentColor) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(item.usage, id: \.self) { point in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 7)
                                    
                                    Text(point)
                                        .font(AppTheme.rounded(14))
                                        .foregroundColor(AppTheme.primaryText(colorScheme))
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(softCardColor)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                if !item.commonMistakes.isEmpty {
                    GrammarInfoSection(title: "Kesalahan Umum", systemImage: "exclamationmark.triangle", accentColor: accentColor) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(item.commonMistakes, id: \.self) { mistake in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(AppTheme.rounded(13))
                                        .foregroundColor(.red)
                                        .padding(.top, 2)

                                    Text(mistake)
                                        .font(AppTheme.rounded(14))
                                        .foregroundColor(AppTheme.primaryText(colorScheme))
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(softCardColor)
                                .cornerRadius(12)
                            }
                        }
                    }
                }

                if !item.examples.isEmpty {
                    GrammarInfoSection(title: "Contoh Kalimat", systemImage: "text.quote", accentColor: accentColor) {
                        VStack(spacing: 10) {
                            ForEach(item.examples.indices, id: \.self) { index in
                                GrammarExampleCard(example: item.examples[index], number: index + 1, accentColor: accentColor)
                            }
                        }
                    } trailing: {
                        Text("\(item.examples.count) kalimat")
                            .font(AppTheme.rounded(11, .bold))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(accentColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
        }
        .background(bgColor.ignoresSafeArea())
        .navigationTitle("Detail Grammar")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Text("JLPT \(item.level)")
                    .font(AppTheme.rounded(11, .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor)
                    .cornerRadius(10)
                
                Spacer()
                
                if !item.structure.isEmpty {
                    Text(item.structure)
                        .font(AppTheme.rounded(11, .semibold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.1))
                        .cornerRadius(10)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.pattern)
                    .font(AppTheme.rounded(36, .black))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !item.romaji.isEmpty {
                    Text(item.romaji)
                        .font(AppTheme.rounded(14, .semibold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                
                Text(item.meaning)
                    .font(AppTheme.rounded(17, .bold))
                    .foregroundColor(accentColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if !item.tags.isEmpty {
                GrammarTagFlow(tags: item.tags, accentColor: accentColor)
            }
        }
        .padding(20)
        .background(cardColor)
        .cornerRadius(22)
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }
    
    private var infoGrid: some View {
        VStack(spacing: 10) {
            if !item.nuance.isEmpty {
                GrammarMiniInfoCard(title: "NUANCE", value: item.nuance, accentColor: accentColor)
            }
            if !item.frequency.isEmpty {
                GrammarMiniInfoCard(title: "FREQUENCY", value: item.frequency, accentColor: accentColor)
            }
        }
    }
}

struct GrammarInfoSection<Content: View, Trailing: View>: View {
    let title: String
    let systemImage: String
    let accentColor: Color
    let content: Content
    let trailing: Trailing

    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, systemImage: String, accentColor: Color, @ViewBuilder content: () -> Content, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.content = content()
        self.trailing = trailing()
    }
    
    init(title: String, systemImage: String, accentColor: Color, @ViewBuilder content: () -> Content) where Trailing == EmptyView {
        self.title = title
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.content = content()
        self.trailing = EmptyView()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(AppTheme.rounded(15, .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 24, height: 24)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(AppTheme.rounded(18, .bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                
                Spacer()
                trailing
            }
            content
        }
        .padding(16)
        .background(AppTheme.surface(colorScheme))
        .cornerRadius(18)
    }
}

struct GrammarMiniInfoCard: View {
    let title: String
    let value: String
    let accentColor: Color

    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(AppTheme.rounded(10, .black))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
                .kerning(1.1)
            
            Text(value)
                .font(AppTheme.rounded(15, .semibold))
                .foregroundColor(accentColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.surface(colorScheme))
        .cornerRadius(16)
    }
}

struct GrammarTagFlow: View {
    let tags: [String]
    let accentColor: Color
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(AppTheme.rounded(11, .bold))
                    .foregroundColor(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(accentColor.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
}

struct GrammarExampleCard: View {
    let example: GrammarExample
    let number: Int
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(number)")
                    .font(AppTheme.rounded(11, .black))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(accentColor)
                    .clipShape(Circle())
                
                Text(example.japanese)
                    .font(AppTheme.rounded(18, .semibold))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if !example.romaji.isEmpty {
                Text(example.romaji)
                    .font(AppTheme.rounded(13))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .padding(.leading, 34)
            }
            
            if !example.translation.isEmpty {
                Text(example.translation)
                    .font(AppTheme.rounded(14, .semibold))
                    .foregroundColor(.primary)
                    .lineSpacing(3)
                    .padding(.leading, 34)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(14)
    }
}

#Preview {
    NavigationView {
        GrammarDetailView(item: GrammarItem.sample)
    }
}
