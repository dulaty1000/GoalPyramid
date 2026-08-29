import SwiftUI

/// Жоба атаулары тізімі: жаңа жоба қосу, барын ашу, керексізін қоқысқа
/// тастау ("Идеялар" тізімімен бірдей үлгі).
///
/// Тізімнің ЕҢ СОҢЫНДА "Аяқталған жобалар" деген бесінші топ бар —
/// онда кемінде 1 тапсырмасы бар ЖӘНЕ солардың БАРЛЫҒЫ орындалған
/// жобалар автоматты түрде көрінеді (есептеу ғана, деректерде ешбір
/// "аяқталды" өрісі сақталмайды — сондықтан тапсырманы кейін қайта
/// "орындалмады" деп белгілесе, жоба өз бастапқы тобына автоматты
/// түрде қайта оралады).
struct ProjectsListView: View {
    let projects: [ProjectItem]
    let allGoals: [GoalItem]
    var onSelect: (ProjectItem) -> Void
    var onAdd: () -> Void
    var onDelete: (ProjectItem) -> Void

    @State private var hoveredProjectID: UUID?
    @State private var pendingDelete: ProjectItem?

    /// Терезе түбірінен келеді — тіл ауысқанда осы бет дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private func tasks(of project: ProjectItem) -> [GoalItem] {
        allGoals.excludingTrashed().filter { $0.projectID == project.id }
    }

    /// Кемінде 1 тапсырмасы бар және солардың барлығы орындалған ба.
    private func isCompleted(_ project: ProjectItem) -> Bool {
        let projectTasks = tasks(of: project)
        return !projectTasks.isEmpty && projectTasks.allSatisfy(\.isCompleted)
    }

    private var activeProjects: [ProjectItem] { projects.filter { !isCompleted($0) } }
    private var completedProjects: [ProjectItem] { projects.filter(isCompleted) }

    /// Санат бойынша топтар — тұрақты рет: апталық → айлық → жылдық → басқа.
    /// Бос топ көрсетілмейді. Аяқталған жобалар бөлек, соңғы топта.
    private var groupedProjects: [(timeframe: ProjectTimeframe, projects: [ProjectItem])] {
        ProjectTimeframe.allCases.compactMap { timeframe in
            let items = activeProjects.filter { $0.timeframe == timeframe }
            return items.isEmpty ? nil : (timeframe, items)
        }
    }

    var body: some View {
        List {
            Section {
                Button {
                    onAdd()
                } label: {
                    Label(L10n.t(.addProjectAction, language), systemImage: "plus.circle.fill")
                }
            }

            if projects.isEmpty {
                Section {
                    Text(L10n.t(.noProjectsYet, language))
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedProjects, id: \.timeframe) { group in
                    Section(group.timeframe.groupTitle(language)) {
                        ForEach(group.projects) { project in
                            projectRow(project)
                        }
                    }
                }

                if !completedProjects.isEmpty {
                    Section(L10n.t(.completedProjectsGroup, language)) {
                        ForEach(completedProjects) { project in
                            projectRow(project)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(L10n.t(.sidebarProjects, language))
        .alert(
            L10n.t(.deleteProjectConfirmTitle, language),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { project in
            Button(L10n.t(.settingsCancel, language), role: .cancel) {}
            Button(L10n.t(.confirmDeleteAction, language), role: .destructive) {
                onDelete(project)
            }
        } message: { project in
            Text(L10n.deleteProjectMessage(projectTitle: project.title, language))
        }
    }

    @ViewBuilder
    private func projectRow(_ project: ProjectItem) -> some View {
        HStack(spacing: 8) {
            Button {
                onSelect(project)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(Theme.accent)
                        .font(.title3)
                    Text(project.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if isCompleted(project) {
                        Label(L10n.t(.projectCompletedBadge, language), systemImage: "checkmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.green)
                            .help(L10n.t(.projectCompletedBadge, language))
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if hoveredProjectID == project.id {
                Button {
                    pendingDelete = project
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(L10n.t(.deleteProjectHelp, language))
            }
        }
        .padding(.vertical, 6)
        .onHover { isHovering in
            hoveredProjectID = isHovering ? project.id : nil
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                pendingDelete = project
            } label: {
                Label(L10n.t(.trashAction, language), systemImage: "trash")
            }
        }
    }
}
