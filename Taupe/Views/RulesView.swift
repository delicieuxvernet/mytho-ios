import SwiftUI

/// Règles du jeu, consultables avant de lancer une manche. Autour d'une table,
/// il y a toujours quelqu'un qui n'a jamais joué.
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Backdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        intro
                        rolesSection
                        flowSection
                        scoreSection
                        Color.clear.frame(height: 12)
                    }
                    .padding(.horizontal, Theme.gutter)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Comment jouer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.brandLight)
                }
            }
            .toolbarBackground(Theme.night, for: .navigationBar)
        }
    }

    private var intro: some View {
        Panel {
            Text("Tout le monde reçoit le même mot secret — sauf les infiltrés. Chacun décrit son mot à tour de rôle, sans jamais le prononcer. Puis on vote pour éliminer celui qui sonne faux.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rolesSection: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Les rôles")
                    .font(Theme.heading(17))
                    .foregroundStyle(Theme.ink)

                roleRow(
                    .civilian,
                    "Reçoit le mot majoritaire. Il gagne quand tous les infiltrés ont été démasqués."
                )
                roleRow(
                    .undercover,
                    "Reçoit un mot proche mais différent. Il doit se fondre dans la masse et survivre."
                )
                roleRow(
                    .mrWhite,
                    "Ne reçoit aucun mot. Il improvise à partir de ce qu'il entend — et s'il est démasqué, il peut encore tout gagner en devinant le mot des civils."
                )
            }
        }
    }

    private func roleRow(_ role: Role, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: role.symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.color(for: role))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.color(for: role).opacity(0.16)))

            VStack(alignment: .leading, spacing: 3) {
                Text(role.displayName)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.color(for: role))
                Text(text)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var flowSection: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Le déroulé d'une manche")
                    .font(Theme.heading(17))
                    .foregroundStyle(Theme.ink)

                step(1, "Distribution", "Le téléphone circule. Chacun pioche une carte et découvre son mot en secret.")
                step(2, "Description", "Dans l'ordre affiché, chacun décrit son mot en une phrase. Trop précis, on se fait repérer par les infiltrés ; trop vague, on se fait accuser.")
                step(3, "Discussion", "La table débat à voix haute. Qui a paru hésitant ? Qui est resté trop flou ?")
                step(4, "Élimination", "On désigne un joueur. Son rôle est révélé, puis un nouveau tour commence — jusqu'à ce qu'un camp l'emporte.")
            }
        }
    }

    private func step(_ number: Int, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(Theme.heading(15))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.brand))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
                Text(text)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var scoreSection: some View {
        Panel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Les points")
                    .font(Theme.heading(17))
                    .foregroundStyle(Theme.ink)

                scoreRow("Chaque civil, si les civils gagnent", Score.civilianWin)
                scoreRow("Un undercover qui survit", Score.undercoverSurvives)
                scoreRow("Mr. White qui survit", Score.mrWhiteSurvives)
                scoreRow("Mr. White qui devine le mot", Score.mrWhiteGuessesRight)

                Text("Les points se cumulent d'une manche à l'autre. Le classement se remet à zéro depuis l'écran d'accueil.")
                    .font(Theme.caption(13))
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }

    private func scoreRow(_ label: String, _ points: Int) -> some View {
        HStack {
            Text(label)
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 10)
            Text("+\(points)")
                .font(Theme.heading(15))
                .foregroundStyle(Theme.amber)
        }
    }
}
