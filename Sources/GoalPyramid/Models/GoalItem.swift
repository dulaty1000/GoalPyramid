import Foundation
import SwiftData

/// Пирамидадағы кез келген деңгейдегі бір мақсат/тапсырма.
/// `levelRaw` арқылы деңгейі, `periodStart` арқылы қай кезеңге (күн/апта/ай/жыл/5 жыл) тиесілі екені анықталады.
@Model
final class GoalItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var levelRaw: Int = GoalLevel.daily.rawValue
    var isCompleted: Bool = false
    var evaluationRaw: String = EvaluationColor.none.rawValue
    var sortOrder: Int = 0
    var periodStart: Date = Date()
    var createdAt: Date = Date()
    var completedAt: Date?
    var parentID: UUID?
    var isDeleted: Bool = false
    var deletedAt: Date?
    /// Бұл тапсырма "Жобалар" бөліміндегі қай жобаға тиесілі екенін білдіреді
    /// (nil болса — жобаға қатысы жоқ, әдеттегі пирамида мақсаты).
    var projectID: UUID?
    /// `false` болса — `periodStart` мәні мәнсіз орынбасар ғана: тапсырманың
    /// нақты күні жоқ, сондықтан ешбір күндік ("Бүгін") тізімінде,
    /// аналитикада не жетістіктер картасында есептелмейді. Тек "Жобалар"
    /// ішінде, күнсіз тапсырма ретінде көрінеді.
    var hasDueDate: Bool = true
    /// "Бүгін" тізімінің астындағы Эйзенхауэр матрицасында пайдаланушы
    /// қолмен қойған квадрат. `nil` болса — матрицаға әлі қойылмаған,
    /// негізгі тізімде көрінеді. Автоматты категорияландыру жоқ.
    var eisenhowerQuadrantRaw: String?
    /// Бұл тапсырма "Дағдылар" бөліміндегі қай дағдыдан автоматты түрде
    /// жасалғанын білдіреді (nil болса — қолмен жасалған, қалыпты
    /// мақсат/тапсырма). Дағды тапсырмалары "Бүгін" тізімінде көрінгенмен,
    /// Аналитика бөлімінің БАРЛЫҚ есептеулерінен (heatmap, деңгей бойынша
    /// пайыз, т.б.) толығымен тыс қалдырылады.
    var habitID: UUID?

    var level: GoalLevel {
        get { GoalLevel(rawValue: levelRaw) ?? .daily }
        set { levelRaw = newValue.rawValue }
    }

    var eisenhowerQuadrant: EisenhowerQuadrant? {
        get { eisenhowerQuadrantRaw.flatMap { EisenhowerQuadrant(rawValue: $0) } }
        set { eisenhowerQuadrantRaw = newValue?.rawValue }
    }

    /// Бағалау түсі енді "орындалды/орындалмады" күйін де тікелей
    /// анықтайды: `.none` (сұр) — орындалмаған, қалған 3 түстің
    /// қайсысы да — орындалған. `isCompleted`/`completedAt` осы setter
    /// арқылы ӘРҚАШАН автоматты синхрондалып отырады, сондықтан бөлек
    /// "Орындалды" checkbox қажет емес.
    var evaluation: EvaluationColor {
        get { EvaluationColor(rawValue: evaluationRaw) ?? .none }
        set {
            evaluationRaw = newValue.rawValue
            let nowCompleted = newValue != .none
            if nowCompleted != isCompleted {
                completedAt = nowCompleted ? Date() : nil
            }
            isCompleted = nowCompleted
        }
    }

    init(
        title: String,
        level: GoalLevel,
        periodStart: Date,
        notes: String = "",
        parentID: UUID? = nil,
        sortOrder: Int = 0,
        projectID: UUID? = nil,
        hasDueDate: Bool = true,
        habitID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.levelRaw = level.rawValue
        self.isCompleted = false
        self.evaluationRaw = EvaluationColor.none.rawValue
        self.sortOrder = sortOrder
        self.periodStart = periodStart
        self.createdAt = Date()
        self.completedAt = nil
        self.parentID = parentID
        self.isDeleted = false
        self.deletedAt = nil
        self.projectID = projectID
        self.hasDueDate = hasDueDate
        self.habitID = habitID
    }
}

extension Sequence where Element == GoalItem {
    /// Қоқысқа тасталмаған (`isDeleted == false`) жазбалар ғана —
    /// Күн/Апта/Ай/Жыл/5 Жыл, Жобалар, MenuBar сияқты БАРЛЫҚ негізгі
    /// тізім беттері дәл осы БІР ОРТАҚ анықтаманы қолдануы керек, әр
    /// бет өз алдына `!$0.isDeleted` деп қайта жазбауы үшін (сол
    /// арқылы беттер арасында сүзгі ауытқымайды). `@Query(filter:)`
    /// деңгейінде (мыс. `AnalyticsView`, `TimelineView`) SwiftData-ның
    /// `#Predicate` макросы шетелдік функцияны шақыра алмайтындықтан,
    /// сол жерлерде `!$0.isDeleted` тікелей жазылады — бірақ МАҒЫНАСЫ
    /// дәл осымен бірдей.
    func excludingTrashed() -> [GoalItem] {
        filter { !$0.isDeleted }
    }
}
