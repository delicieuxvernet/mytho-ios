import Foundation

/// Moteur d'une manche. Logique pure, sans SwiftUI ni effet de bord : tout est
/// testable et rejouable à l'identique en injectant un générateur aléatoire.
///
/// Le déroulé suit celui du jeu de société : distribution des cartes face cachée,
/// puis des cycles description -> vote -> élimination jusqu'à ce qu'un camp gagne.
struct GameEngine: Sendable {

    // MARK: État

    private(set) var config: GameConfig
    private(set) var players: [Player]
    private(set) var phase: GamePhase

    /// Le mot majoritaire, donné aux civils.
    private(set) var civilianWord: String
    /// Le mot proche, donné aux undercover.
    private(set) var undercoverWord: String

    /// Le paquet face cachée : les rôles restant à piocher, dans l'ordre des cartes.
    /// Une case passe à `nil` dès que la carte a été prise.
    private(set) var deck: [Role?]

    /// Ordre de parole de la manche en cours, recalculé à chaque tour.
    private(set) var speakingOrder: [UUID]

    /// Points cumulés sur la manche qui vient de s'achever (vide avant la fin).
    private(set) var roundPoints: [UUID: Int] = [:]

    /// Répartition des pouvoirs effectivement retenus pour cette manche.
    private(set) var specialRoles: [SpecialRole: [UUID]] = [:]

    /// Le duelliste tombé le premier, s'il y en a un.
    private(set) var duelLoser: UUID?

    /// Joueur qui doit mimer son mot à ce tour, si la variante est active.
    private(set) var mimePlayerID: UUID?

    /// Vengeuse en attente : elle a été révélée en même temps que Mr. White,
    /// dont la dernière chance passe avant.
    private var pendingAvenger: UUID?

    /// Numéro du tour de description en cours.
    private var roundNumber = 0

    // MARK: Cycle de vie

    /// Prépare une manche : tire la paire de mots, constitue et mélange le paquet.
    init(
        config: GameConfig,
        pair: WordPair,
        players: [Player]? = nil,
        using generator: inout some RandomNumberGenerator
    ) {
        var cfg = config
        (cfg.undercoverCount, cfg.mrWhiteCount) = Composition.clamp(
            undercover: cfg.undercoverCount,
            mrWhite: cfg.mrWhiteCount,
            playerCount: cfg.playerCount
        )
        self.config = cfg

        // Quel mot de la paire va aux civils : tiré au sort, sinon le premier
        // joueur pourrait déduire son camp en reconnaissant « le mot de gauche ».
        if Bool.random(using: &generator) {
            self.civilianWord = pair.a
            self.undercoverWord = pair.b
        } else {
            self.civilianWord = pair.b
            self.undercoverWord = pair.a
        }

        self.players = players ?? cfg.playerNames.map { Player(name: $0) }

        var roles: [Role] = []
        roles.append(contentsOf: Array(repeating: .undercover, count: cfg.undercoverCount))
        roles.append(contentsOf: Array(repeating: .mrWhite, count: cfg.mrWhiteCount))
        roles.append(contentsOf: Array(repeating: .civilian, count: max(0, cfg.civilianCount)))
        roles.shuffle(using: &generator)
        self.deck = roles.map { Optional($0) }

        self.speakingOrder = []
        self.phase = .dealing(playerIndex: 0)

        // Les pouvoirs sont attribués aux joueurs, pas aux cartes : ils sont
        // indépendants du rôle pioché, et un joueur peut être Civil ET Vengeuse.
        let playable = SpecialRoleAssignment.playable(cfg.specialRoles, playerCount: cfg.playerCount)
        self.config.specialRoles = playable
        self.specialRoles = SpecialRoleAssignment.assign(playable, to: self.players, using: &generator)

        for (role, ids) in self.specialRoles {
            for id in ids {
                guard let index = self.players.firstIndex(where: { $0.id == id }) else { continue }
                self.players[index].specialRole = role
            }
        }
    }

    // MARK: Distribution

    /// Le joueur dont c'est le tour prend la carte à `cardIndex`.
    /// Retourne le rôle révélé, ou nil si le coup est invalide.
    @discardableResult
    mutating func pickCard(at cardIndex: Int) -> Role? {
        guard case .dealing(let playerIndex) = phase,
              players.indices.contains(playerIndex),
              // Un joueur ne pioche qu'une fois : sans ce garde, un retour en
              // arrière lui laissait reprendre une carte, et le dernier joueur
              // trouvait un paquet vide — distribution impossible à terminer.
              players[playerIndex].role == nil,
              deck.indices.contains(cardIndex),
              let role = deck[cardIndex]
        else { return nil }

        deck[cardIndex] = nil
        players[playerIndex].role = role
        players[playerIndex].pickedCardIndex = cardIndex
        return role
    }

