import SwiftUI
import SwiftData
import Charts
import Foundation

/// Прогресс аналитикасы: деңгей бойынша орындалу, түс бойынша бағалау, соңғы 30 күндік тренд.
struct AnalyticsView: View {
    @Query(filter: #Predicate<GoalItem> { !$0.isDeleted }) private var activeGoals: [GoalItem]

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

    private var colorDistribution: [(EvaluationColor, Int)] {
        EvaluationColor.allCases.map { color in
            (color, activeGoals.filter { $0.isCompleted && $0.evaluation == color }.count)
        }
    }

    private var last30DaysTrend: [(Date, Int)] {
        let cal = PeriodHelper.calendar
        let today = cal.startOfDay(for: Date())
        return (0..<30).reversed().compactMap { offset -> (Date, Int)? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let items = activeGoals.filter { $0.level == .daily && $0.periodStart == day }
            return (day, items.filter(\.isCompleted).count)
        }
    }

    private var overallCompletionRate: Double {
        let total = activeGoals.count
        guard total > 0 else { return 0 }
        return Double(activeGoals.filter(\.isCompleted).count) / Double(total)
    }

    private var dailyGoals: [GoalItem] {
        activeGoals.filter { $0.level == .daily }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Аналитика")
                    .font(.largeTitle.bold())

                summaryCards

                card(title: "Деңгей бойынша орындалу") {
                    Chart(levelStats) { stat in
                        BarMark(
                            x: .value("Деңгей", stat.level.shortTitle),
                            y: .value("Пайыз", stat.rate * 100)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .annotation(position: .top) {
                            Text("\(Int(stat.rate * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 220)
                }

                card(title: "Түс бойынша бағалау") {
                    Chart(colorDistribution, id: \.0) { pair in
                        SectorMark(angle: .value("Саны", pair.1), innerRadius: .ratio(0.6))
                            .foregroundStyle(pair.0.color)
                    }
                    .frame(height: 220)

                    HStack(spacing: 16) {
                        ForEach(colorDistribution, id: \.0) { pair in
                            HStack(spacing: 4) {
                                Circle().fill(pair.0.color).frame(width: 8, height: 8)
                                Text("\(pair.0.label): \(pair.1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                card(title: "Жетістіктер картасы (соңғы 1 жыл)") {
                    GoalHeatmapView(dailyGoals: dailyGoals)
                }

                card(title: "Соңғы 30 күн (орындалған күндік тапсырмалар)") {
                    Chart(last30DaysTrend, id: \.0) { entry in
                        LineMark(
                            x: .value("Күн", entry.0),
                            y: .value("Орындалды", entry.1)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.green)

                        PointMark(
                            x: .value("Күн", entry.0),
                            y: .value("Орындалды", entry.1)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 200)
                }
            }
            .padding(24)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 16) {
            statCard(title: "Барлық мақсаттар", value: "\(activeGoals.count)")
            statCard(title: "Орындалды", value: "\(activeGoals.filter(\.isCompleted).count)")
            statCard(title: "Жалпы пайыз", value: "\(Int(overallCompletionRate * 100))%")
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
