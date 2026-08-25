import SwiftUI

/// Берілген жылдың 12 айының тізімі — ағаш навигациядағы "Ай" деңгейінің
/// таңдау беті ("5 Жыл" → Жыл → **Ай** → Апта → Күн).
struct MonthsOverviewView: View {
    let year: Int

    private var monthSymbols: [String] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "kk_KZ")
        return df.standaloneMonthSymbols.map { $0.capitalized }
    }

    var body: some View {
        List(1...12, id: \.self) { month in
            NavigationLink {
                GoalListView(level: .monthly, periodStart: PeriodHelper.monthStart(year: year, month: month))
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                    Text(monthSymbols[month - 1])
                        .font(.title3.weight(.semibold))
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.inset)
        .navigationTitle("\(year) жылдың айлары")
    }
}
