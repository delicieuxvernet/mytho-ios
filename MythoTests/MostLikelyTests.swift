import XCTest
@testable import Mytho

/// Mémoire volatile : un test ne doit rien laisser dans les réglages du
/// simulateur, et deux tests ne doivent pas hériter du paquet l'un de l'autre.
private final class MemoryOnlyDeckStore: DeckMemoryStore {
    private var storage: [String: DeckMemorySnapshot] = [:]

    func memory(forDeck deckID: String) -> DeckMemorySnapshot { storage[deckID] ?? .empty }
    func save(_ memory: DeckMemorySnapshot, forDeck deckID: String) { storage[deckID] = memory }
    func clear(deckID: String) { storage[deckID] = nil }
    func clearAll() { storage.removeAll() }
}

final class MostLikelyTests: XCTestCase {

    // MARK: Outils

    private func table(_ count: Int) -> [Participant] {
        (0..<count).map { Participant(name: "J\($0)") }
    }

    /// Des réglages qui sortent réellement des cartes. Depuis l'écrémage du
    /// 20 août 2026, le paquet ouvert est **vide** : partir de la sélection par
    /// défaut donnerait un paquet de zéro carte, et tous les tests de moteur
    /// échoueraient pour une raison qui n'a rien à voir avec ce qu'ils testent.
    private func jouables(
        limit: MostLikelyEngine.RoundLimit = .twelve,
        counting: MostLikelyEngine.Counting = .quick
    ) -> MostLikelyEngine.Options {
        MostLikelyEngine.Options(
            limit: limit,
            counting: counting,
            packs: [.soiree],
            adultUnlocked: true
        )
    }

    private func makeEngine(
        _ players: [Participant],
        options: MostLikelyEngine.Options? = nil,
        scores: ScoreBoard? = nil,
        seed: UInt64 = 42,
        store: any DeckMemoryStore = MemoryOnlyDeckStore()
    ) -> MostLikelyEngine? {
        var generator = SeededGenerator(seed: seed)
        return MostLikelyEngine(
            players: players,
            options: options ?? jouables(),
            scores: scores,
            store: store,
            using: &generator
        )
    }

    private func options(
        limit: MostLikelyEngine.RoundLimit = .twelve,
        counting: MostLikelyEngine.Counting = .quick
    ) -> MostLikelyEngine.Options {
        jouables(limit: limit, counting: counting)
    }

    /// Joue une manche complète en mode rapide.
    private func playQuickRound(_ engine: inout MostLikelyEngine, designating winner: UUID) {
        engine.countdownFinished()
        XCTAssertTrue(engine.designate([winner]))
    }

    // MARK: - Décompte (checklist §3)

    func testCountdownIsThreeTwoOneThenPoint() {
        XCTAssertEqual(MostLikelyCountdown.steps.map(\.label), ["3", "2", "1", "Pointez"])
    }

    /// La vibration lourde tombe sur « Pointez » et nulle part ailleurs : c'est
    /// elle qui synchronise la table, personne ne regarde l'écran à cet instant.
    func testOnlyTheLastStepHitsHard() {
        XCTAssertEqual(
            MostLikelyCountdown.steps.map(\.haptic),
            [.light, .light, .light, .heavy]
        )
    }

    func testCountdownLastsAboutTwoSecondsAndAHalf() {
        XCTAssertEqual(MostLikelyCountdown.duration, 2.4, accuracy: 0.001)
        for step in MostLikelyCountdown.steps {
            XCTAssertEqual(step.duration, MostLikelyCountdown.stepDuration, accuracy: 0.001)
        }
    }

    // MARK: - Minimum de joueurs (spec §3.6)

    func testThreePlayersAreTheFloor() {
        XCTAssertNil(makeEngine(table(2)), "À deux, pointer l'autre n'a aucun sens")
        XCTAssertNotNil(makeEngine(table(3)))
    }

    /// Un joueur en pause ne compte pas dans le minimum : sinon une table de
    /// trois dont deux sont partis se lancerait quand même.
    func testInactivePlayersDoNotFillTheTable() {
        var players = table(4)
        players[1].isActive = false
        players[2].isActive = false
        XCTAssertNil(makeEngine(players))
    }

    // MARK: - Mode rapide

