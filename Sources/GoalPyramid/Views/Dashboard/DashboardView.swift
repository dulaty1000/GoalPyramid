import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case today, week, month, year, fiveYear, analytics, trash, ideas
    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Бүгін"
        case .week: return "Апта"
        case .month: return "Ай"
        case .year: return "Жыл"
        case .fiveYear: return "5 Жыл"
        case .analytics: return "Аналитика"
        case .trash: return "Қоқыс"
        case .ideas: return "Идеялар"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "checkmark.circle.fill"
        case .week: return "calendar.badge.clock"
        case .month: return "calendar"
        case .year: return "flag.fill"
        case .fiveYear: return "mountain.2.fill"
        case .analytics: return "chart.pie.fill"
        case .trash: return "trash"
        case .ideas: return "lightbulb.fill"
        }
    }
}

/// Негізгі терезе: сол жақта секция таңдау, оң жақта сол секцияға сай көрініс.
///
/// "Бүгін"/"Апта"/"Ай"/"5 Жыл" төртеуі де бір ортақ `periodStop` күйі арқылы
/// `PeriodExplorerView`-ды бөліседі — сайдбардан қайсысын бассаң, `periodStop`
/// сол секцияның бастапқы нүктесіне (бүгінгі күн/осы апта/осы ай/жылдар
/// тізімі) қалпына келеді, содан кейін ◄/► арқылы иерархия бойынша еркін
/// жылжуға болады.
struct DashboardView: View {
    @State private var selection: DashboardSection? = .today
    @State private var periodStop: PeriodStop = .day(PeriodHelper.periodStart(for: .daily))

    var body: some View {
        NavigationSplitView {
            List(DashboardSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Мақсат Пирамидасы")
            .listStyle(.sidebar)
        } detail: {
            switch selection ?? .today {
            case .today, .week, .month, .fiveYear:
                PeriodExplorerView(stop: $periodStop)
            case .year:
                GoalListView(level: .yearly, periodStart: PeriodHelper.periodStart(for: .yearly))
            case .analytics:
                AnalyticsView()
            case .trash:
                TrashView()
            case .ideas:
                IdeasSectionView()
            }
        }
        .onChange(of: selection) { _, newValue in
            switch newValue {
            case .today:
                periodStop = .day(PeriodHelper.periodStart(for: .daily))
            case .week:
                periodStop = .week(PeriodHelper.periodStart(for: .weekly))
            case .month:
                periodStop = .month(PeriodHelper.periodStart(for: .monthly))
            case .fiveYear:
                periodStop = .years
            case .year, .analytics, .trash, .ideas, nil:
                break
            }
        }
    }
}
