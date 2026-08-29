import SwiftUI
import SwiftData

/// Дағды қосу/өңдеу диалогы: атауы + еркін сипаттама. Бақылау (streak,
/// күнделікті белгілеу) кейін бөлек сұраныспен қосылады.
struct AddEditHabitSheet: View {
    let existingHabit: HabitItem?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Терезе түбірінен келеді — тіл ауысқанда осы sheet дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedWeekdays: Set<Int> = []

    private var isEditing: Bool { existingHabit != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? L10n.t(.editHabitTitle, language) : L10n.t(.newHabitTitle, language))
                .font(.title2.bold())

            TextField(L10n.t(.fieldTitleLabel, language), text: $title)
                .textFieldStyle(.roundedBorder)

            TextField(L10n.t(.habitDescriptionLabel, language), text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...8)

            VStack(alignment: .leading, spacing: 10) {
                Picker(L10n.t(.habitFrequencyLabel, language), selection: $frequency) {
                    ForEach(HabitFrequency.allCases) { option in
                        Text(option.title(language)).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if frequency == .specificDays {
                    weekdayPicker
                }
            }

            HStack {
                if isEditing {
                    Button(L10n.t(.trashAction, language), role: .destructive) {
                        if let habit = existingHabit {
                            HabitStore.moveToTrash(habit)
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
            guard let habit = existingHabit else { return }
            title = habit.title
            notes = habit.notes
            frequency = habit.frequency
            selectedWeekdays = Set(habit.selectedWeekdays)
        }
    }

    /// Аптаның 7 күні (Дс...Жс) — тек "Белгілі күндер" жиілігінде
    /// көрінеді. Индекс: 0=Дүйсенбі...6=Жексенбі.
    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                let isOn = selectedWeekdays.contains(index)
                Button {
                    if isOn {
                        selectedWeekdays.remove(index)
                    } else {
                        selectedWeekdays.insert(index)
                    }
                } label: {
                    Text(weekdayShortTitle(index))
                        .font(.caption.weight(.semibold))
                        .frame(width: 34, height: 28)
                        .background(Capsule().fill(isOn ? Theme.accent : Color.secondary.opacity(0.15)))
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func weekdayShortTitle(_ index: Int) -> String {
        switch index {
        case 0: return L10n.t(.weekdayMon, language)
        case 1: return L10n.t(.weekdayTue, language)
        case 2: return L10n.t(.weekdayWed, language)
        case 3: return L10n.t(.weekdayThu, language)
        case 4: return L10n.t(.weekdayFri, language)
        case 5: return L10n.t(.weekdaySat, language)
        default: return L10n.t(.weekdaySun, language)
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let resolvedWeekdays = frequency == .specificDays ? Array(selectedWeekdays).sorted() : []

        if let habit = existingHabit {
            habit.title = trimmed
            habit.notes = notes
            habit.frequency = frequency
            habit.selectedWeekdays = resolvedWeekdays
            habit.updatedAt = Date()
        } else {
            let habit = HabitItem(title: trimmed, notes: notes, frequency: frequency, selectedWeekdays: resolvedWeekdays)
            context.insert(habit)
            HabitStore.generateInitialSchedule(for: habit, in: context)
        }
        dismiss()
    }
}
