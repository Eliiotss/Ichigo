import SwiftUI

// MARK: - Screen Header

/// Pinned screen header: a circular back button next to a bold rounded title.
/// Replaces the system navigation bar so the title stays put while content
/// scrolls underneath it.
struct ScreenHeader: View {
    let title: String
    var onBack: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 14) {
            Button {
                if let onBack { onBack() } else { dismiss() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(AppTheme.rounded(17, .bold))
                    .foregroundStyle(AppTheme.primaryText(scheme))
                    .frame(width: 44, height: 44)
                    .background(AppTheme.surface(scheme))
                    .clipShape(Circle())
                    .shadow(color: AppTheme.softShadow(scheme), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")

            Text(title)
                .font(AppTheme.rounded(24, .heavy))
                .foregroundStyle(AppTheme.primaryText(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Search Field

/// Rounded pill search field used across the browsing screens.
struct SearchField: View {
    let placeholder: String
    @Binding var text: String

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(AppTheme.rounded(17, .semibold))
                .foregroundStyle(AppTheme.secondaryText(scheme))

            TextField(placeholder, text: $text)
                .font(AppTheme.rounded(16, .medium))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTheme.rounded(16))
                        .foregroundStyle(AppTheme.secondaryText(scheme))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hapus pencarian")
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 54)
        .background(AppTheme.surface(scheme))
        .clipShape(Capsule())
        .shadow(color: AppTheme.softShadow(scheme), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Kartu Hero Biru

/// Kartu hero bergradien biru yang dipakai di puncak layar detail (Detail Kanji
/// dan Detail Tata Bahasa).
///
/// Dua lingkaran tembus pandang di sudutnya adalah hiasan dari desain; keduanya
/// dipotong mengikuti sudut kartu lewat `clipShape` sehingga tidak meluber.
struct DetailHeroCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [AppTheme.blueLight, AppTheme.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Hiasan sudut kanan atas dan kiri bawah.
                    GeometryReader { geo in
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 190, height: 190)
                            .offset(x: geo.size.width - 110, y: -70)

                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 150, height: 150)
                            .offset(x: -60, y: geo.size.height - 80)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.heroRadius, style: .continuous))
            .shadow(color: AppTheme.blue.opacity(0.28), radius: 16, x: 0, y: 8)
    }
}

/// Lencana putih pekat di atas kartu hero, mis. "JLPT N5".
struct HeroBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTheme.rounded(11, .bold))
            .foregroundStyle(AppTheme.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
    }
}

/// Pil tembus pandang di atas kartu hero, untuk keterangan tambahan seperti
/// pola struktur atau kategori.
struct HeroPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTheme.rounded(11, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.22))
            .clipShape(Capsule())
    }
}

/// Tombol suara bundar tembus pandang di atas kartu hero.
///
/// Tombol ini menerima teksnya langsung, bukan sebuah closure, karena
/// `AudioSpeechHelper` terikat main actor: closure yang disimpan sebagai
/// properti tidak mewarisi isolasi itu, sedangkan closure yang ditulis di dalam
/// `body` mewarisinya.
struct HeroSpeakButton: View {
    let text: String

    var body: some View {
        Button {
            AudioSpeechHelper.shared.speak(text)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(AppTheme.rounded(15, .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.22))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dengarkan pelafalan \(text)")
    }
}

// MARK: - Bagian Berkartu

/// Kartu putih dengan judul dan ikon kecil bergradien lembut di kirinya, dipakai
/// untuk bagian-bagian di layar detail ("Arti", "Penggunaan", dan seterusnya).
struct DetailSectionCard<Content: View, Trailing: View>: View {
    let title: String
    let systemImage: String
    var tint: Color = AppTheme.blue
    @ViewBuilder let content: Content
    @ViewBuilder let trailing: Trailing

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(AppTheme.rounded(13, .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(AppTheme.rounded(17, .bold))
                    .foregroundStyle(AppTheme.primaryText(scheme))

                Spacer(minLength: 8)

                trailing
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface(scheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow(scheme), radius: 8, x: 0, y: 3)
    }
}

extension DetailSectionCard where Trailing == EmptyView {
    init(title: String, systemImage: String, tint: Color = AppTheme.blue, @ViewBuilder content: () -> Content) {
        self.init(title: title, systemImage: systemImage, tint: tint, content: content, trailing: { EmptyView() })
    }
}

// MARK: - Filter Chips

/// Horizontally scrolling pill filters. The selected pill is filled with the
/// accent colour; the rest sit on the raised surface colour.
struct FilterChipRow: View {
    let filters: [String]
    @Binding var selection: String

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    let isSelected = filter == selection
                    Button {
                        selection = filter
                    } label: {
                        Text(filter)
                            .font(AppTheme.rounded(15, .bold))
                            .foregroundStyle(isSelected ? .white : AppTheme.secondaryText(scheme))
                            .padding(.horizontal, 22)
                            .frame(height: 46)
                            .background(isSelected ? AppTheme.accent : AppTheme.surface(scheme))
                            .clipShape(Capsule())
                            .shadow(color: AppTheme.softShadow(scheme), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Sakelar Geser Tema

/// Sakelar geser terang/gelap. Geser atau ketuk ke kiri untuk terang, ke kanan
/// untuk gelap; knopnya menampilkan matahari saat terang dan bulan saat gelap.
///
/// Terikat pada `Bool` sederhana (mati = terang, hidup = gelap). Pemanggil yang
/// menerjemahkannya ke pilihan tersimpan, sehingga sakelar ini tetap murni soal
/// tampilan.
struct ThemeSlideToggle: View {
    @Binding var isDark: Bool

    private let trackWidth: CGFloat = 78
    private let trackHeight: CGFloat = 40
    private let knobSize: CGFloat = 32
    private let inset: CGFloat = 4

    /// Jarak geser knop dari sisi ke sisi.
    private var knobTravel: CGFloat { (trackWidth - knobSize) / 2 - inset }

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: isDark
                        ? [AppTheme.indigoDeep, AppTheme.navy]
                        : [AppTheme.blueLight, AppTheme.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Lambang matahari dan bulan sebagai penanda arah di balik knop.
            HStack {
                Image(systemName: "sun.max.fill")
                    .opacity(isDark ? 0.45 : 0)
                Spacer()
                Image(systemName: "moon.fill")
                    .opacity(isDark ? 0 : 0.5)
            }
            .font(AppTheme.rounded(13, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)

            Circle()
                .fill(Color.white)
                .frame(width: knobSize, height: knobSize)
                .overlay(
                    Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                        .font(AppTheme.rounded(14, .bold))
                        .foregroundStyle(isDark ? AppTheme.indigoDeep : AppTheme.caution)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                .offset(x: isDark ? knobTravel : -knobTravel)
        }
        .frame(width: trackWidth, height: trackHeight)
        .contentShape(Capsule())
        .onTapGesture {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                isDark.toggle()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 6)
                .onEnded { value in
                    // Geser ke kanan → gelap, ke kiri → terang.
                    if value.translation.width > 10, !isDark {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) { isDark = true }
                    } else if value.translation.width < -10, isDark {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) { isDark = false }
                    }
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Mode tampilan")
        .accessibilityValue(isDark ? "Gelap" : "Terang")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Ketuk untuk beralih terang dan gelap")
    }
}
