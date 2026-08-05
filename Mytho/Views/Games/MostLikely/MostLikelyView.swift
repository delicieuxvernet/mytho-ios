import Foundation
import SwiftUI

/// Le plus susceptible de… (spec §3).
///
/// Une phrase, un décompte, tout le monde pointe du doigt, le plus désigné
/// marque. L'écran ne fait que trois choses : poser la carte, relever la
/// désignation, montrer le résultat — le reste est dans `MostLikelyEngine`.
///
/// La peau suit le moment : **jour** tant que la table discute (carte,
/// désignation, résultat), **nuit** dès qu'un secret circule (vote secret,
/// révélation finale).
struct MostLikelyView: View {

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Les prénoms de la soirée, partagés par tous les jeux : jamais re-saisis ici.
    @ObservedObject var roster: RosterStore
    @ObservedObject var settings: AppSettings
    /// Retour au catalogue. Les points de la soirée ne sont pas perdus pour
    /// autant : c'est l'appelant qui garde le `ScoreBoard` s'il le souhaite.
    var onExit: () -> Void = {}

    @State private var engine: MostLikelyEngine?
    @State private var options = MostLikelyEngine.Options()
    /// Désignations en cours de saisie : une, ou deux si « Ex æquo » est ouvert.
    @State private var picks: [UUID] = []
    @State private var allowsTie = false
    /// Index du temps de décompte affiché ; -1 avant le premier.
    @State private var countdownIndex = -1
    /// Pilote le remplissage des barres et l'apparition du prénom gagnant.
    @State private var resultRevealed = false
    @State private var confettiStart: Date?

    // MARK: Corps

