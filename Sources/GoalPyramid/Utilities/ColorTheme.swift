import SwiftUI

extension EvaluationColor {
    var color: Color {
        switch self {
        case .none: return .gray.opacity(0.35)
        case .green: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .yellow: return Color(red: 0.98, green: 0.75, blue: 0.14)
        case .red: return Color(red: 0.94, green: 0.27, blue: 0.27)
        }
    }
}

enum Theme {
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
}
