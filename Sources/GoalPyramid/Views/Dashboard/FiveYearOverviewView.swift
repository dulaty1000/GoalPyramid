import SwiftUI
import SwiftData

/// "5 Жыл" бөлімінің басты беті: жылдар тізімі. Әр жылды бассаң — сол жылға
/// арналған жеке мақсаттар бетіне (GoalListView) ауысасың, артқа қайту үшін
/// стандартты navigation back батырмасы қолданылады.
struct FiveYearOverviewView: View {
    private var years: [Int] {
        let currentYear = PeriodHelper.calendar.component(.year, from: Date())
        return Array(currentYear...(currentYear + 5))
    }

    var body: some View {
        NavigationStack {
            List(years, id: \.self) { year in
                NavigationLink {
                    GoalListView(level: .fiveYear, periodStart: PeriodHelper.yearStart(year))
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mountain.2.fill")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)
                        Text(String(year))
                            .font(.title3.weight(.semibold))
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.inset)
            .navigationTitle("5 Жыл")
        }
    }
}
