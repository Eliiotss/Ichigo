import SwiftUI

struct HomeStatsCard: View {
    let dueToday: Int
    let studiedToday: Int
    let streak: Int
    let mastered: Int
    let dailyTarget: Int
    let isIPad: Bool
    let cardColor: Color
    let softCardColor: Color
    let shadowOpacity: Double
    
    private var progress: Double {
        guard dailyTarget > 0 else { return 0 }
        return min(Double(studiedToday) / Double(dailyTarget), 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isIPad ? 10 : 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Progress Hari Ini")
                    .font(.system(size: isIPad ? 13 : 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .kerning(0.8)
                Spacer()
                Text("\(studiedToday)/\(dailyTarget)")
                    .font(.system(size: isIPad ? 13 : 11, weight: .bold))
                    .foregroundColor(AppTheme.accent)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.15)).frame(height: 5)
                    Capsule().fill(AppTheme.accent).frame(width: geo.size.width * CGFloat(progress), height: 5)
                }
            }
            .frame(height: 5)
            
            HStack(spacing: isIPad ? 12 : 8) {
                MiniStat(label: "Due", value: "\(dueToday)", color: AppTheme.blue, isIPad: isIPad)
                MiniStat(label: "Streak", value: "\(streak)", color: .orange, isIPad: isIPad)
                MiniStat(label: "Mastered", value: "\(mastered)", color: AppTheme.indigo, isIPad: isIPad)
            }
        }
        .padding(isIPad ? 14 : 10)
        .background(cardColor)
        .cornerRadius(isIPad ? 14 : 12)
        .shadow(color: .black.opacity(shadowOpacity), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Mini Stat (compact horizontal)
struct MiniStat: View {
    let label: String
    let value: String
    let color: Color
    let isIPad: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: isIPad ? 11 : 10, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: isIPad ? 12 : 11, weight: .black))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
