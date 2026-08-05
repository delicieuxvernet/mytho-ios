import SwiftUI

// MARK: - La barre de sortie des jeux de soirée

/// Les deux seules sorties d'un jeu, toujours au même endroit, dans les trois
/// jeux : « Retour » à gauche, « Jeux » à droite.
///
/// Retour utilisateur du 5 août 2026 : « quand on est dans le jeu, on doit avoir
/// un échappatoire facile pour revenir en arrière et un pour revenir au menu. Là
/// c'est trop complexe et les gens vont fermer l'appli. » Chaque jeu inventait sa
/// propre sortie — une croix sur un seul écran, rien du tout ailleurs, un bouton
/// secondaire enfoui en bas. Une soirée passe d'un jeu à l'autre : la sortie doit
/// se trouver sans la chercher.
///
/// Libellés en toutes lettres et jamais une icône seule : c'est précisément le
/// manque de clarté qui était reproché.
///
/// Se pose en `safeAreaInset(edge: .top)` et non en surimpression, pour ne jamais
/// recouvrir le haut de l'écran du jeu (compteur de manche, barre de progression).
/// En pratique, on passe par `partyTopBar(back:exit:confirmsExit:)`.
struct PartyTopBar: View {
    @Environment(\.skin) private var skin

    /// Un pas en arrière dans le jeu. Nul au premier écran : un bouton qui ne
    /// mène nulle part apprend à l'utilisateur à ne plus s'y fier.
    let back: (() -> Void)?
    /// Retour au catalogue. La demande de confirmation, elle, appartient au
    /// modificateur : elle doit s'afficher plein écran, pas dans la barre.
    let exit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if let back = back {
                pill(
                    title: "Retour",
                    systemImage: "chevron.left",
                    accessibility: "Revenir à l'étape précédente",
                    action: back
                )
            }

            Spacer(minLength: 0)

            pill(
                title: "Jeux",
                systemImage: "square.grid.2x2.fill",
                accessibility: "Revenir au choix des jeux",
                action: exit
            )
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    /// Pastille opaque à contour encré, identique à celles d'Undercover : la
    /// soirée reconnaît la même forme d'un jeu à l'autre. Encre pleine et non
    /// atténuée, et hauteur `touchTarget` : ces deux commandes s'appuient dans le
    /// bruit d'une soirée, souvent à l'aveugle.
    ///
    /// Aucune ombre franche ici : posée sur une vue qui porte du texte, elle en
    /// dessinerait une copie nette quelques points plus bas.
    private func pill(
        title: String,
        systemImage: String,
        accessibility: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .accessibilityHidden(true)
                Text(title)
                    .font(Theme.caption(13))
            }
            .foregroundStyle(skin.ink)
            .padding(.horizontal, 13)
            .frame(height: Theme.touchTarget)
            .background(
                Capsule()
                    .fill(skin.panel)
                    .overlay(Capsule().strokeBorder(skin.outline, lineWidth: 2))
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel(accessibility)
    }
}

// MARK: - Pose de la barre

extension View {
    /// Pose la barre de sortie sur un écran de jeu, en une ligne.
    ///
    /// - Parameters:
    ///   - back: le pas en arrière. Omis (ou nul) au premier écran du jeu, où le
    ///     bouton disparaît plutôt que de rester inerte.
    ///   - exit: le retour au catalogue.
    ///   - confirmsExit: vrai dès qu'une manche est engagée. La confirmation vit
    ///     ici et non chez l'appelant, sinon chaque jeu la réécrirait — et l'un
    ///     d'eux finirait par l'oublier.
    ///
    /// À placer **avant** le `.environment(\.skin, …)` de l'écran dans la chaîne
    /// de modificateurs : la barre et sa confirmation lisent la peau ambiante, et
    /// posées au-dessus elles retomberaient sur la peau nuit par défaut.
    func partyTopBar(
        back: (() -> Void)? = nil,
        exit: @escaping () -> Void,
        confirmsExit: Bool = false
    ) -> some View {
        modifier(PartyTopBarModifier(back: back, exit: exit, confirmsExit: confirmsExit))
    }
}

