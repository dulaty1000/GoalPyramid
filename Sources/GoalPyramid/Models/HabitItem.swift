import Foundation
import SwiftData

/// "Дағдылар" бөліміндегі бір дағды — атауы, еркін сипаттамасы және
/// жиілігі сақталады. Дағды жасалған сәттен бастап 1 айлық "циклге"
/// сай "Бүгін" тапсырмалары автоматты жасалады (`HabitStore`-ды
/// қараңыз); 1 ай толғанда пайдаланушыдан жалғастыру сұралады —
/// келіссе, келесі 2 айға цикл ұзартылады, келіспесе `isActive` false
/// болып, тоқтайды (бірақ дағдының өзі, әрі бұрын жасалған тапсырмалар,
/// сақталып қалады).
@Model
final class HabitItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isDeleted: Bool = false
    var deletedAt: Date?
    var frequencyRaw: String = HabitFrequency.daily.rawValue
    /// Тек `.specificDays` жиілігінде мағыналы — 0=Дүйсенбі...6=Жексенбі
    /// (жетістіктер картасындағы апта индекстеуімен бірдей келісім).
    var selectedWeekdays: [Int] = []
    /// `false` болса — пайдаланушы "Жоқ" деп жауап берген, "Бүгін"
    /// бетіне енді жаңа тапсырма жасалмайды.
    var isActive: Bool = true
    /// Ағымдағы циклдің басы мен соңы — осы аралыққа "Бүгін" тапсырмалары
    /// қазірдің өзінде жасалып қойылған.
    var cycleStartDate: Date = Date()
    var cycleEndDate: Date = Date()
    /// Пайдаланушы қолмен Қоқысқа тастаған даналардың күндері
    /// (`periodStart`). Тиісті `GoalItem` жазбасы Қоқыстан ТҮПКІЛІКТІ
    /// өшірілсе де, осы тізім сол күнді ЕШҚАШАН қайта автоматты
    /// жаратпау үшін тұрақты сақталады — тек "Қалпына келтіру" ғана
    /// емес, мүлдем түпкілікті өшіруден кейін де кестелеу логикасы бұл
    /// күнді елеусіз қалдырады.
    var excludedDates: [Date] = []
    /// SwiftData ФРЕЙМВОРК ДЕҢГЕЙІНДЕГІ кепілдік: осы дағды `context.delete(_:)`
    /// арқылы ТҮПКІЛІКТІ өшірілсе (мыс. Қоқыстан "Жою" немесе "Барлығын
    /// өшіру"), SwiftData АВТОМАТТЫ түрде осы тізімдегі барлық `GoalItem`
    /// жазбаларын да бірге өшіреді — қай код жолы арқылы өшірілсе де
    /// (тіпті болашақта жазылатын, әлі жоқ жол арқылы да), "жетім"
    /// тапсырма қалып қоюы енді МҮМКІН ЕМЕС. Күнделікті "Қоқысқа тастау"
    /// (soft-delete, `isDeleted = true`) кезінде бұл ереже іске қосылмайды
    /// — ол тек НАҚТЫ жою (`context.delete`) кезінде жұмыс істейді.
    @Relationship(deleteRule: .cascade, inverse: \GoalItem.habit)
    var tasks: [GoalItem] = []

    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    init(title: String = "", notes: String = "", frequency: HabitFrequency = .daily, selectedWeekdays: [Int] = []) {
        let now = Date()
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.createdAt = now
        self.updatedAt = now
        self.isDeleted = false
        self.deletedAt = nil
        self.frequencyRaw = frequency.rawValue
        self.selectedWeekdays = selectedWeekdays
        self.isActive = true
        let startOfToday = Calendar.current.startOfDay(for: now)
        self.cycleStartDate = startOfToday
        self.cycleEndDate = Calendar.current.date(byAdding: .month, value: 1, to: startOfToday) ?? startOfToday
    }
}
