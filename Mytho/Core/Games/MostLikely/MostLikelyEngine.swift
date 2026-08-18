import Foundation

// MARK: - Décompte

/// Les vibrations du décompte, décrites en donnée plutôt qu'appelées : le moteur
/// reste une valeur pure, et l'ordre des retours haptiques devient vérifiable
/// sans interface (checklist §3). La vue traduit en `Haptics.impact(...)`.
enum MostLikelyHaptic: Equatable, Sendable {
    case light
    case heavy
}

/// Un temps du décompte : ce qui s'affiche, ce qui vibre, combien de temps.
struct MostLikelyCountdownStep: Equatable, Sendable {
    let label: String
    let haptic: MostLikelyHaptic
    let duration: TimeInterval
}

/// « 3 · 2 · 1 · Pointez », ~2,4 s au total (spec §3.1).
///
/// La vibration lourde sur « Pointez » est ce qui synchronise la table, pas
/// l'écran : à cet instant, personne ne regarde le téléphone.
enum MostLikelyCountdown {

    /// Quatre temps égaux : un décompte irrégulier ne se suit pas à l'oreille.
    static let stepDuration: TimeInterval = 0.6

    static let steps: [MostLikelyCountdownStep] = [
        MostLikelyCountdownStep(label: "3", haptic: .light, duration: stepDuration),
        MostLikelyCountdownStep(label: "2", haptic: .light, duration: stepDuration),
        MostLikelyCountdownStep(label: "1", haptic: .light, duration: stepDuration),
        MostLikelyCountdownStep(label: "Pointez", haptic: .heavy, duration: stepDuration)
    ]

    static var duration: TimeInterval { steps.reduce(0) { $0 + $1.duration } }
}

// MARK: - Moteur

/// Moteur du « plus susceptible de… ». Logique pure, sans SwiftUI ni effet de
/// bord : tout se rejoue à l'identique en injectant un générateur aléatoire,
/// comme `GameEngine`.
///
/// Il ne fait qu'assembler deux briques du socle — `Deck` pour la pioche sans
/// répétition, `ScoreBoard` pour les points et l'annulation — autour d'une
/// boucle de quatre temps : carte, décompte, désignation, résultat.
///
/// Volontairement **pas** `Sendable` : `Deck` porte son magasin de mémoire
/// (une classe) et sa fonction d'identité. Le moteur vit sur le main thread,
/// dans le `@State` de l'écran.
struct MostLikelyEngine {

    // MARK: Constantes

    /// Doit rester égal à l'identifiant du jeu dans `GameRegistry` : c'est lui
    /// qui nomme la mémoire du paquet, et « réinitialiser les paquets » balaie
    /// par ce nom.
    static let gameID = "most-likely"

    /// En dessous de trois, le vote n'a plus de sens : chacun pointe l'autre
    /// (spec §3.6).
    static let minimumPlayers = 3

    /// Barème : le plus désigné marque un point. En cas d'égalité, chacun le
    /// marque — pas de demi-point, personne ne compte des demis à table.
    static let pointsForWinner = 1

    /// « Ex æquo » ouvre une deuxième désignation, jamais une troisième : au-delà
    /// ce n'est plus une égalité, c'est un match nul.
    static let maxDesignations = 2

    /// Inclinaison de la carte, figée au tirage : deux cartes ne se posent
    /// jamais pareil sur un vrai paquet.
    static let tiltRange: ClosedRange<Double> = -1.5...1.5

    // MARK: Réglages

    /// Une partie dure un nombre de manches, pas un score cible : le temps de jeu
    /// doit être prévisible (annexe de la spec).
    enum RoundLimit: String, CaseIterable, Hashable, Sendable {
        case six
        case twelve
        case twenty
        case endless

        /// `nil` en mode sans fin : c'est la table qui décide de s'arrêter.
        var rounds: Int? {
            switch self {
            case .six: return 6
            case .twelve: return 12
            case .twenty: return 20
            case .endless: return nil
            }
        }

