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
                .foregroundColor(AppTheme.secondaryText(scheme))

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
                        .foregroundColor(AppTheme.secondaryText(scheme))
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
