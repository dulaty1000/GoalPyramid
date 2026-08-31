import Foundation
import SwiftData

/// JSON-ға экспортталатын, `GoalItem`-нен тәуелсіз тұрақты деректер
/// пішіні — SwiftData моделінің ішкі құрылымы өзгерсе де, ескі backup
/// файлдары оқылатындай.
struct ExportedGoal: Codable {
    var id: UUID
    var title: String
    var notes: String
    var levelRaw: Int
    var isCompleted: Bool
    var evaluationRaw: String
    var sortOrder: Int
    var periodStart: Date
    var createdAt: Date
    var completedAt: Date?
    var parentID: UUID?
    var isDeleted: Bool
    var deletedAt: Date?
    var projectID: UUID?
    var hasDueDate: Bool
    var eisenhowerQuadrantRaw: String?
    var habitID: UUID?

    init(_ model: GoalItem) {
        id = model.id
        title = model.title
        notes = model.notes
        levelRaw = model.levelRaw
        isCompleted = model.isCompleted
        evaluationRaw = model.evaluationRaw
        sortOrder = model.sortOrder
        periodStart = model.periodStart
        createdAt = model.createdAt
        completedAt = model.completedAt
        parentID = model.parentID
        isDeleted = model.isDeleted
        deletedAt = model.deletedAt
        projectID = model.projectID
        hasDueDate = model.hasDueDate
        eisenhowerQuadrantRaw = model.eisenhowerQuadrantRaw
        habitID = model.habitID
    }

    /// Дағдылар (демек `habitID`) қосылмастан бұрын жасалған backup
    /// файлдарында бұл өріс болмайды — сол жағдайда `nil` қабылданады.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decode(String.self, forKey: .notes)
        levelRaw = try container.decode(Int.self, forKey: .levelRaw)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        evaluationRaw = try container.decode(String.self, forKey: .evaluationRaw)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        periodStart = try container.decode(Date.self, forKey: .periodStart)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        parentID = try container.decodeIfPresent(UUID.self, forKey: .parentID)
        isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        projectID = try container.decodeIfPresent(UUID.self, forKey: .projectID)
        hasDueDate = try container.decode(Bool.self, forKey: .hasDueDate)
        eisenhowerQuadrantRaw = try container.decodeIfPresent(String.self, forKey: .eisenhowerQuadrantRaw)
        habitID = try container.decodeIfPresent(UUID.self, forKey: .habitID)
    }

    func makeModel() -> GoalItem {
        let item = GoalItem(
            title: title,
            level: GoalLevel(rawValue: levelRaw) ?? .daily,
            periodStart: periodStart
        )
        item.id = id
        item.notes = notes
        item.isCompleted = isCompleted
        item.evaluationRaw = evaluationRaw
        item.sortOrder = sortOrder
        item.createdAt = createdAt
        item.completedAt = completedAt
        item.parentID = parentID
        item.isDeleted = isDeleted
        item.deletedAt = deletedAt
        item.projectID = projectID
        item.hasDueDate = hasDueDate
        item.eisenhowerQuadrantRaw = eisenhowerQuadrantRaw
        item.habitID = habitID
        return item
    }
}

struct ExportedProject: Codable {
    var id: UUID
    var title: String
    var createdAt: Date
    var sortOrder: Int
    var isDeleted: Bool
    var deletedAt: Date?
    var timeframeRaw: String

    init(_ model: ProjectItem) {
        id = model.id
        title = model.title
        createdAt = model.createdAt
        sortOrder = model.sortOrder
        isDeleted = model.isDeleted
        deletedAt = model.deletedAt
        timeframeRaw = model.timeframeRaw
    }

    func makeModel() -> ProjectItem {
        let item = ProjectItem(
            title: title,
            sortOrder: sortOrder,
            timeframe: ProjectTimeframe(rawValue: timeframeRaw) ?? .other
        )
        item.id = id
        item.createdAt = createdAt
        item.isDeleted = isDeleted
        item.deletedAt = deletedAt
        return item
    }
}

struct ExportedNote: Codable {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    var deletedAt: Date?

    init(_ model: NoteItem) {
        id = model.id
        title = model.title
        content = model.content
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        isDeleted = model.isDeleted
        deletedAt = model.deletedAt
    }

    func makeModel() -> NoteItem {
        let item = NoteItem(title: title, content: content)
        item.id = id
        item.createdAt = createdAt
        item.updatedAt = updatedAt
        item.isDeleted = isDeleted
        item.deletedAt = deletedAt
        return item
    }
}

struct ExportedHabit: Codable {
    var id: UUID
    var title: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    var deletedAt: Date?
    var frequencyRaw: String
    var selectedWeekdays: [Int]
    var isActive: Bool
    var cycleStartDate: Date
    var cycleEndDate: Date
    var excludedDates: [Date]

    init(_ model: HabitItem) {
        id = model.id
        title = model.title
        notes = model.notes
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        isDeleted = model.isTrashed
        deletedAt = model.deletedAt
        frequencyRaw = model.frequencyRaw
        selectedWeekdays = model.selectedWeekdays
        isActive = model.isActive
        cycleStartDate = model.cycleStartDate
        cycleEndDate = model.cycleEndDate
        excludedDates = model.excludedDates
    }

