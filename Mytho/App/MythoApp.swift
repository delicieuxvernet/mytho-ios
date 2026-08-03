import SwiftUI
import UIKit

@main
struct MythoApp: App {
    @StateObject private var session = GameSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
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

    var body: some View {
        ZStack {
            Backdrop()

            Group {
                if let engine = session.engine {
                    gameScreen(for: engine)
                } else {
                    SetupView()
                        .transition(.forward)
                }
            }
            .animation(Theme.spring, value: transitionKey)
            // Barre réservée en haut plutôt qu'un bouton en surimpression : sinon
            // il recouvrirait la barre de progression de la distribution.
            .safeAreaInset(edge: .top, spacing: 0) {
                if let engine = session.engine, !engine.isFinished {
                    HStack {
                        quitButton
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .statusBarHidden(session.engine != nil)
        .persistentSystemOverlays(session.engine != nil ? .hidden : .automatic)
        .confirmationDialog(
            "Abandonner la manche en cours ?",
            isPresented: $confirmQuit,
            titleVisibility: .visible
        ) {
            Button("Abandonner", role: .destructive) { session.backToSetup() }
            Button("Continuer à jouer", role: .cancel) {}
        } message: {
            Text("Les mots et les rôles seront retirés. Le classement des manches précédentes est conservé.")
        }
    }

    /// Sortie de secours : composition ratée, joueur qui s'en va, téléphone
    /// passé au mauvais moment. Sans ça, la manche ne peut plus être quittée.
    private var quitButton: some View {
        Button {
            Haptics.tap()
            confirmQuit = true
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.inkMuted)
                .frame(width: Theme.touchTarget, height: Theme.touchTarget)
                .background(Circle().fill(Theme.surface))
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel("Abandonner la manche")
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
        guard let phase = session.engine?.phase else { return "setup" }
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
