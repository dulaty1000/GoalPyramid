import Foundation
import SwiftData

/// `HabitItem` үшін soft-delete логикасы + "Бүгін" тапсырмаларын
/// автоматты жасау/ұзарту.
enum HabitStore {
    /// Дағдыны Қоқысқа тастайды — сонымен қатар, осы дағдыдан автоматты
    /// жасалған, БҮГІН мен БОЛАШАҚҚА (әлі келмеген күндерге) тиесілі
    /// "Бүгін" тапсырмаларының БӘРІН де бір мезгілде Қоқысқа тастайды.
    /// ӨТКЕН күндерге тиесілі (тарихта қалған, бұрын орындалған/
    /// орындалмаған) даналар өзгеріссіз қалады.
    static func moveToTrash(_ habit: HabitItem) {
        habit.isTrashed = true
        habit.deletedAt = Date()

        guard let context = habit.modelContext else { return }
        let habitID = habit.id
        let todayStart = PeriodHelper.periodStart(for: .daily)
        let descriptor = FetchDescriptor<GoalItem>(
            predicate: #Predicate<GoalItem> { $0.habitID == habitID && !$0.isDeleted && $0.periodStart >= todayStart }
        )
        guard let upcomingTasks = try? context.fetch(descriptor) else { return }
        let deletedNow = Date()
        for task in upcomingTasks {
            task.isDeleted = true
            task.deletedAt = deletedNow
        }
    }

    /// Дағдыны қалпына келтіреді. `tasks` (Қоқыстағы, осы дағдыға
    /// тиесілі данылар) берілсе, солар да бірге қалпына келеді —
    /// `moveToTrash`-тың кері жағы, `ProjectStore.restore`-мен бірдей
    /// үлгі.
    static func restore(_ habit: HabitItem, tasks: [GoalItem] = []) {
        habit.isTrashed = false
        habit.deletedAt = nil
        for task in tasks {
            GoalStore.restore(task)
        }
    }

    /// Дағды жаңадан жасалған сәтте шақырылады — ағымдағы циклге
    /// (`cycleStartDate`..`cycleEndDate`, әдепкі 1 ай) сай "Бүгін"
    /// тапсырмаларын бірден жасайды.
    static func generateInitialSchedule(for habit: HabitItem, in context: ModelContext) {
        generateTasks(for: habit, from: habit.cycleStartDate, to: habit.cycleEndDate, in: context)
    }

    /// Пайдаланушы "Иә, жалғастырамыз" дегенде — ескі циклдің соңынан
    /// бастап келесі 2 айға жаңа тапсырмалар жасап, циклді ұзартады.
    static func renew(_ habit: HabitItem, in context: ModelContext) {
        let newStart = habit.cycleEndDate
        let newEnd = Calendar.current.date(byAdding: .month, value: 2, to: newStart) ?? newStart
        generateTasks(for: habit, from: newStart, to: newEnd, in: context)
        habit.cycleStartDate = newStart
        habit.cycleEndDate = newEnd
    }

    /// Пайдаланушы "Жоқ" дегенде — дағды өзі және бұрын жасалған
    /// тапсырмалар сақталып қалады, тек жаңасы енді жасалмайды.
    static func stop(_ habit: HabitItem) {
        habit.isActive = false
    }

    /// Тоқтатылған дағдыны қайта белсендіру — бүгіннен бастап жаңа
    /// 1 айлық цикл ашады.
    static func reactivate(_ habit: HabitItem, in context: ModelContext) {
        habit.isActive = true
        let startOfToday = Calendar.current.startOfDay(for: Date())
        habit.cycleStartDate = startOfToday
        habit.cycleEndDate = Calendar.current.date(byAdding: .month, value: 1, to: startOfToday) ?? startOfToday
        generateTasks(for: habit, from: habit.cycleStartDate, to: habit.cycleEndDate, in: context)
    }

    /// Циклі аяқталған, әлі белсенді, әлі қоқысқа тасталмаған дағдылар —
    /// пайдаланушыдан "жалғастырамыз ба?" деп сұрау керек тізім.
    static func habitsNeedingRenewalDecision(_ habits: [HabitItem]) -> [HabitItem] {
        let now = Date()
        return habits.filter { !$0.isTrashed && $0.isActive && $0.cycleEndDate <= now }
    }

