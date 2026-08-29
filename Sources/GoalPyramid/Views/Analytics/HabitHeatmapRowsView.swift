import SwiftUI
import Foundation

/// "Жетістіктер картасы" (GitHub-стиль) үлгісіндегі мини-heatmap, бірақ
/// әр дағдыға ӨЗ АЛДЫНА бөлек жол: соңғы 30 күн, әр күн үшін 3 күй —
/// орындалды (жасыл), қалып кетті (қызыл), қолданылмайды/әлі жоқ
/// (сұр). Барлық дағды БІР ортақ түс схемасын пайдаланады — әр дағдыға
/// бөлек түс тағайындалмайды.
struct HabitHeatmapRowsView: View {
    let habits: [HabitItem]
    let habitGoals: [GoalItem]

    @Environment(\.colorScheme) private var colorScheme
    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 3
    private let dayCount = 30

    private enum DayState {
        case done, missed, notApplicable
    }

    private var days: [Date] {
        let cal = PeriodHelper.calendar
        let today = cal.startOfDay(for: Date())
        return (0..<dayCount).reversed().compactMap { offset in
            cal.date(byAdding: .day, value: -offset, to: today)
        }
    }

    /// Күннің күйі: дағды жасалғанға дейінгі немесе жиілігіне сай
    /// "қолданылмайтын" күндер — сұр; сол күнге тапсырма жасалып,
    /// орындалса — жасыл; жасалып, орындалмаса — қызыл.
    private func state(of habit: HabitItem, on day: Date) -> DayState {
        let cal = PeriodHelper.calendar
        let dayStart = cal.startOfDay(for: day)
        let createdDay = cal.startOfDay(for: habit.createdAt)
        guard dayStart >= createdDay else { return .notApplicable }

        if habit.frequency == .specificDays {
            let weekday = Calendar.current.component(.weekday, from: dayStart)
            let mondayIndex = (weekday + 5) % 7
            guard habit.selectedWeekdays.contains(mondayIndex) else { return .notApplicable }
        }

        guard let task = habitGoals.first(where: { $0.habitID == habit.id && $0.periodStart == dayStart }) else {
            return .notApplicable
        }
        return task.isCompleted ? .done : .missed
    }

    private var doneColor: Color {
        colorScheme == .dark ? Color(red: 0.20, green: 0.78, blue: 0.35) : Color(red: 0.13, green: 0.55, blue: 0.20)
    }

    private var emptyColor: Color {
        colorScheme == .dark ? Color(red: 0.16, green: 0.16, blue: 0.17) : Color(red: 0.90, green: 0.90, blue: 0.91)
    }

    private var missedColor: Color {
        colorScheme == .dark ? Color(red: 0.62, green: 0.18, blue: 0.18) : Color(red: 0.86, green: 0.30, blue: 0.30)
    }

    private func color(for state: DayState) -> Color {
        switch state {
        case .done: return doneColor
        case .missed: return missedColor
        case .notApplicable: return emptyColor
        }
    }

    private func statusLabel(for state: DayState) -> String {
        switch state {
        case .done: return L10n.t(.habitLegendDone, language)
        case .missed: return L10n.t(.habitLegendMissed, language)
        case .notApplicable: return L10n.t(.habitLegendNotApplicable, language)
        }
    }

    private func tooltip(day: Date, state: DayState) -> String {
        let df = DateFormatter()
        df.locale = language.locale
        df.dateFormat = AppDateFormat.current.pattern
        return L10n.habitDayTooltip(dateStr: df.string(from: day), statusLabel: statusLabel(for: state), language)
    }

    var body: some View {
        if habits.isEmpty {
            Text(L10n.t(.noHabitsYet, language))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(habits) { habit in
                    HStack(spacing: 10) {
                        Text(habit.title.isEmpty ? L10n.t(.untitledHabit, language) : habit.title)
                            .font(.subheadline)
                            .lineLimit(1)
                            .frame(width: 140, alignment: .leading)

                        HStack(spacing: cellSpacing) {
                            ForEach(days, id: \.self) { day in
                                let dayState = state(of: habit, on: day)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color(for: dayState))
                                    .frame(width: cellSize, height: cellSize)
                                    .help(tooltip(day: day, state: dayState))
                            }
                        }
                    }
                }

                legend
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: doneColor, label: L10n.t(.habitLegendDone, language))
            legendItem(color: missedColor, label: L10n.t(.habitLegendMissed, language))
            legendItem(color: emptyColor, label: L10n.t(.habitLegendNotApplicable, language))
        }
        .padding(.top, 4)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 11, height: 11)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
