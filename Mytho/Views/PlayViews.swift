import SwiftUI

// MARK: - Description

/// Ordre de parole du tour. Le joueur en cours est sous le projecteur, avec un
/// chrono : ça rythme la table et personne ne se demande à qui c'est.
struct DescribeView: View {
    @Environment(\.skin) private var skin

    @EnvironmentObject private var session: GameSession
    let engine: GameEngine
    let round: Int

    @State private var currentSpeaker = 0
    @State private var timeLeft = 0
    @State private var timeUp = false

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timerSeconds: Int { engine.config.describeTimerSeconds }
    private var speakers: [Player] { engine.orderedSpeakers }
    private var everyoneSpoke: Bool { currentSpeaker >= speakers.count }

    var body: some View {
        VStack(spacing: 14) {
            PhasePill(text: "Tour \(round)", tint: Theme.sky, darkText: true)
                .padding(.top, 6)

            if everyoneSpoke {
                doneCard
            } else {
                spotlightCard
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(speakers.enumerated()), id: \.element.id) { index, player in
                        SpeakerRow(
                            position: index + 1,
                            name: player.name,
                            isCurrent: index == currentSpeaker,
                            isDone: index < currentSpeaker,
                            isMime: player.id == engine.mimePlayerID,
                            table: engine.players.map(\.name)
                        ) {
                            Haptics.tap()
                            withAnimation(Theme.spring) { jump(to: index) }
                        }
                    }

                    if engine.config.tableRules.contains(.ghosts),
                       engine.players.contains(where: { !$0.isAlive }) {
                        Label(
                            "Les fantômes participent aux discussions et aux votes.",
                            systemImage: TableRule.ghosts.symbol
                        )
                        .font(Theme.caption(13))
                        .foregroundStyle(skin.inkMuted)
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.bottom, 12)
            }

            if everyoneSpoke {
                PrimaryButton(title: "Passer au vote", systemImage: "hand.raised.fill") {
                    session.startVote()
                }
                .padding(.horizontal, Theme.gutter)
            } else {
                VStack(spacing: 2) {
                    PrimaryButton(title: "Joueur suivant", systemImage: "arrow.right", tint: Theme.sky, foreground: Theme.nightDeep) {
                        withAnimation(Theme.spring) { jump(to: currentSpeaker + 1) }
                    }
                    GhostButton(title: "Passer directement au vote", systemImage: "hand.raised.fill") {
                        session.startVote()
                    }
                }
                .padding(.horizontal, Theme.gutter)
            }
        }
        .padding(.bottom, 12)
        .onAppear { resetTimer() }
        .onReceive(clock) { _ in tick() }
    }

    // MARK: Projecteur

    private var currentName: String {
        speakers.indices.contains(currentSpeaker) ? speakers[currentSpeaker].name : ""
    }

    private var isMimeTurn: Bool {
        speakers.indices.contains(currentSpeaker) && speakers[currentSpeaker].id == engine.mimePlayerID
    }

    private var spotlightCard: some View {
        Panel(padding: 18) {
            HStack(spacing: 16) {
                AvatarView(name: currentName, size: 52, table: engine.players.map(\.name))
                VStack(alignment: .leading, spacing: 4) {
                    Text("C'est à")
                        .font(Theme.body(14))
                        .foregroundStyle(skin.inkMuted)
                    Text(currentName)
                        .font(Theme.title(27))
                        .foregroundStyle(skin.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(isMimeTurn ? "de mimer son mot, sans un bruit." : "de décrire son mot en une phrase.")
                        .font(Theme.body(14))
                        .foregroundStyle(timeUp ? Theme.crimson : skin.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    if timeUp {
                        Label("Temps écoulé !", systemImage: "hourglass.bottomhalf.filled")
                            .font(Theme.caption(13))
                            .foregroundStyle(Theme.crimson)
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 8)

                if timerSeconds > 0 {
                    countdownRing
                }
            }
        }
        .padding(.horizontal, Theme.gutter)
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(skin.panelStrong, lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(timeLeft) / CGFloat(max(1, timerSeconds)))
                .stroke(
                    timeUp ? Theme.crimson : (timeLeft <= 5 ? Theme.amber : Theme.sky),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeLeft)

            Text(timeUp ? "0" : "\(timeLeft)")
                .font(Theme.heading(22))
                .foregroundStyle(timeUp ? Theme.crimson : skin.ink)
                .contentTransition(.numericText(countsDown: true))
        }
        .frame(width: 66, height: 66)
        .accessibilityLabel("Temps restant : \(timeLeft) secondes")
    }

    private var doneCard: some View {
        Panel(padding: 18) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.mint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tout le monde a parlé")
                        .font(Theme.heading(18))
                        .foregroundStyle(skin.ink)
                    Text("Débattez à voix haute, puis passez au vote.")
                        .font(Theme.body(14))
                        .foregroundStyle(skin.inkMuted)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Theme.gutter)
    }

    // MARK: Chrono

    private func jump(to index: Int) {
        currentSpeaker = min(index, speakers.count)
        resetTimer()
    }

    private func resetTimer() {
        timeLeft = timerSeconds
        timeUp = false
    }

    private func tick() {
        guard timerSeconds > 0, !timeUp, !everyoneSpoke else { return }
        if timeLeft > 1 {
            timeLeft -= 1
            if timeLeft <= 5 { Haptics.tap() }
        } else {
            timeLeft = 0
            timeUp = true
            Haptics.warning()
        }
    }
}

