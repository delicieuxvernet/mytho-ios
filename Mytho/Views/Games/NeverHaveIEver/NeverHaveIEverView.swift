import Foundation
import SwiftUI

/// « Je n'ai jamais » (spec §5). Cinq vies chacun, le dernier debout gagne.
///
/// La vue ne décide de rien : elle envoie des gestes au moteur et dessine
/// l'état rendu. En particulier, **elle ne sait pas qui a avoué en mode
/// secret** — le moteur ne le lui dit qu'après « Révéler ».
struct NeverHaveIEverView: View {

    @ObservedObject var roster: RosterStore
    @ObservedObject var settings: AppSettings

    /// Sortie vers le catalogue des jeux.
    ///
    /// Exigée, et non plus optionnelle : la barre de sortie l'offre depuis
    /// **toutes** les phases, et une pastille « Jeux » qui ne mène nulle part
    /// enfermerait la soirée dans le jeu. La navigation de la soirée
    /// (`PartyGameFlow`) la fournit désormais partout où l'écran est présenté.
    var onQuit: () -> Void

    /// Injectable pour que les prévisualisations et les captures d'écran
    /// n'écrivent pas dans la mémoire de paquet du simulateur.
    var deckStore: any DeckMemoryStore = UserDefaultsDeckMemory.shared

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var engine: NeverHaveIEverEngine?
    // Sans élimination d'office (choix produit du 17 août) : personne ne sort,
    // les grands groupes restent à table. L'interrupteur reste à un geste.
    @State private var rules = NeverHaveIEverEngine.Rules(eliminates: false)
    // Aucun paquet pré-coché (choix produit du 17 août) : la table choisit,
    // et le bandeau Épicé se présente à égalité de geste avec le reste.
    @State private var packIDs: Set<String> = []
    @State private var showAgeGate = false

    var body: some View {
        ZStack {
            Backdrop(skin: skin, accent: Theme.mint)
            stage
        }
        // Posée une seule fois à la racine plutôt que sur chacun des huit
        // écrans : aucune phase ne peut alors oublier sa sortie, et la barre ne
        // bouge pas d'un pixel d'un écran à l'autre. Placée **avant**
        // `environment` pour hériter de la peau du moment — nuit comprise.
        .partyTopBar(back: backStep, exit: { quitToGames() }, confirmsExit: isRoundEngaged)
        .environment(\.skin, skin)
        .preferredColorScheme(skin.colorScheme)
        // Un seul point d'animation pour tous les enchaînements d'écran : les
        // gestionnaires restent de simples appels au moteur.
        .animation(motion, value: engine?.phase)
    }

    // MARK: - Réglages d'ambiance

    /// La peau nuit est réservée aux moments secrets : le reste du jeu se joue
    /// à visage découvert, sur le papier crème.
    private var skin: Skin {
        guard let phase = engine?.phase else { return .day }
        switch phase {
        case .secretPass, .secretVote: return .night
        default: return .day
        }
    }

    private var reduceMotion: Bool {
        settings.prefersReducedMotion(system: systemReduceMotion)
    }

    private var motion: Animation? {
        reduceMotion ? .easeInOut(duration: 0.2) : Theme.spring
    }

    private var screenTransition: AnyTransition {
        reduceMotion ? .opacity : .forward
    }

    private var revealTransition: AnyTransition {
        reduceMotion ? .opacity : .reveal
    }

    private var tableNames: [String] { roster.names }

    private func name(of id: UUID) -> String {
        roster.participant(id: id)?.name ?? "Joueur"
    }

    /// « Léa », « Léa et Tom », « Léa, Tom et Nino ».
    private func names(of ids: [UUID]) -> String {
        let all = ids.map { name(of: $0) }
        guard let last = all.last else { return "" }
        guard all.count > 1 else { return last }
        return all.dropLast().joined(separator: ", ") + " et " + last
    }

    // MARK: - Sorties

    /// Le pas en arrière, quand il en existe un — nul le reste du temps : une
    /// pastille inerte apprend à la table à ne plus s'y fier.
    ///
    /// Ce jeu n'en offre qu'un, et il est court : la première carte, tant
    /// qu'aucune vie n'est tombée, rend la main aux réglages — c'est là qu'on
    /// s'aperçoit d'avoir lancé en aveu secret sans le vouloir. Ensuite, plus
    /// rien : revenir sur une désignation rendrait des vies déjà retirées, et
    /// revenir sur un aveu secret remontrerait au joueur suivant ce que le
    /// précédent vient de lire (§2.3). Le tour raté se rattrape par « Annuler
    /// ce tour », qui dit, lui, ce qu'il restitue.
    private var backStep: (() -> Void)? {
        guard let game = engine, game.phase == .card, game.cardNumber <= 1 else { return nil }
        return { returnToSetup() }
    }