    var body: some View {
        ZStack {
            Backdrop(skin: skin, accent: Theme.amber)

            content
                .animation(screenAnimation, value: phaseKey)
        }
        .environment(\.skin, skin)
        .preferredColorScheme(skin.colorScheme)
        // Quelqu'un part toujours en avance : la grille doit le refléter sans
        // que la manche en cours perde ses points (spec §3.6).
        .onChange(of: roster.participants) { _, updated in
            engine?.syncPlayers(updated)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let engine {
            switch engine.phase {
            case .card:
                cardScreen(engine).transition(transition)
            case .designation:
                designationScreen(engine).transition(transition)
            case .pass:
                passScreen(engine).transition(transition)
            case .ballot:
                ballotScreen(engine).transition(transition)
            case .result(let outcome):
                resultScreen(engine, outcome: outcome).transition(transition)
            case .finished:
                standingsScreen(engine).transition(transition)
            }
        } else {
            setupScreen.transition(transition)
        }
    }

    // MARK: - Réglages (spec §3.6)

    private var setupScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    setupHeader
                    packsPanel
                    roundsPanel
                    countingPanel
                    if !hasEnoughPlayers { notEnoughPlayersNotice }
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 6)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar(quitTitle: "Jeux") }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                if !hasEnoughPlayers {
                    Text("Il faut au moins \(MostLikelyEngine.minimumPlayers) joueurs pour que le vote ait un sens.")
                        .font(Theme.caption(13))
                        .foregroundStyle(skin.ink.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PrimaryButton(
                    title: "Commencer",
                    systemImage: "play.fill",
                    tint: Theme.amber,
                    foreground: Theme.night,
                    isEnabled: hasEnoughPlayers
                ) {
                    startGame()
                }
                .accessibilityIdentifier("most-likely-start")
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(bottomBarBackground)
        }
    }

    private var setupHeader: some View {
        VStack(spacing: 6) {
            Text("Le plus susceptible de…")
                .font(Theme.title(30))
                .foregroundStyle(skin.ink)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("Au décompte, tout le monde pointe du doigt. Le plus désigné marque un point.")
                .font(Theme.body(15))
                .foregroundStyle(skin.ink.opacity(0.75))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 2)
    }

    private var packsPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                panelTitle("Paquets", symbol: "rectangle.stack.fill")

                ForEach(MostLikelyPack.available(unlockedExtras: settings.adultContentUnlocked)) { pack in
                    OptionToggle(
                        title: "\(pack.name) · \(pack.cards.count) cartes",
                        subtitle: pack.subtitle,
                        isOn: packBinding(pack)
                    )
                }
            }
        }
    }

    private var roundsPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                panelTitle("Manches", symbol: "flag.checkered")

                ChipRow(
                    labels: MostLikelyEngine.RoundLimit.allCases.map(\.label),
                    selection: MostLikelyEngine.RoundLimit.allCases.firstIndex(of: options.limit) ?? 0,
                    accessibilityPrefix: "Nombre de manches"
                ) { index in
                    options.limit = MostLikelyEngine.RoundLimit.allCases[index]
                }
            }
        }
    }

    private var countingPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                panelTitle("Comptage", symbol: "hand.point.up.left.fill")

                OptionToggle(
                    title: "Vote secret",
                    subtitle: "Le téléphone circule, chacun désigne à l'abri des regards, révélation à la fin.",
                    isOn: Binding(
                        get: { options.counting == .secret },
                        set: { options.counting = $0 ? .secret : .quick }
                    )
                )
            }
        }
    }

    private var notEnoughPlayersNotice: some View {
        Panel {
            HStack(spacing: 10) {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(skin.ink)
                    .accessibilityHidden(true)

                Text("Ajoute des prénoms dans « Qui joue ? » avant de lancer.")
                    .font(Theme.body(14))
                    .foregroundStyle(skin.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Carte + décompte (spec §3.3 écran 1)

    private func cardScreen(_ engine: MostLikelyEngine) -> some View {
        VStack(spacing: 16) {
            PhasePill(text: roundLabel(engine), tint: Theme.amber, darkText: true)

            if engine.hasLoopedDeck {
                Text("Tu as fait le tour du paquet.")
                    .font(Theme.caption(12))
                    .foregroundStyle(skin.ink.opacity(0.75))
            }

            Spacer(minLength: 0)

            promptCard(engine)

            Spacer(minLength: 0)

            // En vote secret, personne ne pointe : décompter jusqu'à « Pointez »
            // annoncerait un geste qui n'aura pas lieu. Le téléphone part
            // directement en tournée.
            if engine.options.counting == .secret {
                PrimaryButton(
                    title: "Faire circuler",
                    systemImage: "arrow.triangle.2.circlepath",
                    tint: Theme.brand
                ) {
                    finishCardPhase()
                }
            } else {
                countdownDisplay

                Spacer(minLength: 0)

                GhostButton(title: "Passer le décompte", systemImage: "forward.fill") {
                    finishCardPhase()
                }
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.bottom, 6)
        .safeAreaInset(edge: .top, spacing: 0) { topBar(quitTitle: "Quitter") }
        .accessibilityIdentifier("most-likely-card")
        // `id:` plutôt qu'un simple `.task` : sans lui, une manche qui réutilise
        // la même vue ne relancerait jamais son décompte.
        .task(id: engine.roundNumber) { await runCountdown() }
    }

    private func promptCard(_ engine: MostLikelyEngine) -> some View {
        Panel(padding: 22) {
            VStack(spacing: 10) {
                Text("Le plus susceptible de…")
                    .font(Theme.caption(13))
                    .tracking(0.8)
                    .foregroundStyle(skin.ink.opacity(0.75))

                Text(engine.card.text)
                    .font(Theme.title(26))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        // Deux cartes ne se posent jamais pareil sur un vrai paquet ; l'angle est
        // figé au tirage, pas recalculé à chaque affichage.
        .rotationEffect(.degrees(reduceMotion ? 0 : engine.tilt))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Le plus susceptible de \(engine.card.text)")
    }

    private var countdownDisplay: some View {
        ZStack {
            if let step = MostLikelyCountdown.steps[safeIndex: countdownIndex] {
                Text(step.label)
                    .font(Theme.title(step.haptic == .heavy ? 44 : 68))
                    .foregroundStyle(skin.ink)
                    .id(countdownIndex)
                    .transition(countdownTransition)
            }
        }
        // Hauteur réservée : sans elle, la carte remonte et redescend à chaque
        // chiffre.
        .frame(height: 84)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MostLikelyCountdown.steps[safeIndex: countdownIndex]?.label ?? "")
    }

    // MARK: - Désignation (spec §3.3 écran 2)

    private func designationScreen(_ engine: MostLikelyEngine) -> some View {
        VStack(spacing: 12) {
            // Violet plein et non le violet clair : le blanc n'y tient que
            // 2,9:1 de contraste, sous la barre des 4,5:1 exigée en petit corps.
            PhasePill(text: "Qui ?", tint: Theme.brand)

            reminder(engine)

            nameGrid(engine)

            GhostButton(
                title: allowsTie ? "Une seule personne" : "Ex æquo",
                systemImage: allowsTie ? "person.fill" : "person.2.fill"
            ) {
                toggleTie()
            }

            PrimaryButton(
                title: "Valider",
                systemImage: "checkmark",
                tint: Theme.amber,
                foreground: Theme.night,
                isEnabled: !picks.isEmpty
            ) {
                validateDesignation()
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.bottom, 6)
        .safeAreaInset(edge: .top, spacing: 0) { topBar(quitTitle: "Quitter") }
        .accessibilityIdentifier("most-likely-grid")
    }

    // MARK: - Vote secret (spec §3.2)

    private func passScreen(_ engine: MostLikelyEngine) -> some View {
        Group {
            if let voter = engine.currentVoter {
                PassPhoneView(
                    name: voter.name,
                    table: roster.names,
                    instruction: "Personne ne regarde qui tu désignes."
                ) {
                    self.engine?.takePhone()
                }
                // Sans identité propre par joueur, `onAppear` ne se rejoue pas :
                // le passage suivant arriverait sans son retour haptique.
                .id(voter.id)
            }
        }
    }

    private func ballotScreen(_ engine: MostLikelyEngine) -> some View {
        VStack(spacing: 12) {
            PhasePill(text: ballotProgress(engine), tint: Theme.brand)

            reminder(engine)

            nameGrid(engine)

            PrimaryButton(
                title: "C'est mon choix",
                systemImage: "lock.fill",
                tint: Theme.brand,
                isEnabled: !picks.isEmpty
            ) {
                validateBallot()
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.vertical, 12)
        // Une révélation ne se rejoue pas : plus de retour, plus de geste de bord.
        .secretScreen()
        .accessibilityIdentifier("most-likely-ballot")
    }

    // MARK: - Résultat (spec §3.3 écran 3)

    private func resultScreen(_ engine: MostLikelyEngine, outcome: MostLikelyEngine.Outcome) -> some View {
        VStack(spacing: 14) {
            PhasePill(text: roundLabel(engine), tint: Theme.amber, darkText: true)

            reminder(engine)

            Spacer(minLength: 0)

            winnerBlock(engine, outcome: outcome)

            Spacer(minLength: 0)

            if engine.canUndo {
                GhostButton(title: "Corriger", systemImage: "arrow.uturn.backward") {
                    undo()
                }
            }

            if engine.totalRounds == nil {
                GhostButton(title: "Terminer la partie", systemImage: "flag.checkered") {
                    finishNow()
                }
            }

            PrimaryButton(
                title: engine.isLastRound ? "Voir le classement" : "Carte suivante",
                systemImage: engine.isLastRound ? "trophy.fill" : "arrow.right",
                tint: Theme.amber,
                foreground: Theme.night
            ) {
                nextRound()
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.bottom, 6)
        .safeAreaInset(edge: .top, spacing: 0) { topBar(quitTitle: "Quitter") }
        .accessibilityIdentifier("most-likely-result")
        .task(id: engine.roundNumber) { await revealResult() }
    }

    private func winnerBlock(_ engine: MostLikelyEngine, outcome: MostLikelyEngine.Outcome) -> some View {
        VStack(spacing: 14) {
            if outcome.winners.isEmpty {
                Text("Personne n'a été désigné")
                    .font(Theme.title(24))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 10) {
                    ForEach(outcome.winners, id: \.self) { id in
                        AvatarView(name: engine.name(for: id), size: 56, table: roster.names)
                    }
                }

                Text(outcome.winners.map { engine.name(for: $0) }.joined(separator: " & "))
                    .font(Theme.title(34))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)

                Text(scoreLine(engine, outcome: outcome))
                    .font(Theme.body(15))
                    .foregroundStyle(skin.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach(Array(bars(engine, outcome: outcome).enumerated()), id: \.element.id) { index, bar in
                    resultBar(bar, index: index)
                }
            }
            .padding(.top, 4)
        }
        // Le contenu de `.reveal` sans la plomberie d'une transition : le bloc est
        // déjà là, il se pose quand le résultat est lu.
        .scaleEffect(resultRevealed ? 1 : 0.86)
        .opacity(resultRevealed ? 1 : 0)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Theme.flip, value: resultRevealed)
        .accessibilityElement(children: .contain)
    }

    /// Une ligne de répartition. En vote secret elle porte un vrai décompte ;
    /// en mode rapide elle ne dit que « désigné », faute d'avoir compté.
    private struct ResultBar: Identifiable {
        let id: UUID
        let name: String
        let ratio: Double
        let detail: String
    }

    private func bars(_ engine: MostLikelyEngine, outcome: MostLikelyEngine.Outcome) -> [ResultBar] {
        guard outcome.isCounted else {
            return outcome.winners.map {
                ResultBar(id: $0, name: engine.name(for: $0), ratio: 1, detail: "désigné")
            }
        }
        let ranked = engine.players
            .map(\.id)
            .filter { outcome.fingers(for: $0) > 0 }
            .sorted { outcome.fingers(for: $0) > outcome.fingers(for: $1) }
            .prefix(3)

        return ranked.map { id in
            let fingers = outcome.fingers(for: id)
            return ResultBar(
                id: id,
                name: engine.name(for: id),
                ratio: Double(fingers) / Double(max(1, outcome.voterCount)),
                detail: fingers > 1 ? "\(fingers) doigts" : "1 doigt"
            )
        }
    }

    private func resultBar(_ bar: ResultBar, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bar.name)
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.ink)
                Spacer(minLength: 8)
                Text(bar.detail)
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.ink.opacity(0.75))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(skin.panelStrong)
                    Capsule()
                        .fill(index == 0 ? Theme.amber : Theme.brandLight)
                        .frame(width: max(6, proxy.size.width * CGFloat(resultRevealed ? bar.ratio : 0)))
                }
                .overlay(Capsule().strokeBorder(skin.outline, lineWidth: 2))
            }
            .frame(height: 16)
            // Décalées de 60 ms : les barres se remplissent l'une après l'autre,
            // pas d'un bloc.
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.06 * Double(index)),
                value: resultRevealed
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(bar.name), \(bar.detail)")
    }

    // MARK: - Classement (spec §3.3 écran 4)

    private func standingsScreen(_ engine: MostLikelyEngine) -> some View {
        ZStack {
            VStack(spacing: 12) {
                PhasePill(text: "Classement", tint: Theme.amber, darkText: true)

                VStack(spacing: 4) {
                    Text(championTitle(engine))
                        .font(Theme.caption(13))
                        .tracking(0.8)
                        .foregroundStyle(skin.ink.opacity(0.75))
                        .multilineTextAlignment(.center)

                    Text(championNames(engine))
                        .font(Theme.title(30))
                        .foregroundStyle(skin.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)

                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(engine.standings) { standing in
                            standingRow(standing, engine: engine)
                        }
                        Color.clear.frame(height: 8)
                    }
                }

                GhostButton(title: "Changer de jeu", systemImage: "square.grid.2x2.fill") {
                    leave()
                }

                PrimaryButton(
                    title: "Rejouer",
                    systemImage: "arrow.clockwise",
                    tint: Theme.amber,
                    foreground: Theme.night
                ) {
                    replay()
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 10)
            .padding(.bottom, 6)

            if let confettiStart {
                MostLikelyConfetti(start: confettiStart)
            }
        }
        .accessibilityIdentifier("most-likely-standings")
        .task { await celebrate() }
    }

    private func standingRow(_ standing: ScoreBoard.Standing, engine: MostLikelyEngine) -> some View {
        let participant = engine.player(id: standing.playerID)
        let isLeading = standing.rank == 1
        let name = participant?.name ?? "—"
        let isAway = participant?.isActive == false
        // La ligne de tête est un aplat ambre : l'encre blanche n'y tient que
        // 1,9:1, il faut y repasser au texte sombre.
        let rowInk = isLeading ? Theme.night : skin.ink

        return HStack(spacing: 12) {
            Text("\(standing.rank)")
                .font(Theme.heading(17))
                .foregroundStyle(rowInk)
                .frame(minWidth: 26)

            AvatarView(name: name, size: 34, dimmed: isAway, table: roster.names)

            Text(name)
                .font(Theme.body(16))
                .foregroundStyle(isAway ? rowInk.opacity(0.75) : rowInk)
                // Barré ET annoncé : un départ ne se lit jamais à la seule couleur.
                .strikethrough(isAway, color: rowInk.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Text("\(standing.points)")
                .font(Theme.heading(19))
                .foregroundStyle(rowInk)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .fill(isLeading ? Theme.amber : skin.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .strokeBorder(skin.outline, lineWidth: Theme.stroke)
                )
                .shadow(color: skin.outline, radius: 0, y: 4)
        )
        .padding(.bottom, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(standing.rank). \(name)\(isAway ? ", parti" : ""), \(standing.points) point\(standing.points > 1 ? "s" : "")"
        )
    }

    // MARK: - Grille de prénoms

    private func nameGrid(_ engine: MostLikelyEngine) -> some View {
        ScrollView {
            LazyVGrid(columns: nameColumns, spacing: 10) {
                ForEach(engine.candidates) { participant in
                    nameTile(participant)
                }
            }
            .padding(.bottom, Theme.drop)
        }
    }

    private func nameTile(_ participant: Participant) -> some View {
        let isPicked = picks.contains(participant.id)

        return Button {
            pick(participant.id)
        } label: {
            HStack(spacing: 10) {
                AvatarView(name: participant.name, size: 34, table: roster.names)

                Text(participant.name)
                    .font(Theme.body(16))
                    .foregroundStyle(isPicked ? Color.white : skin.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)

                // La sélection ne tient pas qu'à la couleur : la coche la dit aussi.
                Image(systemName: isPicked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(isPicked ? Color.white : skin.ink.opacity(0.3))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(tileBackground(isPicked: isPicked))
        }
        .buttonStyle(PressedStyle())
        // Le ressort dépasse 1,04 puis se pose : c'est le rebond de la spec.
        .scaleEffect(isPicked ? 1.04 : 1)
        .animation(reduceMotion ? nil : Theme.snap, value: isPicked)
        .padding(.bottom, 4)
        .accessibilityLabel(participant.name)
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }

    private func tileBackground(isPicked: Bool) -> some View {
        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
            .fill(isPicked ? Theme.brand : skin.panel)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(skin.outline, lineWidth: Theme.stroke)
            )
            .shadow(color: skin.outline, radius: 0, y: 4)
    }

    private var nameColumns: [GridItem] {
        // Aux tailles d'accessibilité, deux colonnes tronquent les prénoms longs
        // (spec §2.8).
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    // MARK: - Morceaux communs

    private func topBar(quitTitle: String) -> some View {
        HStack(spacing: 8) {
            Button {
                haptics { Haptics.tap() }
                leave()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .accessibilityHidden(true)
                    Text(quitTitle)
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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    private func reminder(_ engine: MostLikelyEngine) -> some View {
        Text("Le plus susceptible de \(engine.card.text)")
            .font(Theme.body(15))
            .foregroundStyle(skin.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    private func panelTitle(_ title: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(skin.ink)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.heading(17))
                .foregroundStyle(skin.ink)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private var bottomBarBackground: some View {
        skin.background
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(skin.outline)
                    .frame(height: 2)
            }
            .ignoresSafeArea()
    }

    // MARK: - Libellés

    private func roundLabel(_ engine: MostLikelyEngine) -> String {
        guard let total = engine.totalRounds else { return "Manche \(engine.roundNumber)" }
        return "Manche \(engine.roundNumber) sur \(total)"
    }

    private func ballotProgress(_ engine: MostLikelyEngine) -> String {
        "Bulletin \(min(engine.votesCast + 1, engine.voterCount)) sur \(max(1, engine.voterCount))"
    }

    private func scoreLine(_ engine: MostLikelyEngine, outcome: MostLikelyEngine.Outcome) -> String {
        let points = outcome.isTie
            ? "+\(outcome.points) point chacun"
            : "+\(outcome.points) point"

        guard outcome.isCounted, let first = outcome.winners.first else {
            return outcome.isTie ? "Égalité · \(points)" : "Désigné par la table · \(points)"
        }
        let fingers = outcome.fingers(for: first)
        let doigts = fingers > 1 ? "\(fingers) doigts" : "1 doigt"
        return "\(doigts) sur \(outcome.voterCount) · \(points)"
    }

    private func championTitle(_ engine: MostLikelyEngine) -> String {
        engine.champions.count > 1 ? "Les plus susceptibles de tout" : "Le plus susceptible de tout"
    }

    private func championNames(_ engine: MostLikelyEngine) -> String {
        let names = engine.champions.map { engine.name(for: $0) }
        return names.isEmpty ? "Personne" : names.joined(separator: " & ")
    }

    // MARK: - Actions

    private func startGame() {
        guard hasEnoughPlayers else { return }
        roster.beginRound()
        resetRoundState()
        engine = MostLikelyEngine(players: roster.participants, options: options)
        haptics { Haptics.prepare() }
    }

    private func replay() {
        let carried = engine?.scores
        resetRoundState()
        confettiStart = nil
        roster.beginRound()
        // Les points de la soirée se reprennent : « Rejouer » relance des cartes,
        // pas une nouvelle table.
        engine = MostLikelyEngine(players: roster.participants, options: options, scores: carried)
    }

    /// Sortie du jeu. Referme la fenêtre de manche : hors manche, retirer un
    /// joueur du roster le supprime pour de bon au lieu de le mettre en pause.
    private func leave() {
        roster.endRound()
        onExit()
    }

    private func pick(_ id: UUID) {
        haptics { Haptics.tap() }

        if let index = picks.firstIndex(of: id) {
            picks.remove(at: index)
            return
        }
        if allowsTie, picks.count < MostLikelyEngine.maxDesignations {
            picks.append(id)
        } else {
            // Hors ex æquo, un nouveau prénom remplace le précédent : personne ne
            // veut désélectionner avant de sélectionner.
            picks = [id]
        }
    }

    private func toggleTie() {
        allowsTie.toggle()
        if !allowsTie, picks.count > 1 {
            picks = Array(picks.prefix(1))
        }
    }

    private func validateDesignation() {
        guard engine?.designate(picks) == true else {
            haptics { Haptics.warning() }
            return
        }
        haptics { Haptics.success() }
        picks = []
        allowsTie = false
    }

    private func validateBallot() {
        guard let choice = picks.first, engine?.castBallot(for: choice) == true else {
            haptics { Haptics.warning() }
            return
        }
        picks = []
    }

    private func undo() {
        guard engine?.undoDesignation() == true else { return }
        haptics { Haptics.tap() }
        resultRevealed = false
    }

    private func nextRound() {
        resetRoundState()
        engine?.nextRound()
    }

    private func finishNow() {
        engine?.finishNow()
    }

    /// La carte est lue : on relève. Appelé par la fin du décompte, par
    /// « Passer le décompte », et par « Faire circuler » en vote secret.
    private func finishCardPhase() {
        countdownIndex = -1
        engine?.countdownFinished()
    }

    private func resetRoundState() {
        picks = []
        allowsTie = false
        countdownIndex = -1
        resultRevealed = false
    }

    // MARK: - Séquences animées

    /// « 3 · 2 · 1 · Pointez ». La vibration lourde du dernier temps est ce qui
    /// synchronise la table : à cet instant, personne ne regarde l'écran.
    private func runCountdown() async {
        // Le vote secret n'a pas de décompte : c'est un bouton qui lance la tournée.
        guard let current = engine, current.options.counting == .quick else { return }
        haptics { Haptics.prepare() }

        for (index, step) in MostLikelyCountdown.steps.enumerated() {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : Theme.snap) {
                countdownIndex = index
            }
            haptics {
                switch step.haptic {
                case .light: Haptics.impact(.light)
                case .heavy: Haptics.impact(.heavy)
                }
            }
            do {
                try await Task.sleep(nanoseconds: UInt64(step.duration * 1_000_000_000))
            } catch {
                // Manche abandonnée ou écran quitté : on ne relève rien.
                return
            }
        }

        finishCardPhase()
    }

    private func revealResult() async {
        resultRevealed = false
        guard !reduceMotion else {
            resultRevealed = true
            return
        }
        // Laisse la vue se poser : sans ce souffle, les barres naissent pleines.
        try? await Task.sleep(nanoseconds: 40_000_000)
        resultRevealed = true
    }

    private func celebrate() async {
        // La partie est close : plus personne n'est « en pause », un retrait
        // depuis le roster redevient un vrai retrait.
        roster.endRound()
        haptics { Haptics.success() }
        // Pas de confettis en animations réduites (spec §3.4).
        guard !reduceMotion else { return }

        confettiStart = Date()
        try? await Task.sleep(nanoseconds: UInt64(MostLikelyConfetti.duration * 1_000_000_000))
        confettiStart = nil
    }

    // MARK: - Environnement

    private var reduceMotion: Bool {
        settings.prefersReducedMotion(system: systemReduceMotion)
    }

    private func haptics(_ action: () -> Void) {
        guard settings.hapticsEnabled else { return }
        action()
    }

    private var hasEnoughPlayers: Bool {
        roster.activePlayers.count >= MostLikelyEngine.minimumPlayers
    }

    private func packBinding(_ pack: MostLikelyPack) -> Binding<Bool> {
        Binding(
            get: { options.packs.contains(pack) },
            set: { isOn in
                if isOn {
                    options.packs.insert(pack)
                } else {
                    options.packs.remove(pack)
                }
            }
        )
    }

    /// Jour tant que la table discute, nuit dès qu'un secret circule.
    private var skin: Skin {
        switch engine?.phase {
        case .pass, .ballot, .finished:
            return .night
        default:
            return .day
        }
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .forward
    }

    private var countdownTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 1.35).combined(with: .opacity)
    }

    private var screenAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : Theme.spring
    }

    /// Clé d'identité des écrans : c'est elle qui déclenche la transition, et
    /// non l'égalité d'une phase qui porte un résultat complet.
    private var phaseKey: String {
        guard let engine else { return "setup" }
        switch engine.phase {
        case .card: return "card-\(engine.roundNumber)"
        case .designation: return "designation-\(engine.roundNumber)"
        case .pass(let index): return "pass-\(engine.roundNumber)-\(index)"
        case .ballot(let index): return "ballot-\(engine.roundNumber)-\(index)"
        case .result: return "result-\(engine.roundNumber)"
        case .finished: return "finished"
        }
    }
}

// MARK: - Rangée de choix

/// Sélecteur à quelques options courtes (6 · 12 · 20 · Sans fin). `CounterRow`
/// ne convient pas : « sans fin » n'est pas une valeur qu'on incrémente.
private struct ChipRow: View {
    @Environment(\.skin) private var skin

    let labels: [String]
    let selection: Int
    let accessibilityPrefix: String
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Button {
                    Haptics.tap()
                    onSelect(index)
                } label: {
                    Text(label)
                        .font(Theme.caption(14))
                        .foregroundStyle(index == selection ? Theme.night : skin.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.touchTarget)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(index == selection ? Theme.amber : skin.panelStrong)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .strokeBorder(skin.outline, lineWidth: 2)
                                )
                        )
                }
                .buttonStyle(PressedStyle())
                .accessibilityLabel("\(accessibilityPrefix) : \(label)")
                .accessibilityAddTraits(index == selection ? .isSelected : [])
            }
        }
    }
}

