import XCTest
@testable import Taupe

/// Générateur reproductible : les tests doivent rejouer exactement la même
/// distribution à chaque exécution.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // xorshift reste bloqué sur zéro : on garantit un état initial non nul.
        state = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        if state == 0 { state = 0x2545F4914F6CDD1D }
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

final class GameEngineTests: XCTestCase {

    private let pair = WordPair(a: "Chat", b: "Chien")

    private func makeEngine(
        players: Int = 5,
        undercover: Int = 1,
        mrWhite: Int = 1,
        mrWhiteCanStart: Bool = false,
        seed: UInt64 = 42
    ) -> GameEngine {
        var generator = SeededGenerator(seed: seed)
        let config = GameConfig(
            playerNames: (1...players).map { "J\($0)" },
            undercoverCount: undercover,
            mrWhiteCount: mrWhite,
            mrWhiteCanStart: mrWhiteCanStart
        )
        return GameEngine(config: config, pair: pair, using: &generator)
    }

    /// Fait piocher tout le monde, dans l'ordre, en prenant la première carte libre.
    private func dealAll(_ engine: inout GameEngine, seed: UInt64 = 7) {
        var generator = SeededGenerator(seed: seed)
        while case .dealing = engine.phase {
            guard let freeIndex = engine.deck.firstIndex(where: { $0 != nil }) else { break }
            XCTAssertNotNil(engine.pickCard(at: freeIndex))
            engine.advanceDealing(using: &generator)
        }
    }

    // MARK: Distribution

    func testDealingAssignsExactlyTheConfiguredRoles() {
        var engine = makeEngine(players: 7, undercover: 2, mrWhite: 1)
        XCTAssertEqual(engine.deck.count, 7)

        dealAll(&engine)

        XCTAssertTrue(engine.deck.allSatisfy { $0 == nil }, "Toutes les cartes doivent être prises")
        XCTAssertTrue(engine.players.allSatisfy { $0.role != nil })
        XCTAssertEqual(engine.players.filter { $0.role == .undercover }.count, 2)
        XCTAssertEqual(engine.players.filter { $0.role == .mrWhite }.count, 1)
        XCTAssertEqual(engine.players.filter { $0.role == .civilian }.count, 4)
    }

    func testTakenCardCannotBePickedTwice() {
        var engine = makeEngine()
        XCTAssertNotNil(engine.pickCard(at: 0))
        XCTAssertNil(engine.pickCard(at: 0), "Une carte déjà prise ne doit plus rien rendre")
    }

    func testDealingEndsOnTheFirstDescribingRound() {
        var engine = makeEngine(players: 6)
        dealAll(&engine)

        guard case .describing(let round) = engine.phase else {
            return XCTFail("La distribution doit déboucher sur le tour 1, phase obtenue : \(engine.phase)")
        }
        XCTAssertEqual(round, 1)
        XCTAssertEqual(engine.speakingOrder.count, 6)
    }

    func testWordsAreDistributedPerRole() {
        var engine = makeEngine(players: 5)
        dealAll(&engine)

        for player in engine.players {
            let word = player.word(civilianWord: engine.civilianWord, undercoverWord: engine.undercoverWord)
            switch player.role {
            case .civilian: XCTAssertEqual(word, engine.civilianWord)
            case .undercover: XCTAssertEqual(word, engine.undercoverWord)
            case .mrWhite: XCTAssertNil(word, "Mr. White ne reçoit aucun mot")
            case nil: XCTFail("Rôle non attribué")
            }
        }
        XCTAssertNotEqual(engine.civilianWord, engine.undercoverWord)
    }

    // MARK: Ordre de parole

    func testMrWhiteNeverSpeaksFirstByDefault() {
        // Plusieurs graines : l'ordre est aléatoire, la garantie doit tenir à chaque fois.
        for seed in UInt64(1)...40 {
            var engine = makeEngine(players: 5, undercover: 1, mrWhite: 1, seed: seed)
            dealAll(&engine, seed: seed)
            let first = engine.orderedSpeakers.first
            XCTAssertNotEqual(first?.role, .mrWhite, "Mr. White ne doit pas ouvrir (graine \(seed))")
        }
    }

