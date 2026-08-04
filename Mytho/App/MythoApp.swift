import SwiftUI
import UIKit

@main
struct MythoApp: App {
    @StateObject private var session = GameSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                // Le téléphone circule autour de la table et reste posé pendant
                // les discussions : sans ça, l'écran se verrouille en pleine manche.
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        }
    }
}

/// Aiguillage unique de l'app : la phase du moteur décide de l'écran affiché.
/// Une seule source de vérité, donc aucun état de navigation à resynchroniser.
struct RootView: View {
    @EnvironmentObject private var session: GameSession
    @State private var confirmQuit = false
    /// Nul tant qu'aucun jeu n'est choisi : l'app s'ouvre sur le catalogue.
    @State private var selectedGameID: String?

    var body: some View {
        ZStack {
            Backdrop(skin: currentSkin, accent: Theme.accent(for: session.engine?.phase))

            Group {
                if let engine = session.engine {
                    gameScreen(for: engine)
                } else if selectedGameID == GameRegistry.undercoverID {
                    SetupView()
                        .transition(.forward)
                } else {
                    // Repli sur le catalogue, jamais sur Undercover : le jour où
                    // un autre jeu devient jouable, le choisir ne doit pas
                    // lancer silencieusement celui-ci.
                    GameHubView { game in selectedGameID = game.id }
                        .transition(.forward)
                }
            }
            .animation(Theme.spring, value: transitionKey)
            // Barre réservée en haut plutôt qu'un bouton en surimpression : sinon
            // elle recouvrirait la barre de progression de la distribution.
            .safeAreaInset(edge: .top, spacing: 0) {
                if let engine = session.engine {
                    if !engine.isFinished {
                        HStack(spacing: 8) {
                            quitButton
                            if session.canGoBack { backButton }
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                    }
                } else if selectedGameID == GameRegistry.undercoverID {
                    HStack(spacing: 8) {
                        gamesButton
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
            }

            if confirmQuit {
                QuitConfirmOverlay(
                    onQuit: {
                        confirmQuit = false
                        session.backToSetup()
                    },
                    onCancel: { confirmQuit = false }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .environment(\.skin, currentSkin)
        .preferredColorScheme(currentSkin.colorScheme)
        .animation(Theme.snap, value: confirmQuit)
        .statusBarHidden(session.engine != nil)
        .persistentSystemOverlays(session.engine != nil ? .hidden : .automatic)
    }


    /// Le jour on discute (papier), la nuit on révèle (encre) : la peau suit
    /// la phase. Validé par Arthur le 4 août 2026 (reco mixte).
    private var currentSkin: Skin {
        switch session.engine?.phase {
        case nil, .describing, .voting:
            return .day
        case .dealing, .elimination, .avengerStrike, .mrWhiteGuess, .finished:
            return .night
        }
    }

    /// Sortie de secours : composition ratée, joueur qui s'en va, téléphone
    /// passé au mauvais moment. Libellée en toutes lettres : la croix seule
    /// ne disait pas ce qu'elle faisait.
    private var quitButton: some View {
        Button {
            Haptics.tap()
            confirmQuit = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .accessibilityHidden(true)
                Text("Quitter")
                    .font(Theme.caption(13))
            }
            .foregroundStyle(currentSkin.inkMuted)
            .padding(.horizontal, 13)
            .frame(height: Theme.touchTarget)
            .background(
                Capsule()
                    .fill(currentSkin.panel)
                    .overlay(Capsule().strokeBorder(currentSkin.outline, lineWidth: 2))
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel("Quitter la partie")
    }

    /// Retour au catalogue depuis les réglages : on n'a pas encore engagé de
    /// manche, changer d'avis ne doit rien coûter.
    private var gamesButton: some View {
        Button {
            Haptics.tap()
            selectedGameID = nil
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 12, weight: .bold))
                    .accessibilityHidden(true)
                Text("Jeux")
                    .font(Theme.caption(13))
            }
            .foregroundStyle(currentSkin.inkMuted)
            .padding(.horizontal, 13)
            .frame(height: Theme.touchTarget)
            .background(
                Capsule()
                    .fill(currentSkin.panel)
                    .overlay(Capsule().strokeBorder(currentSkin.outline, lineWidth: 2))
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel("Choisir un autre jeu")
    }

    /// Un pas en arrière : mauvais appui, joueur éliminé trop vite.
    private var backButton: some View {
        Button {
            Haptics.tap()
            withAnimation(Theme.spring) { session.goBack() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 12, weight: .bold))
                    .accessibilityHidden(true)
                Text("Retour")
                    .font(Theme.caption(13))
            }
            .foregroundStyle(currentSkin.inkMuted)
            .padding(.horizontal, 13)
            .frame(height: Theme.touchTarget)
            .background(
                Capsule()
                    .fill(currentSkin.panel)
                    .overlay(Capsule().strokeBorder(currentSkin.outline, lineWidth: 2))
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel("Revenir à l'étape précédente")
    }

    @ViewBuilder
    private func gameScreen(for engine: GameEngine) -> some View {
        switch engine.phase {
        case .dealing(let playerIndex):
            DealView(engine: engine, playerIndex: playerIndex)
                .id("deal-\(playerIndex)")
                .transition(.forward)

        case .describing(let round):
            DescribeView(engine: engine, round: round)
                .id("describe-\(round)")
                .transition(.forward)

        case .voting:
            VoteView(engine: engine)
                .transition(.forward)

        case .elimination(let playerIDs):
            EliminationView(engine: engine, playerIDs: playerIDs)
                .transition(.reveal)

        case .avengerStrike(let playerID):
            AvengerStrikeView(engine: engine, avengerID: playerID)
                .transition(.reveal)

        case .mrWhiteGuess(let playerID):
            MrWhiteGuessView(engine: engine, playerID: playerID)
                .transition(.reveal)

        case .finished(let outcome):
            ResultView(engine: engine, outcome: outcome)
                .transition(.reveal)
        }
    }

    /// Identifiant textuel de l'écran courant : sert de déclencheur d'animation.
    private var transitionKey: String {
        guard let phase = session.engine?.phase else {
            return selectedGameID == GameRegistry.undercoverID ? "setup" : "hub"
        }
        switch phase {
        case .dealing(let index): return "deal-\(index)"
        case .describing(let round): return "describe-\(round)"
        case .voting: return "vote"
        case .elimination(let ids): return "elim-\(ids.map(\.uuidString).joined())"
        case .avengerStrike(let id): return "avenger-\(id)"
        case .mrWhiteGuess(let id): return "white-\(id)"
        case .finished: return "result"
        }
    }
}

/// Confirmation de sortie : fond entièrement flouté pour que la question soit
/// le seul point net de l'écran, et un libellé qui dit exactement ce qui va
/// se passer.
private struct QuitConfirmOverlay: View {
    @Environment(\.skin) private var skin
    let onQuit: () -> Void
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
                    Text("Arrêter la partie ?")
                        .font(Theme.heading(21))
                        .foregroundStyle(skin.ink)
                    Text("La manche en cours sera abandonnée et vous reviendrez aux réglages de la partie. Le classement est conservé.")
                        .font(Theme.body(14))
                        .foregroundStyle(skin.inkMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 2) {
                    PrimaryButton(title: "Arrêter la partie", systemImage: "xmark", tint: Theme.crimson, action: onQuit)
                    GhostButton(title: "Continuer à jouer", action: onCancel)
                }
            }
            .padding(22)
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
