import SwiftUI

/// Берілген аптаның 7 күнінің тізімі — ағаш навигациядағы "Күн" деңгейінің
/// таңдау беті (Ай → Апта → **Күн**). Push жасамайды, тек
/// `onSelectDay`/`onNavigateUp`/`onNavigateDown` closure-дары арқылы.
struct DaysOverviewView: View {
    let weekStart: Date
    var onSelectDay: (Date) -> Void
    var onNavigateUp: (() -> Void)?
    var onNavigateDown: (() -> Void)?

    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private var days: [Date] {
        PeriodHelper.daysInWeek(weekStart)
    }

    var body: some View {
        List(days, id: \.self) { day in
            Button {
                onSelectDay(day)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .font(.title3)
                    Text(PeriodHelper.displayRange(for: .daily, periodStart: day))
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.inset)
        .navigationTitle(L10n.weekDaysTitle(weekLabel: PeriodHelper.displayRange(for: .weekly, periodStart: weekStart), language))
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                if let onNavigateUp {
                    Button {
                        onNavigateUp()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .help(L10n.t(.navBackToWeek, language))
                }
                if let onNavigateDown {
                    Button {
                        onNavigateDown()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .help(L10n.t(.navForwardToDay, language))
                }
            }
        }
    }
}