    func testMrWhiteCanSpeakFirstWhenOptionEnabled() {
        // L'option doit rendre le cas possible ; on cherche une graine où il ouvre.
        var everStartedFirst = false
        for seed in UInt64(1)...80 {
            var engine = makeEngine(players: 5, undercover: 1, mrWhite: 1, mrWhiteCanStart: true, seed: seed)
            dealAll(&engine, seed: seed)
            if engine.orderedSpeakers.first?.role == .mrWhite { everStartedFirst = true; break }
        }
        XCTAssertTrue(everStartedFirst, "Avec l'option activée, Mr. White doit pouvoir ouvrir")
    }

    func testSpeakingOrderOnlyContainsLivingPlayers() {
        var engine = makeEngine(players: 6, undercover: 1, mrWhite: 0)
        dealAll(&engine)

        let victim = engine.players.first { $0.role == .civilian }!
        engine.startVote()
        engine.eliminate(playerID: victim.id)
        var generator = SeededGenerator(seed: 3)
        engine.resolveElimination(using: &generator)

        XCTAssertEqual(engine.speakingOrder.count, 5)
        XCTAssertFalse(engine.speakingOrder.contains(victim.id))
    }

    // MARK: Conditions de victoire

    func testCiviliansWinWhenAllInfiltratorsAreEliminated() {
        var engine = makeEngine(players: 6, undercover: 1, mrWhite: 0)
        dealAll(&engine)

        let undercover = engine.players.first { $0.role == .undercover }!
        engine.startVote()
        engine.eliminate(playerID: undercover.id)
        var generator = SeededGenerator(seed: 5)
        engine.resolveElimination(using: &generator)

        XCTAssertEqual(engine.outcome, .civiliansWin)
        // Cinq civils à deux points chacun.
        XCTAssertEqual(engine.roundPoints.values.reduce(0, +), 5 * Score.civilianWin)
    }

    func testInfiltratorsWinWhenOnlyOneCivilianRemains() {
        var engine = makeEngine(players: 5, undercover: 2, mrWhite: 0)
        dealAll(&engine)

        var generator = SeededGenerator(seed: 9)
        // Trois civils, deux undercover : on élimine deux civils.
        for civilian in engine.players.filter({ $0.role == .civilian }).prefix(2) {
            engine.startVote()
            engine.eliminate(playerID: civilian.id)
            engine.resolveElimination(using: &generator)
        }

        XCTAssertEqual(engine.outcome, .infiltratorsWin)
        XCTAssertEqual(engine.roundPoints.values.reduce(0, +), 2 * Score.undercoverSurvives)
    }

    func testGameContinuesWhileBothCampsCanStillWin() {
        var engine = makeEngine(players: 7, undercover: 2, mrWhite: 0)
        dealAll(&engine)

        let civilian = engine.players.first { $0.role == .civilian }!
        engine.startVote()
        engine.eliminate(playerID: civilian.id)
        var generator = SeededGenerator(seed: 11)
        engine.resolveElimination(using: &generator)

        XCTAssertFalse(engine.isFinished)
        guard case .describing(let round) = engine.phase else {
            return XCTFail("La manche doit repartir sur un tour de description")
        }
        XCTAssertEqual(round, 2)
    }

    // MARK: Mr. White

    func testEliminatingMrWhiteOpensTheGuessPhase() {
        var engine = makeEngine(players: 5, undercover: 1, mrWhite: 1)
        dealAll(&engine)

        let white = engine.players.first { $0.role == .mrWhite }!
        engine.startVote()
        engine.eliminate(playerID: white.id)
        var generator = SeededGenerator(seed: 13)
        engine.resolveElimination(using: &generator)

        guard case .mrWhiteGuess(let playerID) = engine.phase else {
            return XCTFail("Mr. White éliminé doit avoir sa dernière chance")
        }
        XCTAssertEqual(playerID, white.id)
    }

    func testCorrectGuessWinsTheRoundForMrWhite() {
        var engine = makeEngine(players: 5, undercover: 1, mrWhite: 1)
        dealAll(&engine)

        let white = engine.players.first { $0.role == .mrWhite }!
        engine.startVote()
        engine.eliminate(playerID: white.id)
        var generator = SeededGenerator(seed: 17)
        engine.resolveElimination(using: &generator)

        XCTAssertTrue(engine.submitMrWhiteGuess(engine.civilianWord, using: &generator))
        XCTAssertEqual(engine.outcome, .mrWhiteGuessedRight(playerID: white.id))
        XCTAssertEqual(engine.roundPoints[white.id], Score.mrWhiteGuessesRight)
        XCTAssertEqual(engine.roundPoints.count, 1, "Mr. White gagne seul")
    }

