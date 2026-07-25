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

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(AppTheme.rounded(42))
            Text(title).font(AppTheme.rounded(16, .bold))
            Text(subtitle).font(AppTheme.rounded(13)).foregroundColor(.secondary).multilineTextAlignment(.center)
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