    /// `[from, to)` аралығындағы әр күнге, дағдының жиілігіне сай
    /// (`.daily` — барлық күн, `.specificDays` — тек таңдалған апта
    /// күндері) "Бүгін" тапсырмасын жасайды.
    ///
    /// Пайдаланушы бір нақты күнге арналған данасын Қоқысқа тастаса
    /// (soft-delete — жазба дерекқордан МҮЛДЕМ өшірілмейді, тек
    /// `isDeleted = true` болады), сол жазба әлі де осы дағдыға тиесілі
    /// (habitID + periodStart) болып қала береді. Сол себепті, жаңа
    /// тапсырма жасар алдында, осы дағдыға тиесілі БАРЛЫҚ (өшірілгенін
    /// де қоса) бұрыннан бар күндерді бір рет алып, сол жиынтықта БАР
    /// күнге ЕКІНШІ рет жазба жасалмайды — қолмен өшіру сол күн үшін
    /// ТҰРАҚТЫ болып қалады, тек "Қалпына келтіру" арқылы ғана қайта
    /// оралады.
    private static func generateTasks(for habit: HabitItem, from startDate: Date, to endDate: Date, in context: ModelContext) {
        let calendar = Calendar.current
        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let habitID = habit.id
        let existingDescriptor = FetchDescriptor<GoalItem>(predicate: #Predicate<GoalItem> { $0.habitID == habitID })
        var blockedPeriodStarts = Set((try? context.fetch(existingDescriptor))?.map(\.periodStart) ?? [])
        // Түпкілікті өшірілген (Қоқыстан "Жою" арқылы жойылған) күндер де
        // осында — тиісті `GoalItem` жазбасы жоқ болса да, бұл тізім
        // арқылы сол күн ешқашан қайта жаратылмайды.
        blockedPeriodStarts.formUnion(habit.excludedDates)

        while current < end {
            let include: Bool
            switch habit.frequency {
            case .daily:
                include = true
            case .specificDays:
                // Foundation: 1=Жексенбі...7=Сенбі → 0=Дүйсенбі...6=Жексенбі.
                let mondayIndex = (calendar.component(.weekday, from: current) + 5) % 7
                include = habit.selectedWeekdays.contains(mondayIndex)
            }

            if include {
                let dayStart = PeriodHelper.periodStart(for: .daily, containing: current)
                if !blockedPeriodStarts.contains(dayStart) {
                    let task = GoalItem(
                        title: habit.title,
                        level: .daily,
                        periodStart: dayStart,
                        notes: habit.notes,
                        sortOrder: GoalStore.count(level: .daily, periodStart: dayStart, in: context),
                        hasDueDate: true,
                        habitID: habit.id
                    )
                    // Нақты SwiftData қатынасы — `HabitItem.tasks`-тың
                    // `.cascade` ережесі осыны қолданады.
                    task.habit = habit
                    context.insert(task)
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
    }

    /// Ескі деректерде (осы түзетуден бұрын) бір күнге ЕКІ жазба қалып
    /// қоюы мүмкін — біреуі пайдаланушы Қоқысқа тастаған, екіншісі сол
    /// күнге қате қайта жасалған әрі әлі белсенді. Осындай жұп табылса,
    /// пайдаланушының бастапқы шешімін (өшіру) құрметтеп, "қате қайта
    /// жасалған" белсенді данасын да Қоқысқа тастайды. Бір реттік
    /// сақтандыру қадамы.
    static func reconcileDuplicateHabitTasks(in context: ModelContext) {
        guard let habitTasks = try? context.fetch(FetchDescriptor<GoalItem>(predicate: #Predicate<GoalItem> { $0.habitID != nil })) else { return }

        var groups: [String: [GoalItem]] = [:]
        for task in habitTasks {
            guard let habitID = task.habitID else { continue }
            let key = "\(habitID.uuidString)|\(task.periodStart.timeIntervalSinceReferenceDate)"
            groups[key, default: []].append(task)
        }

        var didChange = false
        for group in groups.values where group.count > 1 && group.contains(where: \.isDeleted) {
            for duplicate in group where !duplicate.isDeleted {
                duplicate.isDeleted = true
                duplicate.deletedAt = Date()
                didChange = true
            }
        }
        if didChange {
            try? context.save()
        }
    }

    /// Осы түзетуден БҰРЫН дағды түпкілікті өшірілгенде оның болашаққа
    /// жазылған тапсырмалары бірге өшірілмей, "жетім" болып қалуы мүмкін
    /// еді (иесі жоқ, бірақ әлі белсенді `GoalItem`). Енді
    /// `HabitItem.tasks`-тың `.cascade` ережесі мұны алдын алады, бірақ
    /// БҰРЫН қалып қойған жетімдерді бір рет тазалайды.
    static func reconcileOrphanedHabitTasks(in context: ModelContext) {
        guard let habitTasks = try? context.fetch(FetchDescriptor<GoalItem>(predicate: #Predicate<GoalItem> { $0.habitID != nil && !$0.isDeleted })) else { return }
        guard let allHabits = try? context.fetch(FetchDescriptor<HabitItem>()) else { return }
        let existingHabitIDs = Set(allHabits.map(\.id))

        var didChange = false
        let now = Date()
        for task in habitTasks {
            guard let habitID = task.habitID, !existingHabitIDs.contains(habitID) else { continue }
            task.isDeleted = true
            task.deletedAt = now
            didChange = true
        }
        if didChange {
            try? context.save()
        }
    }
}
