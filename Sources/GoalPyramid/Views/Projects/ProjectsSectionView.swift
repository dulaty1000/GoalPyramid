import SwiftUI
import SwiftData

/// "Жобалар" бөлімінің иесі: тізім ↔ жоба ішкі беті арасында push-сыз
/// ауысады ("Идеялар"-мен бірдей үлгі). Жаңа жоба sheet-і осында ілінеді
/// (тізім бетінде емес), сол себепті жоба құрылғаннан кейін оның ішіне
/// ауысу кезінде sheet-тің өз бетінен айырылып қалуы (detach) болмайды.
struct ProjectsSectionView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<ProjectItem> { !$0.isDeleted },
        sort: \ProjectItem.createdAt,
        order: .reverse
    ) private var projects: [ProjectItem]
    @Query private var allGoals: [GoalItem]

    @State private var selectedProject: ProjectItem?
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            if let project = selectedProject {
                ProjectDetailView(project: project, onBack: { selectedProject = nil })
            } else {
                ProjectsListView(
                    projects: projects,
                    allGoals: allGoals,
                    onSelect: { selectedProject = $0 },
                    onAdd: { showingAdd = true },
                    onDelete: { project in
                        let tasks = allGoals.filter { $0.projectID == project.id }
                        ProjectStore.moveToTrash(project, tasks: tasks)
                    }
                )
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddProjectSheet(onCreate: { project in
                selectedProject = project
            })
        }
    }
}
