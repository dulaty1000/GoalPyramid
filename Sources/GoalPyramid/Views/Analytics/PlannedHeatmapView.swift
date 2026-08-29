import SwiftUI
import Foundation

/// `GoalHeatmapView`-дың қасында тұратын, "Жетістіктер картасы"-ның
/// жұбы: сол күні орындалғанын емес, сол күнге ЖОСПАРЛАНҒАН (periodStart)
/// күндік мақсаттар/тапсырмалар санын көрсетеді. Түсі — қызғылт сары,
/// қанықтығы санына сатылап өседі: 1 мақсат — әлсіз, 2 — орташа,
/// 3+ — қанық. Есептеу логикасы `GoalHeatmapView`-мен бірдей (тор өлшемі,
/// апта/ай белгілері), тек түс пен көрсеткіш өзгеше — сол екінші картаны
/// өзгеріссіз қалдыру үшін бөлек файл ретінде сақталды.
struct PlannedHeatmapView: View {
    let dailyGoals: [GoalItem]

    @Environment(\.colorScheme) private var colorScheme
    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 3

    /// Бүгінгі апта дәл ортаңғы бағанда тұратындай: сол жақта 26 апта
    /// (өткен), оң жақта 26 апта (алдағы, әлі деректер жоқ) — әр аптада
    /// толық 7 күн болғандықтан бос (nil) шаршы мүлдем болмайды, сондықтан
    /// бүгінгі баған ешқашан шетке қарай ауытқымайды. `GoalHeatmapView`-мен
    /// бірдей есептеу — екі карта әрдайым синхронды (бірдей бағандар).
    private let weeksHalfSpan = 26

    private var todayWeekStart: Date {
        PeriodHelper.periodStart(for: .weekly, containing: Date())
    }

    private var paddedWeeks: [[Date]] {
        let cal = PeriodHelper.calendar
        return (-weeksHalfSpan...weeksHalfSpan).map { weekOffset -> [Date] in
            let weekStart = cal.date(byAdding: .day, value: weekOffset * 7, to: todayWeekStart) ?? todayWeekStart
            return (0..<7).map { dayOffset in
                cal.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
            }
        }
    }

    private var monthLabels: [String] {
        let cal = PeriodHelper.calendar
        let df = DateFormatter()
        df.locale = language.locale
        df.dateFormat = "LLL"
        var labels: [String] = []
        var lastMonth: Int?
        for week in paddedWeeks {
            guard let firstDate = week.first else {
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

    private var countByDay: [Date: Int] {
        var dict: [Date: Int] = [:]
        let cal = PeriodHelper.calendar
        for goal in dailyGoals {
            let day = cal.startOfDay(for: goal.periodStart)
            dict[day, default: 0] += 1
        }
        return dict
    }

    private var emptyRGB: (Double, Double, Double) {
        colorScheme == .dark ? (0.16, 0.16, 0.17) : (0.90, 0.90, 0.91)
    }

    private var fullRGB: (Double, Double, Double) {
        colorScheme == .dark ? (1.00, 0.58, 0.00) : (0.80, 0.40, 0.00)
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

    /// Санына қарай сатылап өсетін қанықтық: 0 → түссіз, 1 → әлсіз,
    /// 2 → орташа, 3+ → қанық.
    private func factor(forCount count: Int) -> Double {
        switch count {
        case 0: return 0
        case 1: return 0.35
        case 2: return 0.65
        default: return 1.0
        }
    }

    private func color(for date: Date) -> Color {
        interpolatedColor(factor: factor(forCount: countByDay[date] ?? 0))
    }

    private func weekdayLabel(_ row: Int) -> String {
        switch row {
        case 0: return L10n.t(.weekdayMon, language)
        case 2: return L10n.t(.weekdayWed, language)
        case 4: return L10n.t(.weekdayFri, language)
        default: return ""
        }
    }

    private func tooltip(for date: Date) -> String {
        let df = DateFormatter()
        df.locale = language.locale
        df.dateFormat = AppDateFormat.current.pattern
        let dateStr = df.string(from: date)
        let count = countByDay[date] ?? 0
        guard count > 0 else { return L10n.heatmapNoPlan(dateStr: dateStr, language) }
        return L10n.heatmapPlannedSummary(dateStr: dateStr, count: count, language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollViewReader { proxy in
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

                                ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color(for: date))
                                        .frame(width: cellSize, height: cellSize)
                                        .help(tooltip(for: date))
                                }
                            }
                            .id(index)
                        }
                    }
                }
                .onAppear {
                    // Diaграмма өлшемі бірінші кадрда әлі белгісіз болуы мүмкін,
                    // сол себепті екі рет шақырамыз — бірден кейін де, кадр
                    // орналасқаннан кейін де — ортаға дәл түсуі үшін.
                    proxy.scrollTo(weeksHalfSpan, anchor: .center)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo(weeksHalfSpan, anchor: .center)
                    }
                }
            }

            HStack(spacing: 6) {
                Text(L10n.t(.legendLow, language))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { factor in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(interpolatedColor(factor: factor))
                        .frame(width: 11, height: 11)
                }
                Text(L10n.t(.legendHigh, language))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