/// Ligne d'ordre de parole. Un appui coche le joueur qui vient de parler.
private struct SpeakerRow: View {
    @Environment(\.skin) private var skin

    let position: Int
    let name: String
    let isCurrent: Bool
    let isDone: Bool
    var isMime: Bool = false
    var table: [String] = []
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(name: name, size: 34, dimmed: isDone, table: table)
                    if isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Theme.mint)
                            .background(Circle().fill(Theme.night))
                            .accessibilityHidden(true)
                    }
                }

                Text(name)
                    .font(Theme.body(17))
                    .foregroundStyle(isDone ? skin.inkFaint : skin.ink)
                    .strikethrough(isDone, color: skin.inkFaint)
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
                        .foregroundStyle(Theme.sky)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(isCurrent ? skin.panelStrong : skin.panelSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(isCurrent ? Theme.sky.opacity(0.6) : Color.clear, lineWidth: 1.5)
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
    @Environment(\.skin) private var skin

    @EnvironmentObject private var session: GameSession
    let engine: GameEngine

    @State private var pendingID: UUID?

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                PhasePill(text: "Vote", tint: Theme.crimson)
                Text("Qui éliminez-vous ?")
                    .font(Theme.heading(24))
                    .foregroundStyle(skin.ink)
                Text("Touchez le joueur désigné par la majorité.")
                    .font(Theme.body(14))
                    .foregroundStyle(skin.inkMuted)
            }
            .padding(.top, 10)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(engine.alivePlayers) { player in
                        VoteCard(name: player.name, isPending: pendingID == player.id, table: engine.players.map(\.name)) {
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
                .foregroundStyle(skin.inkMuted)
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
    @Environment(\.skin) private var skin

    let name: String
    let isPending: Bool
    var table: [String] = []
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AvatarView(name: name, size: 40, table: table)
                    .overlay(
                        Circle().strokeBorder(isPending ? Theme.crimson : .clear, lineWidth: 2.5)
                    )
                Text(name)
                    .font(Theme.body(16))
                    .foregroundStyle(skin.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(isPending ? Theme.crimson.opacity(0.18) : skin.panelSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(isPending ? Theme.crimson : skin.hairline, lineWidth: isPending ? 2 : 1)
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
    @Environment(\.skin) private var skin

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
                    .foregroundStyle(skin.inkMuted)
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
                    if role.isInfiltrator {
                        ReptileEyeView(size: big ? 132 : 84, blinking: big)
                    } else {
                        Circle()
                            .fill(Theme.color(for: role).opacity(0.16))
                            .frame(width: big ? 132 : 84, height: big ? 132 : 84)
                        AvatarView(name: player.name, size: big ? 92 : 58, table: engine.players.map(\.name))
                    }
                }
                .scaleEffect(appeared ? 1 : 0.6)

                VStack(spacing: big ? 6 : 3) {
                    Text(player.name)
                        .font(Theme.title(big ? 32 : 23))
                        .foregroundStyle(skin.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                    Text("était")
                        .font(Theme.body(big ? 15 : 13))
                        .foregroundStyle(skin.inkMuted)
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
    @Environment(\.skin) private var skin

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
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                Text("La Vengeuse emmène un joueur avec elle. À elle de choisir.")
                    .font(Theme.body(14))
                    .foregroundStyle(skin.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }
            .padding(.top, 10)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(engine.alivePlayers) { player in
                        VoteCard(name: player.name, isPending: pendingID == player.id, table: engine.players.map(\.name)) {
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
    @Environment(\.skin) private var skin

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

                PhasePill(text: "Dernière chance", tint: Theme.amber, darkText: true)

                Text("\(name) était Mr. White")
                    .font(Theme.heading(23))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                Text("S'il devine le mot des civils, il gagne la manche à lui seul.")
                    .font(Theme.body(14))
                    .foregroundStyle(skin.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }

            TextField("Le mot des civils", text: $guess)
                .font(Theme.heading(20))
                .foregroundStyle(skin.ink)
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
                        .fill(skin.panelSoft)
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
