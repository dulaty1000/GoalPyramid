import SwiftUI
import SwiftData

/// "Хронология" — жаңа дерек емес, бар Бүгін/Апта/Ай/5 Жыл беттерінің
/// деректерін біріктіріп көрсететін жалпы шолу. "Күн" қойындысы нақ
/// "Бүгін" бетінің өзін (`GoalListView`) қайта пайдаланады; "Апта"/"Ай"/
/// "Жыл" қойындылары тор (grid) түрінде, әр ұяшық сол кезеңнің алғашқы
/// 3 тапсырмасын алдын ала көрсетіп, басылғанда тиісті нақты бетке
/// (сол бір ортақ `selection`/`periodStop` тетігі арқылы, жаңа детальды
/// экран жасамай) апарады.
struct TimelineView: View {
    /// `(DashboardSection, PeriodStop)` — сайдбар таңдауын және кезең
    /// күйін дәл сол бар беттердегідей ортақ тетік арқылы ауыстырады.
    var onNavigate: (DashboardSection, PeriodStop) -> Void

    @Environment(\.appLanguage) private var language

    @State private var selectedTab: TimelineTab = .day

    // Бір рет, топтап алынатын дерек — әр ұяшық үшін бөлек сұраныс жоқ
    // (талап 7): барлық "Апта"/"Ай"/"Жыл" қойындыларына керек мақсаттар
    // осы БІР @Query-ден, содан кейін жадыда (periodStart бойынша)
    // топтастырылады.
    @Query(filter: #Predicate<GoalItem> { !$0.isDeleted && $0.hasDueDate }) private var allDatedGoals: [GoalItem]

    private enum TimelineTab: String, CaseIterable, Identifiable {
        case day, week, month, year
        var id: String { rawValue }

        func title(_ language: AppLanguage) -> String {
            switch self {
            case .day: return L10n.t(.timelineTabDay, language)
            case .week: return L10n.t(.timelineTabWeek, language)
            case .month: return L10n.t(.timelineTabMonth, language)
            case .year: return L10n.t(.timelineTabYear, language)
            }
        }
    }

    private var todayStart: Date { PeriodHelper.periodStart(for: .daily) }
    private var weekStart: Date { PeriodHelper.periodStart(for: .weekly) }
    private var currentYear: Int { PeriodHelper.year(of: Date()) }

    /// Ағымдағы аптаның 7 күні.
    private var weekDays: [Date] { PeriodHelper.daysInWeek(weekStart) }

    /// Ағымдағы жылдың 12 айы (1...12).
    private var yearMonths: [Date] {
        (1...12).map { PeriodHelper.monthStart(year: currentYear, month: $0) }
    }

    /// "5 Жыл" сайдбар бөлімімен дәл бірдей диапазон.
    private var fiveYearRange: [Int] {
        Array(currentYear...(currentYear + 5))
    }

    /// Белсенді қойындыға сай деңгей бойынша, `periodStart` кілтімен
    /// топтастырылған мақсаттар — бір рет есептеледі, әр ұяшық осыдан
    /// сөздік іздеу (O(1)) арқылы алады.
    private var goalsByPeriodStart: [Date: [GoalItem]] {
        let level: GoalLevel
        switch selectedTab {
        case .day: return [:]
        case .week: level = .daily
        case .month: level = .monthly
        case .year: level = .fiveYear
        }
        var dict: [Date: [GoalItem]] = [:]
        for goal in allDatedGoals where goal.level == level {
            dict[goal.periodStart, default: []].append(goal)
        }
        for key in dict.keys {
            dict[key]?.sort { $0.sortOrder < $1.sortOrder }
        }
        return dict
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(L10n.t(.sidebarTimeline, language), selection: $selectedTab) {
                ForEach(TimelineTab.allCases) { tab in
                    Text(tab.title(language)).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(16)

            switch selectedTab {
            case .day:
                GoalListView(level: .daily, periodStart: todayStart)
            case .week:
                grid(weekCells)
            case .month:
                grid(monthCells)
            case .year:
                grid(yearCells)
            }
        }
        .navigationTitle(L10n.t(.sidebarTimeline, language))
    }

    private struct Cell: Identifiable {
        let id: Date
        let title: String
        let items: [GoalItem]
        let action: () -> Void
    }

    private var weekCells: [Cell] {
        weekDays.map { day in
            Cell(id: day, title: weekdayCellTitle(day), items: goalsByPeriodStart[day] ?? []) {
                onNavigate(.today, .day(day))
            }
        }
    }

    private var monthCells: [Cell] {
        yearMonths.map { monthStart in
            Cell(id: monthStart, title: monthCellTitle(monthStart), items: goalsByPeriodStart[monthStart] ?? []) {
                onNavigate(.month, .month(monthStart))
            }
        }
    }

    private var yearCells: [Cell] {
        fiveYearRange.map { year in
            let yearStart = PeriodHelper.yearStart(year)
            return Cell(id: yearStart, title: String(year), items: goalsByPeriodStart[yearStart] ?? []) {
                onNavigate(.fiveYear, .year(year))
            }
        }
    }

    private func weekdayCellTitle(_ day: Date) -> String {
        let df = DateFormatter()
        df.locale = language.locale
        df.dateFormat = "d"
        return "\(weekdayShort(day)) \(df.string(from: day))"
    }

    private func weekdayShort(_ day: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: day)
        let mondayIndex = (weekday + 5) % 7
        switch mondayIndex {
        case 0: return L10n.t(.weekdayMon, language)
        case 1: return L10n.t(.weekdayTue, language)
        case 2: return L10n.t(.weekdayWed, language)
        case 3: return L10n.t(.weekdayThu, language)
        case 4: return L10n.t(.weekdayFri, language)
        case 5: return L10n.t(.weekdaySat, language)
        default: return L10n.t(.weekdaySun, language)
        }
    }

    private func monthCellTitle(_ monthStart: Date) -> String {
        let df = DateFormatter()
        df.locale = language.locale
        df.dateFormat = "LLLL"
        return df.string(from: monthStart).capitalized
    }

    @ViewBuilder
    private func grid(_ cells: [Cell]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                ForEach(cells) { cell in
                    TimelineCellView(title: cell.title, items: cell.items, language: language, action: cell.action)
                }
            }
            .padding(16)
        }
    }
}

/// Тор ұяшығы — Жобалар/Идеялар карточкаларына сай минималды стиль:
/// дөңгелек бұрыш, жеңіл фон, тек кезеңнің атауы + алғашқы 3 тапсырма/
/// мақсат атауы (+N көбірек белгісімен).
private struct TimelineCellView: View {
    let title: String
    let items: [GoalItem]
    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                ForEach(items.prefix(3)) { item in
                    Text(item.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if items.count > 3 {
                    Text(L10n.timelineMoreCount(count: items.count - 3, language))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .frame(minHeight: 92, alignment: .topLeading)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
