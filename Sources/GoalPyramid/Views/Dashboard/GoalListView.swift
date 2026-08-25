import SwiftUI
import SwiftData

/// Белгілі бір деңгей + кезең үшін мақсаттар тізімі (Create / Edit / Delete + прогресс).
struct GoalListView: View {
    let level: GoalLevel
    let periodStart: Date

    @Query private var allGoals: [GoalItem]

    @State private var showingAdd = false
    @State private var editingGoal: GoalItem?

    private var goals: [GoalItem] {
        allGoals
            .filter { $0.level == level && $0.periodStart == periodStart && !$0.isDeleted }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var progress: Double {
        guard !goals.isEmpty else { return 0 }
        return Double(goals.filter(\.isCompleted).count) / Double(goals.count)
    }

    private var navTitle: String {
        switch level {
        case .fiveYear:
            return "\(PeriodHelper.year(of: periodStart)) жылғы мақсаттар"
        case .monthly, .weekly, .daily:
            return "\(PeriodHelper.displayRange(for: level, periodStart: periodStart)) — мақсаттар"
        case .yearly:
            return "\(level.title) мақсаттар"
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(PeriodHelper.displayRange(for: level, periodStart: periodStart))
                        .foregroundStyle(.secondary)
                    ProgressView(value: progress)
                        .tint(progress == 1 ? .green : Color.accentColor)
                    Text("\(goals.filter(\.isCompleted).count)/\(goals.count) мақсат · \(Int(progress * 100))% орындалды")
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
                                GoalStore.moveToTrash(goal)
                            } label: {
                                Label("Қоқысқа тастау", systemImage: "trash")
                            }
                        }
                }

                Button {
                    showingAdd = true
                } label: {
                    Label("Жаңа мақсат қосу", systemImage: "plus.circle.fill")
                }
            }

            Section {
                if level == .fiveYear {
                    NavigationLink {
                        MonthsOverviewView(year: PeriodHelper.year(of: periodStart))
                    } label: {
                        Label("Айларға өту", systemImage: "arrow.right.circle.fill")
                    }
                }

                if level == .monthly {
                    NavigationLink {
                        WeeksOverviewView(monthStart: periodStart)
                    } label: {
                        Label("Апталарға өту", systemImage: "arrow.right.circle.fill")
                    }
                    NavigationLink {
                        GoalListView(
                            level: .fiveYear,
                            periodStart: PeriodHelper.yearStart(PeriodHelper.year(of: periodStart))
                        )
                    } label: {
                        Label("Жылға қайту", systemImage: "arrow.up.circle")
                    }
                }

                if level == .weekly {
                    NavigationLink {
                        DaysOverviewView(weekStart: periodStart)
                    } label: {
                        Label("Күндерге өту", systemImage: "arrow.right.circle.fill")
                    }
                    NavigationLink {
                        GoalListView(
                            level: .monthly,
                            periodStart: PeriodHelper.periodStart(for: .monthly, containing: periodStart)
                        )
                    } label: {
                        Label("Айға қайту", systemImage: "arrow.up.circle")
                    }
                }

                if level == .daily {
                    NavigationLink {
                        GoalListView(
                            level: .weekly,
                            periodStart: PeriodHelper.periodStart(for: .weekly, containing: periodStart)
                        )
                    } label: {
                        Label("Аптаға қайту", systemImage: "arrow.up.circle")
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(navTitle)
        .sheet(isPresented: $showingAdd) {
            AddEditGoalSheet(level: level, periodStart: periodStart, parentID: nil, existingGoal: nil)
        }
        .sheet(item: $editingGoal) { goal in
            AddEditGoalSheet(level: level, periodStart: periodStart, parentID: goal.parentID, existingGoal: goal)
        }
    }
}
