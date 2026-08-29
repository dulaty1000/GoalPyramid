import SwiftUI

/// "Бүгін" тізімінің астында көрінетін, толығымен қолмен басқарылатын
/// Эйзенхауэр матрицасы. Автоматты категорияландыру жоқ — пайдаланушы
/// негізгі тізімдегі мақсаттың жанындағы 🔲 батырмасы арқылы оны қай
/// квадратқа қоятынын өзі таңдайды (`GoalListView`). Квадратқа қойылған
/// мақсат осында толық функциясымен (checkbox, ескертпе, баға, өңдеу,
/// өшіру) көрінеді, ал негізгі тізімнен жоғалады.
struct EisenhowerMatrixView: View {
    /// Осы кезеңге (күнге) тиесілі, матрицаға қойылған барлық мақсаттар.
    let placedGoals: [GoalItem]
    var onEdit: (GoalItem) -> Void

    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private func goals(in quadrant: EisenhowerQuadrant) -> [GoalItem] {
        placedGoals
            .filter { $0.eisenhowerQuadrant == quadrant }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t(.matrixTitle, language))
                .font(.headline)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(EisenhowerQuadrant.allCases) { quadrant in
                    quadrantCard(quadrant)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func quadrantCard(_ quadrant: EisenhowerQuadrant) -> some View {
        let items = goals(in: quadrant)
        VStack(alignment: .leading, spacing: 8) {
            Text(quadrant.title(language))
                .font(.subheadline.bold())
                .foregroundStyle(quadrant.accentColor)

            if items.isEmpty {
                Text(L10n.t(.matrixEmpty, language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { goal in
                        matrixRow(goal)
                        if goal.id != items.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(quadrant.accentColor.opacity(0.35), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func matrixRow(_ goal: GoalItem) -> some View {
        HStack(alignment: .top, spacing: 6) {
            GoalRowView(goal: goal)
                .font(.caption)

            Button {
                goal.eisenhowerQuadrant = nil
            } label: {
                Image(systemName: "arrow.uturn.left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.t(.matrixRemove, language))

            Button(role: .destructive) {
                GoalStore.moveToTrash(goal)
            } label: {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.t(.trashAction, language))
        }
        .contentShape(Rectangle())
        .onTapGesture { onEdit(goal) }
    }
}
