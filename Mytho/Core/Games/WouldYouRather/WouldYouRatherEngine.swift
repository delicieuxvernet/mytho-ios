import Foundation

// MARK: - Modes

/// Les trois façons de jouer « Tu préfères ? » (spec §4.1).
///
/// Elles ne changent **que** deux choses : le moteur sait-il qui a voté, et
/// que fait-il de la minorité. Même paquet, mêmes écrans, un seul moteur —
/// trois moteurs séparés seraient trois fois la même chose à corriger.
enum WouldYouRatherMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    /// Tout le monde annonce son choix à voix haute, le porteur compte.
    case debate
    /// Le téléphone circule, chacun vote sans être vu, révélation simultanée.
    case secret
    /// Chacun vote, la minorité est éliminée. Dernier debout.
    case survival

    var id: String { rawValue }

    var title: String {
        switch self {
        case .debate: return "Débat"
        case .secret: return "Vote secret"
        case .survival: return "Survie"
        }
    }

    var tagline: String {
        switch self {
        case .debate: return "Chacun annonce, tu comptes les mains."
        case .secret: return "Le téléphone circule, tout se révèle d'un coup."
        case .survival: return "La minorité saute. Dernier debout."
        }
    }

    /// Vrai quand le moteur a besoin de savoir **qui** a voté quoi. C'est la
    /// seule différence de fond entre les modes — et c'est aussi ce qui impose
    /// les prénoms : le mode débat, lui, se lance sans roster (spec §4.5).
    var identifiesVoters: Bool { self != .debate }

    /// Deux joueurs suffisent partout : en survie, le premier vote non partagé
    /// désigne déjà un survivant.
    var minimumPlayers: Int { identifiesVoters ? 2 : 0 }
}

// MARK: - Les deux moitiés de l'écran

/// Le côté d'un dilemme. Nommé plutôt que booléen : `vote(.a)` se relit,
/// `vote(true)` demande d'aller vérifier lequel des deux est « vrai ».
enum DilemmaSide: String, CaseIterable, Hashable, Sendable {
    case a
    case b

    var other: DilemmaSide { self == .a ? .b : .a }
}

// MARK: - Longueur de partie

/// Nombre de cartes d'une partie (spec §4.5). **Ignoré en mode survie** : cette
/// partie-là s'arrête sur le dernier debout, pas sur un compteur.
enum WouldYouRatherLimit: Hashable, Identifiable, Sendable {
    case cards(Int)
    case endless

    static let choices: [WouldYouRatherLimit] = [.cards(8), .cards(15), .cards(25), .endless]

    /// Milieu de la fourchette : assez long pour que le jeu s'installe, assez
    /// court pour enchaîner sur un autre. La spec ne tranche pas pour ce jeu,
    /// contrairement au « plus susceptible de » (§3.6).
    static let standard = WouldYouRatherLimit.cards(15)

    var id: String {
        switch self {
        case .cards(let total): return "cards-\(total)"
        case .endless: return "endless"
        }
    }

    var label: String {
        switch self {
        case .cards(let total): return "\(total) cartes"
        case .endless: return "Sans fin"
        }
    }

    /// `nil` en mode sans fin : c'est le porteur qui arrête la partie.
    var total: Int? {
        switch self {
        case .cards(let total): return total
        case .endless: return nil
        }
    }
}

// MARK: - Moteur

/// Le moteur de « Tu préfères ? » — **un seul pour les trois modes** (spec §4.1).
///
/// Valeur pure, sans SwiftUI ni horloge : il se rejoue à l'identique en test,
/// générateur aléatoire injecté comme dans `GameEngine`. Il consomme le socle
/// (§2) plutôt que de le refaire : `Deck` pour la pioche sans répétition,
/// `ScoreBoard` pour les points et l'annulation.
///
/// Cycle d'une carte : `.dilemma` (on vote) → `reveal()` → `.split` (on montre
/// la répartition) → `next()` → carte suivante ou `.finished`.
struct WouldYouRatherEngine {

    // MARK: Phases

    enum Phase: Hashable, Sendable {
        /// La carte est posée, les votes se récoltent.
        case dilemma
        /// La répartition est révélée — et, en survie, la minorité est tombée.
        case split
        case finished
    }

