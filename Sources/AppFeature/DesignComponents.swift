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
                    .foregroundColor(AppTheme.primaryText(scheme))
                    .frame(width: 44, height: 44)
                    .background(AppTheme.surface(scheme))
                    .clipShape(Circle())
                    .shadow(color: AppTheme.softShadow(scheme), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")

            Text(title)
                .font(AppTheme.rounded(24, .heavy))
                .foregroundColor(AppTheme.primaryText(scheme))
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
                .foregroundColor(.secondary)

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
                        .foregroundColor(.secondary)
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
                            .foregroundColor(isSelected ? .white : AppTheme.secondaryText(scheme))
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

// MARK: - Settings building blocks

/// Uppercase section label above a settings card.
struct SettingsSectionLabel: View {
    let text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text)
            .font(AppTheme.rounded(12, .heavy))
            .kerning(0.6)
            .foregroundColor(AppTheme.secondaryText(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}

/// Rounded white card that groups settings rows.
struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) { content }
            .background(AppTheme.surface(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.cardShadow(scheme), radius: 7, x: 0, y: 4)
            .padding(.horizontal, 18)
    }
}

/// Small gradient icon chip used at the leading edge of a settings row.
struct SettingsIcon: View {
    let systemName: String
    let colors: [Color]

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 29, height: 29)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// A settings row: gradient icon, title and trailing content, with an optional
/// hairline separator matching the design's inset divider.
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let colors: [Color]
    let title: String
    var showsDivider: Bool = true
    @ViewBuilder var trailing: Trailing

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, colors: colors)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text(title)
                        .font(AppTheme.rounded(16, .semibold))
                        .foregroundColor(AppTheme.primaryText(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    trailing
                }
                .padding(.vertical, 11)

                if showsDivider {
                    Rectangle()
                        .fill(AppTheme.trackColor(scheme))
                        .frame(height: 1)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
    }
}

/// Explanatory footer under a settings card.
struct SettingsFooter: View {
    let text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text)
            .font(AppTheme.rounded(12, .medium))
            .foregroundColor(AppTheme.secondaryText(scheme))
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}
