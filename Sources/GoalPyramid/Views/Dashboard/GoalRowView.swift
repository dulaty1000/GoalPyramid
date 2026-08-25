import SwiftUI

struct GoalRowView: View {
    @Bindable var goal: GoalItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                GoalStore.toggleCompletion(goal)
            } label: {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(goal.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .strikethrough(goal.isCompleted)
                    .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                if !goal.notes.isEmpty {
                    Text(goal.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            EvaluationPicker(evaluation: $goal.evaluation)
        }
        .padding(.vertical, 4)
    }
}

/// 🟢 🟡 🔴 ⚪️ — тапсырманың нәтижесін түспен бағалау виджеті.
struct EvaluationPicker: View {
    @Binding var evaluation: EvaluationColor

    var body: some View {
        HStack(spacing: 6) {
            ForEach(EvaluationColor.allCases) { option in
                Circle()
                    .fill(option.color)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(evaluation == option ? 0.6 : 0), lineWidth: 2)
                    )
                    .onTapGesture { evaluation = option }
                    .help(option.label)
            }
        }
    }
}
