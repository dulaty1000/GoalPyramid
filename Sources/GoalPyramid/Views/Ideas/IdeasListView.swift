import SwiftUI
import SwiftData
import Foundation

/// Идея парақтарының тізімі: жаңа парақ қосу, барын ашу, керексізін
/// қоқысқа тастау.
///
/// Идеяны өшірудің үш тәсілі бар: жол үстіне тінтуірді апарғанда
/// шығатын "қоқыс" таңбашасы, оң жақ батырмамен контекст мәзірі,
/// солға сипау (swipe). Оған қоса, беттің жоғарғы жағындағы "Таңдау"
/// батырмасы арқылы бірнеше идеяны бірден таңдап, топтап өшіруге де
/// болады. Барлығы да `NoteStore.moveToTrash` арқылы **жұмсақ өшіру**
/// ("Қоқыс" бөліміне жіберу) — түпкілікті жою тек `TrashView`-де ғана.
struct IdeasListView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<NoteItem> { !$0.isDeleted },
        sort: \NoteItem.updatedAt,
        order: .reverse
    ) private var notes: [NoteItem]

    var onSelect: (NoteItem) -> Void

    /// Терезе түбірінен келеді — тіл ауысқанда осы бет дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    @State private var hoveredNoteID: UUID?
    @State private var isSelecting = false
    @State private var selectedNoteIDs: Set<UUID> = []

    /// Санат бойынша топтар — "Жобалар" бетімен бірдей тұрақты рет:
    /// апталық → айлық → жылдық → басқа. Бос топ көрсетілмейді.
    private var groupedNotes: [(timeframe: ProjectTimeframe, notes: [NoteItem])] {
        ProjectTimeframe.allCases.compactMap { timeframe in
            let items = notes.filter { $0.timeframe == timeframe }
            return items.isEmpty ? nil : (timeframe, items)
        }
    }

    var body: some View {
        List {
            if !isSelecting {
                Section {
                    Button {
                        let note = NoteItem(title: L10n.t(.untitledNote, language))
                        context.insert(note)
                        onSelect(note)
                    } label: {
                        Label(L10n.t(.addNoteAction, language), systemImage: "plus.circle.fill")
                    }
                }
            }

            if notes.isEmpty {
                Section {
                    Text(L10n.t(.noNotesYet, language))
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedNotes, id: \.timeframe) { group in
                    Section(L10n.ideaGroupTitle(group.timeframe, language)) {
                        ForEach(group.notes) { note in
                            noteRow(note)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(L10n.t(.sidebarIdeas, language))
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if isSelecting {
                    if !selectedNoteIDs.isEmpty {
                        Button(role: .destructive) {
                            deleteSelected()
                        } label: {
                            Label(L10n.deleteSelectedLabel(count: selectedNoteIDs.count, language), systemImage: "trash")
                        }
                    }
                    Button(L10n.t(.settingsCancel, language)) {
                        isSelecting = false
                        selectedNoteIDs.removeAll()
                    }
                } else if !notes.isEmpty {
                    Button(L10n.t(.selectNotesAction, language)) {
                        isSelecting = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func noteRow(_ note: NoteItem) -> some View {
        HStack(spacing: 10) {
            if isSelecting {
                Button {
                    toggleSelection(note)
                } label: {
                    Image(systemName: selectedNoteIDs.contains(note.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selectedNoteIDs.contains(note.id) ? Theme.accent : .secondary)
                }
                .buttonStyle(.plain)
            }

            Button {
                if isSelecting {
                    toggleSelection(note)
                } else {
                    onSelect(note)
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title.isEmpty ? L10n.t(.untitledNote, language) : note.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(note.content.isEmpty ? L10n.t(.emptyNoteContent, language) : note.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isSelecting && hoveredNoteID == note.id {
                Button {
                    NoteStore.moveToTrash(note)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(L10n.t(.deleteNoteHelp, language))
            }
        }
        .onHover { isHovering in
            hoveredNoteID = isHovering ? note.id : nil
        }
        .contextMenu {
            Button(role: .destructive) {
                NoteStore.moveToTrash(note)
            } label: {
                Label(L10n.t(.trashAction, language), systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                NoteStore.moveToTrash(note)
            } label: {
                Label(L10n.t(.trashAction, language), systemImage: "trash")
            }
        }
    }

    private func toggleSelection(_ note: NoteItem) {
        if selectedNoteIDs.contains(note.id) {
            selectedNoteIDs.remove(note.id)
        } else {
            selectedNoteIDs.insert(note.id)
        }
    }

    private func deleteSelected() {
        for note in notes where selectedNoteIDs.contains(note.id) {
            NoteStore.moveToTrash(note)
        }
        selectedNoteIDs.removeAll()
        isSelecting = false
    }
}
