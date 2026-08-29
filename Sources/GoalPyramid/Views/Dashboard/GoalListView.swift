import SwiftUI
import SwiftData

/// Белгілі бір деңгей + кезең үшін мақсаттар тізімі (Create / Edit / Delete + прогресс).
///
/// `onNavigateUp`/`onNavigateDown` — иерархия бойынша жоғары/төмен өту үшін
/// (◄/►, тек мәні берілгенде көрінеді). Бұлар **push жасамайды** — тек
/// шақырушы жақтан берілген closure арқылы қай бет көрсетілетінін ауыстырады,
/// сондықтан macOS-тың өз "артқа" батырмасы қосарланып шықпайды.
struct GoalListView: View {
    let level: GoalLevel
    let periodStart: Date
    var onNavigateUp: (() -> Void)?
    var onNavigateDown: (() -> Void)?

    @Query private var allGoals: [GoalItem]

    @State private var showingAdd = false
    @State private var editingGoal: GoalItem?

    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    /// Осы деңгей + кезеңге тиесілі барлық мақсаттар (матрицаға қойылғандары
    /// да қоса) — прогресс бұрынғыдай СОЛАРДЫҢ БӘРІН есептейді, матрицаға
    /// қойылу прогресс санын өзгертпейді.
    private var allPeriodGoals: [GoalItem] {
        allGoals.excludingTrashed().filter { $0.level == level && $0.periodStart == periodStart && $0.hasDueDate }
    }

    /// Негізгі тізімде көрінетіндер — тек Эйзенхауэр матрицасына әлі
    /// қойылмағандар (`eisenhowerQuadrant == nil`).
    private var goals: [GoalItem] {
        allPeriodGoals
            .filter { $0.eisenhowerQuadrant == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Матрицаға қойылғандар — тек "Бүгін" (күндік) деңгейде мағыналы.
    private var placedGoals: [GoalItem] {
        allPeriodGoals.filter { $0.eisenhowerQuadrant != nil }
    }

    private var progress: Double {
        guard !allPeriodGoals.isEmpty else { return 0 }
        return Double(allPeriodGoals.filter(\.isCompleted).count) / Double(allPeriodGoals.count)
    }

    private var navTitle: String {
        switch level {
        case .fiveYear:
            return L10n.yearGoalsTitle(year: PeriodHelper.year(of: periodStart), language)
        case .daily, .monthly, .weekly:
            return "\(PeriodHelper.displayRange(for: level, periodStart: periodStart))\(L10n.t(.goalsSuffix, language))"
        case .yearly:
            return L10n.levelGoalsTitle(levelTitle: level.title(language), language)
        }
    }

    var body: some View {
        List {
            // Мақсат саны қанша болса да, "Қосу" батырмасы тізімнің ЕҢ
            // ЖОҒАРЫҒЫНДА тұрады — соңына дейін скролл жасамай-ақ әрдайым
            // бірден қолжетімді ("Жобалар" бетіндегідей принцип).
            Section {
                Button {
                    showingAdd = true
                } label: {
                    Label(L10n.t(.addGoal, language), systemImage: "plus.circle.fill")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(PeriodHelper.displayRange(for: level, periodStart: periodStart))
                        .foregroundStyle(.secondary)
                    ProgressView(value: progress)
                        .tint(progress == 1 ? .green : Theme.accent)
                    Text(L10n.progressSummary(done: allPeriodGoals.filter(\.isCompleted).count, total: allPeriodGoals.count, percent: Int(progress * 100), language))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section {
                ForEach(goals) { goal in
                    HStack(spacing: 6) {
                        GoalRowView(goal: goal)

                        if level == .daily {
                            Menu {
                                ForEach(EisenhowerQuadrant.allCases) { quadrant in
                                    Button(quadrant.title(language)) {
                                        goal.eisenhowerQuadrant = quadrant
                                    }
                                }
                            } label: {
                                Image(systemName: "square.grid.2x2")
                                    .foregroundStyle(.secondary)
                            }
                            .menuIndicator(.hidden)
                            .fixedSize()
                            .help(L10n.t(.addToMatrixHelp, language))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editingGoal = goal }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            GoalStore.moveToTrash(goal)
                        } label: {
                            Label(L10n.t(.trashAction, language), systemImage: "trash")
                        }
                    }
                }
            }

            if level == .daily {
                Section {
                    EisenhowerMatrixView(placedGoals: placedGoals, onEdit: { goal in editingGoal = goal })
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(navTitle)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                if let onNavigateUp {
                    Button {
                        onNavigateUp()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                if let onNavigateDown {
                    Button {
                        onNavigateDown()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEditGoalSheet(level: level, periodStart: periodStart, existingGoal: nil)
        }
        .sheet(item: $editingGoal) { goal in
            AddEditGoalSheet(level: level, periodStart: periodStart, existingGoal: goal)
        }
    }
}