    /// Vrai dès qu'une manche est engagée : le téléphone tourne autour de la
    /// table et « Jeux » est à portée de pouce, un appui réflexe emporterait les
    /// vies et les aveux de tout le monde. Aux réglages rien n'a commencé, au
    /// classement tout est déjà joué : y demander confirmation ne protégerait
    /// rien et ferait douter du bouton.
    private var isRoundEngaged: Bool {
        guard let phase = engine?.phase else { return false }
        return phase != .finished
    }

    /// Retour au catalogue. Referme la fenêtre de manche avant de rendre la
    /// main : hors manche, retirer un joueur le supprime pour de bon au lieu de
    /// le laisser barré dans le jeu suivant (§2.2).
    private func quitToGames() {
        roster.endRound()
        onQuit()
    }

    /// Retour aux réglages depuis la première carte. Même fermeture de fenêtre :
    /// le lancement l'avait ouverte, et l'écran de réglages attend le roster
    /// dans son état hors partie.
    private func returnToSetup() {
        roster.endRound()
        engine = nil
    }

    // MARK: - Aiguillage

    @ViewBuilder
    private var stage: some View {
        if let game = engine {
            play(game)
        } else {
            setupScreen.transition(screenTransition)
        }
    }

    @ViewBuilder
    private func play(_ game: NeverHaveIEverEngine) -> some View {
        switch game.phase {
        case .card:
            cardScreen(game).transition(screenTransition)
        case .tally:
            tallyScreen(game).transition(screenTransition)
        case .secretPass:
            passScreen(game)
        case .secretVote:
            voteScreen(game).transition(screenTransition)
        case .secretCount:
            countScreen(game).transition(revealTransition)
        case .secretReveal:
            revealScreen(game).transition(revealTransition)
        case .aftermath:
            aftermathScreen(game).transition(screenTransition)
        case .finished:
            podiumScreen(game).transition(revealTransition)
        }
    }

    // MARK: - Réglages de partie

    private var setupScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    setupHeader

