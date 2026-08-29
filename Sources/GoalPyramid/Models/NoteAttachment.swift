import Foundation
import SwiftData

/// "Идеялар" бөліміндегі бір парақа тіркелген файл/сурет. Іс жүзіндегі
/// файл дискіде (`AttachmentStore.directory`) сақталады — мұнда тек
/// сілтеме (`storedFileName`) мен кіші thumbnail сақталады, үлкен
/// файлдарды SwiftData Binary Data ретінде тікелей сақтамау үшін.
/// `noteID` — қосымшадағы қалыптасқан үлгі бойынша (`GoalItem.projectID`
/// сияқты) бос UUID байланысы, `@Relationship` емес.
@Model
final class NoteAttachment {
    var id: UUID = UUID()
    var noteID: UUID = UUID()
    var originalFileName: String = ""
    var storedFileName: String = ""
    var isImage: Bool = false
    /// Тек суреттер үшін — тізімде тез көрсету үшін кіші JPEG thumbnail.
    var thumbnailData: Data?
    var createdAt: Date = Date()

    init(
        noteID: UUID,
        originalFileName: String,
        storedFileName: String,
        isImage: Bool,
        thumbnailData: Data? = nil
    ) {
        self.id = UUID()
        self.noteID = noteID
        self.originalFileName = originalFileName
        self.storedFileName = storedFileName
        self.isImage = isImage
        self.thumbnailData = thumbnailData
        self.createdAt = Date()
    }
}
