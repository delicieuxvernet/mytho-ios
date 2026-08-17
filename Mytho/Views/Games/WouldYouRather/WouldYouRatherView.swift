import SwiftUI

/// « Tu préfères ? » — l'écran le plus reconnaissable de l'app (spec §4) : deux
/// moitiés plein écran, violet contre ambre, et un « ou » au milieu.
///
/// Un seul écran de jeu pour les trois modes : c'est le moteur qui sait s'il
/// faut faire circuler le téléphone et si la minorité saute. La vue, elle, ne
/// teste jamais le mode pour choisir un chemin — seulement pour habiller.
struct WouldYouRatherView: View {

    // MARK: Entrées

    @ObservedObject var roster: RosterStore
    @ObservedObject var settings: AppSettings
    /// « Changer de jeu » (spec §2.7) : la soirée garde son roster et ses points.
    var onExit: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    // MARK: État d'écran

    /// L'enchaînement de la partie. Un seul chemin linéaire, aucune feuille
    /// par-dessus une manche (spec §2.7).
    private enum Step: Hashable {
        case setup
        case roster
        /// Passage du téléphone au votant suivant — vote secret et survie.
        case pass(UUID)
        case dilemma
        case split
        case survivors
        case results
    }

    @State private var step: Step = .setup
    @State private var mode: WouldYouRatherMode = .debate
    @State private var limit: WouldYouRatherLimit = .standard
    @State private var extremeEnabled = false
    @State private var showAgeGate = false
    @State private var engine: WouldYouRatherEngine?
    /// Les points de la soirée, conservés d'une partie à l'autre.
    @State private var partyScores = ScoreBoard()

    /// Le votant qui tient l'appareil, en vote secret et en survie.
    @State private var voter: UUID?
    /// La moitié que le votant vient de toucher : c'est elle qui s'ouvre à 62 %.
    @State private var picked: DilemmaSide?
    /// Le dernier côté compté en mode débat, pour rattraper un tap de trop.
    @State private var lastCounted: DilemmaSide?
    /// Jeton d'attente : change à chaque vote, ce qui annule la temporisation
    /// précédente au lieu de la laisser tomber sur l'écran suivant.
    @State private var advanceToken: UUID?

    // MARK: Animations d'écran

    @State private var halvesEntered = false
    @State private var orPulsing = false
    @State private var barsFilled = false
    @State private var fallen: Set<UUID> = []
    @State private var eliminationSettled = false

    // MARK: Corps

    var body: some View {
        ZStack {
            Backdrop(skin: skin, accent: accent)

            // La transition est posée sur chaque écran et non sur un conteneur
            // qui les envelopperait : de l'extérieur, elle ne joue qu'à
            // l'apparition du conteneur, pas aux changements de branche.
            switch step {
            case .setup: setupScreen.transition(screenTransition)
            case .roster: rosterScreen.transition(screenTransition)
            case .pass(let id): passScreen(to: id).transition(screenTransition)
            case .dilemma: playScreen.transition(screenTransition)
            case .split: splitScreen.transition(screenTransition)
            case .survivors: survivorsScreen.transition(screenTransition)
            case .results: resultsScreen.transition(revealTransition)
            }
        }
        // Posée sur le conteneur et non sur chaque écran : la barre ne rejoue
        // pas la transition à chaque étape, elle reste exactement là où le pouce
        // l'a laissée. Avant `.environment` dans la chaîne, sans quoi elle ne
        // verrait pas la peau de l'écran en cours et resterait en encre de nuit.
        .partyTopBar(back: backStep, exit: leaveGame, confirmsExit: exitNeedsConfirmation)
        .environment(\.skin, skin)
        .preferredColorScheme(skin.colorScheme)
        // Quelqu'un part toujours en avance : il sort des votants sans être
        // éliminé, et son prénom reste dans la grille (spec §2.2).
        .onChange(of: roster.participants) { _, updated in
            syncPlayers(updated)
        }
    }

    // MARK: Peau et accents

    /// Nuit sur les moments de secret et sur le dilemme lui-même : les deux
    /// moitiés couvrent l'écran, et la pastille « ou » ne tient son contraste
    /// sur le violet comme sur l'ambre qu'en encre sombre.
    private var skin: Skin {
        switch step {
        case .pass, .dilemma: return .night
        default: return .day
        }
    }

    private var accent: Color { Theme.brand }

    private var reduced: Bool { settings.prefersReducedMotion(system: systemReduceMotion) }

    /// L'unique ressort des changements d'écran. En mode réduit, tout devient un
    /// fondu court — jamais une absence d'animation, qui ferait sauter l'écran.
    private var motion: Animation { reduced ? .easeInOut(duration: 0.2) : Theme.spring }

    /// Les déplacements deviennent des fondus quand les animations sont
    /// réduites (spec §2.8).
    private var screenTransition: AnyTransition { reduced ? .opacity : .forward }

    private var revealTransition: AnyTransition { reduced ? .opacity : .reveal }

    private func color(for side: DilemmaSide) -> Color {
        side == .a ? Theme.brand : Theme.amber
    }

    /// Blanc sur le violet (4,7:1), encre sur l'ambre (10,6:1). L'inverse
    /// tomberait sous le seuil de lisibilité dans les deux cas.
    private func ink(for side: DilemmaSide) -> Color {
        side == .a ? .white : Theme.night
    }

    private func name(of id: UUID) -> String {
        roster.participant(id: id)?.name ?? "Joueur"
    }

    // MARK: - Sorties

