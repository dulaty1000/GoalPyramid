import Foundation
import SwiftUI

/// Мақсат пирамидасының 5 деңгейі: 5 жылдық → жылдық → айлық → апталық → күндік.
enum GoalLevel: Int, Codable, CaseIterable, Identifiable {
    case fiveYear = 0
    case yearly = 1
    case monthly = 2
    case weekly = 3
    case daily = 4

    var id: Int { rawValue }

    /// Берілген тілге сай толық атау (мыс. "Жылдық"/"Годовая"/"Yearly").
    func title(_ language: AppLanguage = .current) -> String {
        switch self {
        case .fiveYear: return L10n.t(.levelFiveYearTitle, language)
        case .yearly: return L10n.t(.levelYearlyTitle, language)
        case .monthly: return L10n.t(.levelMonthlyTitle, language)
        case .weekly: return L10n.t(.levelWeeklyTitle, language)
        case .daily: return L10n.t(.levelDailyTitle, language)
        }
    }

    /// Берілген тілге сай қысқа атау (мыс. "Жыл"/"Год"/"Year").
    func shortTitle(_ language: AppLanguage = .current) -> String {
        switch self {
        case .fiveYear: return L10n.t(.levelFiveYearShort, language)
        case .yearly: return L10n.t(.levelYearlyShort, language)
        case .monthly: return L10n.t(.levelMonthlyShort, language)
        case .weekly: return L10n.t(.levelWeeklyShort, language)
        case .daily: return L10n.t(.levelDailyShort, language)
        }
    }

    var systemImage: String {
        switch self {
        case .fiveYear: return "mountain.2.fill"
        case .yearly: return "flag.fill"
        case .monthly: return "calendar"
        case .weekly: return "calendar.badge.clock"
        case .daily: return "checkmark.circle.fill"
        }
    }
}

/// "Жобалар" бөліміндегі жобаны топтастыратын мерзім санаты.
enum ProjectTimeframe: String, Codable, CaseIterable, Identifiable {
    case weekly, monthly, yearly, other

    var id: String { rawValue }

    /// Жоба қосу/өңдеу формасындағы таңдау атауы.
    func label(_ language: AppLanguage = .current) -> String {
        switch self {
        case .weekly: return L10n.t(.timeframeWeekly, language)
        case .monthly: return L10n.t(.timeframeMonthly, language)
        case .yearly: return L10n.t(.timeframeYearly, language)
        case .other: return L10n.t(.timeframeOther, language)
        }
    }

    /// "Жобалар" тізіміндегі топ тақырыбы.
    func groupTitle(_ language: AppLanguage = .current) -> String {
        switch self {
        case .weekly: return L10n.t(.timeframeWeeklyGroup, language)
        case .monthly: return L10n.t(.timeframeMonthlyGroup, language)
        case .yearly: return L10n.t(.timeframeYearlyGroup, language)
        case .other: return L10n.t(.timeframeOtherGroup, language)
        }
    }
}

/// "Бүгін" тізімінің астындағы Эйзенхауэр матрицасының 4 квадраты.
/// Пайдаланушы мақсатты қолмен осы квадраттардың біреуіне қояды —
/// автоматты категорияландыру жоқ.
enum EisenhowerQuadrant: String, Codable, CaseIterable, Identifiable {
    case urgentImportant
    case importantNotUrgent
    case urgentNotImportant
    case neither

    var id: String { rawValue }

    /// Берілген тілге сай атау — параметр ретінде ЕРЕКШЕ талап етіледі
    /// (компьютерленген меншік емес), сол арқылы шақырушы View өз
    /// `@Environment(\.appLanguage)`-ін тікелей береді де, SwiftUI осы
    /// View-дың тілге тәуелді екенін дұрыс бақылап, тіл ауысқанда дереу
    /// қайта салады (GoalListView/EisenhowerMatrixView "Бүгін" бетінде).
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .urgentImportant: return L10n.t(.quadrantUrgentImportant, language)
        case .importantNotUrgent: return L10n.t(.quadrantImportantNotUrgent, language)
        case .urgentNotImportant: return L10n.t(.quadrantUrgentNotImportant, language)
        case .neither: return L10n.t(.quadrantNeither, language)
        }
    }

    var accentColor: Color {
        switch self {
        case .urgentImportant: return Color(red: 0.94, green: 0.27, blue: 0.27)
        case .importantNotUrgent: return Color(red: 0.20, green: 0.55, blue: 0.95)
        case .urgentNotImportant: return Color(red: 0.98, green: 0.75, blue: 0.14)
        case .neither: return .secondary
        }
    }
}

/// Тапсырманы орындағаннан кейінгі түсті бағалау.
enum EvaluationColor: String, Codable, CaseIterable, Identifiable {
    case none
    case green
    case yellow
    case red

    var id: String { rawValue }

    /// Берілген тілге сай атау (себебі жоғарыдағы `EisenhowerQuadrant.title`
    /// комментарийінде түсіндірілген) — GoalRowView-дың EvaluationPicker
    /// тултиптерінде қолданылады.
    func label(_ language: AppLanguage) -> String {
        switch self {
        case .none: return L10n.t(.evalNone, language)
        case .green: return L10n.t(.evalGreen, language)
        case .yellow: return L10n.t(.evalYellow, language)
        case .red: return L10n.t(.evalRed, language)
        }
    }
}

/// "Дағдылар" бөліміндегі жиілік — "Күнделікті" немесе аптаның белгілі
/// күндері ғана. Әзірге тек таңдау/сақтау; нақты бақылау (streak,
/// "Бүгін" бетімен байланыстыру) кейін бөлек сұраныспен қосылады.
enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily, specificDays

    var id: String { rawValue }

    func title(_ language: AppLanguage = .current) -> String {
        switch self {
        case .daily: return L10n.t(.habitFrequencyDaily, language)
        case .specificDays: return L10n.t(.habitFrequencySpecificDays, language)
        }
    }
}
