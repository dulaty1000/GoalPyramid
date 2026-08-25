import Foundation

/// `NoteItem` үшін soft-delete логикасы — `GoalStore`-мен бірдей үлгі.
enum NoteStore {
    static func moveToTrash(_ note: NoteItem) {
        note.isDeleted = true
        note.deletedAt = Date()
    }

    static func restore(_ note: NoteItem) {
        note.isDeleted = false
        note.deletedAt = nil
    }
}
