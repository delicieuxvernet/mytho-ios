import SwiftUI

/// L'aiguillage d'un jeu de la soirée (spec §2.7) : les prénoms si le jeu les
/// réclame, puis l'écran du jeu, puis retour au catalogue.
///
/// Volontairement mince. Chaque jeu porte déjà ses réglages, sa partie **et**
/// ses résultats — « Rejouer » et « Changer de jeu » sont sur son écran de fin.
/// Ce flux ne fait donc que deux choses qu'aucun jeu ne peut faire seul :
/// ouvrir « Qui joue ? » avant un jeu qui exige des prénoms, et donner à
/// « Changer de jeu » une destination réelle, roster et points conservés.
///
/// Undercover n'y passe pas : sa navigation est pilotée par la phase de son
/// moteur depuis `RootView`, et sa v1.0 est en validation chez Apple.
struct PartyGameFlow: View {

    let game: GameEntry
    /// Les prénoms de la soirée. Détenus par l'app et non par ce flux : passer
    /// d'un jeu à l'autre ne doit pas faire re-saisir la table (§2.2).
    @ObservedObject var roster: RosterStore
    @ObservedObject var settings: AppSettings
    /// Retour au catalogue.
    let onExit: () -> Void

    /// L'empilement de la soirée (§2.7). Une seule destination — l'écran du
    /// jeu —, et ce fichier est le seul à l'alimenter : la navigation reste un
    /// enchaînement linéaire, jamais une arborescence.
    @State private var path: [Route] = []

    /// Peau jour : on est autour de la table, personne ne cache rien. Les
    /// moments secrets appartiennent aux jeux, qui basculent en peau nuit chez
    /// eux. Calculée et non stockée, pour ne pas peser sur l'initialiseur
    /// mémorisé que `RootView` appelle.
    private var paperSkin: Skin { .day }

    // MARK: - Corps

    var body: some View {
        NavigationStack(path: $path) {
            entryScreen
                .navigationDestination(for: Route.self) { _ in
                    gameScreen
                }
        }
    }

    /// Les prénoms d'abord quand le jeu les réclame : ses réglages savent dire
    /// qu'il en manque, ils ne savent pas les saisir.
    ///
    /// La condition tient à `game.needsNames`, constant pour toute la durée du
    /// flux. Si elle dépendait du nombre de joueurs, un départ en cours de
    /// partie remplacerait la racine sous les pieds de l'écran empilé.
    @ViewBuilder
    private var entryScreen: some View {
        if game.needsNames {
            rosterScreen
        } else {
            gameScreen
        }
    }

    // MARK: - Qui joue ?

    private var rosterScreen: some View {
        RosterView(
            store: roster,
            // Le plancher affiché sur la tuile est celui du moteur : lancer en
            // dessous n'ouvrirait qu'un écran de réglages qui refuse de démarrer.
            minimumPlayers: game.players.lowerBound,
            // Pas « C'est parti » : l'écran suivant est celui des réglages du
            // jeu, avec son propre bouton de lancement. Deux départs d'affilée
            // font douter de celui qu'on vient d'appuyer.
            startTitle: "Continuer"
        ) {
            path = [.play(gameID: game.id)]
        }
        .safeAreaInset(edge: .top, spacing: 0) { rosterTopBar }
        // La barre système ferait doublon avec l'en-tête « Qui joue ? » et son
        // bandeau de lancement.
        .toolbar(.hidden, for: .navigationBar)
    }

