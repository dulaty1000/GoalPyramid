import SwiftUI

/// Берілген жылдың 12 айының тізімі — ағаш навигациядағы "Ай" деңгейінің
/// таңдау беті ("5 Жыл" → Жыл → **Ай** → Апта → Күн).
/// Жол таңдау мен ◄/► push жасамайды — тек `onSelectMonth`/`onNavigateUp`/
/// `onNavigateDown` арқылы иесі-View-ге қай бет керек екенін хабарлайды.
struct MonthsOverviewView: View {
    let year: Int
    var onSelectMonth: (Int) -> Void
    var onNavigateUp: (() -> Void)?
    var onNavigateDown: (() -> Void)?

    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private var monthSymbols: [String] {
        let df = DateFormatter()
        df.locale = language.locale
        return df.standaloneMonthSymbols.map { $0.capitalized }
    }

    var body: some View {
        List(1...12, id: \.self) { month in
            Button {
                onSelectMonth(month)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Theme.accent)
                        .font(.title3)
                    Text(monthSymbols[month - 1])
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.inset)
        .navigationTitle(L10n.yearMonthsTitle(year: year, language))
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                if let onNavigateUp {
                    Button {
                        onNavigateUp()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .help(L10n.t(.navBackToYear, language))
                }
                if let onNavigateDown {
                    Button {
                        onNavigateDown()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .help(L10n.t(.navForwardToMonth, language))
                }
            }
        }
    }
}
