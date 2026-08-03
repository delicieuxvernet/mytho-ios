import XCTest
@testable import Taupe

/// Les pouvoirs modifient l'élimination — la mécanique la plus sensible du
/// moteur. Chaque règle est vérifiée sur le flux réel, pas sur des raccourcis.
final class SpecialRolesTests: XCTestCase {

    private let pair = WordPair(a: "Chat", b: "Chien")

    private func makeEngine(
        players: Int = 6,
        undercover: Int = 1,
        mrWhite: Int = 0,
        specialRoles: Set<SpecialRole> = [],
        tableRules: Set<TableRule> = [],
        seed: UInt64 = 42
    ) -> GameEngine {
        var generator = SeededGenerator(seed: seed)
        let config = GameConfig(
            playerNames: (1...players).map { "J\($0)" },
            undercoverCount: undercover,
            mrWhiteCount: mrWhite,
            specialRoles: specialRoles,
            tableRules: tableRules
        )
        return GameEngine(config: config, pair: pair, using: &generator)
    }

    private func dealAll(_ engine: inout GameEngine, seed: UInt64 = 7) {
        var generator = SeededGenerator(seed: seed)
        while case .dealing = engine.phase {
            guard let free = engine.deck.firstIndex(where: { $0 != nil }) else { break }
            engine.pickCard(at: free)
            engine.advanceDealing(using: &generator)
        }
    }

    // MARK: Attribution

    func testEveryRequestedRoleIsAssignedToDistinctPlayers() {
        var engine = makeEngine(players: 8, specialRoles: [.justice, .lovers, .avenger, .duelists])
        dealAll(&engine)

        let assigned = engine.players.compactMap(\.specialRole)
        XCTAssertEqual(assigned.count, 1 + 2 + 1 + 2, "6 sièges : justice 1, amoureux 2, vengeuse 1, duellistes 2")
        XCTAssertEqual(engine.players.filter { $0.specialRole == .lovers }.count, 2)
        XCTAssertEqual(engine.players.filter { $0.specialRole == .duelists }.count, 2)
    }

    func testRolesBelowTheirPlayerMinimumAreDropped() {
        // 4 joueurs : les Amoureux (min 5) doivent sauter, la Déesse (min 4) rester.
        var engine = makeEngine(players: 4, specialRoles: [.justice, .lovers])
        dealAll(&engine)

        XCTAssertTrue(engine.config.specialRoles.contains(.justice))
        XCTAssertFalse(engine.config.specialRoles.contains(.lovers))
        XCTAssertNil(engine.players.first { $0.specialRole == .lovers })
    }

    func testAssignmentIsDeterministicForAGivenSeed() {
        let first = makeEngine(players: 8, specialRoles: [.lovers, .avenger], seed: 99)
        let second = makeEngine(players: 8, specialRoles: [.lovers, .avenger], seed: 99)
        XCTAssertEqual(first.specialRoles, second.specialRoles)
    }

    // MARK: Amoureux

    func testEliminatingALoverTakesThePartnerDown() {
        var engine = makeEngine(players: 7, specialRoles: [.lovers])
        dealAll(&engine)

        let lovers = engine.players.filter { $0.specialRole == .lovers }
        XCTAssertEqual(lovers.count, 2)

        engine.startVote()
        engine.eliminate(playerID: lovers[0].id)

        guard case .elimination(let fallen) = engine.phase else {
            return XCTFail("Phase attendue : élimination, obtenu \(engine.phase)")
        }
        XCTAssertEqual(Set(fallen), Set(lovers.map(\.id)), "Les deux amoureux tombent ensemble")
        XCTAssertTrue(engine.players.filter { $0.specialRole == .lovers }.allSatisfy { !$0.isAlive })
    }

    func testLoversFallingCanEndTheRound() {
        // Si l'undercover est amoureux d'un civil, éliminer le civil clôt la manche.
        for seed in UInt64(1)...60 {
            var engine = makeEngine(players: 5, specialRoles: [.lovers], seed: seed)
            dealAll(&engine, seed: seed)

            let lovers = engine.players.filter { $0.specialRole == .lovers }
            guard let undercoverLover = lovers.first(where: { $0.role == .undercover }),
                  let civilianLover = lovers.first(where: { $0.role == .civilian })
            else { continue }

            engine.startVote()
            engine.eliminate(playerID: civilianLover.id)
            var generator = SeededGenerator(seed: seed)
            engine.resolveElimination(using: &generator)

            XCTAssertEqual(engine.outcome, .civiliansWin, "graine \(seed) : l'undercover \(undercoverLover.name) est tombé par amour")
            return
        }
        XCTFail("Aucune graine n'a produit un couple undercover-civil : test à revoir")
    }

    // MARK: Vengeuse

