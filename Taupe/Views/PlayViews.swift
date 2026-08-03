import SwiftUI

// MARK: - Description

/// Ordre de parole du tour. Chaque joueur décrit son mot, puis la table débat.
struct DescribeView: View {
    @EnvironmentObject private var session: GameSession
    let engine: GameEngine
    let round: Int

    @State private var currentSpeaker = 0

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                PhasePill(text: "Tour \(round)")
                Text("Décrivez votre mot")
                    .font(Theme.heading(24))
                    .foregroundStyle(Theme.ink)
                Text("Une phrase chacun, dans cet ordre. Ni trop précis, ni trop vague.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            .padding(.top, 10)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(engine.orderedSpeakers.enumerated()), id: \.element.id) { index, player in
                        SpeakerRow(
                            position: index + 1,
                            name: player.name,
                            isCurrent: index == currentSpeaker,
                            isDone: index < currentSpeaker,
                            isMime: player.id == engine.mimePlayerID
                        ) {
                            Haptics.tap()
                            withAnimation(Theme.spring) {
                                currentSpeaker = index < currentSpeaker ? index : index + 1
                            }
                        }
                    }

                    if engine.config.tableRules.contains(.ghosts),
                       engine.players.contains(where: { !$0.isAlive }) {
                        Label(
                            "Les fantômes participent aux discussions et aux votes.",
                            systemImage: TableRule.ghosts.symbol
                        )
                        .font(Theme.caption(13))
                        .foregroundStyle(Theme.inkMuted)
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.bottom, 12)
            }

            PrimaryButton(title: "Passer au vote", systemImage: "hand.raised.fill") {
                session.startVote()
            }
            .padding(.horizontal, Theme.gutter)
        }
        .padding(.bottom, 12)
    }
}

/// Ligne d'ordre de parole. Un appui coche le joueur qui vient de parler.
private struct SpeakerRow: View {
    let position: Int
    let name: String
    let isCurrent: Bool
    let isDone: Bool
    var isMime: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isDone ? Theme.mint.opacity(0.22) : (isCurrent ? Theme.brand : Theme.surfaceStrong))
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Theme.mint)
                    } else {
                        Text("\(position)")
                            .font(Theme.heading(15))
                            .foregroundStyle(isCurrent ? .white : Theme.inkMuted)
                    }
                }
                .frame(width: 34, height: 34)

                Text(name)
                    .font(Theme.body(17))
                    .foregroundStyle(isDone ? Theme.inkFaint : Theme.ink)
                    .strikethrough(isDone, color: Theme.inkFaint)
                    .lineLimit(1)

                Spacer(minLength: 6)

                if isMime {
                    HStack(spacing: 4) {
                        Image(systemName: TableRule.mime.symbol)
                            .font(.system(size: 11, weight: .bold))
                            .accessibilityHidden(true)
                        Text("mime")
                            .font(Theme.caption(12))
                    }
                    .foregroundStyle(Theme.amber)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.amber.opacity(0.16)))
                }

                if isCurrent {
                    Text("à toi")
                        .font(Theme.caption(12))
                        .foregroundStyle(Theme.brandLight)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(isCurrent ? Theme.surfaceStrong : Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(isCurrent ? Theme.brandLight.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel("\(position). \(name)")
        .accessibilityValue(isDone ? "a parlé" : (isCurrent ? "à son tour" : "en attente"))
    }
}

// MARK: - Vote

/// Le groupe désigne le joueur à éliminer. Le décompte se fait à la table ;
/// l'app n'enregistre que le verdict.
struct VoteView: View {
    @EnvironmentObject private var session: GameSession
    let engine: GameEngine

    @State private var pendingID: UUID?

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                PhasePill(text: "Vote", tint: Theme.crimson)
                Text("Qui éliminez-vous ?")
                    .font(Theme.heading(24))
                    .foregroundStyle(Theme.ink)
                Text("Touchez le joueur désigné par la majorité.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkMuted)
            }
            .padding(.top, 10)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(engine.alivePlayers) { player in
                        VoteCard(name: player.name, isPending: pendingID == player.id) {
                            Haptics.warning()
                            withAnimation(Theme.snap) { pendingID = player.id }
                        }
                    }
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.bottom, 12)
            }

            if engine.config.specialRoles.contains(.justice) {
                Label(
                    "Égalité des votes ? La Déesse de la justice se révèle et tranche.",
                    systemImage: SpecialRole.justice.symbol
                )
                .font(Theme.caption(13))
                .foregroundStyle(Theme.inkMuted)
                .padding(.horizontal, Theme.gutter)
            }

            PrimaryButton(
                title: pendingID == nil ? "Choisissez un joueur" : "Éliminer",
                systemImage: "xmark.circle.fill",
                tint: Theme.crimson,
                isEnabled: pendingID != nil
            ) {
                if let pendingID { session.eliminate(playerID: pendingID) }
            }
            .padding(.horizontal, Theme.gutter)
        }
        .padding(.bottom, 12)
    }
}

private struct VoteCard: View {
    let name: String
    let isPending: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isPending ? Theme.crimson : Theme.inkMuted)
                Text(name)
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(isPending ? Theme.crimson.opacity(0.18) : Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(isPending ? Theme.crimson : Theme.hairline, lineWidth: isPending ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel(name)
        .accessibilityAddTraits(isPending ? [.isSelected] : [])
    }
}

// MARK: - Révélation d'élimination

