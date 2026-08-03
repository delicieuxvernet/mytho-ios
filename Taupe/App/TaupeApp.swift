import SwiftUI
import UIKit

@main
struct TaupeApp: App {
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
        }
        .statusBarHidden(session.engine != nil)
        .persistentSystemOverlays(session.engine != nil ? .hidden : .automatic)
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

        case .elimination(let playerID):
            EliminationView(engine: engine, playerID: playerID)
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
        case .elimination(let id): return "elim-\(id)"
        case .mrWhiteGuess(let id): return "white-\(id)"
        case .finished: return "result"
        }
    }
}
