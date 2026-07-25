import SwiftUI

// MARK: - Detail Tata Bahasa

/// Halaman detail satu pola tata bahasa: kartu hero biru berisi polanya, dua
/// kartu kecil nuansa dan frekuensi, lalu bagian arti, penggunaan, kesalahan
/// umum, dan contoh kalimat.
struct GrammarDetailView: View {
    let item: GrammarItem
    @Environment(\.colorScheme) var colorScheme

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }

    /// Pil kecil di bawah pola: level, kategori, lalu tag-tagnya.
    private var heroPills: [String] {
        var pills: [String] = []
        if !item.level.isEmpty { pills.append(item.level) }
        if !item.treeCategory.isEmpty { pills.append(item.treeCategory) }
        pills.append(contentsOf: item.tags)
        return pills
    }

    var body: some View {
        VStack(spacing: 14) {
            ScreenHeader(title: "Detail Grammar")

            ScrollView {
                VStack(spacing: 14) {
                    heroCard

                    if !item.nuance.isEmpty || !item.frequency.isEmpty {
                        infoRow
                    }

                    if !item.explanation.isEmpty {
                        explanationSection
                    }

                    if !item.usage.isEmpty {
                        usageSection
                    }

                    if !item.commonMistakes.isEmpty {
                        mistakeSection
                    }

                    if !item.examples.isEmpty {
                        exampleSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
        .background(bgColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Kartu hero

    private var heroCard: some View {
        DetailHeroCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    HeroBadge(text: "JLPT \(item.level)")

                    Spacer(minLength: 0)

                    if !item.structure.isEmpty {
                        HeroPill(text: item.structure)
                    }
                }

                Text(item.pattern)
                    .font(AppTheme.rounded(34, .bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                if !item.romaji.isEmpty {
                    Text(item.romaji)
                        .font(AppTheme.rounded(14))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 4)
                }

                Text(item.meaning)
                    .font(AppTheme.rounded(18, .bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                if !heroPills.isEmpty {
                    HeroPillFlow(pills: heroPills)
                        .padding(.top, 14)
                }
            }
        }
    }

    // MARK: - Nuansa & frekuensi

    private var infoRow: some View {
        HStack(spacing: 12) {
            if !item.nuance.isEmpty {
                GrammarMiniInfoCard(title: "NUANCE", value: item.nuance, valueColor: AppTheme.primaryText(colorScheme))
            }
            if !item.frequency.isEmpty {
                GrammarMiniInfoCard(title: "FREQUENCY", value: item.frequency, valueColor: AppTheme.accent)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Bagian isi

    private var explanationSection: some View {
        DetailSectionCard(title: "Arti", systemImage: "doc.text.fill") {
            Text(item.explanation)
                .font(AppTheme.rounded(15))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var usageSection: some View {
        DetailSectionCard(title: "Penggunaan", systemImage: "list.bullet") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(item.usage, id: \.self) { point in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 7, height: 7)
                            .padding(.top, 7)

                        Text(point)
                            .font(AppTheme.rounded(14))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.softSurface(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var mistakeSection: some View {
        DetailSectionCard(title: "Kesalahan Umum", systemImage: "exclamationmark.triangle.fill", tint: AppTheme.warning) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(item.commonMistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(AppTheme.rounded(14))
                            .foregroundColor(AppTheme.warning)
                            .padding(.top, 1)

                        Text(mistake)
                            .font(AppTheme.rounded(14))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.warning.opacity(colorScheme == .dark ? 0.16 : 0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var exampleSection: some View {
        DetailSectionCard(title: "Contoh Kalimat", systemImage: "quote.bubble.fill") {
            VStack(spacing: 10) {
                ForEach(item.examples.indices, id: \.self) { index in
                    GrammarExampleCard(example: item.examples[index], number: index + 1)
                }
            }
        } trailing: {
            Text("\(item.examples.count) kalimat")
                .font(AppTheme.rounded(11, .bold))
                .foregroundColor(AppTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Deretan Pil di Kartu Hero

/// Pil-pil kecil di bawah pola yang otomatis turun baris ketika kehabisan
/// tempat mendatar.
struct HeroPillFlow: View {
    let pills: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(pills, id: \.self) { pill in
                Text(pill)
                    .font(AppTheme.rounded(11, .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Kartu Kecil Nuansa / Frekuensi

/// Kartu kecil berlabel di atas dan nilainya di bawah.
struct GrammarMiniInfoCard: View {
    let title: String
    let value: String
    let valueColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(AppTheme.rounded(10, .bold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
                .kerning(1.1)

            Text(value)
                .font(AppTheme.rounded(15, .semibold))
                .foregroundColor(valueColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(AppTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Kartu Contoh Kalimat

/// Satu contoh kalimat bernomor: kalimat Jepang, romaji, lalu terjemahannya.
struct GrammarExampleCard: View {
    let example: GrammarExample
    let number: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(number)")
                    .font(AppTheme.rounded(11, .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(AppTheme.accent)
                    .clipShape(Circle())

                Text(example.japanese)
                    .font(AppTheme.rounded(17, .semibold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !example.romaji.isEmpty {
                Text(example.romaji)
                    .font(AppTheme.rounded(13))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 32)
            }

            if !example.translation.isEmpty {
                Text(example.translation)
                    .font(AppTheme.rounded(14, .bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 32)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.softSurface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Pratinjau
#Preview {
    NavigationView {
        GrammarDetailView(item: GrammarItem.sample)
    }
}
