import SwiftUI

struct ProfileView: View {
    @ObservedObject var flashcardStore: FlashcardStore
    @ObservedObject private var account = AccountStore.shared
    @Environment(\.colorScheme) private var scheme

    @AppStorage("daily_target") private var dailyTarget = 20

    private var dueTodayTotal: Int { flashcardStore.dueTodayGrandTotal }
    private var targetProgress: Double {
        guard dailyTarget > 0 else { return 0 }
        return min(Double(flashcardStore.studiedTodayTotal) / Double(dailyTarget), 1)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    header

                    dailyTargetCard
                    statsGrid
                    answerSummaryCard

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
            }
            .background(AppTheme.screenBackground(scheme).ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Gradient header

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Profile")
                    .font(AppTheme.rounded(22, .heavy))
                    .foregroundColor(.white)
                Spacer()
            }

            VStack(spacing: 10) {
                Text(account.initials)
                    .font(AppTheme.rounded(32, .heavy))
                    .foregroundColor(.white)
                    .frame(width: 88, height: 88)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 3))

                Text(account.displayName)
                    .font(AppTheme.rounded(22, .heavy))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if !account.email.isEmpty {
                    Text(account.email)
                        .font(AppTheme.rounded(12, .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }

                Text("JLPT Learner")
                    .font(AppTheme.rounded(12, .heavy))
                    .foregroundColor(AppTheme.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: [AppTheme.blueLight, AppTheme.blue],
                               startPoint: .top, endPoint: .bottomTrailing)
                Circle().fill(Color.white.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .offset(x: 30, y: -30)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .padding(.horizontal, -18)
    }

    // MARK: - Daily target

    private var dailyTargetCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Target Harian")
                    .font(AppTheme.rounded(13, .heavy))
                    .foregroundColor(AppTheme.primaryText(scheme))
                Spacer()
                Text("\(flashcardStore.studiedTodayTotal)/\(dailyTarget)")
                    .font(AppTheme.rounded(13, .heavy))
                    .foregroundColor(AppTheme.secondaryText(scheme))
            }

            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.trackColor(scheme))
                    Capsule()
                        .fill(LinearGradient(colors: [AppTheme.blueLight, AppTheme.blue],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(bar.size.width * targetProgress, targetProgress > 0 ? 8 : 0))
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(AppTheme.surface(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.cardShadow(scheme), radius: 9, x: 0, y: 6)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ProfileStatTile(icon: "clock.fill", iconTint: AppTheme.blue, chip: Color(hex: 0xEBF3FF),
                            value: "\(dueTodayTotal)", unit: "due", caption: "hari ini")
            ProfileStatTile(icon: "checkmark.circle.fill", iconTint: Color(hex: 0x22B981), chip: Color(hex: 0xE7F8ED),
                            value: "\(flashcardStore.studiedTodayTotal)", unit: "kartu", caption: "belajar")
            ProfileStatTile(icon: "flame.fill", iconTint: Color(hex: 0xFF9500), chip: Color(hex: 0xFFF1E4),
                            value: "\(flashcardStore.currentStreak)", unit: "hari", caption: "streak")
            ProfileStatTile(icon: "star.fill", iconTint: AppTheme.indigoDeep, chip: Color(hex: 0xEAF0FF),
                            value: "\(flashcardStore.masteredTotal)", unit: "kartu", caption: "mastered")
        }
    }

    // MARK: - Answer summary

    private var answerSummaryCard: some View {
        let summary = flashcardStore.analyticsSummary
        return VStack(alignment: .leading, spacing: 12) {
            Text("Ringkasan Jawaban")
                .font(AppTheme.rounded(15, .heavy))
                .foregroundColor(AppTheme.primaryText(scheme))

            HStack(spacing: 10) {
                answerPill("Ulang", summary.againCount, Color(hex: 0xFF3B30), Color(hex: 0xFFECEB))
                answerPill("Susah", summary.hardCount, Color(hex: 0xFF9500), Color(hex: 0xFFF1E4))
                answerPill("Bagus", summary.goodCount, AppTheme.blue, Color(hex: 0xEBF3FF))
                answerPill("Mudah", summary.easyCount, Color(hex: 0x22B981), Color(hex: 0xE7F8ED))
            }

            Rectangle()
                .fill(AppTheme.trackColor(scheme))
                .frame(height: 1)

            HStack {
                Text("Akurasi keseluruhan")
                    .font(AppTheme.rounded(13, .semibold))
                    .foregroundColor(AppTheme.secondaryText(scheme))
                Spacer()
                Text("\(Int(summary.accuracy * 100))%")
                    .font(AppTheme.rounded(15, .heavy))
                    .foregroundColor(AppTheme.primaryText(scheme))
            }
        }
        .padding(16)
        .background(AppTheme.surface(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.cardShadow(scheme), radius: 9, x: 0, y: 6)
    }

    private func answerPill(_ label: String, _ count: Int, _ tint: Color, _ background: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(AppTheme.rounded(18, .heavy))
                .foregroundColor(tint)
            Text(label)
                .font(AppTheme.rounded(10, .bold))
                .foregroundColor(AppTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Stat tile

struct ProfileStatTile: View {
    let icon: String
    let iconTint: Color
    let chip: Color
    let value: String
    let unit: String
    let caption: String

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(iconTint)
                .frame(width: 32, height: 32)
                .background(chip)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppTheme.rounded(24, .heavy))
                    .foregroundColor(AppTheme.primaryText(scheme))
                Text(unit)
                    .font(AppTheme.rounded(11, .bold))
                    .foregroundColor(AppTheme.secondaryText(scheme))
            }

            Text(caption)
                .font(AppTheme.rounded(11, .bold))
                .foregroundColor(AppTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.surface(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.cardShadow(scheme), radius: 9, x: 0, y: 6)
    }
}

#Preview {
    ProfileView(flashcardStore: FlashcardStore())
}
