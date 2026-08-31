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
    @Query(
        filter: #Predicate<ProjectItem> { $0.isDeleted },
        sort: \ProjectItem.deletedAt,
        order: .reverse
    ) private var trashedProjects: [ProjectItem]
    @Query(
        filter: #Predicate<HabitItem> { $0.isTrashed },
        sort: \HabitItem.deletedAt,
        order: .reverse
    ) private var trashedHabits: [HabitItem]
    @Query private var allGoals: [GoalItem]
    @Query private var allAttachments: [NoteAttachment]

    @State private var showingConfirmClear = false

    /// Терезе түбірінен келеді — тіл ауысқанда осы бет дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    /// Дағдының өзі "Дағдылар" тобында бөлек жол болып көрсетілетіндіктен,
    /// сол дағдыдан жасалған әрбір күндік тапсырма данасын "Мақсаттар"
    /// тобында ҚАЙТА, жеке-жеке көрсетудің қажеті жоқ (мыс. 30 күндік
    /// дағды — 30 бөлек жол болып шығып кетпеуі үшін). Дерекқордан
    /// ЕШТЕҢЕ өшірілмейді — тек осы жерде, тек КӨРСЕТУ үшін сүзіледі,
    /// сондықтан дағдыны қалпына келтіргенде (`HabitStore.restore`)
    /// бұл даналар өзгеріссіз қалпына келе береді.
    private var visibleTrashedGoals: [GoalItem] {
        let trashedHabitIDs = Set(trashedHabits.map(\.id))
        return trashedGoals.filter { goal in
            guard let habitID = goal.habitID else { return true }
            return !trashedHabitIDs.contains(habitID)
        }
    }

    private var isEmpty: Bool {
        visibleTrashedGoals.isEmpty && trashedNotes.isEmpty && trashedProjects.isEmpty && trashedHabits.isEmpty
    }

    private func tasks(of project: ProjectItem) -> [GoalItem] {
        allGoals.filter { $0.projectID == project.id }
    }

    private func tasks(of habit: HabitItem) -> [GoalItem] {
        allGoals.filter { $0.habitID == habit.id }
    }

    /// Идея параққа тиесілі тіркемелер — параққа физикалық файлдары да
    /// қоса түбегейлі жойылғанда пайдаланылады.
    private func attachments(of note: NoteItem) -> [NoteAttachment] {
        allAttachments.filter { $0.noteID == note.id }
    }

    private func permanentlyDelete(_ note: NoteItem) {
        for attachment in attachments(of: note) {
            AttachmentStore.delete(storedFileName: attachment.storedFileName)
            context.delete(attachment)
        }
        context.delete(note)
    }

    var body: some View {
        List {
            if !isEmpty {
                Section {
                    Button(role: .destructive) {
                        showingConfirmClear = true
                    } label: {
                        Label(L10n.t(.deleteAllAction, language), systemImage: "trash.slash.fill")
                    }
                }
            }

            if isEmpty {
                Section {
                    Text(L10n.t(.trashEmpty, language))
                        .foregroundStyle(.secondary)
                }
            } else {
                if !visibleTrashedGoals.isEmpty {
                    Section(L10n.t(.goalsSection, language)) {
                        ForEach(visibleTrashedGoals) { goal in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(goal.title)
                                        .strikethrough()
                                    Text(goal.hasDueDate
                                        ? "\(goal.level.title(language)) · \(PeriodHelper.displayRange(for: goal.level, periodStart: goal.periodStart))"
                                        : "\(goal.level.title(language)) · \(L10n.t(.noDateLabel, language))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    GoalStore.restore(goal)
                                } label: {
                                    Label(L10n.t(.restoreAction, language), systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(.bordered)

                                Button(role: .destructive) {
                                    context.delete(goal)
                                } label: {
                                    Label(L10n.t(.deleteAction, language), systemImage: "xmark.circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !trashedNotes.isEmpty {
                    Section(L10n.t(.notesSection, language)) {
                        ForEach(trashedNotes) { note in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(note.title.isEmpty ? L10n.t(.untitledNote, language) : note.title)
                                        .strikethrough()
                                    Text(note.content.isEmpty ? L10n.t(.emptyNoteContent, language) : note.content)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button {
                                    NoteStore.restore(note)
                                } label: {
                                    Label(L10n.t(.restoreAction, language), systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(.bordered)

                                Button(role: .destructive) {
                                    permanentlyDelete(note)
                                } label: {
                                    Label(L10n.t(.deleteAction, language), systemImage: "xmark.circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !trashedHabits.isEmpty {
                    Section(L10n.t(.habitsSection, language)) {
                        ForEach(trashedHabits) { habit in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(habit.title.isEmpty ? L10n.t(.untitledHabit, language) : habit.title)
                                        .strikethrough()
                                    if !habit.notes.isEmpty {
                                        Text(habit.notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Button {
                                    HabitStore.restore(habit, tasks: tasks(of: habit).filter(\.isDeleted))
                                } label: {
                                    Label(L10n.t(.restoreAction, language), systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(.bordered)

                                Button(role: .destructive) {
                                    for task in tasks(of: habit) {
                                        context.delete(task)
                                    }
                                    context.delete(habit)
                                } label: {
                                    Label(L10n.t(.deleteAction, language), systemImage: "xmark.circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !trashedProjects.isEmpty {
                    Section(L10n.t(.sidebarProjects, language)) {
                        ForEach(trashedProjects) { project in
                            HStack(spacing: 12) {
                                Text(project.title)
                                    .strikethrough()

                                Spacer()

                                Button {
                                    ProjectStore.restore(project, tasks: tasks(of: project).filter(\.isDeleted))
                                } label: {
                                    Label(L10n.t(.restoreAction, language), systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(.bordered)

                                Button(role: .destructive) {
                                    for task in tasks(of: project) {
                                        context.delete(task)
                                    }
                                    context.delete(project)
                                } label: {
                                    Label(L10n.t(.deleteAction, language), systemImage: "xmark.circle")
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
        .navigationTitle(L10n.t(.sidebarTrash, language))
        .alert(L10n.t(.deleteAllConfirmTitle, language), isPresented: $showingConfirmClear) {
            Button(L10n.t(.settingsCancel, language), role: .cancel) {}
            Button(L10n.t(.confirmDeleteAction, language), role: .destructive) {
                // Жобаға тиесілі тапсырма `trashedGoals`-та да, сол жобаның
                // `tasks(of:)` тізімінде де кездесуі мүмкін — бірдей жазбаны
                // екі рет context.delete() шақырмау үшін бақыланады.
                var deletedIDs = Set<PersistentIdentifier>()
                for goal in trashedGoals {
                    context.delete(goal)
                    deletedIDs.insert(goal.persistentModelID)
                }
                for note in trashedNotes {
                    permanentlyDelete(note)
                }
                for habit in trashedHabits {
                    for task in tasks(of: habit) where !deletedIDs.contains(task.persistentModelID) {
                        context.delete(task)
                        deletedIDs.insert(task.persistentModelID)
                    }
                    context.delete(habit)
                }
                for project in trashedProjects {
                    for task in tasks(of: project) where !deletedIDs.contains(task.persistentModelID) {
                        context.delete(task)
                        deletedIDs.insert(task.persistentModelID)
                    }
                    context.delete(project)
                }
            }
        } message: {
            Text(L10n.t(.actionIrreversible, language))
        }
    }
}
