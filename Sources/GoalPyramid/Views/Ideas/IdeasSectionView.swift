import SwiftUI

/// "Идеялар" бөлімінің иесі: тізім ↔ редактор арасында push-сыз ауысады
/// (қалғанындай — `selectedNote` арқылы, NavigationLink push жоқ).
struct IdeasSectionView: View {
    @State private var selectedNote: NoteItem?

    var body: some View {
        NavigationStack {
            if let note = selectedNote {
                NoteEditorView(note: note, onBack: { selectedNote = nil })
            } else {
                IdeasListView(onSelect: { note in selectedNote = note })
            }
        }
    }
}
