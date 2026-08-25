import SwiftUI

/// Берілген айдың апталар тізімі — ағаш навигациядағы "Апта" деңгейінің
/// таңдау беті (Жыл → Ай → **Апта** → Күн).
struct WeeksOverviewView: View {
    let monthStart: Date

    private var weeks: [Date] {
        PeriodHelper.weeksInMonth(monthStart)
    }

    var body: some View {
        List(weeks, id: \.self) { week in
            NavigationLink {
                GoalListView(level: .weekly, periodStart: week)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                    Text(PeriodHelper.displayRange(for: .weekly, periodStart: week))
                        .font(.title3.weight(.semibold))
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.inset)
        .navigationTitle("\(PeriodHelper.displayRange(for: .monthly, periodStart: monthStart)) апталары")
    }
}