    func testEliminatedAvengerChoosesAVictim() {
        var engine = makeEngine(players: 6, specialRoles: [.avenger])
        dealAll(&engine)

        let avenger = engine.players.first { $0.specialRole == .avenger }!
        engine.startVote()
        engine.eliminate(playerID: avenger.id)
        var generator = SeededGenerator(seed: 3)
        engine.resolveElimination(using: &generator)

        guard case .avengerStrike(let strikerID) = engine.phase else {
            return XCTFail("La Vengeuse doit frapper, phase obtenue : \(engine.phase)")
        }
        XCTAssertEqual(strikerID, avenger.id)

        let victim = engine.alivePlayers.first!
        engine.avengerStrikes(playerID: victim.id, using: &generator)

        guard case .elimination(let fallen) = engine.phase else {
            return XCTFail("La victime doit être révélée")
        }
        XCTAssertEqual(fallen, [victim.id])
        XCTAssertFalse(engine.player(id: victim.id)!.isAlive)
    }

    func testAvengerWhoIsAlsoMrWhiteGuessesFirstThenStrikes() {
        // Cas croisé le plus retors : la Vengeuse est aussi Mr. White. Sa
        // dernière chance passe d'abord ; si elle échoue, elle frappe quand même.
        for seed in UInt64(1)...80 {
            var engine = makeEngine(players: 6, undercover: 1, mrWhite: 1, specialRoles: [.avenger], seed: seed)
            dealAll(&engine, seed: seed)

            guard let avengerWhite = engine.players.first(where: { $0.specialRole == .avenger && $0.role == .mrWhite })
            else { continue }

            engine.startVote()
            engine.eliminate(playerID: avengerWhite.id)
            var generator = SeededGenerator(seed: seed)
            engine.resolveElimination(using: &generator)

            guard case .mrWhiteGuess = engine.phase else {
                return XCTFail("graine \(seed) : la dernière chance de Mr. White passe avant la vengeance")
            }

            engine.submitMrWhiteGuess("réponse fausse", using: &generator)
            guard case .avengerStrike(let strikerID) = engine.phase else {
                return XCTFail("graine \(seed) : la vengeance doit suivre l'échec de la devinette")
            }
            XCTAssertEqual(strikerID, avengerWhite.id)
            return
        }
        XCTFail("Aucune graine n'a produit une Vengeuse Mr. White : test à revoir")
    }

    // MARK: Duellistes

    func testFirstDuelistDownLosesPointsAndTheRivalGains() {
        var engine = makeEngine(players: 6, specialRoles: [.duelists])
        dealAll(&engine)

        let duelists = engine.players.filter { $0.specialRole == .duelists }
        XCTAssertEqual(duelists.count, 2)
        let loser = duelists[0], survivor = duelists[1]

        var generator = SeededGenerator(seed: 5)
        engine.startVote()
        engine.eliminate(playerID: loser.id)
        engine.resolveElimination(using: &generator)

        // On termine la manche en éliminant des joueurs jusqu'au verdict.
        var attempts = 0
        while !engine.isFinished, attempts < 10 {
            guard let target = engine.alivePlayers.first(where: { $0.role == .civilian }) ?? engine.alivePlayers.first
            else { break }
            engine.startVote()
            engine.eliminate(playerID: target.id)
            engine.resolveElimination(using: &generator)
            if case .mrWhiteGuess = engine.phase {
                engine.submitMrWhiteGuess("faux", using: &generator)
            }
            if case .avengerStrike = engine.phase {
                engine.avengerStrikes(playerID: engine.alivePlayers.first!.id, using: &generator)
                engine.resolveElimination(using: &generator)
            }
            attempts += 1
        }

        XCTAssertTrue(engine.isFinished)
        // Quel que soit le camp du perdant, son total intègre le malus du duel :
        // il reste strictement sous celui d'un coéquipier sans duel.
        XCTAssertLessThanOrEqual(
            engine.roundPoints[loser.id, default: 0],
            DuelScore.loser + Score.civilianWin,
            "Le perdant du duel doit avoir encaissé \(DuelScore.loser)"
        )
        XCTAssertGreaterThanOrEqual(engine.roundPoints[survivor.id, default: 0], DuelScore.survivor)
    }

    // MARK: Mr. Meme

    func testMimeIsDrawnEachRoundAmongLivingNonWhitePlayers() {
        var engine = makeEngine(players: 6, undercover: 1, mrWhite: 1, tableRules: [.mime])
        dealAll(&engine)

        guard let mimeID = engine.mimePlayerID,
              let mime = engine.player(id: mimeID)
        else { return XCTFail("Un mime doit être désigné dès le premier tour") }

        XCTAssertTrue(mime.isAlive)
        XCTAssertNotEqual(mime.role, .mrWhite, "Mimer sans avoir de mot trahirait Mr. White")
    }

    func testNoMimeWhenTheRuleIsOff() {
        var engine = makeEngine(players: 6, tableRules: [])
        dealAll(&engine)
        XCTAssertNil(engine.mimePlayerID)
    }

    // MARK: Compatibilité des réglages sauvegardés

    func testConfigDecodesFromJSONWithoutTheNewFields() throws {
        // JSON d'une version antérieure : aucun champ de pouvoir présent.
        let legacy = """
        {"playerNames":["A","B","C","D"],"undercoverCount":1,"mrWhiteCount":1,
         "categoryIDs":[],"mrWhiteCanStart":false,"easyMode":false,"randomMode":false}
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(GameConfig.self, from: legacy)
        XCTAssertTrue(config.specialRoles.isEmpty)
        XCTAssertTrue(config.tableRules.isEmpty)
        XCTAssertEqual(config.playerNames.count, 4)
    }
}