    // MARK: Répartition

    /// Le décompte d'une carte. Une seule source de vérité pour l'affichage,
    /// le barème et l'élimination : les trois lisent la même majorité.
    struct Tally: Equatable, Sendable {
        let a: Int
        let b: Int

        var total: Int { a + b }

        func count(_ side: DilemmaSide) -> Int { side == .a ? a : b }

        /// Part d'un côté, de 0 à 1. Une carte sans vote rend 0,5 : les deux
        /// moitiés restent à égalité à l'écran au lieu de s'effondrer.
        func share(_ side: DilemmaSide) -> Double {
            guard total > 0 else { return 0.5 }
            return Double(count(side)) / Double(total)
        }

        var isTie: Bool { a == b }

        /// `nil` sur une égalité parfaite. Il n'y a alors ni majorité ni
        /// minorité — et c'est exactement ce qui sauve la table en mode survie
        /// (spec §4.1) : sans ça, la partie s'arrêterait sur un coup de dé.
        var majority: DilemmaSide? {
            guard !isTie else { return nil }
            return a > b ? .a : .b
        }

        var minority: DilemmaSide? { majority?.other }
    }

    // MARK: Résultat d'une carte

    struct Outcome: Equatable, Sendable {
        let card: Dilemma
        let tally: Tally
        /// Vide hors mode survie, vide aussi sur une égalité et sur un vote
        /// unanime — dans les deux cas il n'y a personne du côté minoritaire.
        /// Toujours dans l'ordre du roster : la grille ne doit pas se réordonner.
        let eliminated: [UUID]
        /// Ceux qui viennent de marquer. Vide en mode débat, où personne n'est
        /// nommé.
        let scored: [UUID]

        var isTie: Bool { tally.isTie }
    }

    // MARK: Paquet

    /// Un seul identifiant de paquet pour les trois modes : changer de mode en
    /// cours de soirée ne doit pas faire revenir les dilemmes déjà vus.
    static let deckID = "would-you-rather.v3"

    static func makeDeck(
        adultUnlocked: Bool = false,
        extremeEnabled: Bool = false,
        store: any DeckMemoryStore = UserDefaultsDeckMemory.shared
    ) -> Deck<Dilemma> {
        Deck(
            id: deckID,
            items: WouldYouRatherBank.dilemmas(adultUnlocked: adultUnlocked, extremeEnabled: extremeEnabled),
            store: store
        )
    }

    // MARK: Configuration

    let mode: WouldYouRatherMode
    let limit: WouldYouRatherLimit
    /// Tous les joueurs de la partie, dans l'ordre du roster. Vide en mode
    /// débat. Les éliminés et les partis y restent : la grille des survivants
    /// les montre encore (spec §4.2).
    let players: [UUID]

    // MARK: État

    private(set) var deck: Deck<Dilemma>
    private(set) var scores: ScoreBoard
    private(set) var phase: Phase = .dilemma

    /// `nil` uniquement si le paquet est vide — la partie s'arrête alors net.
    private(set) var card: Dilemma?
    /// Vrai sur la carte qui ouvre un nouveau tour de paquet : « tu as fait le
    /// tour du paquet » ne s'affiche que là (spec §2.4).
    private(set) var startsNewLap = false
    /// Cartes révélées depuis le début de la partie.
    private(set) var cardsPlayed = 0

    /// Votes nominatifs — vote secret et survie. C'est ce qui permet d'éliminer.
    private(set) var votes: [UUID: DilemmaSide] = [:]
    /// Comptage anonyme du mode débat : deux compteurs, aucun nom.
    private(set) var openVotes: [DilemmaSide: Int] = [:]

    /// Encore en jeu, dans l'ordre du roster. En survie, c'est la liste qui fond.
    private(set) var survivors: [UUID] = []
    /// Sortis du jeu, du premier tombé au dernier.
    private(set) var eliminated: [UUID] = []
    /// Partis de la soirée. Ni votants, ni éliminés : quelqu'un part toujours en
    /// avance, et ce n'est pas une défaite (spec §2.2).
    private(set) var withdrawn: [UUID] = []

    private(set) var lastOutcome: Outcome?

    // MARK: Création

