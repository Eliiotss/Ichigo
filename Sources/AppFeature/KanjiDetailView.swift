import SwiftUI

// MARK: - Kanji Detail View
struct KanjiDetailView: View {
    let item: KanjiItem
    let levelId: String
    @Environment(\.colorScheme) var colorScheme
    
    var bgColor: Color {
        colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground)
    }
    var cardColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // Kartu Kanji Utama
                VStack(spacing: 10) {
                    
                    // Badge level
                    HStack {
                        Text("JLPT \(levelId)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange)
                            .cornerRadius(8)
                        Spacer()
                    }
                    
                    // Kanji besar + tombol audio
                    ZStack(alignment: .topTrailing) {
                        Text(item.kanji)
                            .font(.system(size: 110, weight: .light))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 130)
                        
                        Button(action: { AudioSpeechHelper.shared.speak(item.kanji) }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                                .padding(10)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .background(cardColor)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 6, x: 0, y: 2)
                
                // Romaji + Arti
                VStack(spacing: 4) {
                    Text(item.romaji)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.primary)
                    Text(item.meaning)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                // Onyomi & Kunyomi
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ONYOMI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .kerning(1.2)
                        Text(item.onyomi)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(cardColor)
                    .cornerRadius(14)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KUNYOMI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .kerning(1.2)
                        Text(item.kunyomi)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(cardColor)
                    .cornerRadius(14)
                }
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 4, x: 0, y: 1)
                
                // Contoh Kata & Kalimat
                if !item.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Contoh Kata & Kalimat")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

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
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 4, x: 0, y: 1)
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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Text("(\(example.reading))")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    AudioSpeechHelper.shared.speak(example.sentence ?? example.word)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }

            Text("\(example.romaji) — \(example.meaning)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            if let sentence = displaySentence {
                VStack(alignment: .leading, spacing: 3) {
                    Text(sentence)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let meaning = example.sentenceMeaning, !meaning.isEmpty {
                        Text(meaning)
                            .font(.system(size: 12))
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

