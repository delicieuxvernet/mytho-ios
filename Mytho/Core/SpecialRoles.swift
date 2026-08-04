import Foundation

/// Pouvoirs qui se superposent au rôle de base : un joueur peut être Civil ET
/// Vengeuse. Ils ne changent jamais le camp d'un joueur, seulement ce qui se
/// passe quand il est éliminé, ou la façon dont la table doit trancher.
enum SpecialRole: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    /// Tranche les égalités de votes, et garde ce pouvoir même éliminée.
    case justice
    /// Deux joueurs liés : si l'un tombe, l'autre tombe avec lui.
    case lovers
    /// Éliminée, elle emmène quelqu'un avec elle.
    case avenger
    /// Deux joueurs en compétition secrète : le premier éliminé perd des points,
    /// l'autre en gagne.
    case duelists

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .justice: return "L'Arbitre"
        case .lovers: return "Amoureux"
        case .avenger: return "Vengeuse"
        case .duelists: return "Duellistes"
        }
    }

    var symbol: String {
        switch self {
        case .justice: return "scalemass.fill"
        case .lovers: return "heart.fill"
        case .avenger: return "bolt.fill"
        case .duelists: return "flag.2.crossed.fill"
        }
    }

    /// Combien de joueurs ce pouvoir occupe.
    var seats: Int {
        switch self {
        case .lovers, .duelists: return 2
        case .justice, .avenger: return 1
        }
    }

    /// En dessous de ce seuil, le pouvoir déséquilibre trop la manche.
    var minimumPlayers: Int {
        switch self {
        case .justice: return 4
        case .lovers, .avenger, .duelists: return 5
        }
    }

    /// Ce que le joueur lit sur sa carte au moment de la distribution.
    var briefing: String {
        switch self {
        case .justice:
            return "En cas d'égalité des votes, c'est toi qui tranches. Tu gardes ce pouvoir même après ton élimination."
        case .lovers:
            return "Un autre joueur est lié à toi. Si l'un de vous est éliminé, l'autre l'est aussi."
        case .avenger:
            return "Si tu es éliminé, tu emmènes immédiatement un autre joueur avec toi."
        case .duelists:
            return "Un autre joueur est ton rival. Le premier de vous deux éliminé perd 2 points, l'autre en gagne 2."
        }
    }

    /// Résumé affiché dans les réglages et l'écran de règles.
    var summary: String {
        switch self {
        case .justice: return "Tranche les égalités de votes, même éliminée."
        case .lovers: return "Deux joueurs liés : l'un tombe, l'autre aussi."
        case .avenger: return "Éliminée, elle emmène quelqu'un avec elle."
        case .duelists: return "Deux rivaux : le premier éliminé perd 2 points, l'autre en gagne 2."
        }
    }
}

/// Variantes qui s'appliquent à toute la table plutôt qu'à un joueur.
enum TableRule: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    /// À chaque tour, un joueur tiré au sort décrit son mot en mimant.
    case mime
    /// Les joueurs éliminés continuent de participer aux discussions et aux votes.
    case ghosts

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mime: return "Le Mime"
        case .ghosts: return "Fantôme"
        }
    }

    var symbol: String {
        switch self {
        case .mime: return "hands.and.sparkles.fill"
        case .ghosts: return "moon.stars.fill"
        }
    }

    var summary: String {
        switch self {
        case .mime: return "Chaque tour, un joueur doit mimer son mot au lieu de le décrire."
        case .ghosts: return "Les joueurs éliminés continuent de discuter et de voter."
        }
    }
}

/// Points gagnés ou perdus par les duellistes, indépendamment du camp gagnant.
enum DuelScore {
    static let loser = -2
    static let survivor = 2
}

// MARK: - Répartition des pouvoirs

enum SpecialRoleAssignment {

    /// Nombre de sièges occupés par les pouvoirs demandés.
    static func seats(for roles: Set<SpecialRole>) -> Int {
        roles.reduce(0) { $0 + $1.seats }
    }

    /// Retire les pouvoirs injouables : trop peu de joueurs pour le pouvoir
    /// lui-même, ou pas assez de sièges libres pour tous les caser.
    ///
    /// L'ordre de retrait est déterministe (par `CaseIterable` inversé) pour
    /// qu'un même réglage donne toujours le même résultat.
    static func playable(_ requested: Set<SpecialRole>, playerCount: Int) -> Set<SpecialRole> {
        var kept = requested.filter { playerCount >= $0.minimumPlayers }

        // Un pouvoir par joueur au maximum : on ne peut pas être Amoureux et
        // Vengeuse à la fois sans rendre la carte illisible.
        while seats(for: kept) > playerCount {
            guard let dropped = SpecialRole.allCases.reversed().first(where: { kept.contains($0) }) else { break }
            kept.remove(dropped)
        }
        return kept
    }

    /// Attribue les pouvoirs à des joueurs tirés au sort, un pouvoir par joueur.
    /// Renvoie les identifiants concernés, dans l'ordre du tirage.
    static func assign(
        _ roles: Set<SpecialRole>,
        to players: [Player],
        using generator: inout some RandomNumberGenerator
    ) -> [SpecialRole: [UUID]] {
        var pool = players.map(\.id)
        pool.shuffle(using: &generator)

        var result: [SpecialRole: [UUID]] = [:]
        // Ordre stable : deux manches avec le même tirage donnent la même
        // répartition, ce qui rend les tests reproductibles.
        for role in SpecialRole.allCases where roles.contains(role) {
            guard pool.count >= role.seats else { continue }
            result[role] = Array(pool.prefix(role.seats))
            pool.removeFirst(role.seats)
        }
        return result
    }
}
