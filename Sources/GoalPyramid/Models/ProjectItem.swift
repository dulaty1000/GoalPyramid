import Foundation
import SwiftData

/// "Жобалар" бөліміндегі пайдаланушы жасаған жоба. Атауын өзі береді;
/// ішіндегі тапсырмалар — `GoalItem.projectID` арқылы осы жобаға
/// байланысқан күндік мақсаттар.
@Model
final class ProjectItem {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    var isDeleted: Bool = false
    var deletedAt: Date?
    /// Топтастыру үшін мерзім санаты. Ескі жазбаларда бұл өріс болмағандықтан
    /// әдепкі мәні `.other` — олар "Басқа жобалар" тобында көрінеді.
    var timeframeRaw: String = ProjectTimeframe.other.rawValue

    var timeframe: ProjectTimeframe {
        get { ProjectTimeframe(rawValue: timeframeRaw) ?? .other }
        set { timeframeRaw = newValue.rawValue }
    }

    init(title: String, sortOrder: Int = 0, timeframe: ProjectTimeframe = .other) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.isDeleted = false
        self.deletedAt = nil
        self.timeframeRaw = timeframe.rawValue
    }
}
