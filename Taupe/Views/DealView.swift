import SwiftUI

/// Distribution : chaque joueur prend le téléphone, pioche une carte face cachée
/// et découvre son mot. C'est le moment signature du jeu — l'animation de
/// retournement doit être irréprochable.
struct DealView: View {
    @EnvironmentObject private var session: GameSession
    let engine: GameEngine
    let playerIndex: Int

    private enum Step { case handoff, picking, revealed }
    @State private var step: Step = .handoff
    @State private var revealedRole: Role?
    @State private var pickedIndex: Int?
    @Namespace private var cardNamespace

    private var player: Player { engine.players[playerIndex] }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 6)

            Spacer(minLength: 0)

            Group {
                switch step {
                case .handoff: handoff
                case .picking: picking
                case .revealed: revealed
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 12)
        .onAppear { Haptics.prepare() }
    }

    // MARK: Progression

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surface)
                    Capsule()
                        .fill(Theme.brand)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)

            Text("Carte \(playerIndex + 1) sur \(engine.players.count)")
                .font(Theme.caption(12))
                .foregroundStyle(Theme.inkFaint)
        }
        .animation(Theme.spring, value: progress)
    }

    private var progress: CGFloat {
        CGFloat(playerIndex) / CGFloat(max(1, engine.players.count))
    }

    // MARK: Passage du téléphone

    private var handoff: some View {
        VStack(spacing: 26) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.brandLight)

            VStack(spacing: 8) {
                Text("Passe le téléphone à")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.inkMuted)
                Text(player.name)
                    .font(Theme.title(34))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
            }

            PrimaryButton(title: "Je suis \(player.name)", systemImage: "hand.raised.fill") {
                withAnimation(Theme.spring) { step = .picking }
            }
            .padding(.horizontal, Theme.gutter)
        }
        .padding(.horizontal, Theme.gutter)
        // Glissement plutôt que fondu : deux fondus superposés au même endroit
        // donnaient un chevauchement fantôme des deux écrans (constaté sur les
        // captures du 3 août 2026).
        .transition(.forward)
    }

    // MARK: Pioche

    private var picking: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                PhasePill(text: "Pioche")
                Text("Choisis une carte")
                    .font(Theme.heading(22))
                    .foregroundStyle(Theme.ink)
                Text("Personne ne sait ce qu'elle contient.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkMuted)
            }

            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(engine.deck.indices, id: \.self) { index in
                    CardBack(
                        index: index,
                        isTaken: engine.deck[index] == nil,
                        namespace: cardNamespace
                    ) {
                        pick(index)
                    }
                }
            }
            .padding(.horizontal, Theme.gutter)
        }
        .transition(.forward)
    }

    private var gridColumns: [GridItem] {
        let count = engine.players.count
        let columns = count <= 6 ? 3 : (count <= 12 ? 4 : 5)
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }

    private func pick(_ index: Int) {
        guard revealedRole == nil, let role = session.pickCard(at: index) else { return }
        Haptics.impact(.rigid)
        pickedIndex = index
        revealedRole = role
        withAnimation(Theme.flip) { step = .revealed }
    }

    // MARK: Révélation

    private var revealed: some View {
        VStack(spacing: 24) {
            if let role = revealedRole, let pickedIndex {
                WordCard(
                    role: role,
                    word: player.word(civilianWord: engine.civilianWord, undercoverWord: engine.undercoverWord),
                    showRole: engine.config.easyMode,
                    cardIndex: pickedIndex,
                    namespace: cardNamespace
                )
                .padding(.horizontal, 44)
            }

            VStack(spacing: 10) {
                Text("Retiens-le, puis passe au suivant.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkMuted)

                PrimaryButton(title: "C'est mémorisé", systemImage: "checkmark") {
                    session.advanceDealing()
                }
                .padding(.horizontal, Theme.gutter)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Dos de carte

/// Une carte face cachée dans le paquet. Un léger décalage d'angle par carte
/// donne l'impression d'un vrai paquet posé sur la table.
private struct CardBack: View {
    let index: Int
    let isTaken: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    /// Inclinaison déterministe : la même carte penche toujours pareil.
    private var tilt: Double {
        let pattern = [-2.4, 1.8, -1.1, 2.6, -0.6, 1.3]
        return pattern[index % pattern.count]
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isTaken
                                ? [Theme.surface, Theme.surface]
                                : [Theme.brand, Theme.brand.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isTaken ? Theme.hairline : Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(isTaken ? 0 : 0.32), radius: 8, y: 4)

                Image(systemName: isTaken ? "checkmark" : "questionmark")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(isTaken ? Theme.inkFaint : .white.opacity(0.9))
            }
            .aspectRatio(Theme.cardRatio, contentMode: .fit)
            .rotationEffect(.degrees(isTaken ? 0 : tilt))
            .matchedGeometryEffect(id: "card-\(index)", in: namespace, isSource: true)
        }
        .buttonStyle(PressedStyle())
        .disabled(isTaken)
        .accessibilityLabel(isTaken ? "Carte déjà prise" : "Carte face cachée numéro \(index + 1)")
    }
}

// MARK: - Carte révélée

/// La carte retournée, plein cadre. Le retournement 3D part du dos violet et
/// bascule sur la face claire portant le mot.
private struct WordCard: View {
    let role: Role
    let word: String?
    let showRole: Bool
    let cardIndex: Int
    let namespace: Namespace.ID

    @State private var flipped = false

    var body: some View {
        ZStack {
            back.opacity(flipped ? 0 : 1)
            front.opacity(flipped ? 1 : 0)
        }
        .aspectRatio(Theme.cardRatio, contentMode: .fit)
        .rotation3DEffect(
            .degrees(flipped ? 0 : -180),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.45
        )
        .matchedGeometryEffect(id: "card-\(cardIndex)", in: namespace, isSource: false)
        .onAppear {
            withAnimation(Theme.flip) { flipped = true }
        }
    }

    private var back: some View {
        RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
            .fill(Theme.brand)
            .overlay(
                Image(systemName: "questionmark")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            )
            // Sans ce miroir, la face arrière apparaîtrait inversée pendant la bascule.
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    }

    private var front: some View {
        RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
            .fill(Color.white)
            .overlay(
                VStack(spacing: 14) {
                    if showRole {
                        RoleBadge(role: role, compact: true)
                    }

                    if let word {
                        Text(word)
                            .font(Theme.title(30))
                            .foregroundStyle(Theme.night)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(3)
                            .padding(.horizontal, 18)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: Role.mrWhite.symbol)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(Theme.amber)
                            Text("Aucun mot")
                                .font(Theme.title(26))
                                .foregroundStyle(Theme.night)
                            Text("Tu es Mr. White.\nÉcoute, déduis, improvise.")
                                .font(Theme.body(14))
                                .foregroundStyle(Theme.night.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 18)
                    }
                }
            )
            .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
    }
}
