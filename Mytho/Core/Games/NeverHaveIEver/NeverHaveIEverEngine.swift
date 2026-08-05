import Foundation

// MARK: - Mode d'aveu

/// Comment la table avoue (spec §5.2).
///
/// Le mode ne change ni les vies ni les éliminations : il ne change que la
/// façon dont l'app apprend qui a fait quoi. Un seul moteur, deux entrées.
enum ConfessionMode: String, CaseIterable, Hashable, Sendable {
    /// Chacun s'auto-dénonce à voix haute. Immédiat, c'est le défaut.
    case honour
    /// Le téléphone circule et l'app n'annonce qu'un nombre. Les prénoms ne
    /// sortent que si le groupe appuie sur « Révéler » — ou jamais.
    case secret

    var title: String {
        switch self {
        case .honour: return "À l'honneur"
        case .secret: return "Aveu secret"
        }
    }

    var subtitle: String {
        switch self {
        case .honour: return "Chacun s'accuse à voix haute."
        case .secret: return "Le téléphone circule, l'app ne dit qu'un nombre."
        }
    }
}

// MARK: - Moteur

/// « Je n'ai jamais » (spec §5). Valeur pure, sans SwiftUI : la vue envoie des
/// gestes, le moteur rend un état. C'est ce qui permet de couvrir les vies, les
/// éliminations et les fins de partie sans jamais lancer d'interface.
///
/// Les joueurs sont désignés par leur identifiant et jamais par leur prénom :
/// deux « Tom » à la même table doivent perdre leurs vies chacun de leur côté,
/// et un renommage en cours de soirée ne doit déplacer aucune vie.
struct NeverHaveIEverEngine {

    // MARK: Bornes et défauts

    /// En dessous de trois, avouer devant deux personnes n'a plus rien d'un jeu.
    static let minPlayers = 3

    static let livesChoices = [3, 5, 7]
    static let defaultLives = 5

    /// Nombre de cartes avant le classement, **dans le seul mode sans
    /// élimination** : privé d'éliminations, le jeu n'a plus de condition de fin.
    /// `nil` = sans fin, la table s'arrête quand elle veut.
    static let cardLimitChoices: [Int?] = [10, 15, 25, nil]
    static let defaultCardLimit: Int? = 15

    // MARK: Réglages

    struct Rules: Equatable, Sendable {
        var startingLives: Int
        var mode: ConfessionMode
        /// Faux = mode sans élimination (§5.6) : on compte les aveux, personne
        /// ne sort. Utile aux grands groupes, où tomber tôt est frustrant.
        var eliminates: Bool
        var cardLimit: Int?

        init(
            startingLives: Int = NeverHaveIEverEngine.defaultLives,
            mode: ConfessionMode = .honour,
            eliminates: Bool = true,
            cardLimit: Int? = NeverHaveIEverEngine.defaultCardLimit
        ) {
            // Une partie à zéro vie se terminerait sur la première carte.
            self.startingLives = max(1, startingLives)
            self.mode = mode
            self.eliminates = eliminates
            self.cardLimit = cardLimit
        }
    }

    // MARK: Joueur

    struct Player: Identifiable, Equatable, Sendable {
        let id: UUID
        var lives: Int
        var confessions: Int = 0
        /// Numéro de la carte (1 = la première) sur laquelle il est tombé à
        /// zéro. Le garder plutôt qu'un booléen sert deux fois : l'ordre du
        /// podium, et la règle « tous tombés sur la même carte » (§5.6).
        var eliminatedOnCard: Int? = nil

        var isOut: Bool { eliminatedOnCard != nil }
    }

    // MARK: Phases

    enum Phase: Hashable, Sendable {
        /// L'affirmation est à l'écran, personne n'a encore parlé.
        case card
        /// Désignation publique : le porteur tape les prénoms concernés.
        case tally
        /// « Passe le téléphone à X », avant un aveu secret.
        case secretPass(Int)
        /// X répond oui ou non, seul devant l'écran.
        case secretVote(Int)
        /// Le compte, sans aucun prénom.
        case secretCount
        /// Le groupe a demandé les prénoms.
        case secretReveal
        /// Vies retirées, éliminations prononcées.
        case aftermath
        case finished
    }

