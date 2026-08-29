import Foundation
import SwiftData

/// "Идеялар" бөліміндегі еркін мәтіндік парақ — мақсат пирамидасына
/// қатысы жоқ, тек тақырып пен ерікті мәтін сақтайды.
@Model
final class NoteItem {
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isDeleted: Bool = false
    var deletedAt: Date?
    /// "Идеялар" тізімінде топтастыру үшін — міндетті емес кезең.
    /// Ескі жазбаларда бұл өріс болмағандықтан әдепкі мәні `.other`.
    var timeframeRaw: String = ProjectTimeframe.other.rawValue

    var timeframe: ProjectTimeframe {
        get { ProjectTimeframe(rawValue: timeframeRaw) ?? .other }
        set { timeframeRaw = newValue.rawValue }
    }

    init(title: String = "", content: String = "", timeframe: ProjectTimeframe = .other) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isDeleted = false
        self.deletedAt = nil
        self.timeframeRaw = timeframe.rawValue
    }
}