    /// Le pas en arrière de l'écran en cours. Nul là où il n'y a rien derrière,
    /// ou rien qui puisse se rejouer : une pastille inerte apprend à la table à
    /// ne plus se fier à la barre, et c'est toute la barre qu'on perd alors.
    private var backStep: (() -> Void)? {
        switch step {
        // Le premier écran du jeu ; l'écran de passage, qu'une révélation
        // interdit de rejouer (spec §2.3) ; l'écran de fin, où « Rejouer » et
        // « Changer de jeu » sont déjà les deux seules suites possibles.
        case .setup, .pass, .results:
            return nil

        case .roster:
            return { withAnimation(motion) { step = .setup } }

        case .dilemma:
            // Celui qui tient l'appareil n'a pas encore voté : lui rendre son
            // écran de passage ne touche pas à la manche. En débat, personne ne
            // se passe rien et le dilemme ouvre la carte — rien derrière lui.
            // Le vote part dès le tap, avant la temporisation de passage de
            // main : sans ces deux gardes, on pouvait revenir en arrière une
            // demi-seconde après avoir voté et bloquer le tour.
            guard let voter,
                  engine?.mode.identifiesVoters == true,
                  engine?.votes[voter] == nil,
                  advanceToken == nil
            else { return nil }
            return { withAnimation(motion) { step = .pass(voter) } }

        case .split:
            // Rien : le comptage à main levée se reprend par « Corriger le
            // comptage », un bouton qui dit ce qu'il défait. Deux commandes pour
            // le même effet, dont une muette, apprend à la table à se méfier de
            // la barre — et c'est toute la barre qu'on perd alors.
            return nil

        case .survivors:
            // La répartition reste en mémoire tant que la carte n'a pas tourné :
            // y revenir ne coûte rien et ne rejoue aucune élimination.
            return { withAnimation(motion) { step = .split } }
        }
    }

    /// Une manche engagée ne s'abandonne pas sur un appui réflexe : le téléphone
    /// tourne autour de la table et « Jeux » est à portée de pouce. Aux réglages,
    /// aux prénoms et au résultat il n'y a rien à perdre — demander confirmation
    /// pour rien ferait douter du bouton partout ailleurs.
    private var exitNeedsConfirmation: Bool {
        switch step {
        case .setup, .roster, .results: return false
        case .pass, .dilemma, .split, .survivors: return true
        }
    }

    // MARK: - Réglages