                    Panel {
                        ChoiceRow(
                            title: "Mode d'aveu",
                            options: ConfessionMode.allCases,
                            selection: $rules.mode
                        ) { $0.title }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 14) {
                            OptionToggle(
                                title: "Éliminations",
                                subtitle: rules.eliminates
                                    ? "Cinq vies chacun, le dernier debout gagne."
                                    : "Personne ne sort : on compte les aveux.",
                                isOn: $rules.eliminates
                            )

                            if rules.eliminates {
                                ChoiceRow(
                                    title: "Vies de départ",
                                    options: NeverHaveIEverEngine.livesChoices,
                                    selection: $rules.startingLives
                                ) { "\($0) vies" }
                            } else {
                                ChoiceRow(
                                    title: "Nombre de cartes",
                                    options: NeverHaveIEverEngine.cardLimitChoices,
                                    selection: $rules.cardLimit
                                ) { limit in limit.map { "\($0)" } ?? "Sans fin" }
                            }
                        }
                    }

                    Panel { packPicker }

                    epiceBanner

                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 6)
            }
        }
        .safeAreaInset(edge: .bottom) { startBar }
    }

    private var setupHeader: some View {
        VStack(spacing: 6) {
            Text("Je n'ai jamais")
                .font(Theme.title(32))
                .foregroundStyle(skin.ink)
                .accessibilityAddTraits(.isHeader)

            Text(rules.mode.subtitle)
                .font(Theme.body(15))
                .foregroundStyle(skin.ink.opacity(0.75))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private var packPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Paquets")
                .font(Theme.caption(12))
                .foregroundStyle(skin.ink.opacity(0.75))

            // Les paquets tout public seulement : l'Épicé vit dans son bandeau
            // rose sous le panneau, il ne se fond jamais dans la liste.
            ForEach(NeverHaveIEverBank.selectablePacks(adultUnlocked: settings.adultContentUnlocked)
                .filter { !$0.isLocked }) { pack in
                packRow(pack)
            }
        }
    }

    /// Le pack 18+ en bandeau : l'argument de vente de l'app, sous les
    /// paquets. La confirmation d'âge reste une porte, pas un interrupteur.
    private var epiceBanner: some View {
        AdultPackBanner(
            title: "Pack Épicé · 18+",
            subtitle: "60 cartes crues : sextos, plans d'un soir, lendemains flous.",
            unlocked: settings.adultContentUnlocked,
            isOn: Binding(
                get: { packIDs.contains("epice") },
                set: { if $0 { packIDs.insert("epice") } else { packIDs.remove("epice") } }
            ),
            onUnlock: { showAgeGate = true }
        )
        .alert("Réservé aux adultes", isPresented: $showAgeGate) {
            Button("J'ai 18 ans ou plus") {
                if settings.setAdultContent(true, ageConfirmed: true) {
                    packIDs.insert("epice")
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Ce pack contient des thèmes crus et des références à l'alcool.")
        }
    }

    private func packRow(_ pack: ConfessionPack) -> some View {
        let isOn = packIDs.contains(pack.id)
        return Button {
            Haptics.tap()
            toggle(pack: pack)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: pack.symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.night)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(isOn ? Theme.mint : skin.panelStrong)
                            .overlay(Circle().strokeBorder(skin.outline, lineWidth: 2))
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(Theme.body(15))
                        .foregroundStyle(skin.ink)
                    Text("\(pack.cards.count) cartes")
                        .font(Theme.caption(12))
                        .foregroundStyle(skin.ink.opacity(0.75))
                }

                Spacer(minLength: 8)

                // La coche double la couleur : l'état ne se lit jamais au seul
                // remplissage de la pastille.
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isOn ? Theme.mint : skin.ink.opacity(0.35))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Theme.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel("Paquet \(pack.name), \(pack.cards.count) cartes")
        .accessibilityValue(isOn ? "retenu" : "écarté")
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }

    private func toggle(pack: ConfessionPack) {
        // Tout décocher est permis : c'est « Commencer » qui exige un paquet.
        if packIDs.contains(pack.id) {
            packIDs.remove(pack.id)
        } else {
            packIDs.insert(pack.id)
        }
    }

    private var startBar: some View {
        VStack(spacing: 6) {
            if let notice = startNotice {
                Text(notice)
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            PrimaryButton(
                title: "Commencer",
                systemImage: "play.fill",
                tint: Theme.mint,
                foreground: Theme.night,
                isEnabled: hasEnoughPlayers && !packIDs.isEmpty
            ) {
                startGame()
            }
            .accessibilityIdentifier("nhie-start")
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
        // Bandeau plein et trait encré : la DA n'a aucun dégradé, et il faut
        // bien masquer le contenu qui défile dessous.
        .background(
            skin.background
                .overlay(alignment: .top) {
                    Rectangle().fill(skin.outline).frame(height: 2)
                }
                .ignoresSafeArea()
        )
    }

    private var hasEnoughPlayers: Bool {
        roster.activePlayers.count >= NeverHaveIEverEngine.minPlayers
    }

    /// Ce qui manque avant de lancer, joueurs d'abord : sans table, le choix
    /// des paquets n'a pas encore de sens.
    private var startNotice: String? {
        if !hasEnoughPlayers { return missingPlayersLabel }
        if packIDs.isEmpty { return "Choisis au moins un paquet de cartes." }
        return nil
    }

    private var missingPlayersLabel: String {
        let missing = NeverHaveIEverEngine.minPlayers - roster.activePlayers.count
        return missing <= 1
            ? "Encore un prénom : à deux, avouer n'a plus rien d'un jeu."
            : "Encore \(missing) prénoms avant de lancer."
    }

    private func startGame() {
        let ids = roster.activePlayers.map(\.id)
        guard ids.count >= NeverHaveIEverEngine.minPlayers, !packIDs.isEmpty else { return }

        var game = NeverHaveIEverEngine(
            playerIDs: ids,
            rules: rules,
            deck: NeverHaveIEverBank.deck(
                packIDs: packIDs,
                adultUnlocked: settings.adultContentUnlocked,
                store: deckStore
            )
        )
        game.start()
        // Un départ en cours de partie désactive le joueur au lieu de le
        // supprimer : la manche le cite encore (spec §2.2).
        roster.beginRound()
        engine = game
    }

    // MARK: - La carte

    private func cardScreen(_ game: NeverHaveIEverEngine) -> some View {
        VStack(spacing: 16) {
            phaseBar(game, title: "La carte")

            Spacer(minLength: 0)

            statementPanel(game, large: true)

            if game.showsLapMessage {
                Label("Tu as fait le tour du paquet.", systemImage: "arrow.triangle.2.circlepath")
                    .font(Theme.caption(12))
                    .foregroundStyle(skin.ink.opacity(0.75))
            }

            Spacer(minLength: 0)

            PrimaryButton(
                title: game.rules.mode == .honour ? "Qui l'a déjà fait ?" : "Faire tourner le téléphone",
                systemImage: game.rules.mode == .honour ? "hand.point.up.left.fill" : "iphone.gen3",
                tint: Theme.mint,
                foreground: Theme.night
            ) {
                engine?.beginConfessions()
            }
            .accessibilityIdentifier("nhie-begin")
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 6)
    }

    /// L'affirmation, préfixe compris. Le préfixe est **dans l'interface** : la
    /// donnée n'est qu'un participe passé (spec §5.5).
    private func statementPanel(_ game: NeverHaveIEverEngine, large: Bool) -> some View {
        Panel {
            VStack(spacing: large ? 10 : 5) {
                Text("Je n'ai jamais…")
                    .font(Theme.body(large ? 16 : 13))
                    .foregroundStyle(skin.ink.opacity(0.75))

                Text(game.card?.text ?? "")
                    .font(large ? Theme.title(28) : Theme.heading(17))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity)
        }
        // Lu d'un trait : « Je n'ai jamais menti sur mon âge ».
        .accessibilityElement(children: .combine)
    }

    // MARK: - Bandeau de phase

    /// Où on en est : le nom de l'étape et le compteur de cartes. Purement
    /// informatif depuis que la sortie a rejoint la barre commune — la croix
    /// qui vivait ici faisait doublon avec la pastille « Jeux », et surtout
    /// n'existait que dans ce jeu-ci.
    private func phaseBar(_ game: NeverHaveIEverEngine, title: String) -> some View {
        HStack(spacing: 10) {
            PhasePill(text: title, tint: Theme.mint, darkText: true)

            Spacer(minLength: 0)

            Text(counterLabel(game))
                .font(Theme.caption(12))
                .foregroundStyle(skin.ink.opacity(0.75))
                .lineLimit(1)
        }
        .frame(minHeight: Theme.touchTarget)
    }

    private func counterLabel(_ game: NeverHaveIEverEngine) -> String {
        let card = game.rules.eliminates
            ? "Carte \(game.cardNumber)"
            : (game.rules.cardLimit.map { "Carte \(game.cardNumber) sur \($0)" } ?? "Carte \(game.cardNumber)")
        guard game.rules.eliminates else { return card }
        return "\(card) · \(game.survivorCount) en jeu"
    }

    // MARK: - Désignation publique

    private func tallyScreen(_ game: NeverHaveIEverEngine) -> some View {
        VStack(spacing: 12) {
            phaseBar(game, title: "Qui l'a fait ?")
            statementPanel(game, large: false)

            ScrollView {
                playerGrid(game, interactive: true)
                    .padding(.bottom, 8)
            }

            PrimaryButton(
                title: game.confessionCount == 0 ? "Personne" : "Valider · \(game.confessionCount)",
                systemImage: "checkmark",
                tint: Theme.mint,
                foreground: Theme.night
            ) {
                engine?.validate()
            }
            .accessibilityIdentifier("nhie-validate")
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 6)
    }

    private func playerGrid(
        _ game: NeverHaveIEverEngine,
        interactive: Bool,
        highlighted: Set<UUID> = []
    ) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(orderedPlayers(game)) { player in
                tile(
                    for: player,
                    in: game,
                    interactive: interactive,
                    isHighlighted: highlighted.contains(player.id)
                )
            }
        }
    }

    private func tile(
        for player: NeverHaveIEverEngine.Player,
        in game: NeverHaveIEverEngine,
        interactive: Bool,
        isHighlighted: Bool
    ) -> some View {
        let selected = game.isSelected(player.id)
        // Le geste est monté à part et non en ternaire : un littéral de fermeture
        // face à `nil` laisse l'inférence de type sans contexte.
        var tap: (() -> Void)?
        if interactive, !player.isOut {
            tap = { toggle(player.id, wasSelected: selected) }
        }
        return PlayerTile(
            name: name(of: player.id),
            table: tableNames,
            // Le tap éteint la vie **immédiatement**, avant même la validation
            // (§5.1) : la tuile montre le coup à venir.
            lives: max(0, player.lives - (selected ? 1 : 0)),
            maxLives: game.rules.startingLives,
            showsLives: game.rules.eliminates,
            confessions: player.confessions,
            isSelected: selected,
            isOut: player.isOut,
            isHighlighted: isHighlighted,
            reduceMotion: reduceMotion,
            onTap: tap
        )
    }

    private var gridColumns: [GridItem] {
        // Aux tailles d'accessibilité, deux colonnes tronquent les prénoms.
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    /// Les éliminés descendent en fin de grille (§5.4) — sans jamais disparaître :
    /// un joueur sorti continue de voir les cartes et de commenter (§5.6).
    private func orderedPlayers(_ game: NeverHaveIEverEngine) -> [NeverHaveIEverEngine.Player] {
        let inPlay = game.players.filter { !$0.isOut }
        let out = game.players
            .filter(\.isOut)
            .sorted { ($0.eliminatedOnCard ?? 0) < ($1.eliminatedOnCard ?? 0) }
        return inPlay + out
    }

    private func toggle(_ id: UUID, wasSelected: Bool) {
        // Sec, et un peu désagréable : c'est le bruit d'une vie qui s'éteint.
        if wasSelected {
            Haptics.tap()
        } else {
            Haptics.impact(.rigid)
        }
        engine?.toggle(id)
    }

    // MARK: - Aveu secret

    private func passScreen(_ game: NeverHaveIEverEngine) -> some View {
        let voter = game.currentVoterID
        return PassPhoneView(
            name: voter.map { name(of: $0) } ?? "toi",
            table: tableNames,
            instruction: "Réponds sans que personne ne voie l'écran."
        ) {
            engine?.openSecretVote()
        }
        // Sans changement d'identité, `onAppear` ne se rejoue pas et le passage
        // suivant arriverait sans son retour haptique.
        .id(voter)
    }

    private func voteScreen(_ game: NeverHaveIEverEngine) -> some View {
        VStack(spacing: 16) {
            HStack {
                PhasePill(text: "Aveu secret", tint: Theme.mint, darkText: true)
                Spacer(minLength: 0)
                if let position = game.currentVoterPosition {
                    Text("\(position) sur \(game.voterCount)")
                        .font(Theme.caption(12))
                        .foregroundStyle(skin.inkMuted)
                }
            }
            .frame(minHeight: Theme.touchTarget)

            Spacer(minLength: 0)

            statementPanel(game, large: true)

            Text("Personne ne verra ta réponse.")
                .font(Theme.body(14))
                .foregroundStyle(skin.inkMuted)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                SecretAnswerButton(
                    title: "Je l'ai fait",
                    systemImage: "hand.raised.fill",
                    tint: Theme.crimson,
                    foreground: Theme.night
                ) {
                    answerSecret(true)
                }

                SecretAnswerButton(
                    title: "Jamais",
                    systemImage: "checkmark",
                    tint: Theme.mint,
                    foreground: Theme.night
                ) {
                    answerSecret(false)
                }
            }
            .padding(.bottom, Theme.drop)
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 6)
        // Une réponse ne se rejoue pas : ni bouton retour, ni geste de bord.
        .secretScreen()
    }

    private func answerSecret(_ didIt: Bool) {
        Haptics.impact(didIt ? .rigid : .light)
        engine?.answerSecret(didIt)
    }

    /// Le compte, et rien d'autre : c'est tout ce que l'app sait dire tant que
    /// le groupe n'a pas demandé les prénoms (§5.2).
    private func countScreen(_ game: NeverHaveIEverEngine) -> some View {
        VStack(spacing: 14) {
            phaseBar(game, title: "Aveu secret")

            Spacer(minLength: 0)

            Panel {
                VStack(spacing: 6) {
                    Text("\(game.confessionCount)")
                        .font(Theme.title(76))
                        .foregroundStyle(skin.ink)
                        .contentTransition(.numericText())

                    Text(countSentence(game))
                        .font(Theme.body(16))
                        .foregroundStyle(skin.ink.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityElement(children: .combine)

            statementPanel(game, large: false)

            Spacer(minLength: 0)

            PrimaryButton(
                title: "Révéler qui",
                systemImage: "eye.fill",
                tint: Theme.mint,
                foreground: Theme.night
            ) {
                engine?.reveal()
            }
            .accessibilityIdentifier("nhie-reveal")

            GhostButton(title: "Laisser le doute", systemImage: "questionmark.circle") {
                engine?.validate()
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 6)
    }

    private func countSentence(_ game: NeverHaveIEverEngine) -> String {
        switch game.confessionCount {
        case 0: return "personne ne l'a jamais fait"
        case 1: return "personne sur \(game.voterCount) l'a déjà fait"
        default: return "personnes sur \(game.voterCount) l'ont déjà fait"
        }
    }

    private func revealScreen(_ game: NeverHaveIEverEngine) -> some View {
        VStack(spacing: 12) {
            phaseBar(game, title: "Révélation")
            statementPanel(game, large: false)

            ScrollView {
                VStack(spacing: 8) {
                    if game.confessors.isEmpty {
                        Text("Personne n'a avoué.")
                            .font(Theme.body(16))
                            .foregroundStyle(skin.ink.opacity(0.75))
                            .padding(.top, 12)
                    } else {
                        ForEach(Array(game.confessors.enumerated()), id: \.element) { index, id in
                            ConfessorRow(name: name(of: id), table: tableNames, rank: index, reduceMotion: reduceMotion)
                        }
                    }
                }
                .padding(.bottom, 8)
            }

            PrimaryButton(
                title: "Valider",
                systemImage: "checkmark",
                tint: Theme.mint,
                foreground: Theme.night
            ) {
                engine?.validate()
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 6)
    }

    // MARK: - Conséquences

    private func aftermathScreen(_ game: NeverHaveIEverEngine) -> some View {
        VStack(spacing: 12) {
            phaseBar(game, title: "Conséquences")

            Panel {
                Text(outcomeSentence(game))
                    .font(Theme.body(15))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }

            ScrollView {
                playerGrid(game, interactive: false, highlighted: Set(game.lastConfessors))
                    .padding(.bottom, 8)
            }

            PrimaryButton(
                title: game.isGameOver ? "Voir le podium" : "Carte suivante",
                systemImage: game.isGameOver ? "trophy.fill" : "arrow.right",
                tint: Theme.mint,
                foreground: Theme.night
            ) {
                engine?.nextCard()
            }
            .accessibilityIdentifier("nhie-next")

            HStack(spacing: 12) {
                if game.canUndo {
                    GhostButton(title: "Annuler ce tour", systemImage: "arrow.uturn.backward") {
                        Haptics.warning()
                        engine?.undo()
                    }
                }
                // Toujours offerte, pas seulement en partie sans fin : à six
                // joueurs bien accrochés, personne ne tombe et le classement
                // restait inatteignable — la table ne pouvait que quitter.
                GhostButton(title: "Arrêter là", systemImage: "flag.checkered") {
                    engine?.finishNow()
                }
                .accessibilityIdentifier("nhie-finish")
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 6)
        .onAppear {
            guard !game.lastEliminated.isEmpty else { return }
            Haptics.warning()
        }
    }

    private func outcomeSentence(_ game: NeverHaveIEverEngine) -> String {
        var parts: [String] = []

        if game.lastConfessors.isEmpty && game.confessionCount > 0 {
            // Doute conservé : le compte a parlé, les prénoms non.
            parts.append(
                game.rules.eliminates
                    ? "Les vies sont retirées en silence."
                    : "Les aveux sont comptés en silence."
            )
        } else if game.lastConfessors.isEmpty {
            parts.append("Personne n'a avoué.")
        } else if game.rules.eliminates {
            let verb = game.lastConfessors.count > 1 ? "perdent" : "perd"
            parts.append("\(names(of: game.lastConfessors)) \(verb) une vie.")
        } else {
            parts.append("Un aveu de plus pour \(names(of: game.lastConfessors)).")
        }

        if !game.lastEliminated.isEmpty {
            parts.append("Plus de vies pour \(names(of: game.lastEliminated)).")
        }
        return parts.joined(separator: " ")
    }

    // MARK: - Podium

    private func podiumScreen(_ game: NeverHaveIEverEngine) -> some View {
        ZStack {
            VStack(spacing: 12) {
                Text(podiumTitle(game))
                    .font(Theme.title(30))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                winnerPanel(game)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(game.ranking.enumerated()), id: \.element.id) { index, player in
                            rankingRow(game, player: player, position: index + 1)
                        }
                    }
                    .padding(.bottom, 8)
                }

                PrimaryButton(
                    title: "Rejouer",
                    systemImage: "arrow.clockwise",
                    tint: Theme.mint,
                    foreground: Theme.night
                ) {
                    startGame()
                }

                // Conservé sous « Rejouer » malgré la pastille « Jeux » de la
                // barre (§2.7) : au classement, la question n'est plus « comment
                // je sors d'ici » mais « on remet ça ou on change ? ». Les deux
                // réponses doivent se présenter ensemble, à hauteur de pouce.
                GhostButton(title: "Changer de jeu", systemImage: "square.grid.2x2") {
                    quitToGames()
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 10)

            // Pas de confettis en mouvement réduit (§5.4).
            if !reduceMotion {
                ConfettiLayer()
            }
        }
        .onAppear {
            roster.endRound()
            Haptics.success()
        }
    }

    private func podiumTitle(_ game: NeverHaveIEverEngine) -> String {
        guard game.rules.eliminates else { return "Le plus d'aveux" }
        return game.winners.count > 1 ? "Vainqueurs ex æquo" : "Dernier debout"
    }

    private func winnerPanel(_ game: NeverHaveIEverEngine) -> some View {
        Panel {
            VStack(spacing: 10) {
                HStack(spacing: -8) {
                    ForEach(game.winners.prefix(4), id: \.self) { id in
                        AvatarView(name: name(of: id), size: 64, table: tableNames)
                    }
                }

                Text(game.winners.isEmpty ? "Personne" : names(of: game.winners))
                    .font(Theme.title(26))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)

                Text(winnerSubtitle(game))
                    .font(Theme.body(14))
                    .foregroundStyle(skin.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
    }

    private func winnerSubtitle(_ game: NeverHaveIEverEngine) -> String {
        guard game.rules.eliminates else {
            let best = game.ranking.first?.confessions ?? 0
            return "\(best) aveu\(best > 1 ? "x" : "") sur \(game.cardNumber) cartes"
        }
        if game.survivorCount == 0 {
            return "Tombés ensemble sur la dernière carte."
        }
        return "Encore debout après \(game.cardNumber) cartes."
    }

    private func rankingRow(
        _ game: NeverHaveIEverEngine,
        player: NeverHaveIEverEngine.Player,
        position: Int
    ) -> some View {
        HStack(spacing: 12) {
            Text("\(position)")
                .font(Theme.heading(16))
                .foregroundStyle(skin.ink.opacity(0.75))
                .frame(minWidth: 22)

            AvatarView(name: name(of: player.id), size: 32, dimmed: player.isOut, table: tableNames)

            Text(name(of: player.id))
                .font(Theme.body(16))
                .foregroundStyle(player.isOut ? skin.ink.opacity(0.75) : skin.ink)
                // Grisé, barré **et** annoncé : jamais la couleur seule.
                .strikethrough(player.isOut, color: skin.inkMuted)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(rankingDetail(game, player: player))
                .font(Theme.caption(13))
                .foregroundStyle(skin.ink.opacity(0.75))
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .fill(player.isOut ? skin.panelSoft : skin.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .strokeBorder(skin.outline.opacity(player.isOut ? 0.45 : 1), lineWidth: Theme.stroke)
                )
                .shadow(color: skin.outline.opacity(player.isOut ? 0.35 : 1), radius: 0, y: 4)
        )
        .padding(.bottom, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(position). \(name(of: player.id)). \(rankingVoiceOver(game, player: player))")
    }

    private func rankingDetail(_ game: NeverHaveIEverEngine, player: NeverHaveIEverEngine.Player) -> String {
        guard game.rules.eliminates else { return "\(player.confessions) aveu\(player.confessions > 1 ? "x" : "")" }
        if let card = player.eliminatedOnCard { return "sorti carte \(card)" }
        return "\(player.lives) vie\(player.lives > 1 ? "s" : "")"
    }

    private func rankingVoiceOver(_ game: NeverHaveIEverEngine, player: NeverHaveIEverEngine.Player) -> String {
        guard game.rules.eliminates else { return "\(player.confessions) aveux." }
        if let card = player.eliminatedOnCard { return "Éliminé à la carte \(card)." }
        return "Encore en jeu, \(player.lives) vies."
    }
}

// MARK: - Tuile de joueur

/// Prénom, vies restantes, état. Les points de vie sont visibles **en
/// permanence** (spec §5.3) : c'est la seule information qui compte.
private struct PlayerTile: View {
    @Environment(\.skin) private var skin

    let name: String
    let table: [String]
    let lives: Int
    let maxLives: Int
    let showsLives: Bool
    let confessions: Int
    let isSelected: Bool
    let isOut: Bool
    /// Vient de perdre une vie sur la carte validée.
    let isHighlighted: Bool
    let reduceMotion: Bool
    let onTap: (() -> Void)?

    var body: some View {
        Group {
            if let onTap {
                Button {
                    onTap()
                } label: { card }
                .buttonStyle(PressedStyle())
            } else {
                card
            }
        }
        // Le prénom reste lisible : on ne cache pas les morts (§5.4).
        .rotationEffect(.degrees(isOut && !reduceMotion ? -3 : 0))
        .opacity(isOut ? 0.55 : 1)
        .animation(reduceMotion ? nil : Theme.snap, value: isSelected)
        .padding(.bottom, Theme.drop)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel)
        .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : [])
    }

    private var card: some View {
        VStack(spacing: 8) {
            AvatarView(name: name, size: 40, dimmed: isOut, table: table)

            Text(name)
                .font(Theme.heading(16))
                .foregroundStyle(skin.ink)
                .strikethrough(isOut, color: skin.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if isOut {
                PhasePill(text: "éliminé", tint: skin.panelStrong, darkText: true)
            } else if showsLives {
                lifeDots
            } else {
                PhasePill(
                    text: "\(confessions) aveu\(confessions > 1 ? "x" : "")",
                    tint: skin.panelStrong,
                    darkText: true
                )
            }

            if isSelected {
                PhasePill(text: "− 1 vie", tint: Theme.crimson, darkText: true)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 132)
        // L'ombre franche porte sur la forme de fond seule : appliquée à la
        // tuile entière, un rayon nul recopierait le prénom 5 pt plus bas.
        .background(background)
        .contentShape(Rectangle())
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
            .fill(isOut ? skin.panelSoft : skin.panel)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: isSelected || isHighlighted ? 3.5 : Theme.stroke)
            )
            .shadow(color: skin.outline.opacity(isOut ? 0.35 : 1), radius: 0, y: Theme.drop)
    }

    private var strokeColor: Color {
        if isSelected || isHighlighted { return Theme.crimson }
        return skin.outline.opacity(isOut ? 0.45 : 1)
    }

    /// Une vie perdue s'éteint et rapetisse (§5.4). En mouvement réduit, elle
    /// s'éteint seulement — pas de redimensionnement.
    private var lifeDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxLives, id: \.self) { index in
                dot(isAlive: index < lives)
            }
        }
        .animation(reduceMotion ? nil : Theme.snap, value: lives)
    }

    private func dot(isAlive: Bool) -> some View {
        Circle()
            .fill(isAlive ? Theme.mint : skin.panelStrong)
            .overlay(
                Circle().strokeBorder(skin.outline.opacity(isAlive ? 1 : 0.3), lineWidth: 1.5)
            )
            .frame(width: 12, height: 12)
            .scaleEffect(isAlive || reduceMotion ? 1 : 0.7)
            .opacity(isAlive ? 1 : 0.2)
    }

    private var voiceOverLabel: String {
        if isOut { return "\(name), éliminé." }
        var label = name
        if showsLives {
            label += ", \(lives) vie\(lives > 1 ? "s" : "") sur \(maxLives)"
        } else {
            label += ", \(confessions) aveu\(confessions > 1 ? "x" : "")"
        }
        if isSelected { label += ", désigné, perd une vie" }
        if isHighlighted { label += ", vient de perdre une vie" }
        return label + "."
    }
}

// MARK: - Une ligne de révélation

/// Les prénoms apparaissent un par un, 120 ms d'écart : le silence entre deux
/// noms **est** le jeu (§5.4).
private struct ConfessorRow: View {
    @Environment(\.skin) private var skin

    let name: String
    let table: [String]
    let rank: Int
    let reduceMotion: Bool

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: name, size: 34, table: table)

            Text(name)
                .font(Theme.heading(17))
                .foregroundStyle(skin.ink)
                .lineLimit(1)

            Spacer(minLength: 8)

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.crimson)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .fill(skin.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .strokeBorder(skin.outline, lineWidth: Theme.stroke)
                )
                .shadow(color: skin.outline, radius: 0, y: 4)
        )
        .padding(.bottom, 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(
            reduceMotion
                ? .easeInOut(duration: 0.2)
                : Theme.spring.delay(Double(rank) * 0.12),
            value: appeared
        )
        .onAppear { appeared = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) a avoué.")
    }
}

