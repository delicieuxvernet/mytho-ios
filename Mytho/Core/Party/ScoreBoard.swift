import Foundation

/// Points de la soirée. Valeur pure, sans SwiftUI : chaque jeu applique son
/// barème, le tableau se contente de stocker, de trier et de savoir revenir en
/// arrière d'un cran.
///
/// Les joueurs sont désignés par leur identifiant, jamais par leur prénom : deux
/// « Tom » à la même table doivent marquer chacun de leur côté, et renommer
/// quelqu'un en cours de soirée ne doit pas lui faire perdre ses points.
struct ScoreBoard: Equatable, Codable, Sendable {

    /// Une action de barème. C'est l'unité d'annulation : un « ex æquo » qui donne
    /// un point à deux joueurs se défait en une fois, comme il s'est fait.
    struct Change: Equatable, Codable, Sendable {
        let deltas: [UUID: Int]
    }

    /// Ligne de classement prête à afficher.
    struct Standing: Identifiable, Equatable, Sendable {
        let playerID: UUID
        let points: Int
        /// Rang partagé en cas d'égalité : 1, 1, 3.
        let rank: Int

        var id: UUID { playerID }
    }

    /// Ordre d'inscription des joueurs. Sert d'ordre d'affichage tant que personne
    /// n'a marqué, et de départage stable ensuite : deux consultations du
    /// classement ne doivent jamais permuter deux joueurs à égalité.
    private(set) var playerIDs: [UUID]
    private(set) var points: [UUID: Int]
    /// Actions de la manche en cours, de la plus ancienne à la plus récente.
    private(set) var history: [Change]

    /// Un mauvais tap se rattrape dans la foulée ; au-delà, c'est une autre
    /// manche. La pile reste courte pour ne pas peser sur la sauvegarde.
    private static let historyLimit = 40

    init(playerIDs: [UUID] = []) {
        self.playerIDs = playerIDs
        self.points = playerIDs.reduce(into: [:]) { $0[$1] = 0 }
        self.history = []
    }

    // MARK: Joueurs

    /// Inscrit les joueurs manquants sans toucher aux points déjà marqués :
    /// quelqu'un qui arrive en cours de soirée ne remet pas la table à zéro.
    mutating func register(_ ids: [UUID]) {
        for id in ids where points[id] == nil {
            playerIDs.append(id)
            points[id] = 0
        }
    }

    func score(for playerID: UUID) -> Int { points[playerID] ?? 0 }

    // MARK: Barème

    mutating func award(_ delta: Int, to playerID: UUID) {
        award([playerID: delta])
    }

    /// Même barème pour plusieurs joueurs, en une seule action annulable.
    mutating func award(_ delta: Int, to ids: [UUID]) {
        var deltas: [UUID: Int] = [:]
        for id in ids { deltas[id, default: 0] += delta }
        award(deltas)
    }

    /// Applique une action complète. Un joueur inconnu est inscrit au passage :
    /// un point marqué ne doit jamais se perdre parce que le roster a bougé.
    mutating func award(_ deltas: [UUID: Int]) {
        guard !deltas.isEmpty else { return }
        for (id, delta) in deltas {
            register([id])
            points[id, default: 0] += delta
        }
        history.append(Change(deltas: deltas))
        if history.count > Self.historyLimit { history.removeFirst() }
    }

    // MARK: Retour en arrière

    var canUndo: Bool { !history.isEmpty }

    /// Annule la dernière action. Retourne faux s'il n'y a rien à annuler.
    @discardableResult
    mutating func undoLast() -> Bool {
        guard let last = history.popLast() else { return false }
        for (id, delta) in last.deltas {
            points[id, default: 0] -= delta
        }
        return true
    }

    /// À appeler au début de chaque manche : on n'annule pas le tap d'une manche
    /// déjà refermée, sinon un « annuler » tardif retire un point sans que
    /// personne ne comprenne lequel.
    mutating func startRound() {
        history.removeAll()
    }

    /// Remet tout le monde à zéro sans perdre le roster.
    mutating func resetPoints() {
        points = playerIDs.reduce(into: [:]) { $0[$1] = 0 }
        history.removeAll()
    }

    // MARK: Classement

    var standings: [Standing] {
        var ordered: [(index: Int, id: UUID, points: Int)] = []
        for (index, id) in playerIDs.enumerated() {
            ordered.append((index: index, id: id, points: points[id] ?? 0))
        }
        ordered.sort { $0.points == $1.points ? $0.index < $1.index : $0.points > $1.points }

        var result: [Standing] = []
        var rank = 0
        var previousPoints: Int?
        for (offset, entry) in ordered.enumerated() {
            // Égalité = même rang, et le rang suivant saute d'autant : 1, 1, 3.
            if entry.points != previousPoints {
                rank = offset + 1
                previousPoints = entry.points
            }
            result.append(Standing(playerID: entry.id, points: entry.points, rank: rank))
        }
        return result
    }

    /// Les joueurs en tête — plusieurs en cas d'égalité parfaite, ce qui arrive
    /// assez souvent pour ne pas être traité comme un cas limite.
    var leaders: [UUID] {
        let ranked = standings
        guard let best = ranked.first?.points else { return [] }
        return ranked.filter { $0.points == best }.map(\.playerID)
    }
}
