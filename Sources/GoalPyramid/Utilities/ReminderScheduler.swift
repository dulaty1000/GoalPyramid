import Foundation
import SwiftData

/// Қосымша жұмыс істеп тұрған бойы фонда (30 секунд сайын) тексеретін
/// хабарландыру жоспарлаушы: күнделікті еске салу және апта/ай соңындағы
/// қорытынды. Мазмұны әр тексерісте SwiftData-дан ТІРІ қайта есептеледі
/// (UNCalendarNotificationTrigger сияқты алдын ала бекітілген мәтін емес),
/// сондықтан сан әрдайым дәл. Бір күнде/аптада/айда бір рет қана жіберу
/// үшін соңғы жіберілген күн/апта/ай UserDefaults-та сақталады.
@MainActor
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    /// Апта/ай қорытындысы осы уақытта тексеріледі (уақыт таңдағышы жоқ,
    /// сол себепті кешкі бір тұрақты сағат таңдалды).
    private let summaryCheckHour = 21
    private let summaryCheckMinute = 0

    private var timer: Timer?
    private var context: ModelContext?

    private init() {}

    func start(context: ModelContext) {
        self.context = context
        guard timer == nil else { return }
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        let now = Date()
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now)
        let currentHour = comps.hour ?? 0
        let currentMinute = comps.minute ?? 0

        checkDailyReminder(now: now, currentHour: currentHour, currentMinute: currentMinute)
        checkTrashAutoDelete(now: now)

        guard currentHour == summaryCheckHour, currentMinute == summaryCheckMinute else { return }
        checkWeeklySummary(now: now)
        checkMonthlySummary(now: now)
    }

    /// "Настройка" → "Қоқысты автоматты тазарту" қосулы болса, таңдалған
    /// күн санынан ескі қоқыс жазбаларын (мақсаттар, жобалар — тапсырмалары
    /// қоса, идея парақтары) түбегейлі жояды. `start()` шақырылғанда
    /// (қосымша ашылған сайын) бірден, содан кейін күнде бір рет тексеріледі.
    private func checkTrashAutoDelete(now: Date) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: AppSettingsKey.trashAutoDeleteEnabled) else { return }

        let todayKey = Self.dayString(now)
        guard defaults.string(forKey: AppSettingsKey.trashAutoDeleteLastRunDay) != todayKey else { return }
        defaults.set(todayKey, forKey: AppSettingsKey.trashAutoDeleteLastRunDay)

        let days = defaults.object(forKey: AppSettingsKey.trashAutoDeleteDays) as? Int ?? 30
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) else { return }
        guard let context else { return }

        let allGoals = (try? context.fetch(FetchDescriptor<GoalItem>())) ?? []
        let allProjects = (try? context.fetch(FetchDescriptor<ProjectItem>())) ?? []
        let allNotes = (try? context.fetch(FetchDescriptor<NoteItem>())) ?? []

        var purgedGoalIDs = Set<PersistentIdentifier>()

        for project in allProjects where project.isDeleted {
            guard let deletedAt = project.deletedAt, deletedAt < cutoff else { continue }
            for task in allGoals where task.projectID == project.id {
                context.delete(task)
                purgedGoalIDs.insert(task.persistentModelID)
            }
            context.delete(project)
        }

        for goal in allGoals where goal.isDeleted && !purgedGoalIDs.contains(goal.persistentModelID) {
            if let deletedAt = goal.deletedAt, deletedAt < cutoff {
                context.delete(goal)
            }
        }

        for note in allNotes where note.isDeleted {
            if let deletedAt = note.deletedAt, deletedAt < cutoff {
                context.delete(note)
            }
        }

        try? context.save()
    }

    private func checkDailyReminder(now: Date, currentHour: Int, currentMinute: Int) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: AppSettingsKey.dailyReminderEnabled) else { return }

        let targetHour = defaults.object(forKey: AppSettingsKey.dailyReminderHour) as? Int ?? 20
        let targetMinute = defaults.object(forKey: AppSettingsKey.dailyReminderMinute) as? Int ?? 0
        guard currentHour == targetHour, currentMinute == targetMinute else { return }

        let todayKey = Self.dayString(now)
        guard defaults.string(forKey: AppSettingsKey.dailyReminderLastFiredDay) != todayKey else { return }
        defaults.set(todayKey, forKey: AppSettingsKey.dailyReminderLastFiredDay)

        guard let context else { return }
        let dailyLevelRaw = GoalLevel.daily.rawValue
        let todayStart = PeriodHelper.periodStart(for: .daily, containing: now)
        let descriptor = FetchDescriptor<GoalItem>(
            predicate: #Predicate<GoalItem> {
                $0.levelRaw == dailyLevelRaw
                    && $0.periodStart == todayStart
                    && $0.hasDueDate
                    && !$0.isDeleted
                    && !$0.isCompleted
            }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count > 0 else { return }

        NotificationManager.send(
            title: L10n.t(.appNavTitle),
            body: L10n.dailyReminderBody(count: count)
        )
    }

    private func checkWeeklySummary(now: Date) {
        guard UserDefaults.standard.bool(forKey: AppSettingsKey.summaryEnabled) else { return }
        let cal = PeriodHelper.calendar
        let weekStart = PeriodHelper.periodStart(for: .weekly, containing: now)
        guard let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart) else { return }
        guard cal.isDate(now, inSameDayAs: weekEnd) else { return }

        let weekKey = Self.dayString(weekStart)
        guard UserDefaults.standard.string(forKey: AppSettingsKey.weeklySummaryLastFiredWeek) != weekKey else { return }
        UserDefaults.standard.set(weekKey, forKey: AppSettingsKey.weeklySummaryLastFiredWeek)

        guard let context else { return }
        let dailyLevelRaw = GoalLevel.daily.rawValue
        let descriptor = FetchDescriptor<GoalItem>(
            predicate: #Predicate<GoalItem> {
                $0.levelRaw == dailyLevelRaw
                    && $0.hasDueDate
                    && !$0.isDeleted
                    && $0.periodStart >= weekStart
                    && $0.periodStart <= weekEnd
            }
        )
        guard let items = try? context.fetch(descriptor), !items.isEmpty else { return }
        let completed = items.filter(\.isCompleted).count

        NotificationManager.send(
            title: L10n.t(.notifWeeklyTitle),
            body: L10n.summaryReminderBody(completed: completed, total: items.count, isWeek: true)
        )
    }

    private func checkMonthlySummary(now: Date) {
        guard UserDefaults.standard.bool(forKey: AppSettingsKey.summaryEnabled) else { return }
        let cal = PeriodHelper.calendar
        let monthStart = PeriodHelper.periodStart(for: .monthly, containing: now)
        guard let monthEnd = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return }
        guard cal.isDate(now, inSameDayAs: monthEnd) else { return }

        let monthKey = Self.dayString(monthStart)
        guard UserDefaults.standard.string(forKey: AppSettingsKey.monthlySummaryLastFiredMonth) != monthKey else { return }
        UserDefaults.standard.set(monthKey, forKey: AppSettingsKey.monthlySummaryLastFiredMonth)

        guard let context else { return }
        let dailyLevelRaw = GoalLevel.daily.rawValue
        let descriptor = FetchDescriptor<GoalItem>(
            predicate: #Predicate<GoalItem> {
                $0.levelRaw == dailyLevelRaw
                    && $0.hasDueDate
                    && !$0.isDeleted
                    && $0.periodStart >= monthStart
                    && $0.periodStart <= monthEnd
            }
        )
        guard let items = try? context.fetch(descriptor), !items.isEmpty else { return }
        let completed = items.filter(\.isCompleted).count

        NotificationManager.send(
            title: L10n.t(.notifMonthlyTitle),
            body: L10n.summaryReminderBody(completed: completed, total: items.count, isWeek: false)
        )
    }

    private static func dayString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .current
        return df.string(from: date)
    }
}
