import Foundation

// MARK: - Rôles

/// Les trois rôles de base d'une manche.
enum Role: String, Codable, Hashable, Sendable, CaseIterable {
    /// Reçoit le mot majoritaire. Gagne en éliminant tous les infiltrés.
    case civilian
    /// Reçoit le mot proche. Gagne en survivant.
    case undercover
    /// Ne reçoit aucun mot. Improvise, et peut voler la victoire en devinant.
    case mrWhite

    /// Tout ce qui n'est pas civil forme le camp des infiltrés.
    var isInfiltrator: Bool { self != .civilian }

    var displayName: String {
        switch self {
        case .civilian: return "Civil"
        case .undercover: return "Undercover"
        case .mrWhite: return "Mr. White"
        }
    }

    var symbol: String {
        switch self {
        case .civilian: return "person.fill"
        case .undercover: return "eye.trianglebadge.exclamationmark.fill"
        case .mrWhite: return "hat.widebrim.fill"
        }
    }
}

// MARK: - Joueur

struct Player: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    /// Nil tant que le joueur n'a pas pioché sa carte.
    var role: Role?
    var isAlive: Bool
    /// Index de la carte piochée dans le paquet, pour l'animation de retournement.
    var pickedCardIndex: Int?

    init(id: UUID = UUID(), name: String, role: Role? = nil, isAlive: Bool = true, pickedCardIndex: Int? = nil) {
        self.id = id
        self.name = name
        self.role = role
        self.isAlive = isAlive
        self.pickedCardIndex = pickedCardIndex
    }

    /// Le mot que ce joueur doit décrire, selon la paire tirée. Nil pour Mr. White.
    func word(civilianWord: String, undercoverWord: String) -> String? {
        switch role {
        case .civilian: return civilianWord
        case .undercover: return undercoverWord
        case .mrWhite, nil: return nil
        }
    }
}

// MARK: - Configuration d'une manche

struct GameConfig: Hashable, Codable, Sendable {
    var playerNames: [String]
    var undercoverCount: Int
    var mrWhiteCount: Int
    /// Catégories de mots autorisées. Vide = toutes.
    var categoryIDs: Set<String>
    /// Mr. White peut être le premier à décrire (désactivé par défaut : injouable pour lui).
    var mrWhiteCanStart: Bool
    /// Chaque joueur voit son rôle en plus de son mot.
    var easyMode: Bool
    /// La composition est retirée au hasard à chaque manche, dans les bornes valides.
    var randomMode: Bool

    init(
        playerNames: [String] = [],
        undercoverCount: Int = 1,
        mrWhiteCount: Int = 1,
        categoryIDs: Set<String> = [],
        mrWhiteCanStart: Bool = false,
        easyMode: Bool = false,
        randomMode: Bool = false
    ) {
        self.playerNames = playerNames
        self.undercoverCount = undercoverCount
        self.mrWhiteCount = mrWhiteCount
        self.categoryIDs = categoryIDs
        self.mrWhiteCanStart = mrWhiteCanStart
        self.easyMode = easyMode
        self.randomMode = randomMode
    }

    var playerCount: Int { playerNames.count }
    var infiltratorCount: Int { undercoverCount + mrWhiteCount }
    var civilianCount: Int { playerCount - infiltratorCount }
}

// MARK: - Bornes de composition

/// Règles de composition. Les civils doivent rester strictement majoritaires au
/// début : sinon les infiltrés gagnent avant même la première description.
enum Composition {
    static let minPlayers = 3
    static let maxPlayers = 20

    /// Nombre maximum d'infiltrés pour `n` joueurs, civils strictement majoritaires.
    /// n=3 -> 1, n=5 -> 2, n=8 -> 3, n=20 -> 9.
    static func maxInfiltrators(playerCount n: Int) -> Int {
        max(1, (n - 1) / 2)
    }

    /// Composition suggérée par défaut, calquée sur les usages du jeu de société :
    /// un infiltré pour environ quatre joueurs, plus un Mr. White dès 5 joueurs.
    static func suggested(playerCount n: Int) -> (undercover: Int, mrWhite: Int) {
        guard n >= minPlayers else { return (1, 0) }
        let white = n >= 5 ? 1 : 0
        let undercover = max(1, n / 4)
        let capped = min(undercover, maxInfiltrators(playerCount: n) - white)
        return (max(1, capped), white)
    }

    /// Ramène une composition arbitraire dans les bornes jouables, en réduisant
    /// d'abord les Mr. White (rôle le plus déséquilibrant) puis les undercover.
    static func clamp(undercover: Int, mrWhite: Int, playerCount n: Int) -> (undercover: Int, mrWhite: Int) {
        var uc = max(0, undercover)
        var mw = max(0, mrWhite)
        let cap = maxInfiltrators(playerCount: n)

        // Au moins un infiltré, sinon il n'y a rien à chercher.
        if uc + mw == 0 { uc = 1 }

        while uc + mw > cap {
            if mw > 0 { mw -= 1 } else if uc > 1 { uc -= 1 } else { break }
        }
        return (uc, mw)
    }
}

// MARK: - Issue d'une manche

enum RoundOutcome: Hashable, Codable, Sendable {
    /// Tous les infiltrés ont été démasqués.
    case civiliansWin
    /// Les infiltrés ont survécu jusqu'à la fin.
    case infiltratorsWin
    /// Mr. White, éliminé, a deviné le mot des civils.
    case mrWhiteGuessedRight(playerID: UUID)

    var title: String {
        switch self {
        case .civiliansWin: return "Les civils gagnent"
        case .infiltratorsWin: return "Les infiltrés gagnent"
        case .mrWhiteGuessedRight: return "Mr. White gagne"
        }
    }
}

// MARK: - Barème de points

/// Points attribués en fin de manche, alignés sur le barème du jeu de référence.
enum Score {
    static let civilianWin = 2
    static let undercoverSurvives = 10
    static let mrWhiteSurvives = 6
    static let mrWhiteGuessesRight = 6
}

// MARK: - Phases

enum GamePhase: Hashable, Sendable {
    /// Distribution : chaque joueur pioche une carte à son tour.
    case dealing(playerIndex: Int)
    /// Ordre de parole affiché, les joueurs décrivent puis débattent.
    case describing(round: Int)
    /// Le groupe désigne un joueur à éliminer.
    case voting
    /// Le rôle du joueur éliminé vient d'être révélé.
    case elimination(playerID: UUID)
    /// Mr. White éliminé tente de deviner le mot des civils.
    case mrWhiteGuess(playerID: UUID)
    /// Manche terminée.
    case finished(RoundOutcome)
}