// MARK: - Bouton d'aveu secret

/// Deux réponses de poids égal : aucune des deux n'est le CTA de l'écran, donc
/// aucune n'est un `PrimaryButton` (règle « un seul par écran »).
private struct SecretAnswerButton: View {
    @Environment(\.skin) private var skin

    let title: String
    let systemImage: String
    let tint: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .accessibilityHidden(true)
                Text(title)
                    .font(Theme.heading(17))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 108)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(skin.outline, lineWidth: Theme.stroke)
                    )
                    .shadow(color: skin.outline, radius: 0, y: Theme.drop)
            )
        }
        .buttonStyle(PressedStyle())
    }
}

// MARK: - Choix à plusieurs valeurs

/// Trois vies ou cinq, à l'honneur ou en secret : un choix fermé, en pastilles.
/// `CounterRow` ne convient pas — il incrémente de 1 et laisserait choisir 4.
private struct ChoiceRow<Value: Hashable>: View {
    @Environment(\.skin) private var skin

    let title: String
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.caption(12))
                .foregroundStyle(skin.ink.opacity(0.75))

            HStack(spacing: 8) {
                ForEach(options.indices, id: \.self) { index in
                    pill(for: options[index])
                }
            }
        }
    }

    private func pill(for option: Value) -> some View {
        let isOn = option == selection
        return Button {
            Haptics.tap()
            selection = option
        } label: {
            HStack(spacing: 5) {
                // La coche double la couleur : l'état ne se lit jamais au seul
                // remplissage.
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .accessibilityHidden(true)
                }
                Text(label(option))
                    .font(Theme.caption(13))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isOn ? Theme.night : skin.ink)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isOn ? Theme.mint : skin.panelStrong)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(skin.outline, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel(label(option))
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}