    init(
        mode: WouldYouRatherMode,
        limit: WouldYouRatherLimit = .standard,
        players: [UUID] = [],
        deck: Deck<Dilemma>,
        scores: ScoreBoard = ScoreBoard()
    ) {
        self.mode = mode
        self.limit = limit
        self.players = players
        self.deck = deck
        self.scores = scores
        self.survivors = players
        self.scores.register(players)
    }

    // MARK: Départ

    /// Pioche la première carte. Séparé de l'init pour que le générateur soit
    /// injecté à chaque tirage plutôt que retenu par le moteur.
    ///
    /// Les points de la soirée ne sont **pas** remis à zéro : le tableau est
    /// partagé par les cinq jeux, une partie relancée ne l'efface pas.
    mutating func start(using generator: inout some RandomNumberGenerator) {
        cardsPlayed = 0
        eliminated.removeAll()
        survivors = players.filter { !withdrawn.contains($0) }
        lastOutcome = nil
        drawCard(using: &generator)
    }

    // MARK: Votants

    /// Qui doit voter sur la carte en cours. Vide en mode débat : personne n'est
    /// nommé, le porteur compte des mains levées.
    var voters: [UUID] {
        guard mode.identifiesVoters else { return [] }
        guard mode == .survival else { return players.filter { !withdrawn.contains($0) } }
        return survivors
    }

    /// Ceux dont on attend encore le vote, dans l'ordre du roster.
    var pendingVoters: [UUID] { voters.filter { votes[$0] == nil } }

    /// Le prochain à qui passer le téléphone.
    var nextVoter: UUID? { pendingVoters.first }

    // MARK: Voter

    /// Vote nominatif (vote secret et survie). Refusé si le joueur n'est pas
    /// attendu sur cette carte — un éliminé ne revote pas.
    @discardableResult
    mutating func vote(_ side: DilemmaSide, by playerID: UUID) -> Bool {
        guard phase == .dilemma, voters.contains(playerID) else { return false }
        votes[playerID] = side
        return true
    }

    /// Comptage du mode débat : un tap du porteur = une main de plus de ce côté.
    /// Un `delta` négatif rattrape le tap de trop, sans jamais passer sous zéro.
    @discardableResult
    mutating func countOpenVote(_ side: DilemmaSide, delta: Int = 1) -> Bool {
        guard phase == .dilemma, !mode.identifiesVoters else { return false }
        openVotes[side] = max(0, (openVotes[side] ?? 0) + delta)
        return true
    }

    /// Le décompte courant, quelle que soit la façon dont il a été récolté.
    var tally: Tally {
        var a = openVotes[.a] ?? 0
        var b = openVotes[.b] ?? 0
        for side in votes.values {
            switch side {
            case .a: a += 1
            case .b: b += 1
            }
        }
        return Tally(a: a, b: b)
    }

    /// Vrai quand la répartition peut s'afficher : tout le monde a voté, ou —
    /// en débat — au moins une main a été comptée.
    var isReadyToReveal: Bool {
        guard phase == .dilemma, card != nil else { return false }
        guard mode.identifiesVoters else { return tally.total > 0 }
        return !voters.isEmpty && pendingVoters.isEmpty
    }

    // MARK: Révéler

    /// Ferme la carte : barème appliqué, minorité éliminée en survie.
    ///
    /// **Barème** — un point à chacun des majoritaires. Une seule règle pour les
    /// trois modes : en survie, être avec la table est exactement ce qui
    /// distingue un survivant d'un éliminé, et en débat personne n'étant nommé,
    /// personne ne marque. Sur une égalité, il n'y a pas de majorité : ni point,
    /// ni élimination.
    @discardableResult
    mutating func reveal() -> Outcome? {
        guard isReadyToReveal, let card else { return nil }

        let tally = self.tally
        // Calculés avant toute mutation : `voters` suit `survivors` en survie.
        let scored = identifiedVoters(on: tally.majority)
        let dropped = mode == .survival ? identifiedVoters(on: tally.minority) : []

        if !scored.isEmpty { scores.award(1, to: scored) }

        if !dropped.isEmpty {
            survivors.removeAll { dropped.contains($0) }
            eliminated.append(contentsOf: dropped)
        }

        cardsPlayed += 1
        phase = .split

        let outcome = Outcome(card: card, tally: tally, eliminated: dropped, scored: scored)
        lastOutcome = outcome
        return outcome
    }

