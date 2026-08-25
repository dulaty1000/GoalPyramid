import SwiftUI
import SwiftData

/// Бір идея парағын еркін өңдеу беті: тақырып + шексіз мәтін өрісі.
/// `@Bindable` арқылы өзгерістер SwiftData контекстіне тікелей жазылады —
/// автосақтау контейнер деңгейінде қосулы болғандықтан, бөлек "Сақтау"
/// батырмасы қажет емес.
struct NoteEditorView: View {
    @Bindable var note: NoteItem
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Тақырып", text: $note.title)
                .textFieldStyle(.plain)
                .font(.title.bold())
                .onChange(of: note.title) { _, _ in note.updatedAt = Date() }

            Divider()

            TextEditor(text: $note.content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .onChange(of: note.content) { _, _ in note.updatedAt = Date() }
        }
        .padding(20)
        .navigationTitle(note.title.isEmpty ? "Атаусыз парақ" : note.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .help("Парақтар тізіміне қайту")
            }
        }
    }
}