// MARK: - Confettis

/// Quarante papiers qui tombent, 1,6 s, faits main : aucune bibliothèque, et
/// aucune boucle infinie — l'animation se termine d'elle-même.
private struct ConfettiLayer: View {

    private struct Flake: Identifiable {
        let id: Int
        /// Position horizontale de départ, de 0 à 1.
        let start: Double
        let delay: Double
        let duration: Double
        let drift: Double
        let size: Double
        let spin: Double
        let color: Color
    }

    @State private var flakes = ConfettiLayer.makeFlakes()
    @State private var fallen = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                ForEach(flakes) { flake in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(flake.color)
                        .frame(width: flake.size, height: flake.size * 0.5)
                        .rotationEffect(.degrees(fallen ? flake.spin : 0))
                        .offset(
                            x: proxy.size.width * (flake.start - 0.5) + (fallen ? flake.drift : 0),
                            y: fallen ? proxy.size.height + 40 : -40
                        )
                        .opacity(fallen ? 0 : 1)
                        .animation(
                            .easeIn(duration: flake.duration).delay(flake.delay),
                            value: fallen
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { fallen = true }
    }

    private static func makeFlakes() -> [Flake] {
        (0..<40).map { index in
            Flake(
                id: index,
                start: Double.random(in: 0.02...0.98),
                // Le dernier papier part à 0,4 s et tombe en 1,2 s : 1,6 s au
                // total, la durée annoncée par la spec.
                delay: Double.random(in: 0...0.4),
                duration: Double.random(in: 1.0...1.2),
                drift: Double.random(in: -50...50),
                size: Double.random(in: 8...14),
                spin: Double.random(in: -540...540),
                color: Theme.avatarPalette[index % Theme.avatarPalette.count]
            )
        }
    }
}

#if DEBUG
/// Roster et réglages jetables : une prévisualisation ne doit rien écrire dans
/// les réglages réels du simulateur.
private func previewRoster(_ names: [String]) -> RosterStore {
    let store = RosterStore(
        defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard,
        storageKey: "preview.nhie.roster"
    )
    store.seed(names: names)
    return store
}

private func previewSettings() -> AppSettings {
    AppSettings(defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard)
}

/// Mémoire de paquet volatile : la prévisualisation repart d'un paquet neuf.
private final class PreviewDeckMemory: DeckMemoryStore {
    private var storage: [String: DeckMemorySnapshot] = [:]
    func memory(forDeck deckID: String) -> DeckMemorySnapshot { storage[deckID] ?? .empty }
    func save(_ memory: DeckMemorySnapshot, forDeck deckID: String) { storage[deckID] = memory }
    func clear(deckID: String) { storage[deckID] = nil }
    func clearAll() { storage.removeAll() }
}

#Preview("Je n'ai jamais") {
    NeverHaveIEverView(
        roster: previewRoster(["Léa", "Tom", "Nino", "Sarah", "Inès"]),
        settings: previewSettings(),
        onQuit: {},
        deckStore: PreviewDeckMemory()
    )
}
#endif
