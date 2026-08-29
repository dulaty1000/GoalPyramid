import SwiftUI
import SwiftData

/// Жаңа жоба атауын сұрайтын шағын форма — сақтағанда бірден сол жобаның
/// ішіне ауыстырады (`onCreate`).
struct AddProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var allProjects: [ProjectItem]

    @State private var title: String = ""
    @State private var timeframe: ProjectTimeframe = .other

    /// Терезе түбірінен келеді — тіл ауысқанда осы sheet дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    var onCreate: (ProjectItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t(.newProjectTitle, language))
                .font(.title2.bold())

            TextField(L10n.t(.projectNameField, language), text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit(save)

            Picker(L10n.t(.projectTimeframeLabel, language), selection: $timeframe) {
                ForEach(ProjectTimeframe.allCases) { option in
                    Text(option.label(language)).tag(option)
                }
            }

            HStack {
                Spacer()
                Button(L10n.t(.formCancel, language)) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(L10n.t(.addButton, language)) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 380)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let project = ProjectItem(title: trimmed, sortOrder: allProjects.count, timeframe: timeframe)
        context.insert(project)
        onCreate(project)
        dismiss()
    }
}
