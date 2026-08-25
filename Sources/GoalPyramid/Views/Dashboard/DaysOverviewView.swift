import SwiftUI

/// Берілген аптаның 7 күнінің тізімі — ағаш навигациядағы "Күн" деңгейінің
/// таңдау беті (Ай → Апта → **Күн**).
struct DaysOverviewView: View {
    let weekStart: Date

    private var days: [Date] {
        PeriodHelper.daysInWeek(weekStart)
    }

    var body: some View {
        List(days, id: \.self) { day in
            NavigationLink {
                GoalListView(level: .daily, periodStart: day)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                    Text(PeriodHelper.displayRange(for: .daily, periodStart: day))
                        .font(.title3.weight(.semibold))
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.inset)
        .navigationTitle("\(PeriodHelper.displayRange(for: .weekly, periodStart: weekStart)) күндері")
    }
}
