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
            Image(systemName: icon).font(.system(size: 42))
            Text(title).font(.system(size: 16, weight: .bold))
            Text(subtitle).font(.system(size: 13)).foregroundColor(.secondary).multilineTextAlignment(.center)
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
