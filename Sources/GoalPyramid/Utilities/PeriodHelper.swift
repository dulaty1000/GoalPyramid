import Foundation

/// Әр деңгей үшін "кезең басы" күнін есептейді (күнделікті/апталық/айлық/жылдық/5 жылдық).
/// Барлық сол кезеңге тиесілі мақсаттар бірдей `periodStart` мәнін бөліседі — сол арқылы сұрыпталады.
enum PeriodHelper {
    static var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // дүйсенбіден бастау
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
            let year = cal.component(.year, from: date)
            let eraStartYear = year - (year % 5)
            var comps = DateComponents()
            comps.year = eraStartYear
            comps.month = 1
            comps.day = 1
            return cal.date(from: comps) ?? date
        }
    }

    static func displayRange(for level: GoalLevel, periodStart: Date) -> String {
        let cal = calendar
        let df = DateFormatter()
        df.locale = Locale(identifier: "kk_KZ")

        switch level {
        case .daily:
            df.dateFormat = "d MMMM, EEEE"
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
            let year = cal.component(.year, from: periodStart)
            return "\(year) – \(year + 4)"
        }
    }
}