        var label: String {
            switch self {
            case .six: return "6"
            case .twelve: return "12"
            case .twenty: return "20"
            case .endless: return "Sans fin"
            }
        }
    }

    /// Public par défaut, secret en option : le public est fluide, le secret est
    /// le vrai moment. L'un vend l'autre (spec §3.2).
    enum Counting: String, CaseIterable, Hashable, Sendable {
        case quick
        case secret

        var label: String {
            switch self {
            case .quick: return "Rapide"
            case .secret: return "Vote secret"
            }
        }
    }

    struct Options: Equatable, Sendable {
        var limit: RoundLimit = .twelve
        var counting: Counting = .quick
        var packs: Set<MostLikelyPack> = MostLikelyPack.defaultSelection
        /// L'état de la confirmation d'âge au moment du lancement. Faux par
        /// défaut : un paquet 18+ coché ne sort aucune carte tant que l'écran
        /// n'a pas transmis le déverrouillage.
        var adultUnlocked = false
    }

    // MARK: Résultat d'une manche

    /// Ce que l'écran de résultat a besoin de savoir, figé au moment du dépouillement.
    struct Outcome: Equatable {
        let card: MostLikelyCard
        /// Un prénom, ou deux en cas d'égalité. Vide seulement si plus personne
        /// n'était là pour voter.
        let winners: [UUID]
        /// Doigts par joueur. **Vide en mode rapide** : la table n'a pas compté,
        /// et afficher « 4 doigts sur 6 » sans les avoir comptés serait inventer.
        let tally: [UUID: Int]
        /// Nombre de bulletins dépouillés. Zéro en mode rapide.
        let voterCount: Int
        let points: Int

        var isCounted: Bool { voterCount > 0 }
        var isTie: Bool { winners.count > 1 }

        func fingers(for playerID: UUID) -> Int { tally[playerID] ?? 0 }
    }

    // MARK: Phases

    enum Phase: Equatable {
        /// La carte est posée, le décompte tourne.
        case card
        /// Grille de prénoms, mode rapide : un seul geste.
        case designation
        /// « Passe le téléphone à X », mode secret.
        case pass(voterIndex: Int)
        /// Grille de prénoms, à l'abri des regards.
        case ballot(voterIndex: Int)
        case result(Outcome)
        case finished
    }

    // MARK: État

    private(set) var options: Options
    /// Tous les joueurs, actifs ou partis : un joueur retiré garde ses points et
    /// sort seulement de la grille (spec §3.6).
    private(set) var players: [Participant]
    private(set) var scores: ScoreBoard
    private(set) var phase: Phase
    /// 1 pour la première manche : c'est le numéro affiché.
    private(set) var roundNumber: Int
    private(set) var card: MostLikelyCard
    /// Vrai sur la première carte d'un nouveau tour de paquet, et elle seule :
    /// « tu as fait le tour du paquet » ne s'affiche qu'une fois.
    private(set) var hasLoopedDeck: Bool
    private(set) var tilt: Double

    private var deck: Deck<MostLikelyCard>
    /// Ordre de passage du téléphone, figé à l'ouverture du vote secret.
    private var voters: [UUID]
    /// Bulletin de chacun : votant -> désigné. Jamais exposé, jamais annoncé.
    private var ballots: [UUID: UUID]

    // MARK: Cycle de vie

    /// Échoue si la table est trop petite ou si aucun paquet n'a de carte :
    /// mieux vaut ne pas lancer que lancer une partie injouable.
    init?(
        players: [Participant],
        options: Options = Options(),
        scores: ScoreBoard? = nil,
        store: any DeckMemoryStore = UserDefaultsDeckMemory.shared,
        using generator: inout some RandomNumberGenerator
    ) {
        guard players.filter(\.isActive).count >= Self.minimumPlayers else { return nil }

        var deck = Deck<MostLikelyCard>(
            id: Self.gameID,
            items: MostLikelyBank.cards(for: options.packs, adultUnlocked: options.adultUnlocked),
            store: store
        )
        guard let first = deck.draw(using: &generator) else { return nil }

        // Les points de la soirée se reprennent tels quels : changer de jeu ne
        // remet pas la table à zéro (spec §2.7).
        var board = scores ?? ScoreBoard(playerIDs: players.map(\.id))
        board.register(players.map(\.id))
        board.startRound()

        self.options = options
        self.players = players
        self.scores = board
        self.deck = deck
        self.phase = .card
        self.roundNumber = 1
        self.card = first.item
        self.hasLoopedDeck = first.startsNewLap
        self.tilt = Double.random(in: Self.tiltRange, using: &generator)
        self.voters = []
        self.ballots = [:]
    }