/// Tient l'état de la confirmation. Il ne peut pas vivre dans `PartyTopBar` :
/// l'inset n'occupe que le haut de l'écran, la question doit couvrir le tout.
private struct PartyTopBarModifier: ViewModifier {
    let back: (() -> Void)?
    let exit: () -> Void
    let confirmsExit: Bool

    @State private var isConfirmingExit = false

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                PartyTopBar(back: back, exit: { requestExit() })
            }
            .overlay {
                if isConfirmingExit {
                    PartyExitConfirmOverlay(
                        onExit: {
                            isConfirmingExit = false
                            exit()
                        },
                        onCancel: {
                            withAnimation(Theme.snap) { isConfirmingExit = false }
                        }
                    )
                    .transition(.opacity)
                }
            }
    }

    /// Une manche en cours ne s'abandonne pas sur un appui réflexe : le téléphone
    /// tourne autour de la table et « Jeux » est à portée de pouce. Hors manche,
    /// au contraire, demander confirmation pour rien ferait douter du bouton.
    private func requestExit() {
        guard confirmsExit else {
            exit()
            return
        }
        withAnimation(Theme.snap) { isConfirmingExit = true }
    }
}

// MARK: - Confirmation

/// Reprend mot pour mot le motif validé pour Undercover (`QuitConfirmOverlay`).
/// Il y est `private`, dans un fichier en validation chez Apple : le redire ici
/// coûte moins cher que d'y toucher.
///
/// Le fond flouté est la seule entorse assumée au « zéro flou » de la DA : la
/// question doit être le seul point net de l'écran.
private struct PartyExitConfirmOverlay: View {
    @Environment(\.skin) private var skin
    let onExit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 18) {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.crimson)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Quitter la partie ?")
                        .font(Theme.heading(21))
                        .foregroundStyle(skin.ink)
                    // Dire ce qu'on perd ET ce qu'on garde : sans la seconde
                    // moitié, on hésite à sortir de peur de re-saisir la table.
                    Text("La manche en cours sera abandonnée et vous reviendrez au choix des jeux. Les prénoms de la soirée sont conservés.")
                        .font(Theme.body(14))
                        .foregroundStyle(skin.inkMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 2) {
                    PrimaryButton(
                        title: "Quitter la partie",
                        systemImage: "xmark",
                        tint: Theme.crimson,
                        action: onExit
                    )
                    GhostButton(title: "Continuer à jouer", action: onCancel)
                }
            }
            .padding(22)
            // L'ombre franche porte sur la forme de fond seule : appliquée à la
            // pile, elle recopierait chaque ligne de texte 5 pt plus bas.
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .fill(skin.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                            .strokeBorder(skin.outline, lineWidth: Theme.stroke)
                    )
                    .shadow(color: skin.outline, radius: 0, y: Theme.drop)
            )
            .padding(.horizontal, 34)
        }
        .accessibilityAddTraits(.isModal)
    }
}

#if DEBUG
#Preview("Barre — jour, manche en cours") {
    ZStack {
        Backdrop(skin: .day, accent: Theme.brand)
        Text("Écran de jeu")
            .font(Theme.heading(20))
            .foregroundStyle(Skin.day.ink)
    }
    .partyTopBar(back: {}, exit: {}, confirmsExit: true)
    .environment(\.skin, .day)
    .preferredColorScheme(.light)
}

#Preview("Barre — nuit, premier écran") {
    ZStack {
        Backdrop(skin: .night, accent: Theme.brand)
        Text("Écran de jeu")
            .font(Theme.heading(20))
            .foregroundStyle(Skin.night.ink)
    }
    .partyTopBar(exit: {})
    .environment(\.skin, .night)
    .preferredColorScheme(.dark)
}
#endif
