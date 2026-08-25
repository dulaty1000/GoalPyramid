import Foundation
import SwiftData

/// Пирамидадағы кез келген деңгейдегі бір мақсат/тапсырма.
/// `levelRaw` арқылы деңгейі, `periodStart` арқылы қай кезеңге (күн/апта/ай/жыл/5 жыл) тиесілі екені анықталады.
@Model
final class GoalItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var levelRaw: Int = GoalLevel.daily.rawValue
    var isCompleted: Bool = false
    var evaluationRaw: String = EvaluationColor.none.rawValue
    var sortOrder: Int = 0
    var periodStart: Date = Date()
    var createdAt: Date = Date()
    var completedAt: Date?
    var parentID: UUID?
    var isDeleted: Bool = false
    var deletedAt: Date?

    var level: GoalLevel {
        get { GoalLevel(rawValue: levelRaw) ?? .daily }
        set { levelRaw = newValue.rawValue }
    }

    var evaluation: EvaluationColor {
        get { EvaluationColor(rawValue: evaluationRaw) ?? .none }
        set { evaluationRaw = newValue.rawValue }
    }

    init(
        title: String,
        level: GoalLevel,
        periodStart: Date,
        notes: String = "",
        parentID: UUID? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.levelRaw = level.rawValue
        self.isCompleted = false
        self.evaluationRaw = EvaluationColor.none.rawValue
        self.sortOrder = sortOrder
        self.periodStart = periodStart
        self.createdAt = Date()
        self.completedAt = nil
        self.parentID = parentID
        self.isDeleted = false
        self.deletedAt = nil
    }
}
