import SwiftUI

enum ViewLoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    var icon: String = "tray"

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(AppTheme.rounded(42))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            Text(title)
                .font(AppTheme.rounded(16, .bold))
                .foregroundStyle(AppTheme.primaryText(colorScheme))
            Text(subtitle)
                .font(AppTheme.rounded(13))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}

struct ErrorStateView: View {
    let message: String
    var body: some View {
        EmptyStateView(title: "Gagal memuat data", subtitle: message, icon: "exclamationmark.triangle")
    }
}
