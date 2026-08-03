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
            Backdrop(accent: Theme.accent(for: session.engine?.phase))

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
            // elle recouvrirait la barre de progression de la distribution.
            .safeAreaInset(edge: .top, spacing: 0) {
                if let engine = session.engine, !engine.isFinished {
                    HStack(spacing: 8) {
                        quitButton
                        if session.canGoBack { backButton }
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
        .animation(Theme.snap, value: confirmQuit)
        .statusBarHidden(session.engine != nil)
        .persistentSystemOverlays(session.engine != nil ? .hidden : .automatic)
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
            .foregroundStyle(Theme.inkMuted)
            .padding(.horizontal, 13)
            .frame(height: Theme.touchTarget)
            .background(Capsule().fill(Theme.surface))
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel("Quitter la partie")
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
            .foregroundStyle(Theme.inkMuted)
            .padding(.horizontal, 13)
            .frame(height: Theme.touchTarget)
            .background(Capsule().fill(Theme.surface))
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

/// Confirmation de sortie : fond entièrement flouté pour que la question soit
/// le seul point net de l'écran, et un libellé qui dit exactement ce qui va
/// se passer.
private struct QuitConfirmOverlay: View {
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
                        .foregroundStyle(Theme.ink)
                    Text("La manche en cours sera abandonnée et vous reviendrez au menu principal. Le classement est conservé.")
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.inkMuted)
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
                    .fill(Theme.night)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30, y: 14)
            )
            .padding(.horizontal, 34)
        }
        .accessibilityAddTraits(.isModal)
    }
}