    func testTheDesignatedPlayerScoresOnePoint() throws {
        let players = table(5)
        var engine = try XCTUnwrap(makeEngine(players))
        XCTAssertEqual(engine.phase, .card)

        engine.countdownFinished()
        XCTAssertEqual(engine.phase, .designation)

        XCTAssertTrue(engine.designate([players[2].id]))

        guard case .result(let outcome) = engine.phase else { return XCTFail("Résultat attendu") }
        XCTAssertEqual(outcome.winners, [players[2].id])
        XCTAssertEqual(outcome.points, 1)
        XCTAssertFalse(outcome.isCounted, "Le mode rapide ne compte pas les doigts")
        XCTAssertEqual(engine.score(for: players[2].id), 1)
        XCTAssertEqual(engine.score(for: players[0].id), 0)
    }

    /// « Ex æquo » : les deux marquent (spec §3.6).
    func testATieScoresForBoth() throws {
        let players = table(5)
        var engine = try XCTUnwrap(makeEngine(players))
        engine.countdownFinished()

        XCTAssertTrue(engine.designate([players[0].id, players[3].id]))

        guard case .result(let outcome) = engine.phase else { return XCTFail("Résultat attendu") }
        XCTAssertTrue(outcome.isTie)
        XCTAssertEqual(engine.score(for: players[0].id), 1)
        XCTAssertEqual(engine.score(for: players[3].id), 1)
        XCTAssertEqual(engine.score(for: players[1].id), 0)
    }

