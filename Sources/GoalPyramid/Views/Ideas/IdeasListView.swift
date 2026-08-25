import SwiftUI
import SwiftData
import Foundation

/// Идея парақтарының тізімі: жаңа парақ қосу, барын ашу, керексізін
/// қоқысқа тастау.
struct IdeasListView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<NoteItem> { !$0.isDeleted },
        sort: \NoteItem.updatedAt,
        order: .reverse
    ) private var notes: [NoteItem]

    var onSelect: (NoteItem) -> Void

    var body: some View {
        List {
            Section {
                Button {
                    let note = NoteItem(title: "Атаусыз парақ")
                    context.insert(note)
                    onSelect(note)
                } label: {
                    Label("Жаңа парақ қосу", systemImage: "plus.circle.fill")
                }
            }

            Section {
                if notes.isEmpty {
                    Text("Әзірге парақ жоқ")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(notes) { note in
                        Button {
                            onSelect(note)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.title.isEmpty ? "Атаусыз парақ" : note.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(note.content.isEmpty ? "Бос парақ" : note.content)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                NoteStore.moveToTrash(note)
                            } label: {
                                Label("Қоқысқа тастау", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Идеялар")
    }
}
