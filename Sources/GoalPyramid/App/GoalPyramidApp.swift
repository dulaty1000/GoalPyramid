import SwiftUI
import SwiftData

@main
struct GoalPyramidApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([GoalItem.self])
        // isStoredInMemoryOnly: false → деректер тек осы Mac-та, жергілікті дискіде сақталады.
        // cloudKitDatabase: .none → ешбір желілік синхронизация жоқ, толық offline.
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData контейнерін жасау сәтсіз аяқталды: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            DashboardView()
                .frame(minWidth: 900, minHeight: 620)
        }
        .modelContainer(container)

        MenuBarExtra {
            MenuBarTodayView()
                .modelContainer(container)
        } label: {
            Image(systemName: "checkmark.seal.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
