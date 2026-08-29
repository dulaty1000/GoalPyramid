import SwiftUI
import SwiftData

/// Тапсырманы қай уақыт деңгейіне тіркеу керегін білдіретін, sheet-ке ғана
/// тиесілі таңдау. Нақты сақталатын `GoalLevel`-ге осылай түрленеді:
/// - `.year` → `GoalLevel.fiveYear` (себебі "5 Жыл" бөлімінде әр жылдың
///   өз беті дәл осы деңгейді, тек `periodStart` сол жылдың 1 қаңтары
///   болып, пайдаланады — `PeriodExplorerView`-ды қараңыз)
/// - `.month`/`.week`/`.day` → `GoalLevel.monthly`/`.weekly`/`.daily`
private enum TaskGranularity: Hashable {
    case year, month, week, day

    var goalLevel: GoalLevel {
        switch self {
        case .year: return .fiveYear
        case .month: return .monthly
        case .week: return .weekly
        case .day: return .daily
        }
    }

    /// Segmented control-да көрсетілетін атау. "Жыл" деген қысқа атауы
    /// `GoalLevel.yearly`-ге тиесілі болғандықтан (ал нақты деңгей
    /// `.fiveYear` болып сақталады), атауды НАҚ СОЛ жерден аламыз.
    func shortTitle(_ language: AppLanguage) -> String {
        switch self {
        case .year: return GoalLevel.yearly.shortTitle(language)
        case .month: return GoalLevel.monthly.shortTitle(language)
        case .week: return GoalLevel.weekly.shortTitle(language)
        case .day: return GoalLevel.daily.shortTitle(language)
        }
    }

    /// Осы granularity-ден бір деңгей ЖОҒАРЫ granularity — "Байланысты
    /// мақсат" тізімінде қай деңгейдегі жоба тапсырмалары ұсынылатынын
    /// анықтайды (Күн→Апта→Ай→Жыл). Жылдың өзінен жоғары деңгей жоқ.
    var parentGranularity: TaskGranularity? {
        switch self {
        case .day: return .week
        case .week: return .month
        case .month: return .year
        case .year: return nil
        }
    }
}

/// Жобаға тапсырма қосу/өңдеу формасы.
///
/// "Уақыт белгілеу" ажыратқышы (әдепкі — ӨШІРУЛІ) уақыт таңдауды
/// міндетті емес етеді:
/// - ӨШІРУЛІ болса — granularity селекторы мүлдем жасырылады, тапсырма
///   `hasDueDate = false` күйінде, ешбір Ай/Апта/Күн/Бүгін бетіне
///   тіркелместен, тек жобаның өз тізімінде уақытсыз тұрады
///   (`GoalListView`-дың сұрауы `hasDueDate`-ті міндетті түрде тексереді
///   — толығырақ: `GoalListView.allPeriodGoals`).
/// - ҚОСУЛЫ болса — жобаның "Мерзімі"-не сай granularity таңдалады:
///   - Апталық жоба → Апта/Күн
///   - Айлық жоба → Ай/Апта/Күн
///   - Жылдық жоба → Жыл/Ай/Апта/Күн
///   - Басқа жоба → тек Күн
///
/// Қай деңгейге (`level`) тіркелсе, тапсырма сол деңгейдің НАҚ СОЛ
/// `periodStart`-ы бар тиісті бетінде (5 Жыл/Ай/Апта тізімінде немесе
/// "Бүгін" тізімінде) автоматты түрде көрінеді — бұл екеуі бір ғана
/// `GoalItem` жазбасын оқитындықтан, қосымша синхрондау коды қажет емес.
/// Сол сияқты, ажыратқышты кез келген бағытта ауыстыру да тапсырманы
/// тиісті беттен автоматты түрде қосады/шығарады.
struct AddEditProjectTaskSheet: View {
    let project: ProjectItem
    let existingTask: GoalItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Терезе түбірінен келеді — тіл ауысқанда осы sheet дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    @Query private var allGoals: [GoalItem]

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var evaluation: EvaluationColor = .none

    /// Уақыт (granularity) таңдалатын-таңдалмайтынын білдіреді — әдепкі
    /// ӨШІРУЛІ, яғни жаңа тапсырма уақытсыз жасалады.
    @State private var hasDueDate: Bool = false

    /// Тапсырма қай уақыт деңгейіне тіркелетінін білдіреді.
    @State private var granularity: TaskGranularity = .day

    @State private var selectedYear: Int = PeriodHelper.year(of: Date())
    @State private var selectedMonthStart: Date = PeriodHelper.periodStart(for: .monthly)
    @State private var selectedWeekStart: Date = PeriodHelper.periodStart(for: .weekly)
    @State private var selectedDate: Date = Date()

