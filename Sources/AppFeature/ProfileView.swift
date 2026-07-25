import SwiftUI

struct ProfileView: View {
    @ObservedObject var flashcardStore: FlashcardStore
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("user_name") private var userName = "User123"
    @AppStorage("user_email") private var userEmail = ""
    @AppStorage("daily_target") private var dailyTarget = 20
    
    private var dueTodayTotal: Int { flashcardStore.dueTodayGrandTotal }
    private var targetProgress: Double {
        guard dailyTarget > 0 else { return 0 }
        return min(Double(flashcardStore.studiedTodayTotal) / Double(dailyTarget), 1)
    }
    
    var bgColor: Color { colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground) }
    var cardColor: Color { colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white }
    var softCardColor: Color { colorScheme == .dark ? Color(UIColor.tertiarySystemBackground) : Color(UIColor.secondarySystemGroupedBackground) }
    var shadowOpacity: Double { colorScheme == .dark ? 0.3 : 0.05 }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header profil
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [AppTheme.sky, AppTheme.indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 84, height: 84)
                            Text(initials(from: userName))
                                .font(.system(size: 30, weight: .black))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(userName)
                                .font(.system(size: 22, weight: .black))
                            if !userEmail.isEmpty {
                                Text(userEmail)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            Text("JLPT Learner")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(AppTheme.accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 24)
                    
                    // Target harian
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target Harian")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(flashcardStore.studiedTodayTotal)/\(dailyTarget)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        GeometryReader { bar in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.gray.opacity(0.16))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(AppTheme.accent)
                                    .frame(width: bar.size.width * CGFloat(targetProgress), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(16)
                    .background(cardColor)
                    .cornerRadius(16)
                    
                    // Statistik grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ProfileStatTile(title: "Due", value: "\(dueTodayTotal)", subtitle: "hari ini", color: AppTheme.blue, icon: "clock.fill")
                        ProfileStatTile(title: "Belajar", value: "\(flashcardStore.studiedTodayTotal)", subtitle: "kartu", color: AppTheme.teal, icon: "checkmark.circle.fill")
                        ProfileStatTile(title: "Streak", value: "\(flashcardStore.currentStreak)", subtitle: "hari", color: .orange, icon: "flame.fill")
                        ProfileStatTile(title: "Mastered", value: "\(flashcardStore.masteredTotal)", subtitle: "kartu", color: AppTheme.indigo, icon: "star.fill")
                    }
                    
                    // Ringkasan akurasi
                    let summary = flashcardStore.analyticsSummary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ringkasan Jawaban")
                            .font(.system(size: 15, weight: .bold))
                        
                        HStack(spacing: 12) {
                            accuracyPill(label: "Ulang", count: summary.againCount, color: .red)
                            accuracyPill(label: "Susah", count: summary.hardCount, color: .orange)
                            accuracyPill(label: "Bagus", count: summary.goodCount, color: AppTheme.blue)
                            accuracyPill(label: "Mudah", count: summary.easyCount, color: .green)
                        }
                        
                        HStack {
                            Text("Akurasi keseluruhan")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(summary.accuracy * 100))%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(16)
                    .background(cardColor)
                    .cornerRadius(16)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
            }
            .background(bgColor)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func initials(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "U" }
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }
    
    private func accuracyPill(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ProfileStatTile: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                Spacer()
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary)
                    .kerning(0.8)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(colorScheme == .dark ? 0.14 : 0.1))
        .cornerRadius(14)
    }
}

#Preview {
    ProfileView(flashcardStore: FlashcardStore())
}

