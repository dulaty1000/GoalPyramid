import SwiftUI
import SwiftData

@main
struct GoalPyramidApp: App {
    let container: ModelContainer

    /// "Настройка" бетіндегі "Тақырып"/"Негізгі акцент түсі" баптаулары.
    /// Осы екеуі терезенің ТҮБІРІНДЕ қолданылады, сондықтан пайдаланушы
    /// баптауды өзгерткен сәтте бүкіл терезе (сайдбар, ағымдағы бет) бетті
    /// қайта ашпай-ақ дереу жаңа түспен/режиммен қайта салынады.
    @AppStorage(AppSettingsKey.colorScheme) private var colorSchemeRaw = AppColorScheme.system.rawValue
    @AppStorage(AppSettingsKey.accentColor) private var accentColorRaw = AccentColorOption.blue.rawValue
    /// "Интерфейс тілі" — дәл осы екеуімен бірдей себеппен ТҮБІРДЕ оқылып,
    /// environment арқылы таралады: сыбайлас View-лар арасындағы
    /// `@AppStorage` реактивтілігі (мыс. "Настройка" → сайдбар) сенімсіз
    /// болатыны анықталды, ал терезе-түбірінен environment-модификатормен
    /// тарату әрдайым дереу, кепілді жұмыс істейді.
    @AppStorage(AppSettingsKey.language) private var languageRaw = AppLanguage.kk.rawValue

    private var preferredColorScheme: ColorScheme? {
        (AppColorScheme(rawValue: colorSchemeRaw) ?? .system).colorScheme
    }

    private var accentColor: Color {
        (AccentColorOption(rawValue: accentColorRaw) ?? .blue).color
    }

    private var currentLanguage: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .kk
    }

    init() {
        let schema = Schema([GoalItem.self, NoteItem.self, ProjectItem.self, NoteAttachment.self, HabitItem.self])
        // isStoredInMemoryOnly: false → деректер тек осы Mac-та, жергілікті дискіде сақталады.
        // cloudKitDatabase: .none → ешбір желілік синхронизация жоқ, толық offline.
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData контейнерін жасау сәтсіз аяқталды: \(error)")
        }
        GoalStore.reconcileLegacyCompletionState(in: container.mainContext)
        HabitStore.reconcileDuplicateHabitTasks(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            DashboardView()
                .frame(minWidth: 900, minHeight: 620)
                .tint(accentColor)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.appLanguage, currentLanguage)
        }
        .modelContainer(container)

        MenuBarExtra {
            MenuBarTodayView()
                .modelContainer(container)
                .tint(accentColor)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.appLanguage, currentLanguage)
        } label: {
            Image(systemName: "checkmark.seal.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
