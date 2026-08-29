import Foundation
import SwiftUI

/// Интерфейс тілі. Толық локализация: сайдбар, Бүгін/Апта/Ай/Жыл/5 Жылдық,
/// Аналитика, Иерархия, Жобалар, Идеялар, Қоқыс, Настройка — барлық
/// бет пен sheet осы жүйе арқылы аударылады.
enum AppLanguage: String, CaseIterable, Identifiable {
    case kk, ru, en

    var id: String { rawValue }

    /// Таңдау тізіміндегі атауы — пайдаланушының нақты сұрауы бойынша
    /// әрдайым осы үш атпен көрінеді (ағымдағы тілге қарамастан).
    var title: String {
        switch self {
        case .kk: return "Қазақша"
        case .ru: return "Орысша"
        case .en: return "Ағылшынша"
        }
    }

    static var current: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: AppSettingsKey.language) ?? AppLanguage.kk.rawValue
        return AppLanguage(rawValue: raw) ?? .kk
    }

    /// Күн/ай/апта күні атауларын ("Тамыз"/"Дүйсенбі" т.б.) осы тілде
    /// пішімдеу үшін (`PeriodHelper.displayRange`, ай тізімдері).
    var locale: Locale {
        switch self {
        case .kk: return Locale(identifier: "kk_KZ")
        case .ru: return Locale(identifier: "ru_RU")
        case .en: return Locale(identifier: "en_US")
        }
    }
}

/// Ағымдағы интерфейс тілін терезе түбірінен (`GoalPyramidApp`) бүкіл
/// View иерархиясына тарататын environment кілті. `@AppStorage`-тың
/// сыбайлас View-лар арасындағы (мыс. "Настройка" → сайдбар) реактивтілігі
/// сенімсіз болғандықтан — тек ТҮБІРДЕ бір рет оқылып, содан кейін
/// environment арқылы төмен қарай таралады (`Color.accentColor`/
/// `.preferredColorScheme` дәл осылай жұмыс істейтіні дәлелденген).
private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .kk
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}

enum L10nKey {
    // Сайдбар
    case sidebarToday, sidebarWeek, sidebarMonth, sidebarYear, sidebarFiveYear
    case sidebarAnalytics, sidebarIdeas, sidebarProjects, sidebarSettings, sidebarTrash
    case sidebarHabits
    case sidebarTimeline
    case timelineTabDay, timelineTabWeek, timelineTabMonth, timelineTabYear
    case appNavTitle

    // GoalListView / GoalRowView / EisenhowerMatrixView (Бүгін беті)
    case addGoal
    case trashAction
    case addToMatrixHelp
    case goalsSuffix
    case projectTaskHelp
    case habitTaskHelp
    case matrixTitle
    case matrixEmpty
    case matrixRemove

    // EisenhowerQuadrant
    case quadrantUrgentImportant
    case quadrantImportantNotUrgent
    case quadrantUrgentNotImportant
    case quadrantNeither

    // EvaluationColor
    case evalNone, evalGreen, evalYellow, evalRed

    // Настройка — жалпы
    case settingsAppearanceSection
    case settingsTheme
    case themeSystem, themeLight, themeDark
    case settingsAccentColor
    case accentBlue, accentGreen, accentPurple, accentOrange, accentPink, accentRed
    case settingsWeekStart
    case weekStartMonday, weekStartSunday

    case settingsNotificationsSection
    case settingsDailyReminder
    case settingsReminderTime
    case settingsSummaryReminder
    case settingsPermissionWarning

    case settingsDataSection
    case settingsExport
    case settingsImport
    case settingsResetAll
    case settingsImportConfirmTitle
    case settingsReplace
    case settingsCancel
    case settingsResetConfirmTitle
    case settingsReset
    case settingsResetConfirmMessage
    case settingsErrorTitle
    case settingsOK
    case settingsTrashAutoDelete
    case settingsTrashAutoDeletePeriod
    case periodWeek, periodMonth

    case settingsLanguageRegionSection
    case settingsInterfaceLanguage
    case settingsDateFormat
    case dateFormatTextual, dateFormatDDMMYYYY, dateFormatMMDDYYYY, dateFormatYYYYMMDD

    case errorExportFailed, errorPickFailed, errorImportFailed, errorResetFailed

    case settingsOtherSection
    case settingsCompletionEffects
    case settingsShortcuts
    case shortcutsPageTitle
    case shortcutConfirm, shortcutCancel, shortcutCloseWindow, shortcutQuit
    case settingsAbout
    case aboutVersionLabel, aboutBuildDateLabel, aboutDescription

    // GoalLevel (Апта/Ай/Жыл/5 Жылдық парақтары, Аналитика, Иерархия, Қоқыс)
    case levelFiveYearTitle, levelYearlyTitle, levelMonthlyTitle, levelWeeklyTitle, levelDailyTitle
    case levelFiveYearShort, levelYearlyShort, levelMonthlyShort, levelWeeklyShort, levelDailyShort

    // ProjectTimeframe
    case timeframeWeekly, timeframeMonthly, timeframeYearly, timeframeOther
    case timeframeWeeklyGroup, timeframeMonthlyGroup, timeframeYearlyGroup, timeframeOtherGroup

