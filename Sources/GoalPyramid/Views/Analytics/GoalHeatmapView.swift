import SwiftUI
import Foundation

/// GitHub commit-графигіне ұқсас жылдық "жетістіктер картасы": әр шаршы — бір
/// күн, түс қанықтығы сол күні орындалған күндік мақсаттардың пайызына сай.
struct GoalHeatmapView: View {
    let dailyGoals: [GoalItem]

    @Environment(\.colorScheme) private var colorScheme

    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 3

    /// Бүгінгі күн торлдың ортасында тұратындай: сол жақта өткен ~6 ай,
    /// оң жақта алдағы ~6 ай (әлі деректер жоқ, толтырылмаған) — уақыт
    /// өткен сайын терезе бүгінге қарай жылжып, ортада ұстайды.
    private var days: [Date] {
        let cal = PeriodHelper.calendar
        let today = cal.startOfDay(for: Date())
        let halfSpan = 182
        return (-halfSpan...halfSpan).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: today)
        }
    }

    /// Аптасына 7 күннен бағандар: [апта][дүйсенбі...жексенбі].
    private var paddedWeeks: [[Date?]] {
        let cal = PeriodHelper.calendar
        guard let first = days.first else { return [] }
        let leadingBlanks = (cal.component(.weekday, from: first) + 5) % 7
        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks) + days.map { Optional($0) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    private var monthLabels: [String] {
        let cal = PeriodHelper.calendar
        let df = DateFormatter()
        df.locale = Locale(identifier: "kk_KZ")
        df.dateFormat = "LLL"
        var labels: [String] = []
        var lastMonth: Int?
        for week in paddedWeeks {
            guard let firstDate = week.compactMap({ $0 }).first else {
                labels.append("")
                continue
            }
            let month = cal.component(.month, from: firstDate)
            if month != lastMonth {
                labels.append(df.string(from: firstDate).capitalized)
                lastMonth = month
            } else {
                labels.append("")
            }
        }
        return labels
    }

    private var statsByDay: [Date: (total: Int, completed: Int)] {
        var dict: [Date: (total: Int, completed: Int)] = [:]
        let cal = PeriodHelper.calendar
        for goal in dailyGoals {
            let day = cal.startOfDay(for: goal.periodStart)
            var entry = dict[day] ?? (0, 0)
            entry.total += 1
            if goal.isCompleted { entry.completed += 1 }
            dict[day] = entry
        }
        return dict
    }

    private var emptyRGB: (Double, Double, Double) {
        colorScheme == .dark ? (0.16, 0.16, 0.17) : (0.90, 0.90, 0.91)
    }

    private var fullRGB: (Double, Double, Double) {
        colorScheme == .dark ? (0.20, 0.78, 0.35) : (0.13, 0.55, 0.20)
    }

    private func interpolatedColor(factor: Double) -> Color {
        let e = emptyRGB, f = fullRGB
        let t = min(max(factor, 0), 1)
        return Color(
            red: e.0 + (f.0 - e.0) * t,
            green: e.1 + (f.1 - e.1) * t,
            blue: e.2 + (f.2 - e.2) * t
        )
    }

    private func color(for date: Date) -> Color {
        guard let stat = statsByDay[date], stat.total > 0 else {
            return interpolatedColor(factor: 0)
        }
        let rate = Double(stat.completed) / Double(stat.total)
        return interpolatedColor(factor: 0.22 + rate * 0.78)
    }

    private func weekdayLabel(_ row: Int) -> String {
        switch row {
        case 0: return "Дс"
        case 2: return "Ср"
        case 4: return "Жм"
        default: return ""
        }
    }

    private func tooltip(for date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "kk_KZ")
        df.dateFormat = "d MMMM, EEEE"
        let dateStr = df.string(from: date)
        guard let stat = statsByDay[date], stat.total > 0 else {
            return "\(dateStr): мақсат жоқ"
        }
        return "\(dateStr): \(stat.completed)/\(stat.total) мақсат орындалды"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: cellSpacing) {
                    VStack(spacing: cellSpacing) {
                        Color.clear.frame(height: 14)
                        ForEach(0..<7, id: \.self) { row in
                            Text(weekdayLabel(row))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .frame(width: 20, height: cellSize, alignment: .trailing)
                        }
                    }

                    ForEach(Array(paddedWeeks.enumerated()), id: \.offset) { index, week in
                        VStack(spacing: cellSpacing) {
                            Text(monthLabels[index])
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .frame(height: 14, alignment: .leading)
                                .fixedSize()

                            ForEach(Array(week.enumerated()), id: \.offset) { _, maybeDate in
                                if let date = maybeDate {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color(for: date))
                                        .frame(width: cellSize, height: cellSize)
                                        .help(tooltip(for: date))
                                } else {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.clear)
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                Text("Аз")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { factor in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(interpolatedColor(factor: factor))
                        .frame(width: 11, height: 11)
                }
                Text("Көп")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