/// Les rôles des joueurs tombés, dévoilés d'un coup. Plusieurs à la fois quand
/// les Amoureux ou la Vengeuse entraînent quelqu'un dans leur chute.
struct EliminationView: View {
    @EnvironmentObject private var session: GameSession
    let engine: GameEngine
    let playerIDs: [UUID]

    @State private var appeared = false

    private var fallen: [Player] { playerIDs.compactMap { engine.player(id: $0) } }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 26) {
                ForEach(fallen) { player in
                    reveal(player, big: fallen.count == 1)
                }

                if fallen.count > 1 {
                    HStack(spacing: 6) {
                        Image(systemName: SpecialRole.lovers.symbol)
                            .font(.system(size: 12, weight: .bold))
                            .accessibilityHidden(true)
                        Text(cascadeExplanation)
                            .font(Theme.caption(13))
                    }
                    .foregroundStyle(Theme.inkMuted)
                }
            }

            Spacer()

            PrimaryButton(title: "Continuer", systemImage: "arrow.right") {
                session.resolveElimination()
            }
            .padding(.horizontal, Theme.gutter)
        }
        .padding(.bottom, 12)
        .onAppear {
            Haptics.impact(.heavy)
            withAnimation(Theme.flip) { appeared = true }
        }
    }

    private var cascadeExplanation: String {
        fallen.contains { $0.specialRole == .lovers }
            ? "Les Amoureux tombent ensemble."
            : "Emporté par la Vengeuse."
    }

    @ViewBuilder
    private func reveal(_ player: Player, big: Bool) -> some View {
        if let role = player.role {
            VStack(spacing: big ? 18 : 10) {
                ZStack {
                    Circle()
                        .fill(Theme.color(for: role).opacity(0.16))
                        .frame(width: big ? 132 : 84, height: big ? 132 : 84)
                        .scaleEffect(appeared ? 1 : 0.6)
                    Image(systemName: role.symbol)
                        .font(.system(size: big ? 46 : 30, weight: .bold))
                        .foregroundStyle(Theme.color(for: role))
                        .scaleEffect(appeared ? 1 : 0.4)
                }

                VStack(spacing: big ? 6 : 3) {
                    Text(player.name)
                        .font(Theme.title(big ? 32 : 23))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                    Text("était")
                        .font(Theme.body(big ? 15 : 13))
                        .foregroundStyle(Theme.inkMuted)
                    Text(role.displayName)
                        .font(Theme.title(big ? 28 : 20))
                        .foregroundStyle(Theme.color(for: role))
                }
                .opacity(appeared ? 1 : 0)
            }
        }
    }
}

// MARK: - Frappe de la Vengeuse

/// La Vengeuse éliminée désigne le joueur qu'elle emmène avec elle.
struct AvengerStrikeView: View {
    @EnvironmentObject private var session: GameSession
    let engine: GameEngine
    let avengerID: UUID

    @State private var pendingID: UUID?

    private var avengerName: String { engine.player(id: avengerID)?.name ?? "La Vengeuse" }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                PhasePill(text: "Vengeance", tint: Theme.crimson)
                Text("\(avengerName) frappe en tombant")
                    .font(Theme.heading(23))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                Text("La Vengeuse emmène un joueur avec elle. À elle de choisir.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }
            .padding(.top, 10)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(engine.alivePlayers) { player in
                        VoteCard(name: player.name, isPending: pendingID == player.id) {
                            Haptics.warning()
                            withAnimation(Theme.snap) { pendingID = player.id }
                        }
                    }
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.bottom, 12)
            }

            PrimaryButton(
                title: pendingID == nil ? "Choisis ta cible" : "Emmener ce joueur",
                systemImage: "bolt.fill",
                tint: Theme.crimson,
                isEnabled: pendingID != nil
            ) {
                if let pendingID { session.avengerStrikes(playerID: pendingID) }
            }
            .padding(.horizontal, Theme.gutter)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Dernière chance de Mr. White

/// Mr. White éliminé propose le mot des civils. S'il vise juste, il gagne seul.
struct MrWhiteGuessView: View {
    @EnvironmentObject private var session: GameSession
    let engine: GameEngine
    let playerID: UUID

    @State private var guess = ""
    @FocusState private var focused: Bool

    private var name: String { engine.player(id: playerID)?.name ?? "Mr. White" }

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)

            VStack(spacing: 14) {
                Image(systemName: Role.mrWhite.symbol)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.amber)

                PhasePill(text: "Dernière chance", tint: Theme.amber)

                Text("\(name) était Mr. White")
                    .font(Theme.heading(23))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                Text("S'il devine le mot des civils, il gagne la manche à lui seul.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }

            TextField("Le mot des civils", text: $guess)
                .font(Theme.heading(20))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focused)
                .onSubmit(submit)
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .fill(Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                .strokeBorder(Theme.amber.opacity(0.5), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, Theme.gutter)
                .accessibilityLabel("Mot proposé par Mr. White")

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                PrimaryButton(
                    title: "Valider",
                    systemImage: "checkmark",
                    tint: Theme.amber,
                    isEnabled: !guess.trimmingCharacters(in: .whitespaces).isEmpty,
                    action: submit
                )
                GhostButton(title: "Il passe son tour") {
                    focused = false
                    session.submitMrWhiteGuess("")
                }
            }
            .padding(.horizontal, Theme.gutter)
        }
        .padding(.bottom, 12)
        .onAppear { focused = true }
    }

    private func submit() {
        focused = false
        if !session.submitMrWhiteGuess(guess) { Haptics.warning() }
    }
}
