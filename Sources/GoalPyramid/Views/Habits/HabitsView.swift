import SwiftUI
import SwiftData

/// "Дағдылар" бөлімі: дағды қосу/өңдеу диалогы + тізім + қоқысқа тастау.
/// Әзірге тек негізгі CRUD — бақылау (streak, күнделікті белгілеу) кейін
/// бөлек сұраныспен қосылады.
struct HabitsView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<HabitItem> { !$0.isDeleted },
        sort: \HabitItem.createdAt,
        order: .reverse
    ) private var habits: [HabitItem]

    @State private var showingAdd = false
    @State private var editingHabit: HabitItem?
    @State private var hoveredHabitID: UUID?

    /// Терезе түбірінен келеді — тіл ауысқанда осы бет дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    var body: some View {
        List {
            // "Жобалар"/"Идеялар" беттеріндегідей — қосу батырмасы
            // тізімнің ЕҢ ЖОҒАРЫҒЫНДА, әрдайым бірден қолжетімді.
            Section {
                Button {
                    showingAdd = true
                } label: {
                    Label(L10n.t(.addHabitAction, language), systemImage: "plus.circle.fill")
                }
            }

            if habits.isEmpty {
                Section {
                    Text(L10n.t(.noHabitsYet, language))
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(habits) { habit in
                        habitRow(habit)
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(L10n.t(.sidebarHabits, language))
        .sheet(isPresented: $showingAdd) {
            AddEditHabitSheet(existingHabit: nil)
        }
        .sheet(item: $editingHabit) { habit in
            AddEditHabitSheet(existingHabit: habit)
        }
    }

    @ViewBuilder
    private func habitRow(_ habit: HabitItem) -> some View {
        HStack(spacing: 8) {
            Button {
                editingHabit = habit
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(habit.title.isEmpty ? L10n.t(.untitledHabit, language) : habit.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if !habit.isActive {
                            Text(L10n.t(.habitStoppedBadge, language))
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !habit.notes.isEmpty {
                        Text(habit.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !habit.isActive {
                Button {
                    HabitStore.reactivate(habit, in: context)
                } label: {
                    Label(L10n.t(.reactivateHabitAction, language), systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }

            if hoveredHabitID == habit.id {
                Button {
                    HabitStore.moveToTrash(habit)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(L10n.t(.deleteHabitHelp, language))
            }
        }
        .onHover { isHovering in
            hoveredHabitID = isHovering ? habit.id : nil
        }
        .contextMenu {
            Button(role: .destructive) {
                HabitStore.moveToTrash(habit)
            } label: {
                Label(L10n.t(.trashAction, language), systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                HabitStore.moveToTrash(habit)
            } label: {
                Label(L10n.t(.trashAction, language), systemImage: "trash")
            }
        }
    }
}
