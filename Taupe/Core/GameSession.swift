import Foundation
import SwiftUI

/// État partagé de l'app : la configuration, la manche en cours et le classement
/// cumulé. C'est le seul objet observable ; le moteur reste une valeur pure.
@MainActor
final class GameSession: ObservableObject {

    // MARK: Réglages persistés

    @Published var config: GameConfig {
        didSet { Persistence.save(config: config) }
    }

    /// Points cumulés depuis la dernière remise à zéro, indexés par nom de joueur
    /// (et non par UUID : un joueur garde son score d'une manche à l'autre).
    @Published private(set) var totalScores: [String: Int] {
        didSet { Persistence.save(scores: totalScores) }
    }

    // MARK: Manche en cours

    @Published var engine: GameEngine?

    /// Les dernières paires jouées, pour ne pas retomber dessus tout de suite.
    private var recentPairs: [WordPair] = []
    private let recentPairMemory = 30

    init() {
        let saved = Persistence.loadConfig()
        self.config = saved ?? GameConfig(
            playerNames: ["Joueur 1", "Joueur 2", "Joueur 3", "Joueur 4", "Joueur 5"],
            undercoverCount: 1,
            mrWhiteCount: 1
        )
        self.totalScores = Persistence.loadScores()
    }

    // MARK: Composition

    var playerCount: Int { config.playerNames.count }

    func setPlayerCount(_ count: Int) {
        let target = min(max(count, Composition.minPlayers), Composition.maxPlayers)
        var names = config.playerNames
        while names.count < target { names.append("Joueur \(names.count + 1)") }
        if names.count > target { names.removeLast(names.count - target) }
        config.playerNames = names
        normalizeComposition()
    }

    func addPlayer() { setPlayerCount(playerCount + 1) }

    func removePlayer(at index: Int) {
        guard config.playerNames.indices.contains(index),
              playerCount > Composition.minPlayers else { return }
        config.playerNames.remove(at: index)
        normalizeComposition()
    }

    func adjustUndercover(by delta: Int) {
        config.undercoverCount += delta
        normalizeComposition()
    }

    func adjustMrWhite(by delta: Int) {
        config.mrWhiteCount += delta
        normalizeComposition()
    }

    func applySuggestedComposition() {
        let suggested = Composition.suggested(playerCount: playerCount)
        config.undercoverCount = suggested.undercover
        config.mrWhiteCount = suggested.mrWhite
    }

    private func normalizeComposition() {
        let clamped = Composition.clamp(
            undercover: config.undercoverCount,
            mrWhite: config.mrWhiteCount,
            playerCount: playerCount
        )
        config.undercoverCount = clamped.undercover
        config.mrWhiteCount = clamped.mrWhite
    }

    var canAddInfiltrator: Bool {
        config.infiltratorCount < Composition.maxInfiltrators(playerCount: playerCount)
    }

    // MARK: Démarrage d'une manche

    func startRound() {
        creditedRound = false
        var generator = SystemRandomNumberGenerator()

        var roundConfig = config
        if config.randomMode {
            let cap = Composition.maxInfiltrators(playerCount: playerCount)
            let total = Int.random(in: 1...cap, using: &generator)
            let whites = config.mrWhiteCount > 0 ? Int.random(in: 0...min(total, 2), using: &generator) : 0
            roundConfig.undercoverCount = max(total - whites, whites == total ? 0 : 1)
            roundConfig.mrWhiteCount = whites
            let clamped = Composition.clamp(
                undercover: roundConfig.undercoverCount,
                mrWhite: roundConfig.mrWhiteCount,
                playerCount: playerCount
            )
            roundConfig.undercoverCount = clamped.undercover
            roundConfig.mrWhiteCount = clamped.mrWhite
        }

        let pair = WordBank.randomPair(from: config.categoryIDs, excluding: recentPairs)
        recentPairs.append(pair)
        if recentPairs.count > recentPairMemory { recentPairs.removeFirst() }

        for name in config.playerNames where totalScores[name] == nil {
            totalScores[name] = 0
        }

        engine = GameEngine(config: roundConfig, pair: pair, using: &generator)
    }

    func endRound() {
        engine = nil
    }

    // MARK: Actions de manche

    @discardableResult
    func pickCard(at index: Int) -> Role? {
        guard var current = engine else { return nil }
        let role = current.pickCard(at: index)
        engine = current
        return role
    }

    func advanceDealing() {
        guard var current = engine else { return }
        var generator = SystemRandomNumberGenerator()
        current.advanceDealing(using: &generator)
        engine = current
    }

    func startVote() {
        guard var current = engine else { return }
        current.startVote()
        engine = current
    }

    func eliminate(playerID: UUID) {
        guard var current = engine else { return }
        current.eliminate(playerID: playerID)
        engine = current
    }

    func resolveElimination() {
        guard var current = engine else { return }
        var generator = SystemRandomNumberGenerator()
        current.resolveElimination(using: &generator)
        engine = current
        commitPointsIfFinished()
    }

    @discardableResult
    func submitMrWhiteGuess(_ guess: String) -> Bool {
        guard var current = engine else { return false }
        var generator = SystemRandomNumberGenerator()
        let correct = current.submitMrWhiteGuess(guess, using: &generator)
        engine = current
        commitPointsIfFinished()
        return correct
    }

    /// Les points ne sont versés au classement qu'une seule fois par manche.
    private var creditedRound = false

    private func commitPointsIfFinished() {
        guard let current = engine, current.isFinished, !creditedRound else { return }
        creditedRound = true
        for (playerID, points) in current.roundPoints {
            guard let name = current.player(id: playerID)?.name else { continue }
            totalScores[name, default: 0] += points
        }
    }

    /// Relance une manche avec les mêmes joueurs, en conservant le classement.
    func playAgain() {
        creditedRound = false
        startRound()
    }

    func backToSetup() {
        creditedRound = false
        engine = nil
    }

    // MARK: Classement

    var leaderboard: [(name: String, points: Int)] {
        config.playerNames
            .map { (name: $0, points: totalScores[$0] ?? 0) }
            .sorted { $0.points == $1.points ? $0.name < $1.name : $0.points > $1.points }
    }

    func resetScores() {
        totalScores = config.playerNames.reduce(into: [:]) { $0[$1] = 0 }
    }
}

// MARK: - Persistance

/// Sauvegarde légère dans UserDefaults : réglages et classement seulement,
/// jamais l'état d'une manche en cours (le téléphone circule, une manche
/// interrompue se rejoue).
enum Persistence {
    private static let configKey = "taupe.config"
    private static let scoresKey = "taupe.scores"

    static func save(config: GameConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: configKey)
    }

    static func loadConfig() -> GameConfig? {
        guard let data = UserDefaults.standard.data(forKey: configKey) else { return nil }
        return try? JSONDecoder().decode(GameConfig.self, from: data)
    }

    static func save(scores: [String: Int]) {
        UserDefaults.standard.set(scores, forKey: scoresKey)
    }

    static func loadScores() -> [String: Int] {
        UserDefaults.standard.dictionary(forKey: scoresKey) as? [String: Int] ?? [:]
    }
}