    // Апта/Ай/Жыл/5 Жылдық — ◄/► тултиптері
    case navBackToYear, navForwardToMonth, navBackToMonth, navForwardToWeek, navBackToWeek, navForwardToDay

    // Аналитика
    case analyticsTotalGoals, analyticsCompleted, analyticsOverallPercent
    case analyticsCompletionByLevel, analyticsCountByLevel
    case colTotal, colPending, colCompleted, pyramidTip
    case plannedDaysCardTitle, achievementsCardTitle, last30DaysCardTitle, habitHeatmapCardTitle
    case habitLegendDone, habitLegendMissed, habitLegendNotApplicable
    case chartLevelAxis, chartPercentAxis, chartDayAxis, chartCompletedAxis


    // Heatmap
    case legendLow, legendHigh, weekdayMon, weekdayWed, weekdayFri
    case weekdayTue, weekdayThu, weekdaySat, weekdaySun

    // Форма/sheet ортақ өрістері
    case fieldTitleLabel, fieldNotesOptional, evaluationLabel
    case formCancel, saveButton, addButton, noneOption, editGoalTitle

    // Жобалар
    case addProjectAction, noProjectsYet, deleteProjectConfirmTitle, confirmDeleteAction, deleteProjectHelp
    case completedProjectsGroup, projectCompletedBadge
    case newProjectTitle, projectNameField, projectTimeframeLabel
    case noDateSection, scheduledSection, addTaskAction, backToProjectsHelp
    case untitledProject, noDateLabel, taskGraphTitle, undatedTasksGroupTitle
    case collapseGraphHelp, expandGraphHelp
    case editTaskTitle, newTaskTitle, dateFieldLabel, hasDueDateToggleLabel
    case taskLevelPickerLabel

    // Идеялар
    case addNoteAction, untitledNote, noNotesYet, emptyNoteContent, noteTitlePlaceholder, backToNotesHelp
    case selectNotesAction, deleteNoteHelp
    case ideaTimeframeLabel
    case ideaTimeframeWeeklyGroup, ideaTimeframeMonthlyGroup, ideaTimeframeYearlyGroup, ideaTimeframeOtherGroup
    case attachmentsLabel, attachFileAction, imageLoadFailed, removeAttachmentHelp, attachFailedError

    // Дағдылар
    case addHabitAction, newHabitTitle, editHabitTitle, habitDescriptionLabel, noHabitsYet, deleteHabitHelp, untitledHabit
    case habitFrequencyLabel, habitFrequencyDaily, habitFrequencySpecificDays
    case habitRenewalTitle, habitContinueAction, habitStopAction
    case habitStoppedBadge, reactivateHabitAction

    // Қоқыс
    case deleteAllAction, trashEmpty, goalsSection, notesSection, habitsSection
    case restoreAction, deleteAction, deleteAllConfirmTitle, actionIrreversible

    // MenuBar виджеті
    case menuBarTitle, menuBarEmpty, menuBarAddTask, menuBarFullWindow, menuBarQuit

    // Хабарландыру тақырыптары (ReminderScheduler)
    case notifWeeklyTitle, notifMonthlyTitle
}

/// Аударма кестесі: (қазақша, орысша, ағылшынша).
enum L10n {
    static func t(_ key: L10nKey, _ language: AppLanguage = .current) -> String {
        let (kk, ru, en) = strings(for: key)
        switch language {
        case .kk: return kk
        case .ru: return ru
        case .en: return en
        }
    }