    private var setupScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    setupHeader
                    modePicker
                    if mode != .survival { lengthPicker }
                    extremePanel
                    if mode.identifiesVoters { rosterSummary }
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
        }
        .safeAreaInset(edge: .bottom) { setupBar }
    }

    /// Plus de croix ici : elle n'existait que dans ce jeu et à cet écran-là,
    /// c'est-à-dire nulle part au moment où on en a besoin. La sortie est
    /// désormais dans la barre partagée, au même endroit que dans les autres.
    private var setupHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tu préfères ?")
                .font(Theme.title(32))
                .foregroundStyle(skin.ink)
                .accessibilityAddTraits(.isHeader)

            Text("Deux options, aucune bonne réponse.")
                .font(Theme.caption(13))
                .foregroundStyle(skin.ink.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Le pack Extrême en bandeau rose : l'argument de vente de l'app, posé
    /// entre les réglages. Porte d'âge tant qu'il est verrouillé, interrupteur
    /// ensuite — même doctrine que les deux autres jeux.
    private var extremePanel: some View {
        AdultPackBanner(
            title: "Dilemmes Extrême · 18+",
            subtitle: "60 dilemmes qu'on regrette d'avoir posés.",
            unlocked: settings.adultContentUnlocked,
            isOn: $extremeEnabled,
            onUnlock: { showAgeGate = true }
        )
        .alert("Réservé aux adultes", isPresented: $showAgeGate) {
            Button("J'ai 18 ans ou plus") {
                if settings.setAdultContent(true, ageConfirmed: true) {
                    extremeEnabled = true
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Ce pack contient des thèmes crus et des références à l'alcool.")
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Comment on joue")
            ForEach(WouldYouRatherMode.allCases) { candidate in
                modeRow(candidate)
            }
        }
    }

    private func modeRow(_ candidate: WouldYouRatherMode) -> some View {
        let isSelected = candidate == mode
        return Button {
            Haptics.tap()
            withAnimation(motion) { mode = candidate }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol(for: candidate))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.night)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(candidate == .survival ? Theme.amber : Theme.brandLight)
                            .overlay(Circle().strokeBorder(skin.outline, lineWidth: 2))
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(candidate.title)
                        .font(Theme.heading(17))
                        .foregroundStyle(skin.ink)
                    Text(candidate.tagline)
                        .font(Theme.caption(12))
                        .foregroundStyle(skin.ink.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                // Coche pleine et non simple teinte : la sélection ne se lit
                // jamais à la seule couleur (spec §2.8).
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? skin.ink : skin.inkFaint)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .frame(minHeight: Theme.touchTarget)
            .background(selectableBackground(isSelected))
            .padding(.bottom, 4)
        }
        .buttonStyle(PressedStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(traits(selected: isSelected))
    }

    /// Le mode retenu est annoncé « sélectionné » : à l'oreille, la coche
    /// pleine et le fond teinté ne se distinguent pas de leurs voisins.
    private func traits(selected: Bool) -> AccessibilityTraits {
        selected ? [.isButton, .isSelected] : [.isButton]
    }

    private func symbol(for candidate: WouldYouRatherMode) -> String {
        switch candidate {
        case .debate: return "bubble.left.and.bubble.right.fill"
        case .secret: return "eye.slash.fill"
        case .survival: return "flag.checkered"
        }
    }

    private var lengthPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Longueur de la partie")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                ForEach(WouldYouRatherLimit.choices) { choice in
                    lengthChip(choice)
                }
            }
        }
    }

    private func lengthChip(_ choice: WouldYouRatherLimit) -> some View {
        let isSelected = choice == limit
        return Button {
            Haptics.tap()
            withAnimation(motion) { limit = choice }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark" : "circle.dotted")
                    .font(.system(size: 12, weight: .bold))
                    .accessibilityHidden(true)
                Text(choice.label)
                    .font(Theme.body(15))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(skin.ink)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.touchTarget)
            .background(selectableBackground(isSelected))
            .padding(.bottom, 4)
        }
        .buttonStyle(PressedStyle())
        .accessibilityAddTraits(traits(selected: isSelected))
    }

    private var rosterSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Qui vote")
            Panel(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(rosterLabel)
                        .font(Theme.body(15))
                        .foregroundStyle(skin.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if !roster.activePlayers.isEmpty {
                        HStack(spacing: -6) {
                            ForEach(roster.activePlayers.prefix(8)) { participant in
                                AvatarView(name: participant.name, size: 30, table: roster.names)
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    GhostButton(title: "Modifier les prénoms", systemImage: "person.2.fill") {
                        withAnimation(motion) { step = .roster }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var rosterLabel: String {
        let count = roster.activePlayers.count
        guard count >= mode.minimumPlayers else {
            return "Ce mode nomme les votants : ajoute au moins \(mode.minimumPlayers) prénoms."
        }
        return "\(count) joueur\(count > 1 ? "s" : "") à table."
    }

    private var canStart: Bool {
        !mode.identifiesVoters || roster.activePlayers.count >= mode.minimumPlayers
    }

    private var setupBar: some View {
        VStack(spacing: 6) {
            if !canStart {
                Text("Il faut des prénoms pour éliminer ou pour faire circuler le téléphone.")
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            PrimaryButton(title: "C'est parti", systemImage: "play.fill", isEnabled: canStart) {
                startGame()
            }
            .accessibilityIdentifier("wyr-start")
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(barBackground)
    }

    // MARK: - Prénoms

    /// Le bouton de `RosterView` reste grisé tant qu'il manque des prénoms :
    /// arriver ici par curiosité enfermait la soirée sur « Qui joue ? ». C'est
    /// le « Retour » de la barre partagée qui l'en sort — la barre ad hoc posée
    /// ici faisait le même travail, mais d'une autre forme et sur ce seul écran.
    private var rosterScreen: some View {
        RosterView(
            store: roster,
            minimumPlayers: max(mode.minimumPlayers, RosterStore.minPlayers),
            startTitle: "Enregistrer"
        ) {
            withAnimation(motion) { step = .setup }
        }
    }

    // MARK: - Passage du téléphone

    private func passScreen(to id: UUID) -> some View {
        PassPhoneView(
            name: name(of: id),
            table: roster.names,
            instruction: "Ton choix reste secret jusqu'à la révélation."
        ) {
            voter = id
            picked = nil
            withAnimation(motion) { step = .dilemma }
        }
        // Sans changement d'identité, le passage suivant arriverait sans son
        // retour haptique : `onAppear` ne se rejouerait pas.
        .id(id)
    }

    // MARK: - Le dilemme

    @ViewBuilder
    private var playScreen: some View {
        if let current = engine, let card = current.card {
            dilemmaScreen(current, card: card)
        } else {
            emptyDeckScreen
        }
    }

    private func dilemmaScreen(_ current: WouldYouRatherEngine, card: Dilemma) -> some View {
        ZStack {
            halves(current, card: card)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                dilemmaTopBar(current)
                Spacer(minLength: 0)
                dilemmaBottomBar(current)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.vertical, 8)
        }
        // Une nouvelle carte remonte l'animation d'entrée : sans changement
        // d'identité, les moitiés resteraient posées.
        .id(card.id)
        .task(id: card.id) { await runEntrance() }
        .onChange(of: reduced) { _, _ in refreshPulse() }
        .task(id: advanceToken) { await waitThenContinue() }
        .modifier(SecretLock(active: current.mode.identifiesVoters))
    }

    private func halves(_ current: WouldYouRatherEngine, card: Dilemma) -> some View {
        GeometryReader { geo in
            let topHeight = height(for: .a, total: geo.size.height)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    half(.a, card: card, height: topHeight)
                    half(.b, card: card, height: geo.size.height - topHeight)
                }

                // Le trait de séparation est une forme à part : une ombre franche
                // posée sur une moitié en recopierait le texte 5 pt plus bas.
                Rectangle()
                    .fill(Skin.night.outline)
                    .frame(height: Theme.stroke)
                    .offset(y: topHeight - Theme.stroke / 2)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                orBadge
                    .offset(y: topHeight - 32)
                    .allowsHitTesting(false)
            }
            .animation(motion, value: emphasis)
        }
    }

    private func half(_ side: DilemmaSide, card: Dilemma, height: CGFloat) -> some View {
        Button {
            pick(side)
        } label: {
            ZStack {
                color(for: side)

                VStack(spacing: 12) {
                    Text(card.text(side))
                        .font(Theme.title(27))
                        .foregroundStyle(ink(for: side))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(5)

                    if showsOpenCount {
                        Text("\(openCount(side))")
                            .font(Theme.title(30))
                            .foregroundStyle(ink(for: side))
                            .contentTransition(.numericText())
                            .frame(minWidth: 44, minHeight: 44)
                            .background(
                                Capsule()
                                    .fill(ink(for: side).opacity(0.14))
                                    .overlay(Capsule().strokeBorder(ink(for: side), lineWidth: 2))
                            )
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 34)
            }
            .frame(maxWidth: .infinity)
            .frame(height: max(height, 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressedStyle())
        // La moitié écartée se désature, elle ne disparaît pas : le texte doit
        // rester lisible pendant qu'on commente le choix.
        .saturation(emphasis == nil || emphasis == side ? 1 : 0.35)
        .offset(y: entranceOffset(side))
        .opacity(halvesEntered ? 1 : 0)
        // Le ressort vit ici et non dans un `withAnimation` global : c'est le
        // seul moyen de retarder la moitié du bas de 60 ms (spec §4.3).
        .animation(entranceAnimation(side), value: halvesEntered)
        .accessibilityLabel(accessibilityLabel(for: side, card: card))
        .accessibilityHint(showsOpenCount ? "Ajoute une voix de ce côté" : "Choisis cette option")
    }

    private var orBadge: some View {
        Text("ou")
            .font(Theme.heading(19))
            .foregroundStyle(Skin.night.ink)
            .frame(width: 64, height: 64)
            // L'ombre franche porte sur le rond seul : appliquée au texte, un
            // rayon nul en dessinerait une copie nette 5 pt plus bas.
            .background(
                Circle()
                    .fill(Skin.night.panel)
                    .overlay(Circle().strokeBorder(Skin.night.outline, lineWidth: Theme.stroke))
                    .shadow(color: Skin.night.outline, radius: 0, y: Theme.drop)
            )
            .scaleEffect(orPulsing ? 1.04 : 1)
            .animation(pulseAnimation, value: orPulsing)
            // Apparition centrée après les deux moitiés — l'équivalent de
            // `.reveal`, mais piloté par un délai plutôt que par une transition,
            // qui ne se déclencherait pas sur une vue toujours présente.
            .scaleEffect(halvesEntered ? 1 : 0.86)
            .opacity(halvesEntered ? 1 : 0)
            .animation(reduced ? .easeOut(duration: 0.2) : Theme.spring.delay(0.18), value: halvesEntered)
            .accessibilityHidden(true)
    }

    /// `nil` en animations réduites : le « ou » se fige au lieu de pulser, et
    /// aucune boucle ne reste en fond (spec §4.3).
    private var pulseAnimation: Animation? {
        reduced ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
    }

    private func dilemmaTopBar(_ current: WouldYouRatherEngine) -> some View {
        HStack(spacing: 10) {
            if let voter, current.mode.identifiesVoters {
                PhasePill(text: "À toi, \(name(of: voter))", tint: Skin.night.panel)
            } else {
                PhasePill(
                    text: progressLabel(current, index: current.cardsPlayed + 1),
                    tint: Skin.night.panel
                )
            }

            Spacer(minLength: 0)

            if current.startsNewLap {
                PhasePill(text: "Tour de paquet bouclé", tint: Theme.amber, darkText: true)
            }
        }
    }

    @ViewBuilder
    private func dilemmaBottomBar(_ current: WouldYouRatherEngine) -> some View {
        if showsOpenCount {
            VStack(spacing: 2) {
                if current.tally.total == 0 {
                    Text("Tape une moitié par personne.")
                        .font(Theme.caption(13))
                        .foregroundStyle(Skin.night.ink)
                        .padding(.horizontal, 4)
                        .frame(minHeight: 34)
                } else if lastCounted != nil {
                    GhostButton(title: "Annuler le dernier", systemImage: "arrow.uturn.backward") {
                        undoLastCount()
                    }

                    PrimaryButton(title: "Voir la répartition", systemImage: "chart.bar.fill") {
                        revealSplit()
                    }
                    .accessibilityIdentifier("wyr-reveal")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            // Le bandeau flotte sur l'ambre autant que sur le violet : sans
            // aplat opaque dessous, le texte secondaire passerait sous le seuil
            // de contraste d'un côté ou de l'autre.
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(Skin.night.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(Skin.night.outline, lineWidth: Theme.stroke)
                    )
            )
        }
    }

    private func accessibilityLabel(for side: DilemmaSide, card: Dilemma) -> String {
        let position = side == .a ? "Option du haut" : "Option du bas"
        guard showsOpenCount else { return "\(position) : \(card.text(side))" }
        return "\(position) : \(card.text(side)). \(openCount(side)) voix."
    }

    private var emptyDeckScreen: some View {
        VStack(spacing: 14) {
            Text("Plus aucune carte")
                .font(Theme.title(26))
                .foregroundStyle(skin.ink)
            PrimaryButton(title: "Changer de jeu", systemImage: "square.grid.2x2.fill", action: leaveGame)
                .padding(.horizontal, Theme.gutter)
        }
    }

    // MARK: Géométrie des moitiés

    /// La moitié retenue s'ouvre à 62 %, l'autre se referme à 38 % (spec §4.3).
    /// Sans choix, les deux restent à parité — c'est ce qui rend le dilemme
    /// illisible autrement qu'en le lisant.
    private func height(for side: DilemmaSide, total: CGFloat) -> CGFloat {
        guard let emphasis else { return total / 2 }
        return total * (side == emphasis ? 0.62 : 0.38)
    }

    /// En vote secret, le côté touché ; en débat, le côté qui mène au comptage.
    /// Une seule expression pour les trois modes.
    private var emphasis: DilemmaSide? {
        if let picked { return picked }
        guard showsOpenCount else { return nil }
        return engine?.tally.majority
    }

    /// Les deux moitiés entrent en même temps, l'une par le haut, l'autre par le
    /// bas. En mode réduit elles ne bougent pas : simple fondu (spec §4.3).
    private func entranceOffset(_ side: DilemmaSide) -> CGFloat {
        guard !reduced, !halvesEntered else { return 0 }
        return side == .a ? -420 : 420
    }

    /// Les deux moitiés partent ensemble, celle du bas avec 60 ms de retard :
    /// lancées à la milliseconde près, l'œil ne lit qu'un seul bloc qui s'ouvre.
    private func entranceAnimation(_ side: DilemmaSide) -> Animation {
        guard !reduced else { return .easeOut(duration: 0.2) }
        return Theme.spring.delay(side == .b ? 0.06 : 0)
    }

    private var showsOpenCount: Bool {
        guard let engine else { return false }
        return !engine.mode.identifiesVoters
    }

    private func openCount(_ side: DilemmaSide) -> Int {
        engine?.tally.count(side) ?? 0
    }

    // MARK: - Répartition

    @ViewBuilder
    private var splitScreen: some View {
        if let current = engine, let outcome = current.lastOutcome {
            splitContent(current, outcome: outcome)
        } else {
            emptyDeckScreen
        }
    }

    private func splitContent(_ current: WouldYouRatherEngine, outcome: WouldYouRatherEngine.Outcome) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                PhasePill(text: "Répartition", tint: Theme.brand)
                Spacer(minLength: 0)
                Text(progressLabel(current, index: current.cardsPlayed))
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.ink.opacity(0.75))
            }

            bar(.a, outcome: outcome)
            bar(.b, outcome: outcome)

            if current.mode == .survival {
                Panel(padding: 14) {
                    Text(survivalNote(outcome))
                        .font(Theme.body(15))
                        .foregroundStyle(skin.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 8)
        .safeAreaInset(edge: .bottom) { splitBar(current) }
        .task(id: outcome.card.id) { await runBars() }
    }

    private func bar(_ side: DilemmaSide, outcome: WouldYouRatherEngine.Outcome) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(outcome.card.text(side))
                .font(Theme.body(15))
                .foregroundStyle(skin.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(skin.panelSoft)

                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(color(for: side))
                            .frame(width: barWidth(side, outcome: outcome, available: geo.size.width))
                            .animation(barAnimation(side), value: barsFilled)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(skin.outline, lineWidth: 2)
                    )
                }
                .frame(height: 36)

                Text("\(outcome.tally.count(side))")
                    .font(Theme.title(26))
                    .foregroundStyle(skin.ink)
                    .contentTransition(.numericText())
                    .frame(minWidth: 32, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(outcome.card.text(side)) : \(outcome.tally.count(side)) sur \(outcome.tally.total)")
    }

    /// Une barre à zéro reste à zéro : « personne de ce côté » se lit au chiffre
    /// et à la gouttière vide, pas à un moignon de couleur.
    private func barWidth(_ side: DilemmaSide, outcome: WouldYouRatherEngine.Outcome, available: CGFloat) -> CGFloat {
        guard barsFilled, outcome.tally.count(side) > 0 else { return 0 }
        return max(14, available * CGFloat(outcome.tally.share(side)))
    }

    /// Les deux barres se remplissent de zéro à leur valeur, la seconde avec
    /// 60 ms de retard : remplies en même temps, on ne voit qu'un bloc bouger.
    private func barAnimation(_ side: DilemmaSide) -> Animation? {
        guard !reduced else { return nil }
        return .easeOut(duration: 0.5).delay(side == .b ? 0.06 : 0)
    }

    private func survivalNote(_ outcome: WouldYouRatherEngine.Outcome) -> String {
        if outcome.isTie {
            return "Égalité parfaite : personne ne saute. On passe à la carte suivante."
        }
        guard !outcome.eliminated.isEmpty else {
            return "Tout le monde du même côté : personne ne saute."
        }
        let names = outcome.eliminated.map(name(of:)).joined(separator: ", ")
        return outcome.eliminated.count > 1
            ? "Minoritaires, donc éliminés : \(names)."
            : "Minoritaire, donc éliminé : \(names)."
    }

    private func splitBar(_ current: WouldYouRatherEngine) -> some View {
        VStack(spacing: 4) {
            if !current.mode.identifiesVoters {
                GhostButton(title: "Corriger le comptage", systemImage: "arrow.uturn.backward") {
                    correctTally()
                }
            }

            // La seule sortie en cours de partie : sans elle, une partie de
            // 25 cartes se subit jusqu'au bout et une partie sans fin ne se
            // termine jamais.
            if current.mode != .survival, !current.isOver {
                GhostButton(title: "Terminer la partie", systemImage: "flag.fill") {
                    endGame()
                }
            }

            PrimaryButton(title: splitButtonTitle(current), systemImage: "arrow.right") {
                leaveSplit(current)
            }
            .accessibilityIdentifier("wyr-next")
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(barBackground)
    }

    private func splitButtonTitle(_ current: WouldYouRatherEngine) -> String {
        if current.mode == .survival { return "Voir les survivants" }
        return current.isOver ? "Voir le résultat" : "Carte suivante"
    }

    // MARK: - Survivants

    @ViewBuilder
    private var survivorsScreen: some View {
        if let current = engine {
            survivorsContent(current)
        } else {
            emptyDeckScreen
        }
    }

    private func survivorsContent(_ current: WouldYouRatherEngine) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                PhasePill(text: "Survivants", tint: Theme.amber, darkText: true)
                Spacer(minLength: 0)
                Text("\(current.survivors.count) encore en jeu")
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.ink.opacity(0.75))
            }

            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(current.players, id: \.self) { id in
                        playerTile(id, isOut: current.eliminated.contains(id))
                    }
                }
                .padding(.bottom, 20)

                if current.isFinalDuel {
                    Panel(padding: 14) {
                        Text("Finale. À deux, aucun vote ne peut plus éliminer : continuez tant que ça vous amuse, ou arrêtez-vous à égalité.")
                            .font(Theme.body(14))
                            .foregroundStyle(skin.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 8)
        .safeAreaInset(edge: .bottom) { survivorsBar(current) }
        .task(id: current.lastOutcome?.card.id) { await playElimination() }
    }

    private var gridColumns: [GridItem] {
        // Au-delà de XXL, deux colonnes tronquent les prénoms (spec §2.8).
        let count = typeSize >= .accessibility1 ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    /// Ceux qui tombent sur cette carte-ci. Les éliminés des cartes précédentes
    /// arrivent déjà grisés : leur faire rejouer la chute — ou pire, les
    /// remontrer vivants le temps de l'animation — laisserait croire qu'ils
    /// sont revenus en jeu.
    private var dropping: Set<UUID> {
        Set(engine?.lastOutcome?.eliminated ?? [])
    }

    /// Deux calques superposés : le vivant, qui tombe, et l'éliminé, qui se
    /// révèle en place. Un seul calque obligerait l'ombre à remonter de 400 pt
    /// au moment de se figer, et la tuile repartirait vers le haut.
    private func playerTile(_ id: UUID, isOut: Bool) -> some View {
        let falls = dropping.contains(id)
        // Un éliminé d'avant est posé à l'état final dès l'affichage ; seul le
        // tombant attend la fin de sa chute pour se figer.
        let settled = eliminationSettled || !falls

        return ZStack {
            tileBody(id, dimmed: true)
                .opacity(isOut && settled ? 1 : 0)

            tileBody(id, dimmed: false)
                .opacity(isOut && (settled || fallen.contains(id)) ? 0 : 1)
                .offset(y: fallen.contains(id) ? 400 : 0)
        }
        .animation(.easeOut(duration: 0.25), value: eliminationSettled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isOut ? "\(name(of: id)), éliminé" : "\(name(of: id)), encore en jeu")
    }

    private func tileBody(_ id: UUID, dimmed: Bool) -> some View {
        HStack(spacing: 10) {
            AvatarView(name: name(of: id), size: 34, dimmed: dimmed, table: roster.names)

            VStack(alignment: .leading, spacing: 1) {
                Text(name(of: id))
                    .font(Theme.body(15))
                    .foregroundStyle(dimmed ? skin.inkMuted : skin.ink)
                    // Grisé, barré ET annoncé : jamais la couleur seule.
                    .strikethrough(dimmed, color: skin.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if dimmed {
                    Text("Éliminé")
                        .font(Theme.caption(11))
                        .foregroundStyle(skin.inkMuted)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 56)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .fill(dimmed ? skin.panelSoft : skin.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .strokeBorder(skin.outline.opacity(dimmed ? 0.45 : 1), lineWidth: Theme.stroke)
                )
                .shadow(color: skin.outline.opacity(dimmed ? 0.32 : 1), radius: 0, y: 4)
        )
        .padding(.bottom, 4)
    }

    private func survivorsBar(_ current: WouldYouRatherEngine) -> some View {
        VStack(spacing: 4) {
            if !current.isOver {
                GhostButton(
                    title: current.isFinalDuel ? "Arrêter à égalité" : "Terminer la partie",
                    systemImage: "flag.fill"
                ) {
                    endGame()
                }
            }

            PrimaryButton(
                title: current.isOver ? "Voir le dernier debout" : "Carte suivante",
                systemImage: "arrow.right"
            ) {
                nextCard()
            }
            .accessibilityIdentifier("wyr-next")
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(barBackground)
    }

    // MARK: - Résultat

    @ViewBuilder
    private var resultsScreen: some View {
        if let current = engine {
            resultsContent(current)
        } else {
            emptyDeckScreen
        }
    }

    private func resultsContent(_ current: WouldYouRatherEngine) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            Panel(padding: 20) {
                VStack(spacing: 12) {
                    Text(resultTitle(current))
                        .font(Theme.caption(13))
                        .foregroundStyle(skin.ink.opacity(0.75))
                        .accessibilityAddTraits(.isHeader)

                    if let champion = current.champions.first, current.mode.identifiesVoters {
                        AvatarView(name: name(of: champion), size: 72, table: roster.names)
                        Text(championLabel(current))
                            .font(Theme.title(30))
                            .foregroundStyle(skin.ink)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                    } else {
                        Text(playedLabel(current))
                            .font(Theme.title(26))
                            .foregroundStyle(skin.ink)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if current.mode.identifiesVoters {
                standings(current)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.gutter)
        .safeAreaInset(edge: .bottom) { resultsBar }
        .onAppear { roster.endRound() }
    }

    private func playedLabel(_ current: WouldYouRatherEngine) -> String {
        let plural = current.cardsPlayed > 1 ? "s" : ""
        return "\(current.cardsPlayed) dilemme\(plural) tranché\(plural)"
    }

    /// Le duel final s'arrête à deux : annoncer « dernier debout » devant deux
    /// prénoms passerait pour un bug.
    private func resultTitle(_ current: WouldYouRatherEngine) -> String {
        guard current.mode == .survival else { return "Fin de la partie" }
        return current.champions.count > 1 ? "Ex æquo" : "Dernier debout"
    }

    private func championLabel(_ current: WouldYouRatherEngine) -> String {
        let names = current.champions.map(name(of:))
        guard names.count > 1 else { return names.first ?? "Personne" }
        return names.joined(separator: " & ")
    }

    private func standings(_ current: WouldYouRatherEngine) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(current.scores.standings.prefix(5))) { standing in
                HStack(spacing: 10) {
                    Text("\(standing.rank)")
                        .font(Theme.heading(15))
                        .foregroundStyle(skin.ink)
                        .frame(minWidth: 22)

                    AvatarView(name: name(of: standing.playerID), size: 30, table: roster.names)

                    Text(name(of: standing.playerID))
                        .font(Theme.body(15))
                        .foregroundStyle(skin.ink)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text("\(standing.points) pt\(standing.points > 1 ? "s" : "")")
                        .font(Theme.caption(13))
                        .foregroundStyle(skin.ink.opacity(0.75))
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 12)
                .frame(minHeight: Theme.touchTarget)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .fill(skin.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                .strokeBorder(skin.outline, lineWidth: 2)
                        )
                )
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// Deux sorties, toujours : rejouer, ou changer de jeu en gardant le roster
    /// et les points de la soirée (spec §2.7).
    private var resultsBar: some View {
        VStack(spacing: 4) {
            GhostButton(title: "Changer de jeu", systemImage: "square.grid.2x2.fill", action: leaveGame)

            PrimaryButton(title: "Rejouer", systemImage: "arrow.clockwise") {
                startGame()
            }
            .accessibilityIdentifier("wyr-replay")
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(barBackground)
    }

    // MARK: - Pièces communes

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Theme.caption(12))
            .tracking(1.1)
            .foregroundStyle(skin.ink.opacity(0.75))
    }

    private func selectableBackground(_ isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
            .fill(isSelected ? Theme.brandLight.opacity(0.28) : skin.panel)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(skin.outline, lineWidth: isSelected ? Theme.stroke : 2)
            )
            .shadow(color: skin.outline, radius: 0, y: 4)
    }

    /// Bandeau plein et trait encré plutôt qu'un fondu : la DA n'a aucun dégradé,
    /// et il faut bien masquer le contenu qui défile dessous.
    private var barBackground: some View {
        skin.background
            .overlay(alignment: .top) {
                Rectangle().fill(skin.outline).frame(height: 2)
            }
            .ignoresSafeArea()
    }

    private func progressLabel(_ current: WouldYouRatherEngine, index: Int) -> String {
        if current.mode == .survival { return "\(current.survivors.count) en jeu" }
        guard let total = current.limit.total else { return "Carte \(index)" }
        return "Carte \(min(index, total)) / \(total)"
    }

    // MARK: - Déroulé

    private func startGame() {
        let ids = mode.identifiesVoters ? roster.activePlayers.map(\.id) : []
        var board = partyScores
        board.register(ids)

        var created = WouldYouRatherEngine(
            mode: mode,
            limit: limit,
            players: ids,
            deck: WouldYouRatherEngine.makeDeck(adultUnlocked: settings.adultContentUnlocked, extremeEnabled: extremeEnabled),
            scores: board
        )
        var generator = SystemRandomNumberGenerator()
        created.start(using: &generator)

        engine = created
        partyScores = created.scores
        picked = nil
        lastCounted = nil
        voter = nil
        // Un joueur retiré pendant la partie est désactivé, jamais supprimé :
        // la manche en cours le cite encore (spec §2.2).
        roster.beginRound()

        Haptics.prepare()
        openVoting(created)
    }

    /// Le roster a bougé pendant la partie. Les partants sortent des votants —
    /// sans quoi le téléphone attendrait indéfiniment quelqu'un qui n'est plus
    /// là — mais ils ne rejoignent pas les éliminés : partir n'est pas perdre.
    private func syncPlayers(_ participants: [Participant]) {
        guard let current = engine else { return }

        let stillHere = Set(participants.filter(\.isActive).map(\.id))
        let gone = current.players.filter { !stillHere.contains($0) && !current.withdrawn.contains($0) }
        guard !gone.isEmpty else { return }

        mutate { game in
            for id in gone { game.withdraw(id) }
        }

        let stranded: Bool
        switch step {
        case .pass(let waiting): stranded = gone.contains(waiting)
        case .dilemma: stranded = voter.map { gone.contains($0) } ?? false
        default: stranded = false
        }
        if stranded, let updated = engine { openVoting(updated) }
    }

    private func openVoting(_ current: WouldYouRatherEngine) {
        guard current.card != nil else {
            withAnimation(motion) { step = .results }
            return
        }
        // Plus assez de monde pour voter — la table s'est vidée en cours de
        // partie (spec §2.2). Sans cette sortie, l'écran attendrait un vote que
        // plus personne ne peut donner.
        if current.mode.identifiesVoters, current.voters.isEmpty || current.isOver {
            withAnimation(motion) { step = .results }
            return
        }
        if let next = current.nextVoter {
            withAnimation(motion) { step = .pass(next) }
        } else {
            voter = nil
            withAnimation(motion) { step = .dilemma }
        }
    }

    private func pick(_ side: DilemmaSide) {
        guard let current = engine, current.phase == .dilemma else { return }

        guard current.mode.identifiesVoters else {
            Haptics.tap()
            lastCounted = side
            mutate { _ = $0.countOpenVote(side) }
            return
        }

        guard let voter, current.votes[voter] == nil else { return }
        Haptics.impact(.medium)
        mutate { _ = $0.vote(side, by: voter) }
        withAnimation(motion) { picked = side }
        // La temporisation laisse la moitié s'ouvrir avant que le téléphone
        // change de main : sans elle, le votant ne voit pas son propre choix.
        advanceToken = UUID()
    }

    @MainActor
    private func waitThenContinue() async {
        guard advanceToken != nil else { return }
        let delay: UInt64 = reduced ? 250_000_000 : 550_000_000
        try? await Task.sleep(nanoseconds: delay)
        guard !Task.isCancelled else { return }
        continueVoting()
    }

    private func continueVoting() {
        guard let current = engine else { return }
        advanceToken = nil
        picked = nil

        if let next = current.nextVoter {
            withAnimation(motion) { step = .pass(next) }
        } else {
            revealSplit()
        }
    }

    private func revealSplit() {
        guard let current = engine, current.isReadyToReveal else { return }
        // En survie, c'est l'écran des survivants qui vibre — un `warning()`
        // annonce une élimination, pas une simple répartition.
        if current.mode != .survival { Haptics.impact(.light) }

        mutate { _ = $0.reveal() }
        barsFilled = false
        fallen.removeAll()
        eliminationSettled = false
        withAnimation(motion) { step = .split }
    }

    private func undoLastCount() {
        guard let side = lastCounted else { return }
        Haptics.tap()
        mutate { _ = $0.countOpenVote(side, delta: -1) }
        lastCounted = nil
    }

    /// Le rattrapage du mauvais tap : on revient sur la répartition, les votes
    /// déjà saisis restent, le comptage se corrige (spec §2.5).
    private func correctTally() {
        mutate { _ = $0.undoReveal() }
        withAnimation(motion) { step = .dilemma }
    }

    private func leaveSplit(_ current: WouldYouRatherEngine) {
        if current.mode == .survival {
            withAnimation(motion) { step = .survivors }
        } else {
            nextCard()
        }
    }

    private func nextCard() {
        guard var current = engine else { return }
        var generator = SystemRandomNumberGenerator()
        current.next(using: &generator)
        engine = current
        partyScores = current.scores

        guard current.phase != .finished else {
            withAnimation(motion) { step = .results }
            return
        }
        picked = nil
        lastCounted = nil
        openVoting(current)
    }

    private func endGame() {
        mutate { $0.finish() }
        withAnimation(motion) { step = .results }
    }

    /// La seule sortie vers l'accueil. Elle referme la fenêtre de manche : sans
    /// ça, un retrait de joueur au jeu suivant désactiverait au lieu de
    /// supprimer, et le prénom resterait barré dans le roster (spec §2.2).
    private func leaveGame() {
        roster.endRound()
        onExit()
    }

    /// Toute mutation du moteur passe par ici : le tableau des scores de la
    /// soirée est réécrit du même geste, il ne peut donc pas se désynchroniser.
    private func mutate(_ change: (inout WouldYouRatherEngine) -> Void) {
        guard var current = engine else { return }
        change(&current)
        engine = current
        partyScores = current.scores
    }

    // MARK: - Animations

    /// Une image de battement entre la remise à zéro et le départ : posées dans
    /// la même passe de rendu, les deux valeurs seraient fusionnées et
    /// l'animation ne partirait jamais.
    private static let settleDelay: UInt64 = 16_000_000

    /// Les deux moitiés entrent, puis le « ou ». Relancé à chaque carte par le
    /// `.task(id:)` : une nouvelle carte se pose, elle n'apparaît pas.
    @MainActor
    private func runEntrance() async {
        halvesEntered = false
        orPulsing = false
        picked = nil

        try? await Task.sleep(nanoseconds: Self.settleDelay)
        guard !Task.isCancelled else { return }

        // Sans `withAnimation` : chaque moitié porte son propre ressort, sinon
        // le retard de 60 ms de celle du bas n'aurait nulle part où vivre.
        halvesEntered = true
        refreshPulse()
    }

    /// La pulsation du « ou » est **la seule boucle infinie de l'app** : elle se
    /// coupe net dès que les animations réduites sont demandées (spec §4.3).
    /// L'animation vit dans `pulseAnimation`, ce qui suffit à l'arrêter.
    private func refreshPulse() {
        orPulsing = !reduced
    }

    @MainActor
    private func runBars() async {
        barsFilled = false
        guard !reduced else {
            barsFilled = true
            return
        }

        try? await Task.sleep(nanoseconds: Self.settleDelay)
        guard !Task.isCancelled else { return }
        // Le ressort de chaque barre vit dans `barAnimation` : c'est ce qui
        // permet de décaler la seconde sans deux états séparés.
        barsFilled = true
    }

    /// Les minoritaires tombent, décalés de 60 ms, puis se figent en place à
    /// 32 % d'opacité — ils ne sont jamais retirés de la grille (spec §4.2).
    @MainActor
    private func playElimination() async {
        let dropped = engine?.lastOutcome?.eliminated ?? []
        fallen.removeAll()
        eliminationSettled = false

        guard !dropped.isEmpty else {
            eliminationSettled = true
            return
        }

        Haptics.warning()

        guard !reduced else {
            withAnimation(.easeInOut(duration: 0.2)) { eliminationSettled = true }
            return
        }

        try? await Task.sleep(nanoseconds: Self.settleDelay)
        guard !Task.isCancelled else { return }

        for (index, id) in dropped.enumerated() {
            withAnimation(.easeIn(duration: 0.5).delay(Double(index) * 0.06)) {
                _ = fallen.insert(id)
            }
        }

        let total = 0.5 + Double(dropped.count - 1) * 0.06
        try? await Task.sleep(nanoseconds: UInt64(total * 1_000_000_000))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.25)) { eliminationSettled = true }
    }
}

// MARK: - Verrou d'écran secret

/// `secretScreen()` sous forme de modificateur conditionnel : le dilemme est un
/// écran secret en vote secret et en survie, un écran public en débat, et un
/// `if` dans un `body` changerait l'identité de la vue à chaque bascule.
private struct SecretLock: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.secretScreen()
        } else {
            content
        }
    }
}

#if DEBUG
private func previewRoster(_ names: [String]) -> RosterStore {
    let store = RosterStore(
        defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard,
        storageKey: "preview.roster.wyr"
    )
    store.seed(names: names)
    return store
}

#Preview("Tu préfères ? — réglages") {
    WouldYouRatherView(
        roster: previewRoster(["Léa", "Tom", "Nino", "Sarah"]),
        settings: AppSettings(defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard)
    )
}
#endif