    /// La seule sortie de l'écran des prénoms : sans elle, un jeu ouvert par
    /// erreur enfermerait la soirée sur « Qui joue ? ».
    private var rosterTopBar: some View {
        HStack(spacing: 8) {
            Button {
                Haptics.tap()
                leave()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .accessibilityHidden(true)
                    Text("Jeux")
                        .font(Theme.caption(13))
                }
                .foregroundStyle(paperSkin.ink)
                .padding(.horizontal, 13)
                .frame(height: Theme.touchTarget)
                .background(
                    Capsule()
                        .fill(paperSkin.panel)
                        .overlay(Capsule().strokeBorder(paperSkin.outline, lineWidth: 2))
                )
            }
            .buttonStyle(PressedStyle())
            .accessibilityLabel("Choisir un autre jeu")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Écran du jeu

    /// Le seul `switch` sur un identifiant de jeu de toute l'app. §2.1 l'interdit
    /// dans l'accueil ; sa place est ici, dans l'aiguillage : une vue ne se range
    /// pas dans un `GameEntry`, qui est `Hashable`. Ajouter un jeu reste donc
    /// une entrée au catalogue plus une ligne ici, et aucun écran existant à
    /// rouvrir.
    private var gameScreen: some View {
        Group {
            switch game.id {
            case GameRegistry.mostLikelyID:
                MostLikelyView(roster: roster, settings: settings, onExit: { leave() })
            case GameRegistry.wouldYouRatherID:
                WouldYouRatherView(roster: roster, settings: settings, onExit: { leave() })
            case GameRegistry.neverHaveIEverID:
                NeverHaveIEverView(roster: roster, settings: settings, onQuit: { leave() })
            default:
                missingScreen
            }
        }
        // Les jeux portent leur propre bandeau (« Jeux », « Quitter ») : la barre
        // système ferait doublon, et son geste de retour depuis le bord jetterait
        // une manche en cours — ou remontrerait un écran secret déjà lu (§2.3).
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Filet : un identifiant annoncé jouable au catalogue mais sans écran ici.
    /// La soirée doit pouvoir en sortir autrement qu'en tuant l'app.
    private var missingScreen: some View {
        ZStack {
            Backdrop(skin: paperSkin, accent: game.accent)

            VStack(spacing: 16) {
                Text("\(game.title) n'est pas encore jouable.")
                    .font(Theme.heading(20))
                    .foregroundStyle(paperSkin.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(
                    title: "Changer de jeu",
                    systemImage: "square.grid.2x2.fill",
                    action: { leave() }
                )
            }
            .padding(.horizontal, Theme.gutter)
        }
        .environment(\.skin, paperSkin)
        .preferredColorScheme(paperSkin.colorScheme)
    }

    // MARK: - Sortie

    /// La sortie unique du flux. Elle referme la fenêtre de manche avant de
    /// rendre la main : hors manche, retirer un joueur le supprime pour de bon
    /// au lieu de le laisser barré dans le roster du jeu suivant (§2.2).
    ///
    /// Les jeux la referment déjà de leur côté. La refermer deux fois ne coûte
    /// rien, l'oublier une seule fois se voit à l'écran d'après.
    private func leave() {
        roster.endRound()
        onExit()
    }
}

#if DEBUG
/// Roster et réglages jetables : une prévisualisation ne doit pas écrire dans
/// les réglages réels du simulateur.
private func flowPreviewRoster(_ names: [String], key: String) -> RosterStore {
    let store = RosterStore(
        defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard,
        storageKey: key
    )
    store.seed(names: names)
    return store
}

private func flowPreviewSettings() -> AppSettings {
    AppSettings(defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard)
}

/// Repli plutôt que `!` : une prévisualisation qui plante ne dit pas ce qui
/// manque, elle disparaît de Xcode sans un mot.
private func flowPreviewGame(_ id: String) -> GameEntry {
    GameRegistry.all.first { $0.id == id } ?? GameRegistry.all[0]
}

#Preview("Flux — prénoms requis") {
    PartyGameFlow(
        game: flowPreviewGame(GameRegistry.mostLikelyID),
        roster: flowPreviewRoster(["Léa", "Tom", "Nino"], key: "preview.flow.named"),
        settings: flowPreviewSettings(),
        onExit: {}
    )
}

#Preview("Flux — sans prénoms") {
    PartyGameFlow(
        game: flowPreviewGame(GameRegistry.wouldYouRatherID),
        roster: flowPreviewRoster([], key: "preview.flow.anonymous"),
        settings: flowPreviewSettings(),
        onExit: {}
    )
}
#endif
