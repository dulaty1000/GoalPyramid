import Foundation
import SwiftData

/// Аяқтау логикасын басқаратын орталық утилита.
enum GoalStore {
    static func count(level: GoalLevel, periodStart: Date, in context: ModelContext) -> Int {
        let levelRaw = level.rawValue
        let descriptor = FetchDescriptor<GoalItem>(
            predicate: #Predicate { $0.levelRaw == levelRaw && $0.periodStart == periodStart }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    static func markCompleted(_ goal: GoalItem, evaluation: EvaluationColor) {
        goal.isCompleted = true
        goal.evaluation = evaluation
        goal.completedAt = Date()
    }

    static func toggleCompletion(_ goal: GoalItem) {
        goal.isCompleted.toggle()
        if goal.isCompleted {
            goal.completedAt = Date()
            if goal.evaluation == .none { goal.evaluation = .green }
        } else {
            goal.completedAt = nil
        }
    }
}