    /// Ce qu'une annulation restaure. La pioche n'en fait pas partie : annuler
    /// un mauvais tap ne doit pas rendre la carte au paquet, sinon elle
    /// ressortirait dans la soirée.
    private struct Snapshot {
        let players: [Player]
        let phase: Phase
        let confessors: [UUID]
        let eliminated: [UUID]
    }

    // MARK: État

    private(set) var rules: Rules
    private(set) var players: [Player]
    private(set) var phase: Phase = .card
    private(set) var card: ConfessionCard?
    /// 1 pour la première carte. Vaut 0 tant que la partie n'a pas démarré.
    private(set) var cardNumber = 0
    /// « Tu as fait le tour du paquet », vrai sur la seule carte qui rouvre un
    /// tour — le paquet le dit lui-même, la vue n'a rien à mémoriser.
    private(set) var showsLapMessage = false
    /// Qui vient de sortir. Toujours public, même en aveu secret : on ne peut
    /// pas cacher qu'un joueur n'a plus de vies.
    private(set) var lastEliminated: [UUID] = []

    private var deck: Deck<ConfessionCard>
    /// Les aveux de la carte en cours. **Privé** : c'est ce qui garantit que le
    /// mode secret ne fuite pas par une propriété lue distraitement.
    private var admitted: Set<UUID> = []
    private var voters: [UUID] = []
    private var confessorsOfLastCard: [UUID] = []
    private var secretRevealed = false
    private var undoSnapshot: Snapshot?

    init(playerIDs: [UUID], rules: Rules = Rules(), deck: Deck<ConfessionCard>) {
        self.rules = rules
        self.deck = deck
        self.players = playerIDs.map { Player(id: $0, lives: rules.startingLives) }
    }

    // MARK: Lecture

    var playersInPlay: [Player] { players.filter { !$0.isOut } }
    var survivorCount: Int { playersInPlay.count }
    var isFinished: Bool { phase == .finished }
    var isSecretRevealed: Bool { secretRevealed }

    /// Le nombre d'aveux — c'est exactement ce que l'aveu secret affiche en
    /// grand : « 3 personnes sur 6 l'ont fait ».
    var confessionCount: Int { admitted.count }

    /// Combien de personnes ont eu le téléphone en main sur cette carte.
    var voterCount: Int { rules.mode == .secret ? voters.count : survivorCount }

    func player(_ id: UUID) -> Player? { players.first { $0.id == id } }

    /// Vrai tant que les identités doivent rester tues.
    private var keepsSecret: Bool { rules.mode == .secret && !secretRevealed }

    /// Les prénoms qui ont avoué sur la carte en cours. **Vide tant que le
    /// groupe n'a pas appuyé sur « Révéler »** en mode secret (checklist §5) :
    /// le secret est tenu par le moteur, pas par la discipline de la vue.
    var confessors: [UUID] { keepsSecret ? [] : orderedAdmitted }

    /// Ceux qui ont avoué sur la carte qui vient d'être validée — donc ceux qui
    /// viennent de perdre une vie. Même verrou que `confessors` : sans lui, la
    /// grille trahirait ce que le compte avait tu.
    var lastConfessors: [UUID] { keepsSecret ? [] : confessorsOfLastCard }

    /// La sélection en cours de désignation publique. Faux ailleurs : un aveu
    /// secret ne s'affiche pas sur une tuile.
    func isSelected(_ playerID: UUID) -> Bool {
        phase == .tally && admitted.contains(playerID)
    }

    /// Qui tient le téléphone pendant la séquence secrète.
    var currentVoterID: UUID? {
        switch phase {
        case .secretPass(let index), .secretVote(let index):
            return voters.indices.contains(index) ? voters[index] : nil
        default:
            return nil
        }
    }

