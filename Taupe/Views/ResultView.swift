import SwiftUI

/// Fin de manche : le camp gagnant, les mots dévoilés, tous les rôles, et le
/// classement cumulé mis à jour.
struct ResultView: View {
    @EnvironmentObject private var session: GameSession
    let engine: GameEngine
    let outcome: RoundOutcome

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    banner
                    wordsPanel
                    rolesPanel
                    leaderboardPanel
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 14)
            }

            VStack(spacing: 2) {
                PrimaryButton(title: "Nouvelle manche", systemImage: "arrow.clockwise", tint: accent) {
                    session.playAgain()
                }
                GhostButton(title: "Revenir aux réglages", systemImage: "slider.horizontal.3") {
                    session.backToSetup()
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 12)
        }
        .onAppear {
            Haptics.success()
            withAnimation(Theme.flip.delay(0.05)) { appeared = true }
        }
    }

    // MARK: Bandeau de victoire

    private var accent: Color {
        switch outcome {
        case .civiliansWin: return Theme.mint
        case .infiltratorsWin: return Theme.brandLight
        case .mrWhiteGuessedRight: return Theme.amber
        }
    }

    private var symbol: String {
        switch outcome {
        case .civiliansWin: return "person.3.fill"
        case .infiltratorsWin: return Role.undercover.symbol
        case .mrWhiteGuessedRight: return Role.mrWhite.symbol
        }
    }

    private var subtitle: String {
        switch outcome {
        case .civiliansWin:
            return "Tous les infiltrés ont été démasqués."
        case .infiltratorsWin:
            return "Ils ont survécu jusqu'au bout."
        case .mrWhiteGuessedRight:
            return "Il a trouvé le mot des civils : \(engine.civilianWord)."
        }
    }

    private var banner: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.16))
                    .frame(width: 116, height: 116)
                Image(systemName: symbol)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(accent)
            }
            .scaleEffect(appeared ? 1 : 0.5)

            Text(outcome.title)
                .font(Theme.title(30))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            Text(subtitle)
                .font(Theme.body(15))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
        }
        .opacity(appeared ? 1 : 0)
        .padding(.bottom, 4)
    }

    // MARK: Les deux mots

    private var wordsPanel: some View {
        HStack(spacing: 10) {
            wordTile(label: "Civils", word: engine.civilianWord, tint: Theme.mint)
            wordTile(label: "Undercover", word: engine.undercoverWord, tint: Theme.brandLight)
        }
    }

    private func wordTile(label: String, word: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(label.uppercased())
                .font(Theme.caption(11))
                .tracking(1)
                .foregroundStyle(tint)
            Text(word)
                .font(Theme.heading(19))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .strokeBorder(tint.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: Rôles de tout le monde

    private var rolesPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 0) {
                Text("Les rôles")
                    .font(Theme.heading(17))
                    .foregroundStyle(Theme.ink)
                    .padding(.bottom, 10)

                ForEach(Array(engine.players.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 10) {
                        Text(player.name)
                            .font(Theme.body(15))
                            .foregroundStyle(player.isAlive ? Theme.ink : Theme.inkFaint)
                            .strikethrough(!player.isAlive, color: Theme.inkFaint)
                            .lineLimit(1)

                        Spacer(minLength: 6)

                        if let points = engine.roundPoints[player.id], points > 0 {
                            Text("+\(points)")
                                .font(Theme.caption(13))
                                .foregroundStyle(Theme.amber)
                        }
                        if let role = player.role {
                            RoleBadge(role: role, compact: true)
                        }
                    }
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottom) {
                        if index < engine.players.count - 1 {
                            Rectangle().fill(Theme.hairline).frame(height: 0.5)
                        }
                    }
                }
            }
        }
    }

    private var leaderboardPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 10) {
                Label("Classement", systemImage: "trophy.fill")
                    .font(Theme.heading(17))
                    .foregroundStyle(Theme.ink)
                LeaderboardList(rows: session.leaderboard)
            }
        }
    }
}
