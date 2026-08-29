import Foundation

/// Әр деңгей үшін "кезең басы" күнін есептейді (күнделікті/апталық/айлық/жылдық/5 жылдық).
/// Барлық сол кезеңге тиесілі мақсаттар бірдей `periodStart` мәнін бөліседі — сол арқылы сұрыпталады.
enum PeriodHelper {
    static var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        let raw = UserDefaults.standard.string(forKey: AppSettingsKey.weekStart) ?? WeekStartDay.monday.rawValue
        cal.firstWeekday = (WeekStartDay(rawValue: raw) ?? .monday).calendarFirstWeekday
        cal.timeZone = .current
        return cal
    }

    static func periodStart(for level: GoalLevel, containing date: Date = Date()) -> Date {
        let cal = calendar
        switch level {
        case .daily:
            return cal.startOfDay(for: date)
        case .weekly:
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return cal.date(from: comps) ?? date
        case .monthly:
            let comps = cal.dateComponents([.year, .month], from: date)
            return cal.date(from: comps) ?? date
        case .yearly:
            let comps = cal.dateComponents([.year], from: date)
            return cal.date(from: comps) ?? date
        case .fiveYear:
            let comps = cal.dateComponents([.year], from: date)
            return cal.date(from: comps) ?? date
        }
    }

    /// Берілген жылдың 1 қаңтарын қайтарады — "5 Жыл" бөліміндегі жеке жыл беттері үшін.
    static func yearStart(_ year: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = 1
        comps.day = 1
        return calendar.date(from: comps) ?? Date()
    }

    static func year(of date: Date) -> Int {
        calendar.component(.year, from: date)
    }

    /// Берілген жыл мен ай нөмірінің 1-күнін қайтарады.
    static func monthStart(year: Int, month: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        return calendar.date(from: comps) ?? Date()
    }

    /// Берілген айға тиесілі апталар (айдың 1-күні кіретін аптадан бастап,
    /// соңғы күні кіретін аптаға дейін, дүйсенбіден басталады).
    static func weeksInMonth(_ monthStart: Date) -> [Date] {
        let cal = calendar
        guard let monthEnd = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return [] }
        var result: [Date] = []
        var current = periodStart(for: .weekly, containing: monthStart)
        while current <= monthEnd {
            result.append(current)
            guard let next = cal.date(byAdding: .day, value: 7, to: current) else { break }
            current = next
        }
        return result
    }

    /// Берілген (дүйсенбіден басталатын) аптадағы 7 күн.
    static func daysInWeek(_ weekStart: Date) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    static func displayRange(for level: GoalLevel, periodStart: Date) -> String {
        let cal = calendar
        let df = DateFormatter()
        // Ай/апта күндерінің атаулары ("Тамыз"/"Дүйсенбі" т.б.) да ағымдағы
        // интерфейс тіліне сай көрінуі үшін.
        df.locale = AppLanguage.current.locale

        switch level {
        case .daily:
            df.dateFormat = AppDateFormat.current.pattern
            return df.string(from: periodStart)
        case .weekly:
            guard let end = cal.date(byAdding: .day, value: 6, to: periodStart) else { return "" }
            df.dateFormat = "d MMM"
            return "\(df.string(from: periodStart)) – \(df.string(from: end))"
        case .monthly:
            df.dateFormat = "LLLL yyyy"
            return df.string(from: periodStart).capitalized
        case .yearly:
            df.dateFormat = "yyyy"
            return df.string(from: periodStart)
        case .fiveYear:
            df.dateFormat = "yyyy"
            return df.string(from: periodStart)
        }
    }
}