    /// Rang du porteur dans la tournée, à partir de 1 — « 3 sur 6 ».
    var currentVoterPosition: Int? {
        switch phase {
        case .secretPass(let index), .secretVote(let index):
            return voters.indices.contains(index) ? index + 1 : nil
        default:
            return nil
        }
    }

    private var orderedAdmitted: [UUID] {
        // Ordre du roster et non ordre d'insertion : la révélation sort les
        // prénoms un par un, elle doit être stable d'une lecture à l'autre.
        players.map(\.id).filter { admitted.contains($0) }
    }

    // MARK: Fin de partie

    var isGameOver: Bool {
        guard rules.eliminates else {
            guard let limit = rules.cardLimit else { return false }
            return cardNumber >= limit
        }
        return survivorCount <= 1
    }

    /// Sans élimination **et** sans limite de cartes, aucune condition de fin ne
    /// se déclenchera jamais. L'écran doit alors offrir lui-même la sortie, sans
    /// quoi le classement resterait hors d'atteinte pour toute la partie.
    var isEndless: Bool { !rules.eliminates && rules.cardLimit == nil }

    /// Les vainqueurs — à lire quand la partie est finie.
    ///
    /// Trois cas : le dernier debout ; **tous ceux tombés sur la dernière
    /// carte** quand plus personne ne survit (§5.6) ; et le plus gros total
    /// d'aveux en mode sans élimination.
    var winners: [UUID] {
        guard rules.eliminates else {
            let best = players.map(\.confessions).max() ?? 0
            return players.filter { $0.confessions == best }.map(\.id)
        }

        let alive = playersInPlay
        if !alive.isEmpty { return alive.map(\.id) }

        guard let lastCard = players.compactMap(\.eliminatedOnCard).max() else { return [] }
        return players.filter { $0.eliminatedOnCard == lastCard }.map(\.id)
    }

    /// Classement du podium : les survivants d'abord, puis les éliminés du plus
    /// tardif au plus tôt. Sans élimination, le plus gros total d'aveux mène.
    /// À points égaux, l'ordre du roster départage — deux lectures du classement
    /// ne doivent jamais permuter deux joueurs.
    var ranking: [Player] {
        let indexed = Array(players.enumerated())
        guard rules.eliminates else {
            return indexed
                .sorted {
                    $0.element.confessions == $1.element.confessions
                        ? $0.offset < $1.offset
                        : $0.element.confessions > $1.element.confessions
                }
                .map(\.element)
        }
        return indexed
            .sorted { left, right in
                let l = left.element.eliminatedOnCard ?? Int.max
                let r = right.element.eliminatedOnCard ?? Int.max
                return l == r ? left.offset < right.offset : l > r
            }
            .map(\.element)
    }

    // MARK: Démarrage

    mutating func start(using generator: inout some RandomNumberGenerator) {
        guard cardNumber == 0 else { return }
        drawCard(using: &generator)
    }

    mutating func start() {
        var generator = SystemRandomNumberGenerator()
        start(using: &generator)
    }

    // MARK: Aveux

    /// Quitte la carte pour la désignation — ou pour le premier passage de
    /// téléphone si la table joue en aveu secret.
    mutating func beginConfessions() {
        guard phase == .card else { return }
        admitted.removeAll()
        secretRevealed = false

        switch rules.mode {
        case .honour:
            phase = .tally
        case .secret:
            // Un joueur éliminé n'a plus de vie à perdre : lui faire passer le
            // téléphone allongerait la tournée pour rien.
            voters = playersInPlay.map(\.id)
            phase = voters.isEmpty ? .secretCount : .secretPass(0)
        }
    }

    /// Désignation publique : un tap ajoute un prénom, un second le retire.
    /// C'est l'annulation du mauvais tap (spec §2.5), en plus direct.
    mutating func toggle(_ playerID: UUID) {
        guard phase == .tally, let target = player(playerID), !target.isOut else { return }
        if admitted.contains(playerID) {
            admitted.remove(playerID)
        } else {
            admitted.insert(playerID)
        }
    }

