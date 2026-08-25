import SwiftUI

/// Берілген аптаның 7 күнінің тізімі — ағаш навигациядағы "Күн" деңгейінің
/// таңдау беті (Ай → Апта → **Күн**).
struct DaysOverviewView: View {
    @State private var weekStart: Date

    init(weekStart: Date) {
        _weekStart = State(initialValue: weekStart)
    }

    private var days: [Date] {
        PeriodHelper.daysInWeek(weekStart)
    }

    private func shiftWeek(_ deltaDays: Int) {
        guard let newDate = PeriodHelper.calendar.date(byAdding: .day, value: deltaDays, to: weekStart) else { return }
        weekStart = newDate
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
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    shiftWeek(-7)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .help("Алдыңғы апта")

                Button {
                    shiftWeek(7)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .help("Келесі апта")
            }
        }
    }
}
