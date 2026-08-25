import Foundation
import SwiftData

/// "Әр деңгейде ең көбі 3 мақсат" ережесін және аяқтау логикасын басқаратын орталық утилита.
enum GoalStore {
    static let maxPerPeriod = 3

    static func count(level: GoalLevel, periodStart: Date, in context: ModelContext) -> Int {
        let levelRaw = level.rawValue
        let descriptor = FetchDescriptor<GoalItem>(
            predicate: #Predicate { $0.levelRaw == levelRaw && $0.periodStart == periodStart }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    static func canAdd(level: GoalLevel, periodStart: Date, in context: ModelContext) -> Bool {
        count(level: level, periodStart: periodStart, in: context) < maxPerPeriod
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
