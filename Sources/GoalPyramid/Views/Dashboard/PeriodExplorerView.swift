import SwiftUI

/// Бүгін/Апта/Ай/5 Жыл сайдбар тармақтарының бәрі бөлісетін кезең-иерархия
/// шежіресі: 5 Жыл → Жыл → Ай → Апта → Күн. Қай бет көрсетілетінін сырттан
/// `stop` арқылы басқаруға болады (мыс. "Бүгін" — `.day(today)`-дан
/// бастайды, "5 Жыл" — `.years`-тан). Барлық ауысу (жол таңдау, ◄/►)
/// `stop`-ты ауыстыру арқылы ғана жасалады — **NavigationLink push
/// қолданылмайды**, сондықтан macOS-тың өз "артқа" батырмасы ешқашан
/// пайда болмайды.
struct PeriodExplorerView: View {
    @Binding var stop: PeriodStop

    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private var years: [Int] {
        let currentYear = PeriodHelper.year(of: Date())
        return Array(currentYear...(currentYear + 5))
    }

    var body: some View {
        NavigationStack {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch stop {
        case .years:
            yearsList

        case .year(let year):
            GoalListView(
                level: .fiveYear,
                periodStart: PeriodHelper.yearStart(year),
                onNavigateUp: { stop = .years },
                onNavigateDown: { stop = .months(year) }
            )

        case .months(let year):
            MonthsOverviewView(
                year: year,
                onSelectMonth: { month in
                    stop = .month(PeriodHelper.monthStart(year: year, month: month))
                },
                onNavigateUp: { stop = .year(year) },
                onNavigateDown: { stop = .month(PeriodHelper.monthStart(year: year, month: 1)) }
            )

        case .month(let monthStart):
            GoalListView(
                level: .monthly,
                periodStart: monthStart,
                onNavigateUp: { stop = .year(PeriodHelper.year(of: monthStart)) },
                onNavigateDown: { stop = .weeks(monthStart) }
            )

        case .weeks(let monthStart):
            WeeksOverviewView(
                monthStart: monthStart,
                onSelectWeek: { week in stop = .week(week) },
                onNavigateUp: { stop = .month(monthStart) },
                onNavigateDown: {
                    let weeks = PeriodHelper.weeksInMonth(monthStart)
                    stop = .week(weeks.first ?? monthStart)
                }
            )

        case .week(let weekStart):
            GoalListView(
                level: .weekly,
                periodStart: weekStart,
                onNavigateUp: { stop = .month(PeriodHelper.periodStart(for: .monthly, containing: weekStart)) },
                onNavigateDown: { stop = .days(weekStart) }
            )

        case .days(let weekStart):
            DaysOverviewView(
                weekStart: weekStart,
                onSelectDay: { day in stop = .day(day) },
                onNavigateUp: { stop = .week(weekStart) },
                onNavigateDown: {
                    let days = PeriodHelper.daysInWeek(weekStart)
                    stop = .day(days.first ?? weekStart)
                }
            )

        case .day(let dayStart):
            GoalListView(
                level: .daily,
                periodStart: dayStart,
                onNavigateUp: { stop = .week(PeriodHelper.periodStart(for: .weekly, containing: dayStart)) }
            )
        }
    }

    private var yearsList: some View {
        List(years, id: \.self) { year in
            Button {
                stop = .year(year)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mountain.2.fill")
                        .foregroundStyle(Theme.accent)
                        .font(.title3)
                    Text(String(year))
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.inset)
        .navigationTitle(L10n.t(.sidebarFiveYear, language))
    }
}
