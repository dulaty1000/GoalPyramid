import Foundation

/// Мақсат пирамидасының 5 деңгейі: 5 жылдық → жылдық → айлық → апталық → күндік.
enum GoalLevel: Int, Codable, CaseIterable, Identifiable {
    case fiveYear = 0
    case yearly = 1
    case monthly = 2
    case weekly = 3
    case daily = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .fiveYear: return "5 жылдық"
        case .yearly: return "Жылдық"
        case .monthly: return "Айлық"
        case .weekly: return "Апталық"
        case .daily: return "Күндік"
        }
    }

    var shortTitle: String {
        switch self {
        case .fiveYear: return "5 жыл"
        case .yearly: return "Жыл"
        case .monthly: return "Ай"
        case .weekly: return "Апта"
        case .daily: return "Күн"
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

    /// Иерархиядағы бір деңгей жоғары мақсат түрі (байланыстыру үшін).
    var parentLevel: GoalLevel? {
        switch self {
        case .fiveYear: return nil
        case .yearly: return .fiveYear
        case .monthly: return .yearly
        case .weekly: return .monthly
        case .daily: return .weekly
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

    var label: String {
        switch self {
        case .none: return "Бағаланбаған"
        case .green: return "Үздік"
        case .yellow: return "Жартылай"
        case .red: return "Орындалмады"
        }
    }
}
