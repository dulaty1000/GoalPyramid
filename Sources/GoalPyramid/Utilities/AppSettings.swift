import SwiftUI

/// Тұрақты (UserDefaults арқылы сақталатын, қосымшаны жапса да сақталып
/// қалатын) баптаулардың кілттері мен нұсқалары. `@AppStorage` осы
/// кілттерді қолданады — қай view осы кілтпен байланысса да, өзгеріс
/// бірден сол view-ге тарайды.
enum AppSettingsKey {
    static let colorScheme = "appColorScheme"
    static let accentColor = "appAccentColor"
    static let weekStart = "appWeekStartDay"

    static let dailyReminderEnabled = "notifyDailyReminderEnabled"
    static let dailyReminderHour = "notifyDailyReminderHour"
    static let dailyReminderMinute = "notifyDailyReminderMinute"
    static let dailyReminderLastFiredDay = "notifyDailyReminderLastFiredDay"

    static let summaryEnabled = "notifySummaryEnabled"
    static let weeklySummaryLastFiredWeek = "notifyWeeklySummaryLastFiredWeek"
    static let monthlySummaryLastFiredMonth = "notifyMonthlySummaryLastFiredMonth"

    static let trashAutoDeleteEnabled = "trashAutoDeleteEnabled"
    static let trashAutoDeleteDays = "trashAutoDeleteDays"
    static let trashAutoDeleteLastRunDay = "trashAutoDeleteLastRunDay"

    static let language = "appLanguage"
    static let dateFormat = "appDateFormat"

    static let completionEffectsEnabled = "completionEffectsEnabled"

    /// "Жобалар" → жоба бетіндегі "Тапсырмалар графигі" жиналған
    /// (collapsed) күйде тұр ма — барлық жоба беттеріне ортақ, бір рет
    /// таңдалған теңшеу ретінде сақталады.
    static let projectTaskGraphCollapsed = "projectTaskGraphCollapsed"
}

/// "Тақырып" баптауы — Light / Dark / Жүйеге сай.
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    /// `nil` — жүйенің өз режимін қолдану (`.preferredColorScheme(nil)`).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// "Негізгі акцент түсі" баптауы.
enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue, green, purple, orange, pink, red

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .red: return .red
        }
    }
}

/// "Апта қай күннен басталады" баптауы.
enum WeekStartDay: String, CaseIterable, Identifiable {
    case monday, sunday

    var id: String { rawValue }

    /// `Calendar.firstWeekday` мәні: 1 — жексенбі, 2 — дүйсенбі.
    var calendarFirstWeekday: Int {
        switch self {
        case .monday: return 2
        case .sunday: return 1
        }
    }
}

/// "Күн/ай пішімі" баптауы — `PeriodHelper.displayRange(for: .daily, ...)`
/// және heatmap тултиптері осыны қолданады (қосымшаның барлық жерінде
/// бір ғана күн көрсетілетін орындар).
enum AppDateFormat: String, CaseIterable, Identifiable {
    case textual, ddmmyyyy, mmddyyyy, yyyymmdd

    var id: String { rawValue }

    /// `DateFormatter.dateFormat`-қа берілетін үлгі.
    var pattern: String {
        switch self {
        case .textual: return "d MMMM, EEEE"
        case .ddmmyyyy: return "dd.MM.yyyy"
        case .mmddyyyy: return "MM/dd/yyyy"
        case .yyyymmdd: return "yyyy-MM-dd"
        }
    }

    static var current: AppDateFormat {
        let raw = UserDefaults.standard.string(forKey: AppSettingsKey.dateFormat) ?? AppDateFormat.textual.rawValue
        return AppDateFormat(rawValue: raw) ?? .textual
    }
}
