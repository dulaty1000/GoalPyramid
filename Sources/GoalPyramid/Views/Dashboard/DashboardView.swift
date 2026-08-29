import SwiftUI
import SwiftData

enum DashboardSection: String, CaseIterable, Identifiable {
    case timeline, today, week, month, year, fiveYear, habits, analytics, ideas, projects, settings, trash
    var id: String { rawValue }

    /// Сайдбардың жоғарғы тобы — "Хронология" (бүкіл мәзірдің ең
    /// басты, бірінші элементі) + мақсат пирамидасының кезең-иерархиясы.
    static let primaryGroup: [DashboardSection] = [.timeline, .today, .week, .month, .year, .fiveYear]

    /// Сайдбардың ортаңғы тобы — екі топтың арасында, өз алдына бөлек,
    /// екі жағынан да divider-мен қоршалған.
    static let habitsGroup: [DashboardSection] = [.habits]

    /// Сайдбардың төменгі тобы — қосымша бөлімдер, divider-ден кейін.
    static let secondaryGroup: [DashboardSection] = [.analytics, .ideas, .projects, .settings, .trash]

    /// Берілген тілге сай атау — параметр ретінде талап етіледі, сол арқылы
    /// `DashboardView` өз `@Environment(\.appLanguage)`-ін тікелей береді
    /// де, SwiftUI тіл ауысқанда сайдбарды дереу қайта салады.
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .timeline: return L10n.t(.sidebarTimeline, language)
        case .today: return L10n.t(.sidebarToday, language)
        case .projects: return L10n.t(.sidebarProjects, language)
        case .week: return L10n.t(.sidebarWeek, language)
        case .month: return L10n.t(.sidebarMonth, language)
        case .year: return L10n.t(.sidebarYear, language)
        case .fiveYear: return L10n.t(.sidebarFiveYear, language)
        case .habits: return L10n.t(.sidebarHabits, language)
        case .analytics: return L10n.t(.sidebarAnalytics, language)
        case .trash: return L10n.t(.sidebarTrash, language)
        case .ideas: return L10n.t(.sidebarIdeas, language)
        case .settings: return L10n.t(.sidebarSettings, language)
        }
    }

    var systemImage: String {
        switch self {
        case .timeline: return "clock"
        case .today: return "checkmark.circle.fill"
        case .projects: return "folder.fill"
        case .week: return "calendar.badge.clock"
        case .month: return "calendar"
        case .year: return "flag.fill"
        case .fiveYear: return "mountain.2.fill"
        case .habits: return "repeat.circle.fill"
        case .analytics: return "chart.pie.fill"
        case .trash: return "trash"
        case .ideas: return "lightbulb.fill"
        case .settings: return "gearshape.fill"
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

    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [HabitItem]
    /// Циклі аяқталған, "жалғастырамыз ба?" деп сұрау керек дағды — бір
    /// сәтте біреуі ғана сұралады, жауап бергеннен кейін келесісі
    /// (болса) қайта тексеріледі.
    @State private var renewalHabit: HabitItem?
    /// "Хронология"-дан ұяшық басып нақты күн/апта/ай/жылға секіргенде,
    /// төмендегі `.onChange(of: selection)` сол секцияның ӘДЕПКІ мәніне
    /// (мыс. бүгінгі күн) қайта орнатып, дәл біз таңдаған нәтижені
    /// езіп жіберуі мүмкін. Осы жалауша сол бір ғана келесі `onChange`
    /// шақыруын аттап өтеді.
    @State private var suppressNextPeriodReset = false

    /// Терезе түбірінен (`GoalPyramidApp`) `.environment(\.appLanguage, ...)`
    /// арқылы келеді — тіл ауысқанда SwiftUI осы мәнді оқитын әр View-ды
    /// (соның ішінде осы сайдбарды) дереу, кепілді қайта салады.
    @Environment(\.appLanguage) private var language

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(DashboardSection.primaryGroup) { section in
                    Label(section.title(language), systemImage: section.systemImage)
                        .tag(section)
                }

                Divider()

                ForEach(DashboardSection.habitsGroup) { section in
                    Label(section.title(language), systemImage: section.systemImage)
                        .tag(section)
                }

                Divider()

                ForEach(DashboardSection.secondaryGroup) { section in
                    Label(section.title(language), systemImage: section.systemImage)
                        .tag(section)
                }
            }
            .navigationTitle(L10n.t(.appNavTitle, language))
            .listStyle(.sidebar)
        } detail: {
            switch selection ?? .today {
            case .timeline:
                TimelineView(onNavigate: { section, stop in
                    suppressNextPeriodReset = true
                    periodStop = stop
                    selection = section
                })
            case .today, .week, .month, .fiveYear:
                PeriodExplorerView(stop: $periodStop)
            case .year:
                GoalListView(
                    level: .yearly,
                    periodStart: PeriodHelper.periodStart(for: .yearly),
                    onNavigateUp: {
                        periodStop = .years
                        selection = .fiveYear
                    },
                    onNavigateDown: {
                        periodStop = .months(PeriodHelper.year(of: Date()))
                        selection = .fiveYear
                    }
                )
            case .habits:
                HabitsView()
            case .analytics:
                AnalyticsView()
            case .trash:
                TrashView()
            case .ideas:
                IdeasSectionView()
            case .projects:
                ProjectsSectionView()
            case .settings:
                SettingsView()
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            if suppressNextPeriodReset {
                suppressNextPeriodReset = false
                return
            }
            switch newValue {
            case .today:
                periodStop = .day(PeriodHelper.periodStart(for: .daily))
            case .week:
                periodStop = .week(PeriodHelper.periodStart(for: .weekly))
            case .month:
                periodStop = .month(PeriodHelper.periodStart(for: .monthly))
            case .fiveYear:
                // "Жыл" бетіндегі ◄/► батырмалары periodStop-ты өздері нақты
                // мәнге (`.years` немесе `.months(year)`) орнатып, содан кейін
                // ғана selection-ды `.fiveYear`-ге ауыстырады — бұл жерде
                // қайта `.years`-қа қалпына келтіріп, сол мәнді езіп
                // жібермеу үшін, тек сайдбардан тікелей басылғанда ғана
                // (oldValue != .year) periodStop қалпына келеді.
                if oldValue != .year {
                    periodStop = .years
                }
            case .timeline, .year, .habits, .analytics, .trash, .ideas, .projects, .settings, nil:
                break
            }
        }
        .onAppear {
            ReminderScheduler.shared.start(context: modelContext)
            checkForHabitRenewal()
        }
        .alert(
            L10n.t(.habitRenewalTitle, language),
            isPresented: Binding(
                get: { renewalHabit != nil },
                set: { if !$0 { renewalHabit = nil } }
            ),
            presenting: renewalHabit
        ) { habit in
            Button(L10n.t(.habitStopAction, language), role: .cancel) {
                HabitStore.stop(habit)
                renewalHabit = nil
                checkForHabitRenewal()
            }
            Button(L10n.t(.habitContinueAction, language)) {
                HabitStore.renew(habit, in: modelContext)
                renewalHabit = nil
                checkForHabitRenewal()
            }
        } message: { habit in
            Text(L10n.habitRenewalMessage(title: habit.title, language))
        }
    }

    /// Циклі аяқталған, жауап күтіп тұрған дағдылардың біреуін тауып,
    /// растау диалогын шығарады (бір сәтте біреу ғана).
    private func checkForHabitRenewal() {
        guard renewalHabit == nil else { return }
        renewalHabit = HabitStore.habitsNeedingRenewalDecision(allHabits).first
    }
}