// MARK: - Confettis

/// 40 particules dessinées dans un `Canvas`, 1,6 s, aucune bibliothèque
/// (spec §3.4). Contours encrés comme le reste de l'app : des confettis flous
/// trahiraient la direction artistique.
private struct MostLikelyConfetti: View {
    @Environment(\.skin) private var skin

    static let duration: TimeInterval = 1.6
    static let count = 40

    let start: Date

    private let flakes: [Flake] = (0..<MostLikelyConfetti.count).map { _ in Flake() }

    struct Flake {
        let column = Double.random(in: 0.04...0.96)
        let drift = Double.random(in: -34...34)
        let delay = Double.random(in: 0...0.35)
        let size = Double.random(in: 8...15)
        let spin = Double.random(in: 0...(2 * Double.pi))
        let turns = Double.random(in: 1.5...4)
        let color = [Theme.amber, Theme.brand, Theme.brandLight, Theme.mint, Theme.sky, Theme.crimson]
            .randomElement() ?? Theme.amber
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                // Tout est calculé en `Double` puis converti une fois : mélanger
                // `CGFloat` et `Double` dans une même expression fait ramer le
                // vérificateur de types pour rien.
                let width = Double(size.width)
                let height = Double(size.height)

                for flake in flakes {
                    let span = Self.duration - flake.delay
                    guard span > 0 else { continue }
                    let progress = (elapsed - flake.delay) / span
                    guard progress > 0, progress < 1 else { continue }

                    let sway = sin(progress * 6 + flake.spin) * flake.drift
                    let x = flake.column * width + sway
                    let y = -20 + progress * (height + 40)
                    let angle = flake.spin + progress * flake.turns * 2 * Double.pi

                    let rect = CGRect(
                        x: -flake.size / 2,
                        y: -flake.size / 4,
                        width: flake.size,
                        height: flake.size / 2
                    )
                    let transform = CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y))
                        .rotated(by: CGFloat(angle))
                    let path = Path(roundedRect: rect, cornerRadius: 1.5).applying(transform)

                    context.fill(path, with: .color(flake.color))
                    context.stroke(path, with: .color(skin.outline), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - Accès sûr

private extension Array {
    /// Le décompte lit l'index -1 avant son premier temps : un accès direct
    /// planterait au premier affichage.
    subscript(safeIndex index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#if DEBUG
/// Roster jetable : une prévisualisation ne doit rien écrire dans les réglages
/// réels du simulateur.
private func mostLikelyPreviewRoster(_ names: [String], key: String) -> RosterStore {
    let store = RosterStore(
        defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard,
        storageKey: key
    )
    store.seed(names: names)
    return store
}

#Preview("Le plus susceptible — réglages") {
    MostLikelyView(
        roster: mostLikelyPreviewRoster(
            ["Léa", "Tom", "Nino", "Sarah", "Camille"],
            key: "preview.mostlikely.setup"
        ),
        settings: AppSettings(defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard)
    )
}

#Preview("Le plus susceptible — table réduite") {
    MostLikelyView(
        roster: mostLikelyPreviewRoster(["Léa", "Tom"], key: "preview.mostlikely.small"),
        settings: AppSettings(defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard)
    )
}
#endif