    /// "N/M мақсат · X% орындалды" үлгісіндегі прогресс жолағы.
    static func progressSummary(done: Int, total: Int, percent: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(done)/\(total) мақсат · \(percent)% орындалды"
        case .ru: return "\(done)/\(total) целей · \(percent)% выполнено"
        case .en: return "\(done)/\(total) goals · \(percent)% completed"
        }
    }

    /// "5 Жыл" тізіміндегі бір жылды ашқанда: "\(year) жылғы мақсаттар".
    static func yearGoalsTitle(year: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(year) жылғы мақсаттар"
        case .ru: return "Цели на \(year) год"
        case .en: return "\(year) Goals"
        }
    }

    /// "Ай" тізімі: "\(year) жылдың айлары".
    static func yearMonthsTitle(year: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(year) жылдың айлары"
        case .ru: return "Месяцы \(year) года"
        case .en: return "\(year) — Months"
        }
    }

    /// "Апта" тізімі: "\(monthLabel) апталары".
    static func monthWeeksTitle(monthLabel: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(monthLabel) апталары"
        case .ru: return "Недели — \(monthLabel)"
        case .en: return "\(monthLabel) — Weeks"
        }
    }

    /// "Күн" тізімі: "\(weekLabel) күндері".
    static func weekDaysTitle(weekLabel: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(weekLabel) күндері"
        case .ru: return "Дни — \(weekLabel)"
        case .en: return "\(weekLabel) — Days"
        }
    }

    /// `AddEditGoalSheet` тақырыбы: "Жаңа \(деңгей) мақсат".
    static func newGoalTitle(levelTitle: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "Жаңа \(levelTitle.lowercased()) мақсат"
        case .ru: return "Новая цель («\(levelTitle)»)"
        case .en: return "New \(levelTitle) Goal"
        }
    }

    /// "Хронология" тор ұяшығындағы "+N көбірек" белгісі.
    static func timelineMoreCount(count: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "+\(count) көбірек"
        case .ru: return "+\(count) ещё"
        case .en: return "+\(count) more"
        }
    }

    /// "Дағдыны жалғастырамыз ба?" растау диалогының хабар мәтіні.
    static func habitRenewalMessage(title: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "«\(title)» дағдысының 1 айлық мерзімі аяқталды. Оны жалғастырамыз ба?"
        case .ru: return "Месячный срок привычки «\(title)» истёк. Продолжить её?"
        case .en: return "The habit “\(title)”'s 1-month period has ended. Continue it?"
        }
    }

    /// "Байланысты ... мақсат" Picker лейблі.
    static func parentGoalPickerLabel(parentLevelTitle: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "Байланысты \(parentLevelTitle.lowercased()) мақсат"
        case .ru: return "Связанная цель («\(parentLevelTitle)»)"
        case .en: return "Linked \(parentLevelTitle) Goal"
        }
    }

    /// `GoalListView`-дегі "Жылдық мақсаттар" тақырыбы.
    static func levelGoalsTitle(levelTitle: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(levelTitle) мақсаттар"
        case .ru: return "\(levelTitle) цели"
        case .en: return "\(levelTitle) Goals"
        }
    }

    /// Жоба ішіндегі "N/M тапсырма орындалды".
    static func tasksCompletedSummary(completed: Int, total: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(completed)/\(total) тапсырма орындалды"
        case .ru: return "\(completed)/\(total) задач выполнено"
        case .en: return "\(completed)/\(total) tasks completed"
        }
    }

    /// "Идеялар" бетіндегі таңдау режиміндегі топтап өшіру батырмасы.
    static func deleteSelectedLabel(count: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "Таңдалғанды өшіру (\(count))"
        case .ru: return "Удалить выбранное (\(count))"
        case .en: return "Delete selected (\(count))"
        }
    }

    /// Жобаны қоқысқа тастау растауындағы хабар мәтіні.
    static func deleteProjectMessage(projectTitle: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "«\(projectTitle)» жобасы және оның барлық тапсырмалары қоқысқа тасталады. Кейін \"Қоқыс\" бөлімінен қалпына келтіруге болады."
        case .ru: return "Проект «\(projectTitle)» и все его задачи будут перемещены в корзину. Позже их можно восстановить в разделе «Корзина»."
        case .en: return "The project “\(projectTitle)” and all its tasks will be moved to Trash. You can restore them later from the Trash section."
        }
    }

    /// Жетістіктер картасының тултипі (мақсат жоқ күн).
    static func heatmapNoGoals(dateStr: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(dateStr): мақсат жоқ"
        case .ru: return "\(dateStr): целей нет"
        case .en: return "\(dateStr): no goals"
        }
    }

    /// Жетістіктер картасының тултипі (орындалу қатынасы бар күн).
    static func heatmapCompletedSummary(dateStr: String, completed: Int, total: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(dateStr): \(completed)/\(total) мақсат орындалды"
        case .ru: return "\(dateStr): выполнено \(completed)/\(total)"
        case .en: return "\(dateStr): \(completed)/\(total) completed"
        }
    }

    /// "Дағдылар (соңғы 30 күн)" heatmap-ындағы бір шаршының тултипі.
    static func habitDayTooltip(dateStr: String, statusLabel: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(dateStr): \(statusLabel)"
        case .ru: return "\(dateStr): \(statusLabel)"
        case .en: return "\(dateStr): \(statusLabel)"
        }
    }

    /// "Жоспарланған күндер" картасының тултипі (жоспар жоқ күн).
    static func heatmapNoPlan(dateStr: String, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(dateStr): жоспар жоқ"
        case .ru: return "\(dateStr): нет плана"
        case .en: return "\(dateStr): no plan"
        }
    }

    /// "Жоспарланған күндер" картасының тултипі (жоспарланған саны бар күн).
    static func heatmapPlannedSummary(dateStr: String, count: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "\(dateStr): \(count) мақсат жоспарланды"
        case .ru: return "\(dateStr): запланировано \(count)"
        case .en: return "\(dateStr): \(count) planned"
        }
    }

    /// Күнделікті еске салу хабарландыруының мәтіні.
    static func dailyReminderBody(count: Int, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return "Бүгін әлі \(count) мақсат орындалмады."
        case .ru: return "Сегодня ещё не выполнено \(count) целей."
        case .en: return "\(count) goals are still not completed today."
        }
    }

    /// "Идеялар" тізіміндегі топ тақырыбы ("Жобалар"-дағы `groupTitle`-мен
    /// бірдей санат, тек сөзі "идеялар" болғандықтан бөлек кестеленген).
    static func ideaGroupTitle(_ timeframe: ProjectTimeframe, _ language: AppLanguage = .current) -> String {
        switch timeframe {
        case .weekly: return t(.ideaTimeframeWeeklyGroup, language)
        case .monthly: return t(.ideaTimeframeMonthlyGroup, language)
        case .yearly: return t(.ideaTimeframeYearlyGroup, language)
        case .other: return t(.ideaTimeframeOtherGroup, language)
        }
    }

    /// Апта/ай соңындағы қорытынды хабарландыру мәтіні.
    static func summaryReminderBody(completed: Int, total: Int, isWeek: Bool, _ language: AppLanguage = .current) -> String {
        switch language {
        case .kk: return isWeek ? "Бұл аптада \(completed)/\(total) мақсат орындадыңыз." : "Бұл айда \(completed)/\(total) мақсат орындадыңыз."
        case .ru: return isWeek ? "На этой неделе вы выполнили \(completed)/\(total) целей." : "В этом месяце вы выполнили \(completed)/\(total) целей."
        case .en: return isWeek ? "You completed \(completed)/\(total) goals this week." : "You completed \(completed)/\(total) goals this month."
        }
    }

    private static func strings(for key: L10nKey) -> (String, String, String) {
        switch key {
        case .sidebarTimeline: return ("Хронология", "Хронология", "Timeline")
        case .timelineTabDay: return ("Күн", "День", "Day")
        case .timelineTabWeek: return ("Апта", "Неделя", "Week")
        case .timelineTabMonth: return ("Ай", "Месяц", "Month")
        case .timelineTabYear: return ("Жыл", "Год", "Year")
        case .sidebarToday: return ("Күн", "Сегодня", "Today")
        case .sidebarWeek: return ("Апта", "Неделя", "Week")
        case .sidebarMonth: return ("Ай", "Месяц", "Month")
        case .sidebarYear: return ("Жыл", "Год", "Year")
        case .sidebarFiveYear: return ("5 Жыл", "5 Лет", "5 Years")
        case .sidebarAnalytics: return ("Аналитика", "Аналитика", "Analytics")
        case .sidebarIdeas: return ("Идеялар", "Идеи", "Ideas")
        case .sidebarHabits: return ("Дағдылар", "Привычки", "Habits")
        case .sidebarProjects: return ("Жобалар", "Проекты", "Projects")
        case .sidebarSettings: return ("Настройка", "Настройки", "Settings")
        case .sidebarTrash: return ("Қоқыс", "Корзина", "Trash")
        case .appNavTitle: return ("Мақсат Пирамидасы", "Пирамида целей", "Goal Pyramid")

        case .addGoal: return ("Жаңа мақсат қосу", "Добавить цель", "Add goal")
        case .trashAction: return ("Қоқысқа тастау", "В корзину", "Move to trash")
        case .addToMatrixHelp: return ("Эйзенхауэр матрицасына қосу", "Добавить в матрицу Эйзенхауэра", "Add to Eisenhower matrix")
        case .goalsSuffix: return (" — мақсаттар", " — цели", " — goals")
        case .projectTaskHelp: return ("Жоба тапсырмасы", "Задача проекта", "Project task")
        case .habitTaskHelp: return ("Дағды тапсырмасы", "Задача привычки", "Habit task")
        case .matrixTitle: return ("Эйзенхауэр матрицасы", "Матрица Эйзенхауэра", "Eisenhower matrix")
        case .matrixEmpty: return ("Бос", "Пусто", "Empty")
        case .matrixRemove: return ("Матрицадан алып тастау", "Убрать из матрицы", "Remove from matrix")

        case .quadrantUrgentImportant: return ("Маңызды және Шұғыл", "Важно и Срочно", "Important & Urgent")
        case .quadrantImportantNotUrgent: return ("Маңызды, бірақ Шұғыл емес", "Важно, но не Срочно", "Important, Not Urgent")
        case .quadrantUrgentNotImportant: return ("Маңызды емес, бірақ Шұғыл", "Неважно, но Срочно", "Urgent, Not Important")
        case .quadrantNeither: return ("Маңызды емес және Шұғыл емес", "Неважно и не Срочно", "Neither Urgent nor Important")

        case .evalNone: return ("Орындалмаған", "Не выполнено", "Not done")
        case .evalGreen: return ("Үздік", "Отлично", "Great")
        case .evalYellow: return ("Жартылай", "Частично", "Partial")
        case .evalRed: return ("Нашар", "Плохо", "Poor")

        case .settingsAppearanceSection: return ("Сыртқы көрініс", "Внешний вид", "Appearance")
        case .settingsTheme: return ("Тақырып", "Тема", "Theme")
        case .themeSystem: return ("Жүйеге сай", "Как в системе", "System")
        case .themeLight: return ("Light", "Светлая", "Light")
        case .themeDark: return ("Dark", "Тёмная", "Dark")
        case .settingsAccentColor: return ("Негізгі акцент түсі", "Основной акцентный цвет", "Accent color")
        case .accentBlue: return ("Көк", "Синий", "Blue")
        case .accentGreen: return ("Жасыл", "Зелёный", "Green")
        case .accentPurple: return ("Күлгін", "Фиолетовый", "Purple")
        case .accentOrange: return ("Қызғылт сары", "Оранжевый", "Orange")
        case .accentPink: return ("Қызғылт", "Розовый", "Pink")
        case .accentRed: return ("Қызыл", "Красный", "Red")
        case .settingsWeekStart: return ("Апта қай күннен басталады", "С какого дня начинается неделя", "Week starts on")
        case .weekStartMonday: return ("Дүйсенбі", "Понедельник", "Monday")
        case .weekStartSunday: return ("Жексенбі", "Воскресенье", "Sunday")

        case .settingsNotificationsSection: return ("Хабарландырулар", "Уведомления", "Notifications")
        case .settingsDailyReminder: return ("Күнделікті мақсаттарды еске салу", "Напоминание о ежедневных целях", "Daily goal reminder")
        case .settingsReminderTime: return ("Уақыты", "Время", "Time")
        case .settingsSummaryReminder: return ("Апта/ай соңында қорытынды хабарландыру", "Итоговое уведомление в конце недели/месяца", "Weekly/monthly summary notification")
        case .settingsPermissionWarning: return ("Жүйе баптауларынан рұқсат беріңіз", "Разрешите в системных настройках", "Please allow in System Settings")

        case .settingsDataSection: return ("Деректер", "Данные", "Data")
        case .settingsExport: return ("Барлық мақсаттарды файлға сақтау", "Сохранить все цели в файл", "Save all goals to file")
        case .settingsImport: return ("Файлдан қалпына келтіру", "Восстановить из файла", "Restore from file")
        case .settingsResetAll: return ("Барлық деректерді нөлдеу", "Сбросить все данные", "Reset all data")
        case .settingsImportConfirmTitle: return ("Бұл қазіргі деректеріңізді ауыстырады, жалғастырасыз ба?", "Это заменит ваши текущие данные, продолжить?", "This will replace your current data. Continue?")
        case .settingsReplace: return ("Ауыстыру", "Заменить", "Replace")
        case .settingsCancel: return ("Болдырмау", "Отмена", "Cancel")
        case .settingsResetConfirmTitle: return ("Барлық деректерді нөлдеу керек пе?", "Сбросить все данные?", "Reset all data?")
        case .settingsReset: return ("Нөлдеу", "Сбросить", "Reset")
        case .settingsResetConfirmMessage: return (
            "Бұл әрекетті кері қайтару мүмкін емес. Барлық мақсаттар, жобалар және идеялар жойылады. Шынымен жалғастырасыз ба?",
            "Это действие необратимо. Все цели, проекты и идеи будут удалены. Вы уверены, что хотите продолжить?",
            "This action cannot be undone. All goals, projects, and ideas will be deleted. Are you sure you want to continue?"
        )
        case .settingsErrorTitle: return ("Қате", "Ошибка", "Error")
        case .settingsOK: return ("Жарайды", "Хорошо", "OK")
        case .settingsTrashAutoDelete: return ("Қоқысты автоматты тазарту", "Автоматическая очистка корзины", "Auto-clean trash")
        case .settingsTrashAutoDeletePeriod: return ("Мерзімі", "Период", "Period")
        case .periodWeek: return ("Апта", "Неделя", "Week")
        case .periodMonth: return ("Ай", "Месяц", "Month")

        case .settingsLanguageRegionSection: return ("Тіл мен аймақ", "Язык и регион", "Language & Region")
        case .settingsInterfaceLanguage: return ("Интерфейс тілі", "Язык интерфейса", "Interface language")
        case .settingsDateFormat: return ("Күн/ай пішімі", "Формат даты", "Date format")
        case .dateFormatTextual: return ("Мәтіндік түрде (31 тамыз, жексенбі)", "Текстовый (31 августа, понедельник)", "Textual (August 31, Monday)")
        case .dateFormatDDMMYYYY: return ("КК.АА.ЖЖЖЖ (31.08.2026)", "ДД.ММ.ГГГГ (31.08.2026)", "DD.MM.YYYY (08/31/2026)")
        case .dateFormatMMDDYYYY: return ("АА/КК/ЖЖЖЖ (08/31/2026)", "ММ/ДД/ГГГГ (08/31/2026)", "MM/DD/YYYY (08/31/2026)")
        case .dateFormatYYYYMMDD: return ("ЖЖЖЖ-АА-КК (2026-08-31)", "ГГГГ-ММ-ДД (2026-08-31)", "YYYY-MM-DD (2026-08-31)")

        case .errorExportFailed: return ("Экспорттау сәтсіз аяқталды", "Не удалось экспортировать", "Export failed")
        case .errorPickFailed: return ("Файл таңдау сәтсіз аяқталды", "Не удалось выбрать файл", "File selection failed")
        case .errorImportFailed: return ("Қалпына келтіру сәтсіз аяқталды", "Не удалось восстановить", "Restore failed")
        case .errorResetFailed: return ("Нөлдеу сәтсіз аяқталды", "Не удалось сбросить", "Reset failed")

        case .settingsOtherSection: return ("Басқа", "Другое", "Other")
        case .settingsCompletionEffects: return ("Дыбыстық/визуалды эффект", "Звуковой/визуальный эффект", "Sound & visual effect")
        case .settingsShortcuts: return ("Пернетақта тіркесімдері", "Комбинации клавиш", "Keyboard shortcuts")
        case .shortcutsPageTitle: return ("Пернетақта тіркесімдері", "Комбинации клавиш", "Keyboard Shortcuts")
        case .shortcutConfirm: return ("Терезедегі негізгі әрекетті растау (Қосу/Сақтау)", "Подтвердить основное действие (Добавить/Сохранить)", "Confirm the primary action (Add/Save)")
        case .shortcutCancel: return ("Ашық терезені бас тарту арқылы жабу", "Закрыть окно (Отмена)", "Cancel and close the window")
        case .shortcutCloseWindow: return ("Терезені жабу", "Закрыть окно", "Close window")
        case .shortcutQuit: return ("Қосымшадан шығу", "Выйти из приложения", "Quit the app")
        case .settingsAbout: return ("Қосымша туралы", "О приложении", "About")
        case .aboutVersionLabel: return ("Нұсқа", "Версия", "Version")
        case .aboutBuildDateLabel: return ("Құрастырылған күні", "Дата сборки", "Build date")
        case .aboutDescription: return (
            "Мақсаттарды 5 жылдық көзқарастан күнделікті тапсырмаларға дейін пирамида түрінде жоспарлауға арналған macOS қосымшасы.",
            "Приложение для macOS для планирования целей в виде пирамиды — от 5-летнего видения до ежедневных задач.",
            "A macOS app for planning goals as a pyramid — from a 5-year vision down to daily tasks."
        )

        case .levelFiveYearTitle: return ("5 жылдық", "5-летняя", "5-Year")
        case .levelYearlyTitle: return ("Жылдық", "Годовая", "Yearly")
        case .levelMonthlyTitle: return ("Айлық", "Месячная", "Monthly")
        case .levelWeeklyTitle: return ("Апталық", "Недельная", "Weekly")
        case .levelDailyTitle: return ("Күндік", "Дневная", "Daily")
        case .levelFiveYearShort: return ("5 жыл", "5 лет", "5yr")
        case .levelYearlyShort: return ("Жыл", "Год", "Year")
        case .levelMonthlyShort: return ("Ай", "Месяц", "Month")
        case .levelWeeklyShort: return ("Апта", "Неделя", "Week")
        case .levelDailyShort: return ("Күн", "День", "Day")

        case .timeframeWeekly: return ("Апталық", "Еженедельный", "Weekly")
        case .timeframeMonthly: return ("Айлық", "Ежемесячный", "Monthly")
        case .timeframeYearly: return ("Жылдық", "Ежегодный", "Yearly")
        case .timeframeOther: return ("Басқа", "Другое", "Other")
        case .timeframeWeeklyGroup: return ("Апталық жобалар", "Еженедельные проекты", "Weekly Projects")
        case .timeframeMonthlyGroup: return ("Айлық жобалар", "Ежемесячные проекты", "Monthly Projects")
        case .timeframeYearlyGroup: return ("Жылдық жобалар", "Ежегодные проекты", "Yearly Projects")
        case .timeframeOtherGroup: return ("Басқа жобалар", "Другие проекты", "Other Projects")

        case .navBackToYear: return ("Жылға қайту", "Назад к году", "Back to year")
        case .navForwardToMonth: return ("Айға өту", "К месяцу", "Go to month")
        case .navBackToMonth: return ("Айға қайту", "Назад к месяцу", "Back to month")
        case .navForwardToWeek: return ("Аптаға өту", "К неделе", "Go to week")
        case .navBackToWeek: return ("Аптаға қайту", "Назад к неделе", "Back to week")
        case .navForwardToDay: return ("Күнге өту", "К дню", "Go to day")

        case .analyticsTotalGoals: return ("Барлық мақсаттар", "Все цели", "Total goals")
        case .analyticsCompleted: return ("Орындалды", "Выполнено", "Completed")
        case .analyticsOverallPercent: return ("Жалпы пайыз", "Общий процент", "Overall rate")
        case .analyticsCompletionByLevel: return ("Деңгей бойынша орындалу", "Выполнение по уровням", "Completion by level")
        case .analyticsCountByLevel: return ("Деңгей бойынша барлық сан", "Количество по уровням", "Count by level")
        case .colTotal: return ("Барлығы", "Всего", "Total")
        case .colPending: return ("Орындалмағандар", "Невыполненные", "Pending")
        case .colCompleted: return ("Орындалғандар", "Выполненные", "Completed")
        case .pyramidTip: return ("Кеңес: әр бөлім келесі бөлікке қарағанда 3 есе көп болса жақсы", "Совет: каждый уровень желательно делать в 3 раза больше следующего", "Tip: each level should ideally be 3x the next")
        case .plannedDaysCardTitle: return ("Жоспарланған күндер", "Запланированные дни", "Planned Days")
        case .achievementsCardTitle: return ("Жетістіктер картасы (соңғы 1 жыл)", "Карта достижений (последний год)", "Achievements Map (last year)")
        case .last30DaysCardTitle: return ("Соңғы 30 күн (орындалған күндік тапсырмалар)", "Последние 30 дней (выполненные дневные задачи)", "Last 30 Days (completed daily tasks)")
        case .habitHeatmapCardTitle: return ("Дағдылар (соңғы 30 күн)", "Привычки (последние 30 дней)", "Habits (last 30 days)")
        case .habitLegendDone: return ("Орындалды", "Выполнено", "Done")
        case .habitLegendMissed: return ("Қалып кетті", "Пропущено", "Missed")
        case .habitLegendNotApplicable: return ("Қолданылмайды", "Не применяется", "Not applicable")
        case .chartLevelAxis: return ("Деңгей", "Уровень", "Level")
        case .chartPercentAxis: return ("Пайыз", "Процент", "Percent")
        case .chartDayAxis: return ("Күн", "День", "Day")
        case .chartCompletedAxis: return ("Орындалды", "Выполнено", "Completed")


        case .legendLow: return ("Аз", "Меньше", "Less")
        case .legendHigh: return ("Көп", "Больше", "More")
        case .weekdayMon: return ("Дс", "Пн", "Mo")
        case .weekdayWed: return ("Ср", "Ср", "We")
        case .weekdayFri: return ("Жм", "Пт", "Fr")
        case .weekdayTue: return ("Сс", "Вт", "Tu")
        case .weekdayThu: return ("Бс", "Чт", "Th")
        case .weekdaySat: return ("Сб", "Сб", "Sa")
        case .weekdaySun: return ("Жс", "Вс", "Su")

        case .fieldTitleLabel: return ("Атауы", "Название", "Title")
        case .fieldNotesOptional: return ("Ескертпе (міндетті емес)", "Заметка (необязательно)", "Notes (optional)")
        case .evaluationLabel: return ("Бағалау:", "Оценка:", "Rating:")
        case .formCancel: return ("Бас тарту", "Отмена", "Cancel")
        case .saveButton: return ("Сақтау", "Сохранить", "Save")
        case .addButton: return ("Қосу", "Добавить", "Add")
        case .noneOption: return ("Жоқ", "Нет", "None")
        case .editGoalTitle: return ("Мақсатты өңдеу", "Редактировать цель", "Edit Goal")

        case .addProjectAction: return ("Жаңа жоба қосу", "Добавить проект", "Add project")
        case .noProjectsYet: return ("Әзірге жоба жоқ", "Пока нет проектов", "No projects yet")
        case .deleteProjectConfirmTitle: return ("Бұл жобаны шынымен өшіргіңіз келе ме?", "Вы точно хотите удалить этот проект?", "Are you sure you want to delete this project?")
        case .confirmDeleteAction: return ("Өшіру", "Удалить", "Delete")
        case .deleteProjectHelp: return ("Жобаны өшіру", "Удалить проект", "Delete project")
        case .completedProjectsGroup: return ("Аяқталған жобалар", "Завершённые проекты", "Completed Projects")
        case .projectCompletedBadge: return ("Аяқталды", "Завершён", "Completed")
        case .newProjectTitle: return ("Жаңа жоба", "Новый проект", "New Project")
        case .projectNameField: return ("Жобаның атауы", "Название проекта", "Project name")
        case .projectTimeframeLabel: return ("Мерзімі", "Период", "Timeframe")
        case .noDateSection: return ("Күні жоқ", "Без даты", "No date")
        case .scheduledSection: return ("Жоспарланған", "Запланировано", "Scheduled")
        case .addTaskAction: return ("Жаңа тапсырма қосу", "Добавить задачу", "Add task")
        case .backToProjectsHelp: return ("Жобалар тізіміне қайту", "Назад к списку проектов", "Back to projects list")
        case .untitledProject: return ("Жоба", "Проект", "Project")
        case .noDateLabel: return ("Күнсіз", "Без даты", "No date")
        case .taskGraphTitle: return ("Тапсырмалар графигі", "Граф задач", "Task graph")
        case .undatedTasksGroupTitle: return ("Уақытсыз тапсырмалар", "Задачи без даты", "Undated tasks")
        case .collapseGraphHelp: return ("Графты жию", "Свернуть граф", "Collapse graph")
        case .expandGraphHelp: return ("Графты жаю", "Развернуть граф", "Expand graph")
        case .editTaskTitle: return ("Тапсырманы өңдеу", "Редактировать задачу", "Edit Task")
        case .newTaskTitle: return ("Жаңа тапсырма", "Новая задача", "New Task")
        case .dateFieldLabel: return ("Күні", "Дата", "Date")
        case .hasDueDateToggleLabel: return ("Уақыт белгілеу", "Указать время", "Set a due date")
        case .taskLevelPickerLabel: return ("Қай деңгейге тіркеу", "Уровень привязки", "Assign to")

        case .addNoteAction: return ("Жаңа парақ қосу", "Добавить страницу", "Add page")
        case .untitledNote: return ("Атаусыз парақ", "Страница без названия", "Untitled page")
        case .noNotesYet: return ("Әзірге парақ жоқ", "Пока нет страниц", "No pages yet")
        case .emptyNoteContent: return ("Бос парақ", "Пустая страница", "Empty page")
        case .noteTitlePlaceholder: return ("Тақырып", "Заголовок", "Title")
        case .backToNotesHelp: return ("Парақтар тізіміне қайту", "Назад к списку страниц", "Back to pages list")
        case .selectNotesAction: return ("Таңдау", "Выбрать", "Select")
        case .deleteNoteHelp: return ("Идеяны қоқысқа тастау", "Переместить идею в корзину", "Move idea to trash")
        case .ideaTimeframeLabel: return ("Кезең", "Период", "Timeframe")
        case .ideaTimeframeWeeklyGroup: return ("Апталық идеялар", "Еженедельные идеи", "Weekly Ideas")
        case .ideaTimeframeMonthlyGroup: return ("Айлық идеялар", "Ежемесячные идеи", "Monthly Ideas")
        case .ideaTimeframeYearlyGroup: return ("Жылдық идеялар", "Ежегодные идеи", "Yearly Ideas")
        case .ideaTimeframeOtherGroup: return ("Басқа идеялар", "Другие идеи", "Other Ideas")
        case .attachmentsLabel: return ("Тіркемелер", "Вложения", "Attachments")
        case .attachFileAction: return ("Файл/Сурет тіркеу", "Прикрепить файл/изображение", "Attach File/Image")
        case .imageLoadFailed: return ("Сурет ашылмады", "Не удалось открыть изображение", "Couldn't load image")
        case .removeAttachmentHelp: return ("Тіркемені өшіру", "Удалить вложение", "Remove attachment")
        case .attachFailedError: return ("Тіркеу сәтсіз аяқталды", "Не удалось прикрепить", "Failed to attach")

        case .addHabitAction: return ("Жаңа дағды қосу", "Добавить привычку", "Add habit")
        case .newHabitTitle: return ("Жаңа дағды", "Новая привычка", "New habit")
        case .editHabitTitle: return ("Дағдыны өңдеу", "Редактировать привычку", "Edit habit")
        case .habitDescriptionLabel: return ("Дағды туралы (міндетті емес)", "О привычке (необязательно)", "About the habit (optional)")
        case .noHabitsYet: return ("Әзірге дағды жоқ", "Пока нет привычек", "No habits yet")
        case .deleteHabitHelp: return ("Дағдыны қоқысқа тастау", "Переместить привычку в корзину", "Move habit to trash")
        case .untitledHabit: return ("Атаусыз дағды", "Привычка без названия", "Untitled habit")
        case .habitFrequencyLabel: return ("Жиілігі", "Частота", "Frequency")
        case .habitFrequencyDaily: return ("Күнделікті", "Ежедневно", "Daily")
        case .habitFrequencySpecificDays: return ("Белгілі күндер", "Определённые дни", "Specific days")
        case .habitRenewalTitle: return ("Дағдыны жалғастыру", "Продолжить привычку?", "Continue habit?")
        case .habitContinueAction: return ("Иә, жалғастырамыз", "Да, продолжить", "Yes, continue")
        case .habitStopAction: return ("Жоқ", "Нет", "No")
        case .habitStoppedBadge: return ("Тоқтатылды", "Остановлено", "Stopped")
        case .reactivateHabitAction: return ("Қайта белсендіру", "Возобновить", "Reactivate")

        case .deleteAllAction: return ("Барлығын өшіру", "Удалить всё", "Delete all")
        case .trashEmpty: return ("Қоқыс бос", "Корзина пуста", "Trash is empty")
        case .goalsSection: return ("Мақсаттар", "Цели", "Goals")
        case .notesSection: return ("Идея парақтары", "Страницы идей", "Idea pages")
        case .habitsSection: return ("Дағдылар", "Привычки", "Habits")
        case .restoreAction: return ("Қалпына келтіру", "Восстановить", "Restore")
        case .deleteAction: return ("Жою", "Удалить", "Delete")
        case .deleteAllConfirmTitle: return ("Барлық қоқысты өшіру керек пе?", "Очистить всю корзину?", "Empty the entire trash?")
        case .actionIrreversible: return ("Бұл әрекетті болдырмау мүмкін емес.", "Это действие нельзя отменить.", "This action cannot be undone.")

        case .menuBarTitle: return ("Бүгінгі 3 тапсырма", "3 задачи на сегодня", "Today's 3 Tasks")
        case .menuBarEmpty: return ("Бүгінге тапсырма қосылмаған", "На сегодня задач нет", "No tasks added for today")
        case .menuBarAddTask: return ("+ Тапсырма қосу", "+ Добавить задачу", "+ Add Task")
        case .menuBarFullWindow: return ("Толық терезе", "Полное окно", "Full Window")
        case .menuBarQuit: return ("Шығу", "Выход", "Quit")

        case .notifWeeklyTitle: return ("Апталық қорытынды", "Итоги недели", "Weekly Summary")
        case .notifMonthlyTitle: return ("Айлық қорытынды", "Итоги месяца", "Monthly Summary")
        }
    }
}