    /// Passe au joueur suivant, ou démarre la partie si tout le monde a pioché.
    mutating func advanceDealing(using generator: inout some RandomNumberGenerator) {
        guard case .dealing(let playerIndex) = phase else { return }
        guard players[playerIndex].role != nil else { return }

        let next = playerIndex + 1
        if next < players.count {
            phase = .dealing(playerIndex: next)
        } else {
            startRound(1, using: &generator)
        }
    }

    // MARK: Tours de description

    private mutating func startRound(_ round: Int, using generator: inout some RandomNumberGenerator) {
        roundNumber = round
        speakingOrder = makeSpeakingOrder(using: &generator)
        // La variante du mime désigne un joueur différent à chaque tour. Mr. White en est
        // exclu : mimer un mot qu'on n'a pas le trahirait immédiatement.
        mimePlayerID = config.tableRules.contains(.mime)
            ? players.filter { $0.isAlive && $0.role != .mrWhite }.randomElement(using: &generator)?.id
            : nil
        phase = .describing(round: round)
    }

    /// Ordre de parole aléatoire parmi les joueurs encore en vie.
    /// Sauf option contraire, Mr. White ne peut pas ouvrir : sans mot ni indice
    /// préalable, il serait démasqué à tous les coups.
    private func makeSpeakingOrder(using generator: inout some RandomNumberGenerator) -> [UUID] {
        var alive = players.filter(\.isAlive)
        alive.shuffle(using: &generator)

        if !config.mrWhiteCanStart, alive.count > 1, alive[0].role == .mrWhite {
            // On échange avec un joueur non-Mr. White s'il en existe un.
            if let swapIndex = alive.dropFirst().firstIndex(where: { $0.role != .mrWhite }) {
                alive.swapAt(0, swapIndex)
            }
        }
        return alive.map(\.id)
    }

    /// Fin de la phase de description : on passe au vote.
    mutating func startVote() {
        guard case .describing = phase else { return }
        phase = .voting
    }

    // MARK: Élimination

    /// Élimine un joueur et révèle son rôle. Le vote lui-même se fait à la table.
    mutating func eliminate(playerID: UUID) {
        guard case .voting = phase else { return }
        let fallen = applyElimination(of: playerID)
        guard !fallen.isEmpty else { return }
        phase = .elimination(playerIDs: fallen)
    }

    /// Marque un joueur comme éliminé, en emportant son amoureux s'il en a un.
    /// Retourne tous les joueurs tombés, dans l'ordre de révélation.
    @discardableResult
    private mutating func applyElimination(of playerID: UUID) -> [UUID] {
        guard let index = players.firstIndex(where: { $0.id == playerID }),
              players[index].isAlive
        else { return [] }

        players[index].isAlive = false
        recordDuelIfNeeded(players[index])
        var fallen = [playerID]

        // Les Amoureux tombent ensemble. Un seul niveau de propagation suffit :
        // un joueur ne porte qu'un pouvoir, l'amoureux entraîné ne peut donc pas
        // en entraîner un troisième.
        if players[index].specialRole == .lovers {
            for partner in players.indices
            where players[partner].specialRole == .lovers
                && players[partner].id != playerID
                && players[partner].isAlive {
                players[partner].isAlive = false
                recordDuelIfNeeded(players[partner])
                fallen.append(players[partner].id)
            }
        }
        return fallen
    }

    /// Le premier duelliste éliminé perd des points, son rival en gagne.
    private mutating func recordDuelIfNeeded(_ player: Player) {
        guard player.specialRole == .duelists, duelLoser == nil else { return }
        duelLoser = player.id
    }

    /// Enchaîne après la révélation : Mr. White tente sa chance, la Vengeuse
    /// frappe, ou l'on vérifie les conditions de victoire.
    mutating func resolveElimination(using generator: inout some RandomNumberGenerator) {
        guard case .elimination(let playerIDs) = phase else { return }
        let fallen = playerIDs.compactMap { id in players.first { $0.id == id } }

        // Mr. White d'abord : sa dernière chance peut clore la manche avant
        // même que la Vengeuse ait à choisir sa victime.
        if let white = fallen.first(where: { $0.role == .mrWhite }) {
            pendingAvenger = fallen.first { $0.specialRole == .avenger }?.id
            phase = .mrWhiteGuess(playerID: white.id)
            return
        }
        if let avenger = fallen.first(where: { $0.specialRole == .avenger }), canAvengerStrike {
            phase = .avengerStrike(playerID: avenger.id)
            return
        }
        continueOrFinish(using: &generator)
    }

    /// La Vengeuse n'a de sens que s'il reste quelqu'un à emmener.
    private var canAvengerStrike: Bool {
        players.filter(\.isAlive).count >= 2
    }