    /// "Байланысты мақсат" — осы жобаның бір деңгей ЖОҒАРЫ granularity-дегі
    /// тапсырмасы. `nil` болса, тапсырма "Тапсырмалар графигінде" тікелей
    /// орталық (жоба) түйініне жалғанады.
    @State private var selectedParentID: UUID?

    private var isEditing: Bool { existingTask != nil }

    /// Жобаның "Мерзімі"-не қарай рұқсат етілген granularity-лер.
    private var availableGranularities: [TaskGranularity] {
        switch project.timeframe {
        case .weekly: return [.week, .day]
        case .monthly: return [.month, .week, .day]
        case .yearly: return [.year, .month, .week, .day]
        case .other: return [.day]
        }
    }

    /// "Байланысты мақсат" тізіміндегі кандидаттар — тек ОСЫ жобаға
    /// тиесілі, granularity-ден бір деңгей ЖОҒАРЫ, уақыты бар тапсырмалар
    /// (өзін-өзі таңдамас үшін өңделіп жатқан тапсырманың өзі алынып
    /// тасталады).
    private var potentialParentTasks: [GoalItem] {
        guard let parentGranularity = granularity.parentGranularity else { return [] }
        let parentLevel = parentGranularity.goalLevel
        return allGoals.excludingTrashed().filter {
            $0.projectID == project.id
                && $0.level == parentLevel
                && $0.hasDueDate
                && $0.id != existingTask?.id
        }
    }

    /// "Жыл" таңдауы үшін тізім — "5 Жыл" сайдбар бөлімімен дәл бірдей
    /// диапазон (ағымдағы жылдан бастап, алдағы 5 жыл).
    private var yearOptions: [Int] {
        let currentYear = PeriodHelper.year(of: Date())
        return Array(currentYear...(currentYear + 5))
    }

    /// "Апта" таңдауы үшін тізім: өткен ~4 апта — алдағы ~26 апта.
    private var weekOptions: [Date] {
        let cal = PeriodHelper.calendar
        let today = Date()
        guard let startBound = cal.date(byAdding: .weekOfYear, value: -4, to: today),
              let endBound = cal.date(byAdding: .weekOfYear, value: 26, to: today) else { return [] }
        var weeks: [Date] = []
        var current = PeriodHelper.periodStart(for: .weekly, containing: startBound)
        while current <= endBound {
            weeks.append(current)
            guard let next = cal.date(byAdding: .day, value: 7, to: current) else { break }
            current = next
        }
        return weeks
    }

    /// "Ай" таңдауы үшін тізім: өткен ~2 ай — алдағы ~18 ай.
    private var monthOptions: [Date] {
        let cal = PeriodHelper.calendar
        let today = Date()
        guard let startBound = cal.date(byAdding: .month, value: -2, to: today),
              let endBound = cal.date(byAdding: .month, value: 18, to: today) else { return [] }
        var months: [Date] = []
        var current = PeriodHelper.periodStart(for: .monthly, containing: startBound)
        while current <= endBound {
            months.append(current)
            guard let next = cal.date(byAdding: .month, value: 1, to: current) else { break }
            current = next
        }
        return months
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? L10n.t(.editTaskTitle, language) : L10n.t(.newTaskTitle, language))
                .font(.title2.bold())

            // Жыл/апта/ай тізімі көп болса да (~30 нұсқа), форма шектен
            // тыс ұзарып, төмендегі "Қосу"/"Бас тарту" батырмаларын
            // экраннан шығарып жібермеуі үшін — енгізу өрістері scroll
            // ішінде, батырма қатары ӘРҚАШАН көрінетін, бекітілген
            // күйде қалады.
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField(L10n.t(.fieldTitleLabel, language), text: $title)
                        .textFieldStyle(.roundedBorder)

                    TextField(L10n.t(.fieldNotesOptional, language), text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)

                    Toggle(L10n.t(.hasDueDateToggleLabel, language), isOn: $hasDueDate)

                    if hasDueDate {
                        scheduleControl
                        parentTaskControl
                    }

                    HStack {
                        Text(L10n.t(.evaluationLabel, language))
                        EvaluationPicker(evaluation: $evaluation)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 360)

            HStack {
                if isEditing {
                    Button(L10n.t(.trashAction, language), role: .destructive) {
                        if let task = existingTask {
                            GoalStore.moveToTrash(task)
                        }
                        dismiss()
                    }
                }
                Spacer()
                Button(L10n.t(.formCancel, language)) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(isEditing ? L10n.t(.saveButton, language) : L10n.t(.addButton, language)) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear(perform: loadInitialState)
        .onChange(of: granularity) { _, _ in selectedParentID = nil }
    }

