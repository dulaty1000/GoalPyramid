import Foundation

/// `ProjectItem` үшін soft-delete логикасы — `GoalStore`/`NoteStore`-мен
/// бірдей үлгі. Жобаны қоқысқа тастағанда/қалпына келтіргенде оған тиесілі
/// тапсырмалар (`tasks`) да бірге өзгереді, сол арқылы "Бүгін" тізімінен де
/// жоғалады/қайта пайда болады.
enum ProjectStore {
    static func moveToTrash(_ project: ProjectItem, tasks: [GoalItem] = []) {
        project.isDeleted = true
        project.deletedAt = Date()
        for task in tasks {
            GoalStore.moveToTrash(task)
        }
    }

    static func restore(_ project: ProjectItem, tasks: [GoalItem] = []) {
        project.isDeleted = false
        project.deletedAt = nil
        for task in tasks {
            GoalStore.restore(task)
        }
    }
}
