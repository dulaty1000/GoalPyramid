import SwiftUI
import SwiftData
import AppKit

/// Mac menu bar-ды басқанда ашылатын шағын терезе: бүгінгі 3 тапсырма.
struct MenuBarTodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openWindow) private var openWindow
    @Query private var allGoals: [GoalItem]

    @State private var showingAdd = false

    private var todayStart: Date { PeriodHelper.periodStart(for: .daily) }

    private var todayGoals: [GoalItem] {
        allGoals
            .filter { $0.level == .daily && $0.periodStart == todayStart }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Бүгінгі 3 тапсырма")
                .font(.headline)

            Divider()

            if todayGoals.isEmpty {
                Text("Бүгінге тапсырма қосылмаған")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(todayGoals) { goal in
                    HStack(spacing: 8) {
                        Button {
                            GoalStore.toggleCompletion(goal)
                        } label: {
                            Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(goal.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text(goal.title)
                            .strikethrough(goal.isCompleted)
                            .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                            .lineLimit(1)

                        Spacer()

                        Circle()
                            .fill(goal.evaluation.color)
                            .frame(width: 10, height: 10)
                    }
                }
            }

            Divider()

            HStack {
                if todayGoals.count < GoalStore.maxPerPeriod {
                    Button("+ Тапсырма қосу") { showingAdd = true }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Button("Толық терезе") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
                .buttonStyle(.plain)

                Button("Шығу") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
            }
            .font(.caption)
        }
        .padding(14)
        .frame(width: 280)
        .sheet(isPresented: $showingAdd) {
            AddEditGoalSheet(level: .daily, periodStart: todayStart, parentID: nil, existingGoal: nil)
        }
    }
}
