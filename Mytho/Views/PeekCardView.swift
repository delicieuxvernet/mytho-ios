import SwiftUI

/// « Ma carte » : relire son mot en cours de partie, sans le montrer aux autres.
///
/// Née d'une soirée du 20 août 2026 : un joueur avait oublié son mot, la table
/// a essayé le bouton « Retour », et l'app a rouvert la carte du **dernier
/// joueur servi**. Ce coup-ci c'était le sien ; la fois d'après c'était le mot
/// d'un autre, en clair, devant tout le monde.
///
/// Deux principes ici :
/// 1. **on ne rembobine rien** — la manche n'est pas touchée, on relit un état
///    déjà connu ;
/// 2. **deux gestes délibérés** avant qu'un mot n'apparaisse — choisir un
///    prénom, puis confirmer que c'est bien soi. Impossible d'ouvrir la carte
///    de quelqu'un d'autre par accident.
struct PeekCardView: View {
    @Environment(\.skin) private var skin

    let engine: GameEngine
    let onClose: () -> Void

    /// Le joueur qui s'est annoncé. Nil = on en est encore au choix du prénom.
    @State private var chosen: Player?
    /// Passe à vrai quand il a confirmé : c'est le seul chemin vers le mot.
    @State private var revealed = false

    /// Seuls les joueurs déjà servis ont quelque chose à relire. Pendant la
    /// distribution, ceux qui n'ont pas encore pioché n'apparaissent pas.
    private var candidates: [Player] {
        engine.players.filter { $0.role != nil }
    }

    var body: some View {
        ZStack {
            // Le jeu disparaît complètement derrière : la carte relue doit être
            // le seul point net de l'écran, comme au moment de la pioche.
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { if !revealed { onClose() } }

            Panel(padding: 20) {
                VStack(spacing: 18) {
                    if let chosen, revealed {
                        card(for: chosen)
                    } else if let chosen {
                        handoff(to: chosen)
                    } else {
                        chooser
                    }
                }
            }
            .padding(.horizontal, 26)
        }
        .animation(Theme.spring, value: chosen)
        .animation(Theme.spring, value: revealed)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: 1. Qui a oublié ?

    private var chooser: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.brandLight)
                    .accessibilityHidden(true)
                Text("Revoir sa carte")
                    .font(Theme.heading(21))
                    .foregroundStyle(skin.ink)
                Text("Qui a oublié son mot ?")
                    .font(Theme.body(14))
                    .foregroundStyle(skin.inkMuted)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(candidates) { player in
                    Button {
                        Haptics.tap()
                        chosen = player
                    } label: {
                        HStack(spacing: 9) {
                            AvatarView(name: player.name, size: 30, table: engine.players.map(\.name))
                            Text(player.name)
                                .font(Theme.body(15))
                                .foregroundStyle(skin.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: Theme.touchTarget)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                .fill(skin.panelSoft)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                        .strokeBorder(skin.outline, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PressedStyle())
                }
            }

            GhostButton(title: "Fermer", action: onClose)
        }
    }

    // MARK: 2. C'est bien toi ?

    private func handoff(to player: Player) -> some View {
        VStack(spacing: 16) {
            AvatarView(name: player.name, size: 62, table: engine.players.map(\.name))

            VStack(spacing: 6) {
                Text("Passe le téléphone à")
                    .font(Theme.body(14))
                    .foregroundStyle(skin.inkMuted)
                Text(player.name)
                    .font(Theme.title(30))
                    .foregroundStyle(skin.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
                Text("Personne d'autre ne doit regarder l'écran.")
                    .font(Theme.body(14))
                    .foregroundStyle(skin.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 2) {
                PrimaryButton(title: "Je suis \(player.name)", systemImage: "hand.raised.fill") {
                    revealed = true
                }
                GhostButton(title: "Ce n'est pas moi") { chosen = nil }
            }
        }
    }

    // MARK: 3. La carte

    private func card(for player: Player) -> some View {
        VStack(spacing: 16) {
            Text(player.name)
                .font(Theme.caption(14))
                .foregroundStyle(skin.inkMuted)

            WordCard(
                role: player.role ?? .civilian,
                word: player.word(civilianWord: engine.civilianWord, undercoverWord: engine.undercoverWord),
                showRole: engine.config.easyMode
            )
            .padding(.horizontal, 34)

            if let special = player.specialRole {
                SpecialRoleNote(role: special)
            }

            PrimaryButton(title: "C'est bon, je referme", systemImage: "checkmark", action: onClose)
        }
    }
}
