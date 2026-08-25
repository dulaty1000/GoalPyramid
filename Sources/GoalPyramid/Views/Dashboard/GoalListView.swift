import SwiftUI
import SwiftData

/// Белгілі бір деңгей + кезең үшін мақсаттар тізімі (Create / Edit / Delete + прогресс).
struct GoalListView: View {
    let level: GoalLevel
    let periodStart: Date

    @Environment(\.modelContext) private var context
    @Query private var allGoals: [GoalItem]

    @State private var showingAdd = false
    @State private var editingGoal: GoalItem?

    private var goals: [GoalItem] {
        allGoals
            .filter { $0.level == level && $0.periodStart == periodStart }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var progress: Double {
        guard !goals.isEmpty else { return 0 }
        return Double(goals.filter(\.isCompleted).count) / Double(goals.count)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(PeriodHelper.displayRange(for: level, periodStart: periodStart))
                        .foregroundStyle(.secondary)
                    ProgressView(value: progress)
                        .tint(progress == 1 ? .green : Color.accentColor)
                    Text("\(goals.count)/\(GoalStore.maxPerPeriod) мақсат · \(Int(progress * 100))% орындалды")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section {
                ForEach(goals) { goal in
                    GoalRowView(goal: goal)
                        .contentShape(Rectangle())
                        .onTapGesture { editingGoal = goal }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                context.delete(goal)
                            } label: {
                                Label("Өшіру", systemImage: "trash")
                            }
                        }
                }

                if goals.count < GoalStore.maxPerPeriod {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Жаңа мақсат қосу", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("\(level.title) мақсаттар")
        .sheet(isPresented: $showingAdd) {
            AddEditGoalSheet(level: level, periodStart: periodStart, parentID: nil, existingGoal: nil)
        }
        .sheet(item: $editingGoal) { goal in
            AddEditGoalSheet(level: level, periodStart: periodStart, parentID: goal.parentID, existingGoal: goal)
        }
    }
}
