import SwiftUI

/// Берілген айдың апталар тізімі — ағаш навигациядағы "Апта" деңгейінің
/// таңдау беті (Жыл → Ай → **Апта** → Күн).
struct WeeksOverviewView: View {
    @State private var monthStart: Date

    init(monthStart: Date) {
        _monthStart = State(initialValue: monthStart)
    }

    private var weeks: [Date] {
        PeriodHelper.weeksInMonth(monthStart)
    }

    private func shiftMonth(_ delta: Int) {
        guard let newDate = PeriodHelper.calendar.date(byAdding: .month, value: delta, to: monthStart) else { return }
        monthStart = newDate
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
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    shiftMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .help("Алдыңғы ай")

                Button {
                    shiftMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .help("Келесі ай")
            }
        }
    }
}
