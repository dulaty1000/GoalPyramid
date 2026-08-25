import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case today, week, month, year, fiveYear, analytics, trash
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
        }
    }
}

/// Негізгі терезе: сол жақта секция таңдау, оң жақта сол секцияға сай көрініс.
struct DashboardView: View {
    @State private var selection: DashboardSection? = .today

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
            case .today:
                GoalListView(level: .daily, periodStart: PeriodHelper.periodStart(for: .daily))
            case .week:
                GoalListView(level: .weekly, periodStart: PeriodHelper.periodStart(for: .weekly))
            case .month:
                GoalListView(level: .monthly, periodStart: PeriodHelper.periodStart(for: .monthly))
            case .year:
                GoalListView(level: .yearly, periodStart: PeriodHelper.periodStart(for: .yearly))
            case .fiveYear:
                FiveYearOverviewView()
            case .analytics:
                AnalyticsView()
            case .trash:
                TrashView()
            }
        }
    }
}