    /// La partie réelle n'a pas de graine.
    init?(
        players: [Participant],
        options: Options = Options(),
        scores: ScoreBoard? = nil,
        store: any DeckMemoryStore = UserDefaultsDeckMemory.shared
    ) {
        var generator = SystemRandomNumberGenerator()
        self.init(players: players, options: options, scores: scores, store: store, using: &generator)
    }

    // MARK: Décompte

    /// « Pointez » vient d'être annoncé : la table a pointé, on relève.
    mutating func countdownFinished() {
        guard phase == .card else { return }

        switch options.counting {
        case .quick:
            phase = .designation
        case .secret:
            // L'ordre de passage est figé ici : un joueur qui s'ajoute en plein
            // tour ne doit pas s'intercaler entre deux bulletins.
            voters = candidates.map(\.id)
            ballots = [:]
            phase = voters.isEmpty ? .designation : .pass(voterIndex: 0)
        }
    }

    // MARK: Mode rapide

    /// Le porteur valide le prénom le plus désigné — deux en cas d'ex æquo.
    /// Renvoie faux si la désignation est vide, trop large ou hors table.
    @discardableResult
    mutating func designate(_ playerIDs: [UUID]) -> Bool {
        guard phase == .designation else { return false }

        var unique: [UUID] = []
        for id in playerIDs where !unique.contains(id) { unique.append(id) }

        let table = Set(candidates.map(\.id))
        guard (1...Self.maxDesignations).contains(unique.count),
              unique.allSatisfy({ table.contains($0) })
        else { return false }

        award(winners: unique, tally: [:], voterCount: 0)
        return true
    }

    /// Rattrape un mauvais tap : les points repartent, la grille revient.
    ///
    /// Réservé au mode rapide — refaire circuler le téléphone après un
    /// dépouillement remontrerait des bulletins déjà lus.
    @discardableResult
    mutating func undoDesignation() -> Bool {
        guard case .result = phase, options.counting == .quick, scores.canUndo else { return false }
        scores.undoLast()
        phase = .designation
        return true
    }

    // MARK: Vote secret

    /// Le joueur annoncé a pris l'appareil : on lui ouvre la grille.
    mutating func takePhone() {
        guard case .pass(let index) = phase else { return }
        phase = .ballot(voterIndex: index)
    }

    /// Bulletin déposé. Passe au votant suivant, ou dépouille si c'était le dernier.
    @discardableResult
    mutating func castBallot(for playerID: UUID) -> Bool {
        guard case .ballot(let index) = phase,
              voters.indices.contains(index),
              candidates.contains(where: { $0.id == playerID })
        else { return false }

        ballots[voters[index]] = playerID

        let next = index + 1
        if next < voters.count {
            phase = .pass(voterIndex: next)
        } else {
            closeSecretRound()
        }
        return true
    }

    private mutating func closeSecretRound() {
        var tally: [UUID: Int] = [:]
        for designated in ballots.values { tally[designated, default: 0] += 1 }

        let best = tally.values.max() ?? 0
        // Parcours du roster et non du dictionnaire : deux dépouillements du même
        // vote ne doivent jamais permuter deux prénoms à égalité.
        var winners: [UUID] = []
        if best > 0 {
            winners = players.map(\.id).filter { tally[$0] == best }
        }

        award(winners: winners, tally: tally, voterCount: ballots.count)
    }

