import SwiftUI
import SwiftData

/// Бір жобаның ішкі беті: атауын өңдеу + соған тиесілі тапсырмалар тізімі.
/// Тапсырмалар — жай ғана `projectID` арқылы байланысқан `GoalItem`
/// жазбалары; деңгейі (`.monthly`/`.weekly`/`.daily`) жобаның "Мерзімі"
/// мен пайдаланушы таңдаған granularity-ге қарай өзгереді (`AddEditProjectTaskSheet`),
/// сондықтан тиісті Ай/Апта бетімен немесе "Бүгін" тізімімен БІР деректі
/// бөліседі: қайсысында толтырсаң/белгілесең, екіншісінде де сол күйде
/// көрінеді — екеуі бір ғана жазбаны оқып тұр.
struct ProjectDetailView: View {
    @Bindable var project: ProjectItem
    var onBack: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var allGoals: [GoalItem]

    @State private var showingAdd = false
    @State private var editingTask: GoalItem?

    /// Терезе түбірінен келеді — тіл ауысқанда осы бет дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private var tasks: [GoalItem] {
        allGoals.excludingTrashed().filter { $0.projectID == project.id }
    }

    /// Күні белгіленбеген тапсырмалар — қосылған ретімен.
    private var undatedTasks: [GoalItem] {
        tasks.filter { !$0.hasDueDate }.sorted { $0.createdAt < $1.createdAt }
    }

    /// Күні бар тапсырмалар — күні бойынша ретімен.
    private var datedTasks: [GoalItem] {
        tasks.filter(\.hasDueDate).sorted {
            $0.periodStart == $1.periodStart
                ? $0.sortOrder < $1.sortOrder
                : $0.periodStart < $1.periodStart
        }
    }

    private var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.isCompleted).count) / Double(tasks.count)
    }

    var body: some View {
        List {
            Section {
                TextField(L10n.t(.projectNameField, language), text: $project.title)
                    .textFieldStyle(.plain)
                    .font(.title2.bold())

                Picker(L10n.t(.projectTimeframeLabel, language), selection: $project.timeframe) {
                    ForEach(ProjectTimeframe.allCases) { option in
                        Text(option.label(language)).tag(option)
                    }
                }
            }

            tasksSections

            // Граф — енді List-тің ҚАЛЫПТЫ scroll ағынының бөлігі,
            // тапсырмалар тізімінен КЕЙІН: бөлек/бекітілген панель емес,
            // бетті төмен скролл жасағанда ғана көрінеді.
            if !tasks.isEmpty {
                Section {
                    ProjectTaskGraphView(project: project, tasks: tasks, onSelect: { task in editingTask = task })
                        .listRowInsets(EdgeInsets())
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(project.title.isEmpty ? L10n.t(.untitledProject, language) : project.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .help(L10n.t(.backToProjectsHelp, language))
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEditProjectTaskSheet(project: project, existingTask: nil)
        }
        .sheet(item: $editingTask) { task in
            AddEditProjectTaskSheet(project: project, existingTask: task)
        }
    }

    @ViewBuilder
    private var tasksSections: some View {
        // Тапсырма саны қанша болса да, "Қосу" батырмасы тізімнің ЕҢ
        // ЖОҒАРЫҒЫНДА тұрады — соңына дейін скролл жасамай-ақ әрдайым
        // бірден қолжетімді.
        Section {
            Button {
                showingAdd = true
            } label: {
                Label(L10n.t(.addTaskAction, language), systemImage: "plus.circle.fill")
            }
        }

        if !tasks.isEmpty {
            Section {
                ProgressView(value: progress)
                    .tint(progress == 1 ? .green : Theme.accent)
                Text(L10n.tasksCompletedSummary(completed: tasks.filter(\.isCompleted).count, total: tasks.count, language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        if !undatedTasks.isEmpty {
            Section(L10n.t(.noDateSection, language)) {
                ForEach(undatedTasks) { task in
                    taskRow(task)
                }
            }
        }

        if !datedTasks.isEmpty {
            Section(L10n.t(.scheduledSection, language)) {
                ForEach(datedTasks) { task in
                    taskRow(task)
                }
            }
        }
    }

    @ViewBuilder
    private func taskRow(_ task: GoalItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            GoalRowView(goal: task)
            if task.hasDueDate {
                Text(PeriodHelper.displayRange(for: task.level, periodStart: task.periodStart))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 44)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { editingTask = task }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                GoalStore.moveToTrash(task)
            } label: {
                Label(L10n.t(.trashAction, language), systemImage: "trash")
            }
        }
    }
}
