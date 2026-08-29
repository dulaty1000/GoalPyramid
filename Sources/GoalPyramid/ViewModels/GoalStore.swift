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

    /// Тапсырманы "орындалды ↔ орындалмады" күйіне ауыстырады. Негізгі
    /// интерфейсте (тізім жолдары, "Жаңа тапсырма" диалогтары) бұл енді
    /// ТІКЕЛЕЙ `EvaluationPicker` арқылы басқарылады (`GoalItem.evaluation`
    /// setter-ін қараңыз); бұл функция тек MenuBar виджетінің жинақы
    /// жылдам-toggle батырмасы сияқты бөлек checkbox қолданатын
    /// орындарда қажет.
    static func toggleCompletion(_ goal: GoalItem) {
        goal.evaluation = goal.isCompleted ? .none : .green
    }

    /// Ескі деректерде (мыс. бұрынғы backup-тан импортталған) `isCompleted`
    /// пен `evaluation` арасында сәйкессіздік қалып қоюы мүмкін —
    /// бұрын checkbox арқылы "Орындалды" деп белгіленген, бірақ бағасы
    /// әлі "сұр" (`.none`) болып қалған тапсырмаларды "жасыл" бағаға
    /// көшіреді. Жаңа модельде екеуі әрдайым бірге жүреді, сондықтан
    /// бұл тек бір реттік сақтандыру қадамы.
    static func reconcileLegacyCompletionState(in context: ModelContext) {
        guard let items = try? context.fetch(FetchDescriptor<GoalItem>()) else { return }
        var didChange = false
        for item in items where item.isCompleted && item.evaluation == .none {
            item.evaluation = .green
            didChange = true
        }
        if didChange {
            try? context.save()
        }
    }

    /// Тапсырманы Қоқысқа тастайды. Егер бұл дағдыдан автоматты жасалған
    /// тапсырма болса (`habitID != nil`), сол дағдының
    /// `excludedDates`-іне осы күнді де қосады — осылай, осы `GoalItem`
    /// жазбасы Қоқыстан кейін ТҮПКІЛІКТІ өшірілсе де, дағдының кестелеу
    /// логикасы бұл нақты күнге ЕШҚАШАН қайта тапсырма жасамайды (тек
    /// "Дағдылар" бетінен қолмен қайта белсендірусіз/жаңа циклсіз).
    static func moveToTrash(_ goal: GoalItem) {
        goal.isDeleted = true
        goal.deletedAt = Date()

        if let habitID = goal.habitID, let context = goal.modelContext {
            let descriptor = FetchDescriptor<HabitItem>(predicate: #Predicate<HabitItem> { $0.id == habitID })
            if let habit = try? context.fetch(descriptor).first, !habit.excludedDates.contains(goal.periodStart) {
                habit.excludedDates.append(goal.periodStart)
            }
        }
    }

    static func restore(_ goal: GoalItem) {
        goal.isDeleted = false
        goal.deletedAt = nil
    }
}