    /// "Байланысты мақсат" — Иерархия бөліміндегі "Байланысты мақсат"
    /// функциясымен бірдей логика: granularity-ден бір деңгей жоғары,
    /// осы жобаға тиесілі тапсырмалар арасынан таңдалады.
    @ViewBuilder
    private var parentTaskControl: some View {
        // Жылдық granularity-ден жоғары деңгей жоқ болғандықтан ғана
        // жол мүлдем жасырылады. Қалған жағдайда жол ӘРҚАШАН көрінеді —
        // сол жобада тиісті жоғарғы деңгейде тапсырма әлі жоқ болса,
        // тізімде тек "Ешқайсы" қалады, пайдаланушы байланыссыз
        // жалғастыра алады.
        if let parentGranularity = granularity.parentGranularity {
            Picker(L10n.parentGoalPickerLabel(parentLevelTitle: parentGranularity.shortTitle(language), language), selection: $selectedParentID) {
                Text(L10n.t(.noneOption, language)).tag(UUID?.none)
                ForEach(potentialParentTasks) { parent in
                    Text(parent.title).tag(Optional(parent.id))
                }
            }
            .pickerStyle(.menu)
        }
    }

    @ViewBuilder
    private var scheduleControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            if availableGranularities.count > 1 {
                Picker(L10n.t(.taskLevelPickerLabel, language), selection: $granularity) {
                    ForEach(availableGranularities, id: \.self) { level in
                        Text(level.shortTitle(language)).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch granularity {
            case .year:
                Picker(GoalLevel.yearly.shortTitle(language), selection: $selectedYear) {
                    ForEach(yearOptions, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
            case .month:
                Picker(GoalLevel.monthly.shortTitle(language), selection: $selectedMonthStart) {
                    ForEach(monthOptions, id: \.self) { month in
                        Text(PeriodHelper.displayRange(for: .monthly, periodStart: month)).tag(month)
                    }
                }
                .pickerStyle(.menu)
            case .week:
                Picker(GoalLevel.weekly.shortTitle(language), selection: $selectedWeekStart) {
                    ForEach(weekOptions, id: \.self) { week in
                        Text(PeriodHelper.displayRange(for: .weekly, periodStart: week)).tag(week)
                    }
                }
                .pickerStyle(.menu)
            case .day:
                DatePicker(L10n.t(.dateFieldLabel, language), selection: $selectedDate, displayedComponents: [.date])
            }
        }
    }

    private func loadInitialState() {
        guard let task = existingTask else {
            granularity = availableGranularities.first ?? .day
            hasDueDate = false
            return
        }
        title = task.title
        notes = task.notes
        evaluation = task.evaluation
        hasDueDate = task.hasDueDate
        selectedParentID = task.parentID

        if task.hasDueDate {
            switch task.level {
            case .fiveYear:
                granularity = .year
                selectedYear = PeriodHelper.year(of: task.periodStart)
            case .monthly:
                granularity = .month
                selectedMonthStart = task.periodStart
            case .weekly:
                granularity = .week
                selectedWeekStart = task.periodStart
            default:
                granularity = .day
                selectedDate = task.periodStart
            }
        } else {
            granularity = availableGranularities.first ?? .day
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let resolvedLevel: GoalLevel
        let resolvedPeriodStart: Date

        if hasDueDate {
            resolvedLevel = granularity.goalLevel
            switch granularity {
            case .year:
                resolvedPeriodStart = PeriodHelper.yearStart(selectedYear)
            case .month:
                resolvedPeriodStart = selectedMonthStart
            case .week:
                resolvedPeriodStart = selectedWeekStart
            case .day:
                resolvedPeriodStart = PeriodHelper.periodStart(for: .daily, containing: selectedDate)
            }
        } else {
            resolvedLevel = .daily
            resolvedPeriodStart = PeriodHelper.periodStart(for: .daily, containing: Date())
        }

        // Жылдық granularity-нің жоғары деңгейі жоқ, ал уақыты жоқ
        // тапсырма granularity-ге ие емес — екеуінде де "Байланысты
        // мақсат" мағынасыз, сондықтан ескі таңдау есепке алынбайды.
        let resolvedParentID: UUID? = (hasDueDate && granularity.parentGranularity != nil) ? selectedParentID : nil

        if let task = existingTask {
            task.title = trimmed
            task.notes = notes
            task.level = resolvedLevel
            task.periodStart = resolvedPeriodStart
            task.hasDueDate = hasDueDate
            task.evaluation = evaluation
            task.parentID = resolvedParentID
        } else {
            let newTask = GoalItem(
                title: trimmed,
                level: resolvedLevel,
                periodStart: resolvedPeriodStart,
                notes: notes,
                parentID: resolvedParentID,
                sortOrder: GoalStore.count(level: resolvedLevel, periodStart: resolvedPeriodStart, in: context),
                projectID: project.id,
                hasDueDate: hasDueDate
            )
            newTask.evaluation = evaluation
            context.insert(newTask)
        }
        dismiss()
    }
}
