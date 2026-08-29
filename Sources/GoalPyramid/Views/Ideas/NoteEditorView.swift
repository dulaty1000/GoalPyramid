import SwiftUI
import SwiftData

/// Бір идея парағын еркін өңдеу беті: тақырып + шексіз мәтін өрісі.
/// `@Bindable` арқылы өзгерістер SwiftData контекстіне тікелей жазылады —
/// автосақтау контейнер деңгейінде қосулы болғандықтан, бөлек "Сақтау"
/// батырмасы қажет емес.
struct NoteEditorView: View {
    @Bindable var note: NoteItem
    var onBack: () -> Void

    /// Терезе түбірінен келеді — тіл ауысқанда осы бет дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField(L10n.t(.noteTitlePlaceholder, language), text: $note.title)
                .textFieldStyle(.plain)
                .font(.title.bold())
                .onChange(of: note.title) { _, _ in note.updatedAt = Date() }

            Picker(L10n.t(.ideaTimeframeLabel, language), selection: $note.timeframe) {
                ForEach(ProjectTimeframe.allCases) { option in
                    Text(option.label(language)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)
            .onChange(of: note.timeframe) { _, _ in note.updatedAt = Date() }

            Divider()

            TextEditor(text: $note.content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .onChange(of: note.content) { _, _ in note.updatedAt = Date() }

            AttachmentsView(noteID: note.id)
        }
        .padding(20)
        .navigationTitle(note.title.isEmpty ? L10n.t(.untitledNote, language) : note.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .help(L10n.t(.backToNotesHelp, language))
            }
        }
    }
}