    /// Жиілік/цикл өрістері қосылмастан бұрын жасалған backup
    /// файлдарында олар болмайды — сол жағдайда "Күнделікті"/бос
    /// тізім/белсенді/дағды жасалған күннен бастап 1 айлық цикл
    /// қабылданады.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decode(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        frequencyRaw = try container.decodeIfPresent(String.self, forKey: .frequencyRaw) ?? HabitFrequency.daily.rawValue
        selectedWeekdays = try container.decodeIfPresent([Int].self, forKey: .selectedWeekdays) ?? []
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        let fallbackStart = Calendar.current.startOfDay(for: createdAt)
        let fallbackEnd = Calendar.current.date(byAdding: .month, value: 1, to: fallbackStart) ?? fallbackStart
        cycleStartDate = try container.decodeIfPresent(Date.self, forKey: .cycleStartDate) ?? fallbackStart
        cycleEndDate = try container.decodeIfPresent(Date.self, forKey: .cycleEndDate) ?? fallbackEnd
        excludedDates = try container.decodeIfPresent([Date].self, forKey: .excludedDates) ?? []
    }

    func makeModel() -> HabitItem {
        let item = HabitItem(title: title, notes: notes, frequency: HabitFrequency(rawValue: frequencyRaw) ?? .daily, selectedWeekdays: selectedWeekdays)
        item.id = id
        item.createdAt = createdAt
        item.updatedAt = updatedAt
        item.isTrashed = isDeleted
        item.deletedAt = deletedAt
        item.isActive = isActive
        item.excludedDates = excludedDates
        item.cycleStartDate = cycleStartDate
        item.cycleEndDate = cycleEndDate
        return item
    }
}

/// Бір JSON файлындағы толық backup — Бүгін/Апта/Ай/Жыл/5 Жыл
/// мақсаттары (`GoalItem`), Жобалар (`ProjectItem`), Идея парақтары
/// (`NoteItem`) және Дағдылар (`HabitItem`), қоқысқа тасталғандарын да қоса.
struct AppDataExport: Codable {
    var formatVersion: Int
    var exportedAt: Date
    var goals: [ExportedGoal]
    var projects: [ExportedProject]
    var notes: [ExportedNote]
    var habits: [ExportedHabit]

    init(formatVersion: Int, exportedAt: Date, goals: [ExportedGoal], projects: [ExportedProject], notes: [ExportedNote], habits: [ExportedHabit]) {
        self.formatVersion = formatVersion
        self.exportedAt = exportedAt
        self.goals = goals
        self.projects = projects
        self.notes = notes
        self.habits = habits
    }

    /// Ескі (Дағдылар қосылмастан бұрын жасалған) backup файлдарында
    /// "habits" кілті болмайды — сол жағдайда бос тізім қабылданады,
    /// импорт қатесіз жалғаса береді.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        formatVersion = try container.decode(Int.self, forKey: .formatVersion)
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        goals = try container.decode([ExportedGoal].self, forKey: .goals)
        projects = try container.decode([ExportedProject].self, forKey: .projects)
        notes = try container.decode([ExportedNote].self, forKey: .notes)
        habits = try container.decodeIfPresent([ExportedHabit].self, forKey: .habits) ?? []
    }
}

/// "Настройка" бетіндегі "Деректер" тобының іс жүзіндегі логикасы:
/// JSON-ға экспорттау, JSON-нан қалпына келтіру (қазіргі деректерді
/// толықтай ауыстырады) және барлық деректерді нөлдеу.
enum DataBackupManager {
    private static let currentFormatVersion = 1

    static func exportData(context: ModelContext) throws -> Data {
        let goals = try context.fetch(FetchDescriptor<GoalItem>())
        let projects = try context.fetch(FetchDescriptor<ProjectItem>())
        let notes = try context.fetch(FetchDescriptor<NoteItem>())
        let habits = try context.fetch(FetchDescriptor<HabitItem>())

        let export = AppDataExport(
            formatVersion: currentFormatVersion,
            exportedAt: Date(),
            goals: goals.map(ExportedGoal.init),
            projects: projects.map(ExportedProject.init),
            notes: notes.map(ExportedNote.init),
            habits: habits.map(ExportedHabit.init)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    /// Қазіргі деректерді толықтай ӨШІРІП, файлдағы деректермен ауыстырады.
    static func importData(from data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(AppDataExport.self, from: data)

        try deleteAll(context: context)

        for dto in export.projects {
            context.insert(dto.makeModel())
        }
        for dto in export.notes {
            context.insert(dto.makeModel())
        }
        for dto in export.habits {
            context.insert(dto.makeModel())
        }
        for dto in export.goals {
            context.insert(dto.makeModel())
        }

        try context.save()
    }

    static func resetAllData(context: ModelContext) throws {
        try deleteAll(context: context)
        try context.save()
    }

    private static func deleteAll(context: ModelContext) throws {
        for goal in try context.fetch(FetchDescriptor<GoalItem>()) {
            context.delete(goal)
        }
        for project in try context.fetch(FetchDescriptor<ProjectItem>()) {
            context.delete(project)
        }
        for note in try context.fetch(FetchDescriptor<NoteItem>()) {
            context.delete(note)
        }
        for habit in try context.fetch(FetchDescriptor<HabitItem>()) {
            context.delete(habit)
        }
        // Тіркемелердің физикалық файлдары да өшірілуі керек, әйтпесе
        // жазба жойылғаннан кейін дискіде иесіз (orphan) қалып қояды.
        for attachment in try context.fetch(FetchDescriptor<NoteAttachment>()) {
            AttachmentStore.delete(storedFileName: attachment.storedFileName)
            context.delete(attachment)
        }
    }
}
