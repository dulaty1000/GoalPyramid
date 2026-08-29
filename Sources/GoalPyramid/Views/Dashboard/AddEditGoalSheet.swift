import SwiftUI
import SwiftData

/// Мақсат қосу/өңдеу формасы. Жаңа мақсат қосқанда "әр кезеңге 3" ережесі тексеріледі.
struct AddEditGoalSheet: View {
    let level: GoalLevel
    let periodStart: Date
    let existingGoal: GoalItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Терезе түбірінен келеді — тіл ауысқанда осы sheet дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var evaluation: EvaluationColor = .none

    private var isEditing: Bool { existingGoal != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? L10n.t(.editGoalTitle, language) : L10n.newGoalTitle(levelTitle: level.title(language), language))
                .font(.title2.bold())

            TextField(L10n.t(.fieldTitleLabel, language), text: $title)
                .textFieldStyle(.roundedBorder)

            TextField(L10n.t(.fieldNotesOptional, language), text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            HStack {
                Text(L10n.t(.evaluationLabel, language))
                EvaluationPicker(evaluation: $evaluation)
            }

            HStack {
                if isEditing {
                    Button(L10n.t(.trashAction, language), role: .destructive) {
                        if let goal = existingGoal {
                            GoalStore.moveToTrash(goal)
                        }
                        dismiss()
                    }
                }
                Spacer()
                Button(L10n.t(.formCancel, language)) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(isEditing ? L10n.t(.saveButton, language) : L10n.t(.addButton, language)) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            guard let goal = existingGoal else { return }
            title = goal.title
            notes = goal.notes
            evaluation = goal.evaluation
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let goal = existingGoal {
            goal.title = trimmed
            goal.notes = notes
            goal.evaluation = evaluation
        } else {
            let newGoal = GoalItem(
                title: trimmed,
                level: level,
                periodStart: periodStart,
                notes: notes,
                sortOrder: GoalStore.count(level: level, periodStart: periodStart, in: context)
            )
            newGoal.evaluation = evaluation
            context.insert(newGoal)
        }
        dismiss()
    }
}
