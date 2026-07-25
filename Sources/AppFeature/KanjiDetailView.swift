import SwiftUI

// MARK: - Detail Kanji

/// Halaman detail satu kanji: kartu hero biru berisi hurufnya, dua kartu cara
/// baca, lalu daftar contoh kata beserta kalimatnya.
struct KanjiDetailView: View {
    let item: KanjiItem
    let levelId: String
    @Environment(\.colorScheme) var colorScheme

    var bgColor: Color { AppTheme.screenBackground(colorScheme) }

    var body: some View {
        VStack(spacing: 14) {
            ScreenHeader(title: "Detail Kanji")

            ScrollView {
                VStack(spacing: 14) {
                    heroCard
                    readingCards

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
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    HeroBadge(text: "JLPT \(levelId)")

                    Spacer()

                    HeroSpeakButton(text: item.kanji)
                }

                Text(item.kanji)
                    .font(AppTheme.rounded(96, .regular))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                Text(item.romaji)
                    .font(AppTheme.rounded(30, .bold))
                    .foregroundColor(.white)
                    .padding(.top, 10)

                Text(item.meaning)
                    .font(AppTheme.rounded(15))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Onyomi & Kunyomi

    private var readingCards: some View {
        HStack(spacing: 12) {
            KanjiReadingCard(title: "ONYOMI", value: item.onyomi)
            KanjiReadingCard(title: "KUNYOMI", value: item.kunyomi)
        }
    }

    // MARK: - Contoh kata & kalimat

    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contoh Kata & Kalimat")
                .font(AppTheme.rounded(18, .bold))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(item.examples.indices, id: \.self) { index in
                KanjiExampleCard(example: item.examples[index])
            }
        }
    }
}

// MARK: - Kartu Cara Baca

/// Satu kartu cara baca (onyomi atau kunyomi) dengan label kecil di atasnya.
struct KanjiReadingCard: View {
    let title: String
    let value: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.rounded(10, .bold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
                .kerning(1.2)

            Text(value.isEmpty ? "—" : value)
                .font(AppTheme.rounded(17, .bold))
                .foregroundColor(AppTheme.accent)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Kartu Contoh Kanji

/// Satu contoh kata: kata dan cara bacanya, romaji beserta artinya, lalu kalimat
/// contoh di dalam kotak lembut bila datanya tersedia.
struct KanjiExampleCard: View {
    let example: KanjiExample

    @Environment(\.colorScheme) private var colorScheme

    /// Kalimat yang ditampilkan: utamakan versi berfurigana bila ada.
    private var displaySentence: String? {
        if let furigana = example.sentenceFurigana, !furigana.isEmpty { return furigana }
        if let sentence = example.sentence, !sentence.isEmpty { return sentence }
        return nil
    }

    private var softBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : AppTheme.pageLight.opacity(0.55)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Text(example.word)
                    .font(AppTheme.rounded(19, .bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text("（\(example.reading)）")
                    .font(AppTheme.rounded(13))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))

                Spacer(minLength: 4)

                Button {
                    AudioSpeechHelper.shared.speak(example.sentence ?? example.word)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(AppTheme.rounded(12, .semibold))
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.accent.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dengarkan \(example.word)")
            }

            Text("\(example.romaji) — \(example.meaning)")
                .font(AppTheme.rounded(13, .semibold))
                .foregroundColor(AppTheme.accent)
                .fixedSize(horizontal: false, vertical: true)

            if let sentence = displaySentence {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sentence)
                        .font(AppTheme.rounded(15, .medium))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)

                    if let meaning = example.sentenceMeaning, !meaning.isEmpty {
                        Text(meaning)
                            .font(AppTheme.rounded(13))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(softBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Pratinjau
#Preview {
    NavigationView {
        KanjiDetailView(
            item: KanjiItem(
                id: "N5_001",
                kanji: "日",
                onyomi: "ニチ・ジツ",
                kunyomi: "ひ・か",
                romaji: "nichi",
                meaning: "hari / matahari",
                examples: [
                    KanjiExample(
                        word: "日曜日",
                        reading: "にちようび",
                        romaji: "nichiyoubi",
                        meaning: "Minggu",
                        sentence: "日曜日はやすみです。",
                        sentenceMeaning: "Hari Minggu libur."
                    )
                ]
            ),
            levelId: "N5"
        )
    }
}