    /// Revient sur la révélation : les points reviennent, les éliminés aussi, et
    /// la carte se rejoue avec les votes déjà saisis. C'est le rattrapage du
    /// mauvais tap (spec §2.5) — sans lui, une élimination fautive fige la
    /// partie jusqu'à la fin.
    @discardableResult
    mutating func undoReveal() -> Bool {
        guard phase == .split, let outcome = lastOutcome else { return false }

        if !outcome.scored.isEmpty { scores.undoLast() }
        if !outcome.eliminated.isEmpty {
            eliminated.removeAll { outcome.eliminated.contains($0) }
            // Reconstruit depuis le roster : la grille garde son ordre d'origine
            // au lieu de renvoyer les revenants en fin de liste.
            survivors = players.filter { !eliminated.contains($0) && !withdrawn.contains($0) }
        }

        cardsPlayed -= 1
        lastOutcome = nil
        phase = .dilemma
        return true
    }

    // MARK: Carte suivante

    mutating func next(using generator: inout some RandomNumberGenerator) {
        guard phase == .split else { return }
        guard !isOver else {
            phase = .finished
            return
        }
        drawCard(using: &generator)
    }

    /// Sortie du mode sans fin : c'est la table qui décide d'arrêter.
    mutating func finish() {
        phase = .finished
    }

    /// Quelqu'un quitte la soirée. Il n'est **pas** éliminé : il sort des
    /// votants sans entrer dans la liste des sortis du jeu, et ses points lui
    /// restent (spec §2.2).
    mutating func withdraw(_ playerID: UUID) {
        guard !withdrawn.contains(playerID) else { return }
        withdrawn.append(playerID)
        survivors.removeAll { $0 == playerID }
        votes[playerID] = nil
    }

    // MARK: Fin de partie

    var isOver: Bool {
        switch mode {
        case .survival:
            // Le compteur de cartes ne s'applique pas ici (spec §4.5).
            return survivors.count <= 1
        case .debate, .secret:
            guard let total = limit.total else { return false }
            return cardsPlayed >= total
        }
    }

    /// Le duel final : à deux, **aucun vote ne peut plus éliminer personne**.
    /// 1-1 est une égalité, et 2-0 laisse le côté minoritaire vide — dans les
    /// deux cas la règle de la spec ne désigne personne.
    ///
    /// La spec assume la boucle (« on passe la carte, indéfiniment s'il le
    /// faut », §4.5) mais annonce aussi un « dernier debout » que le vote ne
    /// peut donc pas produire. Le moteur expose l'état plutôt que d'inventer un
    /// départage : c'est à la table de continuer ou d'arrêter à égalité.
    var isFinalDuel: Bool {
        mode == .survival && survivors.count == 2
    }

    /// Le ou les vainqueurs. En survie, le dernier debout ; ailleurs, la tête du
    /// classement — plusieurs en cas d'égalité, ce qui arrive souvent.
    var champions: [UUID] {
        mode == .survival ? survivors : scores.leaders
    }

    // MARK: Interne

    private mutating func drawCard(using generator: inout some RandomNumberGenerator) {
        votes.removeAll()
        openVotes.removeAll()
        // L'annulation ne doit jamais remonter à la carte précédente : un
        // « annuler » tardif retirerait un point sans que personne ne comprenne
        // lequel (spec §2.5).
        scores.startRound()

        guard let draw = deck.draw(using: &generator) else {
            card = nil
            startsNewLap = false
            phase = .finished
            return
        }

        card = draw.item
        startsNewLap = draw.startsNewLap
        phase = .dilemma
    }

    /// Les votants d'un côté, dans l'ordre du roster. `nil` (égalité) ne
    /// désigne personne. Nom distinct de la propriété `voters` : une méthode et
    /// une propriété homonymes rendraient chaque usage ambigu à la lecture.
    private func identifiedVoters(on side: DilemmaSide?) -> [UUID] {
        guard let side else { return [] }
        return voters.filter { votes[$0] == side }
    }
}