    /// Le porteur a confirmé « Je suis X » : la question peut s'afficher.
    mutating func openSecretVote() {
        guard case .secretPass(let index) = phase else { return }
        phase = .secretVote(index)
    }

    /// La réponse du porteur, puis le téléphone repart. Rien n'est affiché
    /// entre deux votants : c'est le passage de téléphone qui fait le vide.
    mutating func answerSecret(_ didIt: Bool) {
        guard case .secretVote(let index) = phase, voters.indices.contains(index) else { return }
        let voter = voters[index]
        if didIt {
            admitted.insert(voter)
        } else {
            admitted.remove(voter)
        }

        let next = index + 1
        phase = next < voters.count ? .secretPass(next) : .secretCount
    }

    /// Le groupe demande les prénoms. Irréversible pour la carte en cours :
    /// une révélation ne se re-cache pas.
    mutating func reveal() {
        guard phase == .secretCount else { return }
        secretRevealed = true
        phase = .secretReveal
    }

    // MARK: Conséquences

    /// Applique les vies perdues et les éliminations qui suivent.
    mutating func validate() {
        switch phase {
        case .tally, .secretCount, .secretReveal:
            break
        default:
            return
        }

        undoSnapshot = Snapshot(
            players: players,
            phase: phase,
            confessors: confessorsOfLastCard,
            eliminated: lastEliminated
        )

        var confessed: [UUID] = []
        var eliminated: [UUID] = []

        for id in orderedAdmitted {
            guard let index = players.firstIndex(where: { $0.id == id }), !players[index].isOut else { continue }
            players[index].confessions += 1
            confessed.append(id)

            // Sans élimination, l'aveu se compte mais ne coûte rien (§5.6).
            guard rules.eliminates else { continue }

            players[index].lives = max(0, players[index].lives - 1)
            if players[index].lives == 0 {
                players[index].eliminatedOnCard = cardNumber
                eliminated.append(id)
            }
        }

        confessorsOfLastCard = confessed
        lastEliminated = eliminated
        // Toujours l'après-carte, même quand la partie est jouée : l'élimination
        // a besoin de sa seconde à l'écran avant le podium.
        phase = .aftermath
    }

    var canUndo: Bool { phase == .aftermath && undoSnapshot != nil }

    /// Rend la carte comme elle était avant la validation. Le mauvais tap arrive
    /// à chaque partie, et ici il coûte une vie.
    @discardableResult
    mutating func undo() -> Bool {
        guard let snapshot = undoSnapshot, phase == .aftermath else { return false }
        players = snapshot.players
        phase = snapshot.phase
        confessorsOfLastCard = snapshot.confessors
        lastEliminated = snapshot.eliminated
        undoSnapshot = nil
        return true
    }

    // MARK: Carte suivante

    mutating func nextCard(using generator: inout some RandomNumberGenerator) {
        guard phase == .aftermath else { return }
        guard !isGameOver else {
            phase = .finished
            return
        }
        drawCard(using: &generator)
    }

    mutating func nextCard() {
        var generator = SystemRandomNumberGenerator()
        nextCard(using: &generator)
    }

    /// Sortie manuelle du mode sans fin : la table s'arrête quand elle en a
    /// assez, et le classement s'affiche.
    mutating func finishNow() {
        guard phase != .finished else { return }
        phase = .finished
    }

    private mutating func drawCard(using generator: inout some RandomNumberGenerator) {
        guard let draw = deck.draw(using: &generator) else {
            // Paquet vide (aucun pack retenu) : mieux vaut clore la partie que
            // de tourner sur une carte fantôme.
            phase = .finished
            return
        }

        card = draw.item
        showsLapMessage = draw.startsNewLap
        cardNumber += 1
        admitted.removeAll()
        voters.removeAll()
        confessorsOfLastCard = []
        lastEliminated = []
        secretRevealed = false
        undoSnapshot = nil
        phase = .card
    }
}
