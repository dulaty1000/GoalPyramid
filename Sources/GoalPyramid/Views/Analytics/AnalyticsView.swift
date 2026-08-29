import SwiftUI
import SwiftData
import Charts
import Foundation

/// Прогресс аналитикасы: деңгей бойынша орындалу, деңгей бойынша барлық сан, соңғы 30 күндік тренд.
struct AnalyticsView: View {
    // `habitID == nil` — "Дағдылар"-дан автоматты жасалған "Бүгін"
    // тапсырмалары Аналитиканың БАРЛЫҚ есептеулерінен (heatmap-тар,
    // деңгей бойынша пайыз, т.б.) осылай толығымен тыс қалады.
    @Query(filter: #Predicate<GoalItem> { !$0.isDeleted && $0.habitID == nil }) private var activeGoals: [GoalItem]
    // Дәл осы екі @Query — жоғарыдағы `activeGoals`-тан МҮЛДЕМ бөлек:
    // тек "Дағдылар" графигі үшін ғана қолданылады, басқа ешбір
    // Аналитика есептеуіне (heatmap, кесте, т.б.) араласпайды.
    @Query(filter: #Predicate<HabitItem> { !$0.isDeleted }) private var habitsForChart: [HabitItem]
    @Query(filter: #Predicate<GoalItem> { !$0.isDeleted && $0.habitID != nil }) private var habitGoalsForChart: [GoalItem]

    /// Терезе түбірінен келеді — тіл ауысқанда осы бет дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private struct LevelStat: Identifiable {
        let id = UUID()
        let level: GoalLevel
        let total: Int
        let completed: Int
        var rate: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    }

    private var levelStats: [LevelStat] {
        GoalLevel.allCases.map { level in
            let items = activeGoals.filter { $0.level == level }
            return LevelStat(level: level, total: items.count, completed: items.filter(\.isCompleted).count)
        }
    }

    private struct LevelCountRow: Identifiable {
        let id = UUID()
        let label: String
        let total: Int
        let completed: Int
        var pending: Int { total - completed }
    }

    private func levelCountRow(label: String, level: GoalLevel) -> LevelCountRow {
        let items = activeGoals.filter { $0.level == level }
        return LevelCountRow(label: label, total: items.count, completed: items.filter(\.isCompleted).count)
    }

    private var levelCountRows: [LevelCountRow] {
        [
            levelCountRow(label: GoalLevel.yearly.shortTitle(language), level: .yearly),
            levelCountRow(label: GoalLevel.monthly.shortTitle(language), level: .monthly),
            levelCountRow(label: GoalLevel.weekly.shortTitle(language), level: .weekly),
            levelCountRow(label: GoalLevel.daily.shortTitle(language), level: .daily)
        ]
    }

    private var last30DaysTrend: [(Date, Int)] {
        let cal = PeriodHelper.calendar
        let today = cal.startOfDay(for: Date())
        return (0..<30).reversed().compactMap { offset -> (Date, Int)? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let items = activeGoals.filter { $0.level == .daily && $0.periodStart == day && $0.hasDueDate }
            return (day, items.filter(\.isCompleted).count)
        }
    }

    private var overallCompletionRate: Double {
        let total = activeGoals.count
        guard total > 0 else { return 0 }
        return Double(activeGoals.filter(\.isCompleted).count) / Double(total)
    }

    private var dailyGoals: [GoalItem] {
        activeGoals.filter { $0.level == .daily && $0.hasDueDate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(L10n.t(.sidebarAnalytics, language))
                    .font(.largeTitle.bold())

                summaryCards

                card(title: L10n.t(.analyticsCompletionByLevel, language)) {
                    Chart(levelStats) { stat in
                        BarMark(
                            x: .value(L10n.t(.chartLevelAxis, language), stat.level.shortTitle(language)),
                            y: .value(L10n.t(.chartPercentAxis, language), stat.rate * 100)
                        )
                        .foregroundStyle(Theme.accent.gradient)
                        .annotation(position: .top) {
                            Text("\(Int(stat.rate * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 220)
                }

                card(title: L10n.t(.analyticsCountByLevel, language)) {
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                        GridRow {
                            Text("")
                            Text(L10n.t(.colTotal, language))
                            Text(L10n.t(.colPending, language))
                            Text(L10n.t(.colCompleted, language))
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                        Divider()
                            .gridCellColumns(4)

                        ForEach(levelCountRows) { row in
                            GridRow {
                                Text(row.label)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(row.total)")
                                    .font(.title3.bold())
                                Text("\(row.pending)")
                                    .font(.title3.bold())
                                    .foregroundStyle(.orange)
                                Text("\(row.completed)")
                                    .font(.title3.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    Text(L10n.t(.pyramidTip, language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                }

                HStack(alignment: .top, spacing: 16) {
                    card(title: L10n.t(.plannedDaysCardTitle, language)) {
                        PlannedHeatmapView(dailyGoals: dailyGoals)
                    }
                    .frame(maxWidth: .infinity)

                    card(title: L10n.t(.achievementsCardTitle, language)) {
                        GoalHeatmapView(dailyGoals: dailyGoals)
                    }
                    .frame(maxWidth: .infinity)
                }

                card(title: L10n.t(.last30DaysCardTitle, language)) {
                    Chart(last30DaysTrend, id: \.0) { entry in
                        LineMark(
                            x: .value(L10n.t(.chartDayAxis, language), entry.0),
                            y: .value(L10n.t(.chartCompletedAxis, language), entry.1)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.green)

                        PointMark(
                            x: .value(L10n.t(.chartDayAxis, language), entry.0),
                            y: .value(L10n.t(.chartCompletedAxis, language), entry.1)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 200)
                }

                card(title: L10n.t(.habitHeatmapCardTitle, language)) {
                    HabitHeatmapRowsView(habits: habitsForChart, habitGoals: habitGoalsForChart)
                }
            }
            .padding(24)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 16) {
            statCard(title: L10n.t(.analyticsTotalGoals, language), value: "\(activeGoals.count)")
            statCard(title: L10n.t(.analyticsCompleted, language), value: "\(activeGoals.filter(\.isCompleted).count)")
            statCard(title: L10n.t(.analyticsOverallPercent, language), value: "\(Int(overallCompletionRate * 100))%")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.system(size: 32, weight: .bold, design: .rounded))
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
