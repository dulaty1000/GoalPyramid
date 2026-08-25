import SwiftUI
import SwiftData

/// Барлық 5 деңгейді (5 жыл → жыл → ай → апта → күн) бір бетте ашып-жабуға болатын accordion көрінісі.
struct HierarchyAccordionView: View {
    @Query private var allGoals: [GoalItem]

    private func goals(_ level: GoalLevel, _ periodStart: Date) -> [GoalItem] {
        allGoals
            .filter { $0.level == level && $0.periodStart == periodStart && !$0.isDeleted }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func progress(_ items: [GoalItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        return Double(items.filter(\.isCompleted).count) / Double(items.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(GoalLevel.allCases.reversed()) { level in
                    let periodStart = PeriodHelper.periodStart(for: level)
                    let items = goals(level, periodStart)

                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            if items.isEmpty {
                                Text("Мақсат жоқ")
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                            } else {
                                ForEach(items) { goal in
                                    HStack {
                                        Circle()
                                            .fill(goal.evaluation.color)
                                            .frame(width: 8, height: 8)
                                        Text(goal.title)
                                            .strikethrough(goal.isCompleted)
                                        Spacer()
                                        if goal.isCompleted {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 6)
                        .padding(.leading, 4)
                    } label: {
                        HStack {
                            Image(systemName: level.systemImage)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading) {
                                Text(level.title).font(.headline)
                                Text(PeriodHelper.displayRange(for: level, periodStart: periodStart))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(items.filter(\.isCompleted).count)/\(items.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            ProgressView(value: progress(items))
                                .frame(width: 60)
                        }
                    }
                    .padding(14)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
        }
        .navigationTitle("Иерархия")
    }
}
