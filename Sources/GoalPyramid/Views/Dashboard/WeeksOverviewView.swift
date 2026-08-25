import SwiftUI

/// Берілген айдың апталар тізімі — ағаш навигациядағы "Апта" деңгейінің
/// таңдау беті (Жыл → Ай → **Апта** → Күн). Push жасамайды, тек
/// `onSelectWeek`/`onNavigateUp`/`onNavigateDown` closure-дары арқылы.
struct WeeksOverviewView: View {
    let monthStart: Date
    var onSelectWeek: (Date) -> Void
    var onNavigateUp: (() -> Void)?
    var onNavigateDown: (() -> Void)?

    private var weeks: [Date] {
        PeriodHelper.weeksInMonth(monthStart)
    }

    var body: some View {
        List(weeks, id: \.self) { week in
            Button {
                onSelectWeek(week)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                    Text(PeriodHelper.displayRange(for: .weekly, periodStart: week))
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.inset)
        .navigationTitle("\(PeriodHelper.displayRange(for: .monthly, periodStart: monthStart)) апталары")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                if let onNavigateUp {
                    Button {
                        onNavigateUp()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .help("Айға қайту")
                }
                if let onNavigateDown {
                    Button {
                        onNavigateDown()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .help("Аптаға өту")
                }
            }
        }
    }
}
