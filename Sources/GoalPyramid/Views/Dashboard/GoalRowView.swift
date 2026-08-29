import SwiftUI
import AppKit

struct GoalRowView: View {
    @Bindable var goal: GoalItem

    @AppStorage(AppSettingsKey.completionEffectsEnabled) private var effectsEnabled = false
    @State private var bounce = false

    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(goal.title)
                        .strikethrough(goal.isCompleted)
                        .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                    if goal.projectID != nil {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .help(L10n.t(.projectTaskHelp, language))
                    }
                    if goal.habitID != nil {
                        Image(systemName: "repeat.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .help(L10n.t(.habitTaskHelp, language))
                    }
                }
                if !goal.notes.isEmpty {
                    Text(goal.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            EvaluationPicker(evaluation: Binding(
                get: { goal.evaluation },
                set: { setEvaluation($0) }
            ))
            .scaleEffect(bounce ? 1.25 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.35), value: bounce)
        }
        .padding(.vertical, 4)
    }

    /// Бағалау түсін таңдау "орындалды" күйін де тікелей белгілейді
    /// (`GoalItem.evaluation`-ды қараңыз) — бөлек checkbox енді жоқ.
    /// "Настройка" → "Басқа" → "Дыбыстық/визуалды эффект" қосулы болса,
    /// тапсырма СҰРдан басқа түске (яғни ОРЫНДАЛҒАН күйге) ауысқан сәтте
    /// ғана қысқа дыбыс пен секіру анимациясын ойнатады.
    private func setEvaluation(_ newValue: EvaluationColor) {
        let willComplete = !goal.isCompleted && newValue != .none
        goal.evaluation = newValue
        guard willComplete, effectsEnabled else { return }
        NSSound(named: "Tink")?.play()
        bounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            bounce = false
        }
    }
}

/// 🟢 🟡 🔴 ⚪️ — тапсырманың нәтижесін түспен бағалау виджеті.
struct EvaluationPicker: View {
    @Binding var evaluation: EvaluationColor

    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

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
                    .help(option.label(language))
            }
        }
    }
}
