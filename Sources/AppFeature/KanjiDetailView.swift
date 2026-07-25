import SwiftUI

// MARK: - Kanji Detail View
struct KanjiDetailView: View {
    let item: KanjiItem
    let levelId: String
    @Environment(\.colorScheme) var colorScheme
    
    var bgColor: Color { AppTheme.screenBackground(colorScheme) }
    var cardColor: Color { AppTheme.surface(colorScheme) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // Kartu Kanji Utama
                VStack(spacing: 10) {
                    
                    // Badge level
                    HStack {
                        Text("JLPT \(levelId)")
                            .font(AppTheme.rounded(12, .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.accent)
                            .cornerRadius(8)
                        Spacer()
                    }
                    
                    // Kanji besar + tombol audio
                    ZStack(alignment: .topTrailing) {
                        Text(item.kanji)
                            .font(AppTheme.rounded(110, .light))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                            .frame(maxWidth: .infinity)
                            .frame(height: 130)
                        
                        Button(action: { AudioSpeechHelper.shared.speak(item.kanji) }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(AppTheme.rounded(16, .semibold))
                                .foregroundColor(AppTheme.accent)
                                .padding(10)
                                .background(AppTheme.accent.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .background(cardColor)
                .cornerRadius(18)
                .shadow(color: AppTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
                
                // Romaji + Arti
                VStack(spacing: 4) {
                    Text(item.romaji)
                        .font(AppTheme.rounded(28, .black))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                    Text(item.meaning)
                        .font(AppTheme.rounded(16))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                .padding(.vertical, 4)
                
                // Onyomi & Kunyomi
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ONYOMI")
                            .font(AppTheme.rounded(10, .bold))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .kerning(1.2)
                        Text(item.onyomi)
                            .font(AppTheme.rounded(16, .semibold))
                            .foregroundColor(AppTheme.ocean)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(cardColor)
                    .cornerRadius(14)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KUNYOMI")
                            .font(AppTheme.rounded(10, .bold))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .kerning(1.2)
                        Text(item.kunyomi)
                            .font(AppTheme.rounded(16, .semibold))
                            .foregroundColor(AppTheme.ocean)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(cardColor)
                    .cornerRadius(14)
                }
                .shadow(color: AppTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                
                // Contoh Kata & Kalimat
                if !item.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Contoh Kata & Kalimat")
                            .font(AppTheme.rounded(18, .bold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))

                        VStack(spacing: 0) {
                            ForEach(item.examples.indices, id: \.self) { idx in
                                KanjiExampleRow(example: item.examples[idx])
                                if idx < item.examples.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .background(cardColor)
                        .cornerRadius(14)
                        .shadow(color: AppTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
                    }
                }
            }
            .padding(16)
        }
        .background(bgColor)
        .navigationTitle("Detail Kanji")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Kanji Example Row
struct KanjiExampleRow: View {
    let example: KanjiExample

    private var displaySentence: String? {
        if let furigana = example.sentenceFurigana, !furigana.isEmpty { return furigana }
        if let sentence = example.sentence, !sentence.isEmpty { return sentence }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(example.word)
                    .font(AppTheme.rounded(17, .semibold))
                    .foregroundColor(.primary)
                Text("(\(example.reading))")
                    .font(AppTheme.rounded(13))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    AudioSpeechHelper.shared.speak(example.sentence ?? example.word)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(AppTheme.rounded(13, .semibold))
                        .foregroundColor(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }

            Text("\(example.romaji) — \(example.meaning)")
                .font(AppTheme.rounded(13))
                .foregroundColor(.secondary)

            if let sentence = displaySentence {
                VStack(alignment: .leading, spacing: 3) {
                    Text(sentence)
                        .font(AppTheme.rounded(14, .medium))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let meaning = example.sentenceMeaning, !meaning.isEmpty {
                        Text(meaning)
                            .font(AppTheme.rounded(12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        KanjiDetailView(
            item: KanjiItem(
                id: "N5_004",
                kanji: "学",
                onyomi: "ガク (Gaku)",
                kunyomi: "まな・ぶ (Mana-bu)",
                romaji: "Gaku",
                meaning: "Belajar / Ilmu",
                examples: [
                    KanjiExample(word: "学生", reading: "がくせい", romaji: "Gakusei", meaning: "Mahasiswa/Siswa"),
                    KanjiExample(word: "学校", reading: "がっこう", romaji: "Gakkou", meaning: "Sekolah"),
                    KanjiExample(word: "学ぶ", reading: "まなぶ", romaji: "Manabu", meaning: "Belajar"),
                    KanjiExample(word: "大学", reading: "だいがく", romaji: "Daigaku", meaning: "Universitas"),
                ]
            ),
            levelId: "N5"
        )
    }
}

