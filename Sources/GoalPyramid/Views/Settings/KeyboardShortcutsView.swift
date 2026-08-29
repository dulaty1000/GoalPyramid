import SwiftUI

/// "Настройка" → "Басқа" → "Пернетақта тіркесімдері" арқылы ашылатын
/// анықтамалық парақ — қосымшада НАҚТЫ қолданылатын тіркесімдер ғана
/// тізімделеді (жоқ мүмкіндіктер ойдан қосылмайды).
struct KeyboardShortcutsView: View {
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss

    private var items: [(combo: String, key: L10nKey)] {
        [
            ("⏎", .shortcutConfirm),
            ("⎋", .shortcutCancel),
            ("⌘W", .shortcutCloseWindow),
            ("⌘Q", .shortcutQuit)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t(.shortcutsPageTitle, language))
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                ForEach(items, id: \.combo) { item in
                    HStack(alignment: .top, spacing: 14) {
                        Text(item.combo)
                            .font(.system(.body, design: .monospaced).bold())
                            .frame(width: 56, alignment: .leading)
                        Text(L10n.t(item.key, language))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button(L10n.t(.settingsOK, language)) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420, height: 280)
    }
}