    /// La Vengeuse éliminée désigne le joueur qu'elle emmène avec elle.
    mutating func avengerStrikes(playerID: UUID, using generator: inout some RandomNumberGenerator) {
        guard case .avengerStrike = phase else { return }
        let fallen = applyElimination(of: playerID)
        guard !fallen.isEmpty else { return }
        phase = .elimination(playerIDs: fallen)
    }

    /// Mr. White éliminé propose un mot. Retourne `true` s'il a vu juste.
    @discardableResult
    mutating func submitMrWhiteGuess(_ guess: String, using generator: inout some RandomNumberGenerator) -> Bool {
        guard case .mrWhiteGuess(let playerID) = phase else { return false }

        if Self.matches(guess: guess, word: civilianWord) {
            finish(.mrWhiteGuessedRight(playerID: playerID))
            return true
        }
        // La Vengeuse tombée dans la même charrette frappe une fois la
        // dernière chance de Mr. White consommée.
        if let avenger = pendingAvenger {
            pendingAvenger = nil
            if canAvengerStrike {
                phase = .avengerStrike(playerID: avenger)
                return false
            }
        }
        continueOrFinish(using: &generator)
        return false
    }

    /// Comparaison tolérante : casse, accents, espaces et articles ignorés.
    /// « LES chats » doit valider « Chat ».
    static func matches(guess: String, word: String) -> Bool {
        normalized(guess) == normalized(word)
    }

    private static func normalized(_ text: String) -> String {
        var value = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        for article in ["l'", "le ", "la ", "les ", "un ", "une ", "des ", "du "] where value.hasPrefix(article) {
            value = String(value.dropFirst(article.count))
            break
        }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // Pluriel simple : « chats » vaut « chat ».
        if value.count > 3, value.hasSuffix("s") { value = String(value.dropLast()) }
        return value
    }

    // MARK: Conditions de victoire

    private mutating func continueOrFinish(using generator: inout some RandomNumberGenerator) {
        let alive = players.filter(\.isAlive)
        let infiltrators = alive.filter { $0.role?.isInfiltrator == true }.count
        let civilians = alive.count - infiltrators

        if infiltrators == 0 {
            finish(.civiliansWin)
        } else if civilians <= 1 {
            // Les infiltrés ne peuvent plus être mis en minorité.
            finish(.infiltratorsWin)
        } else {
            // Le compteur explicite remplace l'ancienne déduction par nombre
            // d'éliminés : les chutes en cascade (Amoureux, Vengeuse) faisaient
            // sauter des numéros de tour à l'affichage.
            startRound(roundNumber + 1, using: &generator)
        }
    }

    private mutating func finish(_ outcome: RoundOutcome) {
        roundPoints = Self.points(for: outcome, players: players)
        applyDuelPoints()
        pendingAvenger = nil
        phase = .finished(outcome)
    }

    /// Le duel est un pari personnel, réglé quel que soit le camp gagnant :
    /// le premier duelliste tombé paie, l'autre encaisse.
    private mutating func applyDuelPoints() {
        guard let loser = duelLoser, let duelists = specialRoles[.duelists] else { return }
        for id in duelists {
            roundPoints[id, default: 0] += id == loser ? DuelScore.loser : DuelScore.survivor
        }
    }

    /// Barème : civils +2 chacun, undercover survivant +10, Mr. White +6
    /// (qu'il survive ou qu'il devine le mot).
    static func points(for outcome: RoundOutcome, players: [Player]) -> [UUID: Int] {
        var points: [UUID: Int] = [:]
        switch outcome {
        case .civiliansWin:
            for player in players where player.role == .civilian {
                points[player.id] = Score.civilianWin
            }
        case .infiltratorsWin:
            for player in players where player.isAlive {
                switch player.role {
                case .undercover: points[player.id] = Score.undercoverSurvives
                case .mrWhite: points[player.id] = Score.mrWhiteSurvives
                default: break
                }
            }
        case .mrWhiteGuessedRight(let playerID):
            points[playerID] = Score.mrWhiteGuessesRight
        }
        return points
    }

    // MARK: Accès de confort

    var alivePlayers: [Player] { players.filter(\.isAlive) }

    var isFinished: Bool {
        if case .finished = phase { return true }
        return false
    }

    /// La distribution est-elle en cours ? Sert à interdire tout retour en
    /// arrière tant que les cartes circulent : un état de distribution ramené
    /// à l'écran, c'est le mot d'un joueur affiché devant les autres.
    var isDealing: Bool {
        if case .dealing = phase { return true }
        return false
    }

    var outcome: RoundOutcome? {
        if case .finished(let outcome) = phase { return outcome }
        return nil
    }

    /// Les joueurs dans l'ordre de parole du tour en cours.
    var orderedSpeakers: [Player] {
        speakingOrder.compactMap { id in players.first { $0.id == id } }
    }

    func player(id: UUID) -> Player? { players.first { $0.id == id } }
}