    // MARK: Manches

    /// Carte suivante, ou classement final si la dernière manche est jouée.
    mutating func nextRound(using generator: inout some RandomNumberGenerator) {
        guard case .result = phase else { return }

        if let total = options.limit.rounds, roundNumber >= total {
            phase = .finished
            return
        }
        guard let draw = deck.draw(using: &generator) else {
            phase = .finished
            return
        }

        card = draw.item
        hasLoopedDeck = draw.startsNewLap
        tilt = Double.random(in: Self.tiltRange, using: &generator)
        roundNumber += 1
        voters = []
        ballots = [:]
        // L'annulation ne vaut que pour la manche en cours : un « corriger »
        // tardif retirerait un point sans que personne ne comprenne lequel.
        scores.startRound()
        phase = .card
    }

    mutating func nextRound() {
        var generator = SystemRandomNumberGenerator()
        nextRound(using: &generator)
    }

    /// Sortie du mode sans fin : la table décide d'arrêter.
    mutating func finishNow() {
        guard phase != .finished else { return }
        phase = .finished
    }

    // MARK: Roster mouvant

    /// Le roster a bougé en cours de partie. Les points restent attachés aux
    /// identifiants, donc un départ ne coûte rien à personne ; le joueur sort
    /// seulement de la grille (spec §3.6).
    mutating func syncPlayers(_ updated: [Participant]) {
        players = updated
        scores.register(updated.filter(\.isActive).map(\.id))

        switch phase {
        case .pass(let index), .ballot(let index):
            // Un joueur parti ne prend plus le téléphone. Les bulletins déjà
            // déposés restent : ils ont été exprimés, ils comptent.
            let stillHere = Set(updated.filter(\.isActive).map(\.id))
            let done = Array(voters.prefix(index))
            let waiting = voters.dropFirst(index).filter { stillHere.contains($0) }
            voters = done + waiting

            if index >= voters.count {
                closeSecretRound()
            } else {
                // Retour au passage du téléphone : le prénom annoncé a pu changer
                // sous les doigts de celui qui s'apprêtait à voter.
                phase = .pass(voterIndex: index)
            }
        default:
            break
        }
    }

    // MARK: Lecture

    /// Les joueurs encore à table : la grille de désignation, et rien d'autre.
    var candidates: [Participant] { players.filter(\.isActive) }

    var hasEnoughPlayers: Bool { candidates.count >= Self.minimumPlayers }

    var totalRounds: Int? { options.limit.rounds }

    var isLastRound: Bool {
        guard let total = totalRounds else { return false }
        return roundNumber >= total
    }

    var isFinished: Bool { phase == .finished }

    /// L'annulation n'est proposée que là où elle est sans danger.
    var canUndo: Bool { options.counting == .quick && scores.canUndo }

    var standings: [ScoreBoard.Standing] { scores.standings }

    /// Les joueurs en tête — plusieurs en cas d'égalité parfaite.
    var champions: [UUID] { scores.leaders }

    /// Celui qui doit prendre le téléphone, pendant un vote secret.
    var currentVoter: Participant? {
        switch phase {
        case .pass(let index), .ballot(let index):
            guard voters.indices.contains(index) else { return nil }
            return player(id: voters[index])
        default:
            return nil
        }
    }

    var voterCount: Int { voters.count }
    var votesCast: Int { ballots.count }

    func player(id: UUID) -> Participant? { players.first { $0.id == id } }

    func name(for playerID: UUID) -> String { player(id: playerID)?.name ?? "—" }

    func score(for playerID: UUID) -> Int { scores.score(for: playerID) }

    // MARK: Outils

    private mutating func award(winners: [UUID], tally: [UUID: Int], voterCount: Int) {
        if !winners.isEmpty {
            scores.award(Self.pointsForWinner, to: winners)
        }
        phase = .result(
            Outcome(
                card: card,
                winners: winners,
                tally: tally,
                voterCount: voterCount,
                points: Self.pointsForWinner
            )
        )
    }
}