    func testWrongGuessLetsTheRoundContinue() {
        var engine = makeEngine(players: 6, undercover: 1, mrWhite: 1)
        dealAll(&engine)

        let white = engine.players.first { $0.role == .mrWhite }!
        engine.startVote()
        engine.eliminate(playerID: white.id)
        var generator = SeededGenerator(seed: 19)
        engine.resolveElimination(using: &generator)

        XCTAssertFalse(engine.submitMrWhiteGuess("Manifestement faux", using: &generator))
        XCTAssertFalse(engine.isFinished, "Il reste un undercover à démasquer")
        XCTAssertTrue(engine.roundPoints.isEmpty)
    }

    func testMrWhiteSurvivingScoresSixPoints() {
        var engine = makeEngine(players: 5, undercover: 0, mrWhite: 2)
        dealAll(&engine)

        var generator = SeededGenerator(seed: 23)
        for civilian in engine.players.filter({ $0.role == .civilian }).prefix(2) {
            engine.startVote()
            engine.eliminate(playerID: civilian.id)
            engine.resolveElimination(using: &generator)
        }

        XCTAssertEqual(engine.outcome, .infiltratorsWin)
        XCTAssertEqual(engine.roundPoints.values.reduce(0, +), 2 * Score.mrWhiteSurvives)
    }

    // MARK: Tolérance de la réponse

    func testGuessMatchingIgnoresCaseAccentsArticlesAndPlural() {
        XCTAssertTrue(GameEngine.matches(guess: "chat", word: "Chat"))
        XCTAssertTrue(GameEngine.matches(guess: "  CHAT  ", word: "Chat"))
        XCTAssertTrue(GameEngine.matches(guess: "le chat", word: "Chat"))
        XCTAssertTrue(GameEngine.matches(guess: "les chats", word: "Chat"))
        XCTAssertTrue(GameEngine.matches(guess: "elephant", word: "Éléphant"))
        XCTAssertTrue(GameEngine.matches(guess: "l'avion", word: "Avion"))
    }

    func testGuessMatchingRejectsADifferentWord() {
        XCTAssertFalse(GameEngine.matches(guess: "Chien", word: "Chat"))
        XCTAssertFalse(GameEngine.matches(guess: "", word: "Chat"))
        XCTAssertFalse(GameEngine.matches(guess: "Chaton", word: "Chat"))
    }

    // MARK: Robustesse

    func testActionsOutsideTheirPhaseAreIgnored() {
        var engine = makeEngine(players: 5)
        var generator = SeededGenerator(seed: 29)

        // On vote alors que la distribution n'est pas terminée : rien ne doit bouger.
        engine.startVote()
        guard case .dealing = engine.phase else {
            return XCTFail("La phase de distribution ne doit pas être quittée")
        }
        engine.eliminate(playerID: engine.players[0].id)
        XCTAssertTrue(engine.players[0].isAlive)
        XCTAssertFalse(engine.submitMrWhiteGuess("Chat", using: &generator))
    }

    func testEveryRoundEndsWithinAFiniteNumberOfEliminations() {
        // Filet de sécurité contre une boucle infinie : quelle que soit la
        // composition, éliminer les joueurs un à un doit finir par clore la manche.
        for players in Composition.minPlayers...12 {
            let suggested = Composition.suggested(playerCount: players)
            var engine = makeEngine(
                players: players,
                undercover: suggested.undercover,
                mrWhite: suggested.mrWhite,
                seed: UInt64(players)
            )
            dealAll(&engine, seed: UInt64(players))

            var generator = SeededGenerator(seed: UInt64(players) &+ 100)
            var eliminations = 0
            while !engine.isFinished, eliminations < players {
                guard let target = engine.alivePlayers.first else { break }
                engine.startVote()
                engine.eliminate(playerID: target.id)
                engine.resolveElimination(using: &generator)
                if case .mrWhiteGuess = engine.phase {
                    engine.submitMrWhiteGuess("réponse fausse", using: &generator)
                }
                eliminations += 1
            }
            XCTAssertTrue(engine.isFinished, "Manche à \(players) joueurs jamais terminée")
        }
    }
}
