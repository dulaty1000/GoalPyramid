import SwiftUI
import SwiftData

/// Мақсат қосу/өңдеу формасы. Жаңа мақсат қосқанда "әр кезеңге 3" ережесі тексеріледі.
struct AddEditGoalSheet: View {
    let level: GoalLevel
    let periodStart: Date
    let parentID: UUID?
    let existingGoal: GoalItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var allGoals: [GoalItem]

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var evaluation: EvaluationColor = .none
    @State private var isCompleted: Bool = false
    @State private var selectedParentID: UUID?

    private var isEditing: Bool { existingGoal != nil }

    private var potentialParents: [GoalItem] {
        guard let parentLevel = level.parentLevel else { return [] }
        return allGoals.filter { $0.level == parentLevel }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Мақсатты өңдеу" : "Жаңа \(level.title.lowercased()) мақсат")
                .font(.title2.bold())

            TextField("Атауы", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Ескертпе (міндетті емес)", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            if let parentLevel = level.parentLevel, !potentialParents.isEmpty {
                Picker("Байланысты \(parentLevel.title.lowercased()) мақсат", selection: $selectedParentID) {
                    Text("Жоқ").tag(UUID?.none)
                    ForEach(potentialParents) { parent in
                        Text(parent.title).tag(Optional(parent.id))
                    }
                }
            }

            Toggle("Орындалды", isOn: $isCompleted)

            HStack {
                Text("Бағасы:")
                EvaluationPicker(evaluation: $evaluation)
            }

            HStack {
                if isEditing {
                    Button("Өшіру", role: .destructive) {
                        if let goal = existingGoal {
                            context.delete(goal)
                        }
                        dismiss()
                    }
                }
                Spacer()
                Button("Бас тарту") { dismiss() }
                Button(isEditing ? "Сақтау" : "Қосу") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            if let goal = existingGoal {
                title = goal.title
                notes = goal.notes
                evaluation = goal.evaluation
                isCompleted = goal.isCompleted
                selectedParentID = goal.parentID
            } else {
                selectedParentID = parentID
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let goal = existingGoal {
            goal.title = trimmed
            goal.notes = notes
            goal.evaluation = evaluation
            goal.parentID = selectedParentID
            if isCompleted != goal.isCompleted {
                GoalStore.toggleCompletion(goal)
            }
        } else {
            guard GoalStore.canAdd(level: level, periodStart: periodStart, in: context) else {
                dismiss()
                return
            }
            let newGoal = GoalItem(
                title: trimmed,
                level: level,
                periodStart: periodStart,
                notes: notes,
                parentID: selectedParentID,
                sortOrder: GoalStore.count(level: level, periodStart: periodStart, in: context)
            )
            newGoal.evaluation = evaluation
            context.insert(newGoal)
            if isCompleted {
                GoalStore.markCompleted(newGoal, evaluation: evaluation == .none ? .green : evaluation)
            }
        }
        dismiss()
    }
}
