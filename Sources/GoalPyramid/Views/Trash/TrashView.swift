import SwiftUI
import SwiftData
import Foundation

/// Қоқысқа тасталған мақсаттар МЕН идея парақтары: қалпына келтіру немесе
/// түбегейлі жою.
struct TrashView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<GoalItem> { $0.isDeleted },
        sort: \GoalItem.deletedAt,
        order: .reverse
    ) private var trashedGoals: [GoalItem]
    @Query(
        filter: #Predicate<NoteItem> { $0.isDeleted },
        sort: \NoteItem.deletedAt,
        order: .reverse
    ) private var trashedNotes: [NoteItem]

    @State private var showingConfirmClear = false

    private var isEmpty: Bool { trashedGoals.isEmpty && trashedNotes.isEmpty }

    var body: some View {
        List {
            if !isEmpty {
                Section {
                    Button(role: .destructive) {
                        showingConfirmClear = true
                    } label: {
                        Label("Барлығын өшіру", systemImage: "trash.slash.fill")
                    }
                }
            }

            if isEmpty {
                Section {
                    Text("Қоқыс бос")
                        .foregroundStyle(.secondary)
                }
            } else {
                if !trashedGoals.isEmpty {
                    Section("Мақсаттар") {
                        ForEach(trashedGoals) { goal in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(goal.title)
                                        .strikethrough()
                                    Text("\(goal.level.title) · \(PeriodHelper.displayRange(for: goal.level, periodStart: goal.periodStart))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    GoalStore.restore(goal)
                                } label: {
                                    Label("Қалпына келтіру", systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(.bordered)

                                Button(role: .destructive) {
                                    context.delete(goal)
                                } label: {
                                    Label("Жою", systemImage: "xmark.circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !trashedNotes.isEmpty {
                    Section("Идея парақтары") {
                        ForEach(trashedNotes) { note in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(note.title.isEmpty ? "Атаусыз парақ" : note.title)
                                        .strikethrough()
                                    Text(note.content.isEmpty ? "Бос парақ" : note.content)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button {
                                    NoteStore.restore(note)
                                } label: {
                                    Label("Қалпына келтіру", systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(.bordered)

                                Button(role: .destructive) {
                                    context.delete(note)
                                } label: {
                                    Label("Жою", systemImage: "xmark.circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Қоқыс")
        .alert("Барлық қоқысты өшіру керек пе?", isPresented: $showingConfirmClear) {
            Button("Болдырмау", role: .cancel) {}
            Button("Өшіру", role: .destructive) {
                for goal in trashedGoals {
                    context.delete(goal)
                }
                for note in trashedNotes {
                    context.delete(note)
                }
            }
        } message: {
            Text("Бұл әрекетті болдырмау мүмкін емес.")
        }
    }
}
