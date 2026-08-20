import XCTest
@testable import Mytho

/// Réponse formelle à la question d'Arthur : « est-ce que l'attribution des
/// rôles est vraiment aléatoire ? ». On simule des milliers de distributions
/// et on vérifie qu'aucune position — de carte comme de joueur — n'est
/// favorisée. Les bornes laissent ±4 écarts-types : un vrai biais les crève,
/// le bruit statistique jamais (pas de test flaky en CI).
final class RoleDistributionTests: XCTestCase {

    private let pair = WordPair(a: "Chat", b: "Chien")

    private func engine(seed: UInt64, players: Int = 6) -> GameEngine {
        var generator = SeededGenerator(seed: seed)
        let config = GameConfig(
            playerNames: (1...players).map { "J\($0)" },
            undercoverCount: 1,
            mrWhiteCount: 1
        )
        return GameEngine(config: config, pair: pair, using: &generator)
    }

    /// Le paquet est-il mélangé uniformément ? Sur 6 000 manches, l'Undercover
    /// doit se trouver ~1 000 fois sur chacune des 6 cartes.
    func testUndercoverLandsOnEveryCardPositionEqually() {
        let deals = 6_000
        var byCard = [Int](repeating: 0, count: 6)

        for seed in 0..<deals {
            let deck = engine(seed: UInt64(seed)).deck
            if let index = deck.firstIndex(of: .undercover) {
                byCard[index] += 1
            }
        }

        // Espérance 1000, écart-type ~28,9 : la bande ±120 vaut > 4 sigmas.
        for (position, count) in byCard.enumerated() {
            XCTAssertTrue(
                (880...1120).contains(count),
                "Carte \(position + 1) : \(count) Undercover sur \(deals) — hors bande"
            )
        }
        XCTAssertEqual(byCard.reduce(0, +), deals)
    }

    /// Même exigence pour Mr. White : aucune carte fétiche.
    func testMrWhiteLandsOnEveryCardPositionEqually() {
        let deals = 6_000
        var byCard = [Int](repeating: 0, count: 6)

        for seed in 0..<deals {
            let deck = engine(seed: UInt64(seed) &+ 1_000_000).deck
            if let index = deck.firstIndex(of: .mrWhite) {
                byCard[index] += 1
            }
        }
        for (position, count) in byCard.enumerated() {
            XCTAssertTrue(
                (880...1120).contains(count),
                "Carte \(position + 1) : \(count) Mr. White sur \(deals) — hors bande"
            )
        }
    }

    /// Et côté joueurs : si chacun pioche la première carte libre (l'ordre le
    /// plus prévisible possible), le rôle doit rester équiréparti entre les
    /// positions à table. C'est le scénario le plus défavorable — toute autre
    /// stratégie de pioche ajoute du hasard, elle n'en retire jamais.
    func testSeatOrderGivesNoAdvantageEvenWithPredictablePicking() {
        let deals = 6_000
        var undercoverBySeat = [Int](repeating: 0, count: 6)

        for seed in 0..<deals {
            var current = engine(seed: UInt64(seed) &+ 2_000_000)
            var generator = SeededGenerator(seed: UInt64(seed) &+ 3_000_000)
            while case .dealing(let playerIndex) = current.phase {
                guard let free = current.deck.firstIndex(where: { $0 != nil }) else { break }
                if current.pickCard(at: free) == .undercover {
                    undercoverBySeat[playerIndex] += 1
                }
                current.advanceDealing(using: &generator)
            }
        }

        for (seat, count) in undercoverBySeat.enumerated() {
            XCTAssertTrue(
                (880...1120).contains(count),
                "Position à table \(seat + 1) : \(count) Undercover sur \(deals) — hors bande"
            )
        }
        XCTAssertEqual(undercoverBySeat.reduce(0, +), deals)
    }

    /// Les tests ci-dessus pilotent le moteur avec un générateur de test, qui
    /// rend les manches rejouables. Celui-ci utilise le générateur **réel** de
    /// l'app — `SystemRandomNumberGenerator`, celui du système — pour que la
    /// garantie porte sur le tirage tel qu'il se produit sur le téléphone, et
    /// pas seulement sur l'algorithme de mélange.
    func testTheGeneratorUsedInProductionIsAlsoUnbiased() {
        let deals = 6_000
        var byCard = [Int](repeating: 0, count: 6)
        var generator = SystemRandomNumberGenerator()
        let config = GameConfig(
            playerNames: (1...6).map { "J\($0)" },
            undercoverCount: 1,
            mrWhiteCount: 1
        )

        for _ in 0..<deals {
            let deck = GameEngine(config: config, pair: pair, using: &generator).deck
            if let index = deck.firstIndex(of: .undercover) {
                byCard[index] += 1
            }
        }

        // Espérance 1000, écart-type ~28,9 : la bande ±150 vaut > 5 sigmas,
        // large de quoi ne jamais clignoter en intégration continue.
        for (position, count) in byCard.enumerated() {
            XCTAssertTrue(
                (850...1150).contains(count),
                "Carte \(position + 1) : \(count) Undercover sur \(deals) — hors bande"
            )
        }
        XCTAssertEqual(byCard.reduce(0, +), deals)
    }

    /// Le mot des civils est tiré au sort dans la paire : sur 4 000 manches,
    /// chaque mot doit être côté civils environ la moitié du temps — sinon un
    /// habitué saurait que « le mot de gauche » est toujours le bon.
    func testCivilianWordSideIsAlsoRandom() {
        let deals = 4_000
        var sideA = 0
        for seed in 0..<deals where engine(seed: UInt64(seed) &+ 4_000_000).civilianWord == pair.a {
            sideA += 1
        }
        // Espérance 2000, écart-type ~31,6 : bande ±140 > 4 sigmas.
        XCTAssertTrue(
            (1860...2140).contains(sideA),
            "Mot A côté civils \(sideA) fois sur \(deals) — hors bande"
        )
    }
}