    func testADesignationOutsideTheTableIsRefused() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players))
        engine.countdownFinished()

        XCTAssertFalse(engine.designate([]), "Valider sans personne ne veut rien dire")
        XCTAssertFalse(
            engine.designate([players[0].id, players[1].id, players[2].id]),
            "Trois prénoms, ce n'est plus une égalité"
        )
        XCTAssertFalse(engine.designate([UUID()]), "Un joueur hors table ne peut pas marquer")
        XCTAssertEqual(engine.phase, .designation, "Aucun refus ne doit faire avancer la manche")
    }

    /// Un même prénom tapé deux fois reste une seule désignation.
    func testDuplicateTapsCollapseIntoOneWinner() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players))
        engine.countdownFinished()

        XCTAssertTrue(engine.designate([players[1].id, players[1].id]))
        XCTAssertEqual(engine.score(for: players[1].id), 1)
    }

    // MARK: - Rattrapage d'un mauvais tap

    func testUndoGivesTheGridBackAndTakesThePointAway() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players))
        playQuickRound(&engine, designating: players[0].id)
        XCTAssertTrue(engine.canUndo)

        XCTAssertTrue(engine.undoDesignation())
        XCTAssertEqual(engine.phase, .designation)
        XCTAssertEqual(engine.score(for: players[0].id), 0)

        XCTAssertTrue(engine.designate([players[1].id]))
        XCTAssertEqual(engine.score(for: players[1].id), 1)
    }

    /// L'annulation ne franchit pas la manche : un « corriger » tardif retirerait
    /// un point sans que personne ne comprenne lequel.
    func testUndoDoesNotReachIntoThePreviousRound() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(limit: .endless)))
        playQuickRound(&engine, designating: players[0].id)
        engine.nextRound()
        playQuickRound(&engine, designating: players[1].id)

        XCTAssertTrue(engine.undoDesignation())
        XCTAssertFalse(engine.canUndo, "La manche précédente est refermée")
        XCTAssertEqual(engine.score(for: players[0].id), 1)
    }

    func testSecretVotingNeverOffersUndo() throws {
        let players = table(3)
        var engine = try XCTUnwrap(makeEngine(players, options: options(counting: .secret)))
        engine.countdownFinished()
        for _ in 0..<3 {
            engine.takePhone()
            XCTAssertTrue(engine.castBallot(for: players[0].id))
        }

        XCTAssertFalse(engine.canUndo, "Refaire circuler le téléphone remontrerait des bulletins")
        XCTAssertFalse(engine.undoDesignation())
    }

    // MARK: - Vote secret (spec §3.2)

    func testSecretVoteCountsEveryFinger() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(counting: .secret)))

        engine.countdownFinished()
        guard case .pass(let first) = engine.phase else { return XCTFail("Passage du téléphone attendu") }
        XCTAssertEqual(first, 0)
        XCTAssertEqual(engine.currentVoter?.id, players[0].id)

        // Trois doigts sur le deuxième joueur, un sur le premier.
        let choices = [players[1].id, players[1].id, players[1].id, players[0].id]
        for choice in choices {
            engine.takePhone()
            XCTAssertTrue(engine.castBallot(for: choice))
        }

        guard case .result(let outcome) = engine.phase else { return XCTFail("Résultat attendu") }
        XCTAssertTrue(outcome.isCounted)
        XCTAssertEqual(outcome.voterCount, 4)
        XCTAssertEqual(outcome.fingers(for: players[1].id), 3)
        XCTAssertEqual(outcome.fingers(for: players[0].id), 1)
        XCTAssertEqual(outcome.winners, [players[1].id])
        XCTAssertEqual(engine.score(for: players[1].id), 1)
    }

    func testSecretVoteTieScoresForBoth() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(counting: .secret)))
        engine.countdownFinished()

        let choices = [players[1].id, players[1].id, players[2].id, players[2].id]
        for choice in choices {
            engine.takePhone()
            XCTAssertTrue(engine.castBallot(for: choice))
        }

        guard case .result(let outcome) = engine.phase else { return XCTFail("Résultat attendu") }
        // Ordre du roster : deux dépouillements du même vote donnent la même liste.
        XCTAssertEqual(outcome.winners, [players[1].id, players[2].id])
        XCTAssertEqual(engine.score(for: players[1].id), 1)
        XCTAssertEqual(engine.score(for: players[2].id), 1)
    }

    /// Le bulletin ne s'ouvre qu'après « Je suis X » : sans ce passage, le voisin
    /// verrait la grille du précédent.
    func testTheBallotOnlyOpensOnceThePhoneIsTaken() throws {
        let players = table(3)
        var engine = try XCTUnwrap(makeEngine(players, options: options(counting: .secret)))
        engine.countdownFinished()

        XCTAssertFalse(engine.castBallot(for: players[0].id), "Le téléphone n'a pas encore été pris")
        engine.takePhone()
        XCTAssertEqual(engine.phase, .ballot(voterIndex: 0))
        XCTAssertTrue(engine.castBallot(for: players[0].id))
        XCTAssertEqual(engine.phase, .pass(voterIndex: 1))
    }

    // MARK: - Fin de partie

    func testTheGameStopsAfterTheChosenNumberOfRounds() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(limit: .six)))

        for round in 1...6 {
            XCTAssertEqual(engine.roundNumber, round)
            playQuickRound(&engine, designating: players[0].id)
            XCTAssertEqual(engine.isLastRound, round == 6)
            engine.nextRound()
        }

        XCTAssertEqual(engine.phase, .finished)
        XCTAssertEqual(engine.score(for: players[0].id), 6)
        XCTAssertEqual(engine.champions, [players[0].id])
    }

    func testEndlessModeOnlyStopsWhenTheTableSaysSo() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(limit: .endless)))

        for _ in 0..<10 {
            playQuickRound(&engine, designating: players[1].id)
            XCTAssertFalse(engine.isLastRound)
            engine.nextRound()
            XCTAssertEqual(engine.phase, .card)
        }
        XCTAssertNil(engine.totalRounds)

        engine.finishNow()
        XCTAssertEqual(engine.phase, .finished)
        XCTAssertTrue(engine.isFinished)
    }

    /// Le classement partage les rangs à égalité : 1, 1, 3.
    func testStandingsShareRanksOnATie() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(limit: .endless)))
        playQuickRound(&engine, designating: players[0].id)
        engine.nextRound()
        playQuickRound(&engine, designating: players[1].id)

        let standings = engine.standings
        XCTAssertEqual(standings.prefix(2).map(\.rank), [1, 1])
        XCTAssertEqual(standings[2].rank, 3)
        XCTAssertEqual(Set(engine.champions), Set([players[0].id, players[1].id]))
    }

    // MARK: - Roster mouvant (spec §3.6)

    func testALeavingPlayerKeepsPointsAndLeavesTheGrid() throws {
        var players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(limit: .endless)))
        playQuickRound(&engine, designating: players[3].id)
        engine.nextRound()

        players[3].isActive = false
        engine.syncPlayers(players)

        XCTAssertEqual(engine.score(for: players[3].id), 1, "Un départ ne coûte pas les points déjà marqués")
        XCTAssertFalse(engine.candidates.contains { $0.id == players[3].id })
        XCTAssertEqual(engine.candidates.count, 3)
        XCTAssertTrue(engine.hasEnoughPlayers)
    }

    func testAVoterWhoLeavesMidBallotIsSkipped() throws {
        var players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(counting: .secret)))
        engine.countdownFinished()

        engine.takePhone()
        XCTAssertTrue(engine.castBallot(for: players[2].id))
        XCTAssertEqual(engine.currentVoter?.id, players[1].id)

        // Le deuxième votant s'en va avant d'avoir pris le téléphone.
        players[1].isActive = false
        engine.syncPlayers(players)
        XCTAssertEqual(engine.currentVoter?.id, players[2].id, "La file se referme sur le suivant")

        for _ in 0..<2 {
            engine.takePhone()
            XCTAssertTrue(engine.castBallot(for: players[2].id))
        }

        guard case .result(let outcome) = engine.phase else { return XCTFail("Résultat attendu") }
        XCTAssertEqual(outcome.voterCount, 3, "Trois bulletins déposés, pas quatre")
        XCTAssertEqual(outcome.winners, [players[2].id])
    }

    /// Le dernier votant part : le dépouillement se fait sans l'attendre.
    func testTheRoundCanCloseWhenTheLastVoterLeaves() throws {
        var players = table(3)
        var engine = try XCTUnwrap(makeEngine(players, options: options(counting: .secret)))
        engine.countdownFinished()

        for _ in 0..<2 {
            engine.takePhone()
            XCTAssertTrue(engine.castBallot(for: players[0].id))
        }
        XCTAssertEqual(engine.currentVoter?.id, players[2].id)

        players[2].isActive = false
        engine.syncPlayers(players)

        guard case .result(let outcome) = engine.phase else { return XCTFail("Résultat attendu") }
        XCTAssertEqual(outcome.voterCount, 2)
        XCTAssertEqual(outcome.winners, [players[0].id])
    }

    // MARK: - Pioche et carte

    /// Une carte ne revient jamais tant que le paquet n'a pas défilé en entier
    /// (spec §8). On tire donc exactement la taille du paquet, et les tirages
    /// doivent tous différer. Le nombre se **déduit** du paquet : écrit en dur,
    /// ce test repasserait au rouge au prochain écrémage sans qu'aucune
    /// régression n'ait eu lieu — c'est arrivé le 20 août.
    func testACardNeverComesBackWithinAGame() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(limit: .endless)))
        let taille = MostLikelyPack.soiree.cards.count

        var seen: [String] = [engine.card.id]
        for _ in 1..<taille {
            playQuickRound(&engine, designating: players[0].id)
            engine.nextRound()
            seen.append(engine.card.id)
        }
        XCTAssertEqual(seen.count, taille, "Le tour du paquet doit se jouer en entier")
        XCTAssertEqual(Set(seen).count, seen.count, "Une carte est revenue avant la fin du paquet")
        XCTAssertFalse(engine.hasLoopedDeck, "Le paquet ne doit pas avoir bouclé avant d'être épuisé")
    }

    func testTheCardTiltIsFrozenWhenItIsDealt() throws {
        let players = table(4)
        var engine = try XCTUnwrap(makeEngine(players, options: options(limit: .endless)))

        let dealt = engine.tilt
        XCTAssertTrue(MostLikelyEngine.tiltRange.contains(dealt))

        engine.countdownFinished()
        XCTAssertEqual(engine.tilt, dealt, "L'angle ne se recalcule pas d'un écran à l'autre")

        XCTAssertTrue(engine.designate([players[0].id]))
        XCTAssertEqual(engine.tilt, dealt)

        engine.nextRound()
        XCTAssertTrue(MostLikelyEngine.tiltRange.contains(engine.tilt))
    }

    /// Deux graines identiques rejouent la même soirée : c'est ce qui rend le
    /// moteur reproductible.
    func testTheSameSeedDealsTheSameCards() throws {
        let players = table(4)
        // Les generateurs vivent dans le test, pas dans le constructeur : la
        // surcharge de confort `nextRound()` tire du hasard systeme, elle ne
        // peut pas prolonger une suite reproductible.
        var leftRNG = SeededGenerator(seed: 7)
        var rightRNG = SeededGenerator(seed: 7)

        // XCTUnwrap prend une autoclosure : `&generator` ne peut pas y entrer,
        // d'ou la construction en deux temps.
        let leftBuilt = MostLikelyEngine(
            players: players,
            options: options(limit: .endless),
            scores: nil,
            store: MemoryOnlyDeckStore(),
            using: &leftRNG
        )
        let rightBuilt = MostLikelyEngine(
            players: players,
            options: options(limit: .endless),
            scores: nil,
            store: MemoryOnlyDeckStore(),
            using: &rightRNG
        )
        var left = try XCTUnwrap(leftBuilt)
        var right = try XCTUnwrap(rightBuilt)

        for _ in 0..<10 {
            XCTAssertEqual(left.card.id, right.card.id)
            XCTAssertEqual(left.tilt, right.tilt)
            playQuickRound(&left, designating: players[0].id)
            playQuickRound(&right, designating: players[0].id)
            left.nextRound(using: &leftRNG)
            right.nextRound(using: &rightRNG)
        }
    }

    /// La mémoire du paquet est celle du jeu : elle survit à une nouvelle partie
    /// dans la même soirée.
    func testTheDeckRemembersBetweenTwoGames() throws {
        let players = table(4)
        let store = MemoryOnlyDeckStore()

        var first = try XCTUnwrap(makeEngine(players, options: options(limit: .endless), seed: 3, store: store))
        var seen: Set<String> = [first.card.id]
        for _ in 0..<5 {
            playQuickRound(&first, designating: players[0].id)
            first.nextRound()
            seen.insert(first.card.id)
        }

        let second = try XCTUnwrap(makeEngine(players, options: options(limit: .endless), seed: 3, store: store))
        XCTAssertFalse(seen.contains(second.card.id), "La partie suivante repart où le paquet s'est arrêté")
    }

    // MARK: - Points de la soirée

    /// Changer de jeu conserve les points : le tableau se reprend tel quel.
    func testAnExistingScoreBoardIsCarriedOver() throws {
        let players = table(4)
        var board = ScoreBoard(playerIDs: players.map(\.id))
        board.award(3, to: players[0].id)

        let engine = try XCTUnwrap(makeEngine(players, scores: board))
        XCTAssertEqual(engine.score(for: players[0].id), 3)
        XCTAssertFalse(engine.canUndo, "Une nouvelle partie n'annule pas les points du jeu précédent")
    }

    // MARK: - Contenu (spec §3.5)

    func testPackVolumesMatchTheSpec() {
        XCTAssertEqual(MostLikelyPack.potes.cards.count, 0, "Vidé par l'écrémage du 20 août : c'est voulu")
        XCTAssertEqual(MostLikelyPack.soiree.cards.count, 14)
        XCTAssertEqual(
            MostLikelyBank.cards(for: MostLikelyPack.defaultSelection).count,
            0,
            "Le paquet tout public est vide : l'écran doit le dire, pas servir du 18+"
        )
        XCTAssertEqual(MostLikelyBank.all.count, 14)
    }

    func testNoCardIsEmptyOrDuplicated() {
        let cards = MostLikelyBank.all

        XCTAssertEqual(Set(cards.map(\.id)).count, cards.count, "Deux cartes portent le même identifiant")
        XCTAssertEqual(Set(cards.map(\.text)).count, cards.count, "Deux cartes disent la même chose")

        for card in cards {
            XCTAssertFalse(card.id.isEmpty)
            XCTAssertFalse(card.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(card.id) est vide")
            XCTAssertEqual(card.text, card.text.trimmingCharacters(in: .whitespacesAndNewlines), "\(card.id) traîne un espace")
        }
    }

    /// La phrase se lit après « Le plus susceptible de… » : verbe à l'infinitif,
    /// sans majuscule ni point final. Une carte qui échoue ici est mal écrite.
    func testEveryCardReadsAfterThePrefix() {
        for card in MostLikelyBank.all {
            guard let first = card.text.first else { return XCTFail("\(card.id) est vide") }
            XCTAssertEqual(
                String(first), String(first).lowercased(),
                "\(card.id) commence par une majuscule : « \(card.text) »"
            )
            XCTAssertFalse(card.text.hasSuffix("."), "\(card.id) finit par un point : « \(card.text) »")

            // Le pronom réfléchi se retire avant de juger la terminaison.
            var head = card.text
            for prefix in ["se ", "s'"] where head.hasPrefix(prefix) {
                head = String(head.dropFirst(prefix.count))
                break
            }
            let verb = head.split(separator: " ").first.map(String.init) ?? head
            XCTAssertTrue(
                verb.hasSuffix("er") || verb.hasSuffix("ir") || verb.hasSuffix("re"),
                "\(card.id) ne commence pas par un infinitif : « \(card.text) »"
            )
        }
    }

    /// Le préfixe est dans l'interface, jamais dans la donnée.
    func testNoCardRepeatsThePrefix() {
        for card in MostLikelyBank.all {
            XCTAssertFalse(
                card.text.lowercased().contains("plus susceptible"),
                "\(card.id) recopie le préfixe de l'écran"
            )
        }
    }

    /// « Entre potes » est tout public ; « Soirée » vit derrière la porte
    /// d'âge et n'apparaît jamais tant qu'elle n'est pas passée.
    func testOnlyTheAdultPackHidesBehindTheAgeGate() {
        XCTAssertFalse(MostLikelyPack.available(unlockedExtras: false).contains(.soiree),
                       "Le 18+ reste invisible tant que l'âge n'est pas confirmé")
        XCTAssertTrue(MostLikelyPack.available(unlockedExtras: true).contains(.soiree))
        XCTAssertFalse(MostLikelyPack.defaultSelection.contains(.soiree), "Jamais coché d'office")
    }

    /// Un paquet vidé de ses cartes ne se propose plus : cocher une case qui ne
    /// sortira jamais rien est une promesse qu'on ne tient pas. Le paquet
    /// « Entre potes » est dans ce cas depuis l'écrémage du 20 août.
    func testAnEmptiedPackIsNotOfferedAnymore() {
        XCTAssertTrue(MostLikelyPack.potes.cards.isEmpty, "État attendu après l'écrémage")
        XCTAssertFalse(MostLikelyPack.available(unlockedExtras: false).contains(.potes))
        XCTAssertFalse(MostLikelyPack.available(unlockedExtras: true).contains(.potes))
    }

    /// Sans confirmation d'âge, il n'y a plus rien à jouer — et le moteur doit
    /// le dire en refusant de démarrer, jamais en piochant dans le 18+.
    func testWithoutTheAgeGateThereIsNothingLeftToPlay() {
        XCTAssertTrue(MostLikelyBank.cards(for: [], adultUnlocked: false).isEmpty)
        XCTAssertNil(
            makeEngine(table(4), options: MostLikelyEngine.Options()),
            "Un paquet sans carte ne lance pas de partie"
        )
    }

    /// Le verrou 18+ vit dans la banque, pas seulement dans l'écran : cocher
    /// « Soirée » puis refermer le contenu adulte dans les réglages ne doit plus
    /// sortir une seule carte du paquet. Sans cette garde, le chemin
    /// confirmer l'âge → cocher → refermer → lancer les servait quand même.
    func testTheAdultPackNeverLeaksOnceTheAgeGateIsClosedAgain() {
        let tout: Set<MostLikelyPack> = [.potes, .soiree]

        XCTAssertEqual(
            MostLikelyBank.cards(for: tout, adultUnlocked: false).count,
            MostLikelyPack.potes.cards.count,
            "Verrou fermé : le paquet 18+ ne fournit aucune carte"
        )
        XCTAssertEqual(
            MostLikelyBank.cards(for: tout, adultUnlocked: true).count,
            MostLikelyPack.potes.cards.count + MostLikelyPack.soiree.cards.count
        )
        XCTAssertEqual(
            MostLikelyBank.cards(for: [.soiree], adultUnlocked: false).count,
            MostLikelyPack.potes.cards.count,
            "Le 18+ seul et verrouillé retombe sur le paquet tout public"
        )

        // Et jusque dans le moteur. Le paquet tout public étant vide depuis
        // l'écrémage du 20 août, le verrou fermé ne laisse plus AUCUNE carte :
        // le moteur doit refuser de démarrer. C'est plus fort que l'ancienne
        // version du test, qui vérifiait que les cartes piochées étaient
        // publiques — ici, il ne doit pas y avoir de pioche du tout.
        var reglages = options(limit: .endless)
        reglages.packs = tout
        reglages.adultUnlocked = false
        XCTAssertNil(
            makeEngine(table(4), options: reglages),
            "Verrou fermé et paquet public vide : aucune partie ne se lance, et surtout aucune carte 18+"
        )

        // Verrou ouvert, en revanche, la partie tourne et ne pioche que du 18+.
        let adultes = Set(MostLikelyPack.soiree.cards.map(\.id))
        reglages.adultUnlocked = true
        let players = table(4)
        guard var engine = makeEngine(players, options: reglages) else {
            return XCTFail("Le moteur doit se lancer une fois l'âge confirmé")
        }
        for _ in 0..<30 {
            XCTAssertTrue(adultes.contains(engine.card.id), "\(engine.card.id) sort d'un paquet inattendu")
            playQuickRound(&engine, designating: players[0].id)
            engine.nextRound()
        }
    }

    func testTheDeckIdMatchesTheRegistryEntry() {
        XCTAssertTrue(
            GameRegistry.all.contains { $0.id == MostLikelyEngine.gameID },
            "La mémoire du paquet est nommée d'après l'identifiant du jeu"
        )
    }
}
