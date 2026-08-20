import XCTest
@testable import Mytho

/// Mémoire volatile : un test ne doit rien laisser dans les réglages du
/// simulateur, ni hériter du paquet du test précédent.
private final class MemoryDeckStore: DeckMemoryStore {
    private var storage: [String: DeckMemorySnapshot] = [:]

    func memory(forDeck deckID: String) -> DeckMemorySnapshot { storage[deckID] ?? .empty }
    func save(_ memory: DeckMemorySnapshot, forDeck deckID: String) { storage[deckID] = memory }
    func clear(deckID: String) { storage[deckID] = nil }
    func clearAll() { storage.removeAll() }
}

final class WouldYouRatherTests: XCTestCase {

    // MARK: Outils

    private func players(_ count: Int) -> [UUID] {
        (0..<count).map { _ in UUID() }
    }

    private func makeEngine(
        mode: WouldYouRatherMode,
        limit: WouldYouRatherLimit = .standard,
        players ids: [UUID] = [],
        seed: UInt64 = 1
    ) -> (WouldYouRatherEngine, SeededGenerator) {
        var generator = SeededGenerator(seed: seed)
        var engine = WouldYouRatherEngine(
            mode: mode,
            limit: limit,
            players: ids,
            deck: WouldYouRatherEngine.makeDeck(store: MemoryDeckStore())
        )
        engine.start(using: &generator)
        return (engine, generator)
    }

    /// Joue une carte entière **avec la même API quel que soit le mode**. Si ce
    /// helper avait besoin d'un `switch` par mode, c'est qu'il y aurait trois
    /// moteurs déguisés en un.
    @discardableResult
    private func playCard(
        _ engine: inout WouldYouRatherEngine,
        sides: [DilemmaSide]
    ) -> WouldYouRatherEngine.Outcome? {
        if engine.mode.identifiesVoters {
            let voters = engine.voters
            for (index, voter) in voters.enumerated() {
                engine.vote(sides[index % sides.count], by: voter)
            }
        } else {
            for side in sides { engine.countOpenVote(side) }
        }
        return engine.reveal()
    }

    // MARK: - Un seul moteur pour trois modes

    /// Checklist §4 : « les trois modes partagent le même moteur et le même
    /// paquet ».
    func testTheThreeModesRunOnTheSameEngineAndTheSameDeck() {
        let table = players(4)

        for mode in WouldYouRatherMode.allCases {
            let ids = mode.identifiesVoters ? table : []
            var (engine, generator) = makeEngine(mode: mode, limit: .cards(3), players: ids)

            XCTAssertEqual(engine.deck.deckID, WouldYouRatherEngine.deckID, "\(mode) doit piocher dans le paquet commun")
            XCTAssertEqual(engine.deck.count, WouldYouRatherBank.all.count)
            XCTAssertEqual(engine.phase, .dilemma)
            XCTAssertNotNil(engine.card)

            let outcome = playCard(&engine, sides: [.a, .a, .b, .b])
            XCTAssertNotNil(outcome, "\(mode) doit pouvoir refermer une carte")
            XCTAssertEqual(engine.phase, .split)
            XCTAssertEqual(outcome?.tally.total, 4)

            engine.next(using: &generator)
            XCTAssertEqual(engine.phase, .dilemma, "\(mode) enchaîne sur la carte suivante")
        }
    }

    /// Deux modes qui tournent en parallèle ne doivent pas se prêter leurs
    /// cartes : la mémoire est celle du jeu, pas celle du mode.
    func testTheDeckMemoryIsSharedAcrossModes() {
        let store = MemoryDeckStore()
        var generator = SeededGenerator(seed: 9)

        var debate = WouldYouRatherEngine(
            mode: .debate,
            deck: WouldYouRatherEngine.makeDeck(store: store)
        )
        debate.start(using: &generator)
        let firstCard = debate.card?.id

        var survival = WouldYouRatherEngine(
            mode: .survival,
            players: players(3),
            deck: WouldYouRatherEngine.makeDeck(store: store)
        )
        survival.start(using: &generator)

        XCTAssertNotNil(firstCard)
        XCTAssertNotEqual(survival.card?.id, firstCard, "La carte déjà vue en débat ne doit pas revenir en survie")
    }

    // MARK: - Mode débat

    /// Le mode débat se lance **sans prénoms** (spec §4.5) : dix secondes pour
    /// démarrer avec des inconnus.
    func testDebateRunsWithoutAnyNames() {
        var (engine, generator) = makeEngine(mode: .debate, limit: .cards(2))

        XCTAssertTrue(engine.voters.isEmpty)
        XCTAssertTrue(engine.pendingVoters.isEmpty)
        XCTAssertNil(engine.nextVoter)
        XCTAssertFalse(engine.isReadyToReveal, "Sans une seule main comptée, il n'y a rien à montrer")

        engine.countOpenVote(.a)
        engine.countOpenVote(.a)
        engine.countOpenVote(.b)
        XCTAssertTrue(engine.isReadyToReveal)

        let outcome = engine.reveal()
        XCTAssertEqual(outcome?.tally.a, 2)
        XCTAssertEqual(outcome?.tally.b, 1)
        XCTAssertEqual(outcome?.tally.majority, .a)
        XCTAssertEqual(outcome?.tally.minority, .b)
        XCTAssertTrue(outcome?.scored.isEmpty == true, "Personne n'est nommé, personne ne marque")
        XCTAssertTrue(outcome?.eliminated.isEmpty == true, "On n'élimine qu'en survie")

        engine.next(using: &generator)
        XCTAssertEqual(engine.tally.total, 0, "Le comptage repart de zéro à chaque carte")
    }

    func testTheOpenCountNeverGoesBelowZero() {
        var (engine, _) = makeEngine(mode: .debate)

        engine.countOpenVote(.a)
        engine.countOpenVote(.a, delta: -1)
        engine.countOpenVote(.a, delta: -1)
        XCTAssertEqual(engine.tally.a, 0, "Un tap de trop se rattrape, il ne creuse pas")
        XCTAssertFalse(engine.isReadyToReveal)
    }

    /// Le comptage anonyme n'existe qu'en débat : ailleurs, un vote sans nom
    /// fausserait l'élimination.
    func testOpenCountingIsRefusedWhenVotersAreNamed() {
        let ids = players(3)
        var (engine, _) = makeEngine(mode: .secret, players: ids)

        XCTAssertFalse(engine.countOpenVote(.a))
        XCTAssertEqual(engine.tally.total, 0)
    }

    func testAGameEndsAfterTheChosenNumberOfCards() {
        var (engine, generator) = makeEngine(mode: .debate, limit: .cards(3))

        for card in 1...3 {
            engine.countOpenVote(.a)
            engine.reveal()
            XCTAssertEqual(engine.cardsPlayed, card)
            engine.next(using: &generator)
        }
        XCTAssertEqual(engine.phase, .finished)
        XCTAssertTrue(engine.isOver)
    }

    func testAnEndlessGameOnlyStopsWhenTheTableSaysSo() {
        var (engine, generator) = makeEngine(mode: .debate, limit: .endless)

        for _ in 0..<30 {
            engine.countOpenVote(.b)
            engine.reveal()
            engine.next(using: &generator)
            XCTAssertEqual(engine.phase, .dilemma)
            XCTAssertFalse(engine.isOver)
        }

        engine.finish()
        XCTAssertEqual(engine.phase, .finished)
    }

    // MARK: - Vote secret

    func testSecretVoteWaitsForEveryoneBeforeRevealing() {
        let ids = players(5)
        var (engine, _) = makeEngine(mode: .secret, limit: .cards(1), players: ids)

        XCTAssertEqual(engine.voters, ids, "Tout le monde vote, dans l'ordre du roster")
        XCTAssertEqual(engine.nextVoter, ids[0])

        engine.vote(.a, by: ids[0])
        XCTAssertEqual(engine.pendingVoters, Array(ids.dropFirst()))
        XCTAssertEqual(engine.nextVoter, ids[1])
        XCTAssertFalse(engine.isReadyToReveal, "Une révélation partielle trahirait le vote")

        engine.vote(.a, by: ids[1])
        engine.vote(.a, by: ids[2])
        engine.vote(.b, by: ids[3])
        engine.vote(.b, by: ids[4])
        XCTAssertTrue(engine.isReadyToReveal)

        let outcome = engine.reveal()
        XCTAssertEqual(outcome?.tally.a, 3)
        XCTAssertEqual(outcome?.tally.b, 2)
        XCTAssertTrue(outcome?.eliminated.isEmpty == true)
    }

    func testAnUnknownPlayerCannotVote() {
        let ids = players(3)
        var (engine, _) = makeEngine(mode: .secret, players: ids)

        XCTAssertFalse(engine.vote(.a, by: UUID()))
        XCTAssertEqual(engine.tally.total, 0)
    }

    // MARK: - Barème

    /// Une seule règle pour les trois modes : être avec la table rapporte un
    /// point. C'est aussi ce qui distingue un survivant d'un éliminé.
    func testTheMajorityScoresOnePointEach() {
        let ids = players(5)
        var (engine, _) = makeEngine(mode: .secret, players: ids)

        engine.vote(.a, by: ids[0])
        engine.vote(.a, by: ids[1])
        engine.vote(.a, by: ids[2])
        engine.vote(.b, by: ids[3])
        engine.vote(.b, by: ids[4])
        let outcome = engine.reveal()

        XCTAssertEqual(outcome?.scored, [ids[0], ids[1], ids[2]], "Dans l'ordre du roster, pas celui des votes")
        XCTAssertEqual(engine.scores.score(for: ids[0]), 1)
        XCTAssertEqual(engine.scores.score(for: ids[3]), 0)
        XCTAssertEqual(engine.scores.score(for: ids[4]), 0)
    }

    func testAPerfectTieScoresNothing() {
        let ids = players(4)
        var (engine, _) = makeEngine(mode: .secret, players: ids)

        engine.vote(.a, by: ids[0])
        engine.vote(.a, by: ids[1])
        engine.vote(.b, by: ids[2])
        engine.vote(.b, by: ids[3])
        let outcome = engine.reveal()

        XCTAssertTrue(outcome?.isTie == true)
        XCTAssertNil(outcome?.tally.majority)
        XCTAssertTrue(outcome?.scored.isEmpty == true, "Sans majorité, personne n'est avec la table")
        for id in ids { XCTAssertEqual(engine.scores.score(for: id), 0) }
    }

    /// L'annulation ne remonte jamais à la carte précédente (spec §2.5).
    func testUndoDoesNotReachBackToThePreviousCard() {
        let ids = players(3)
        var (engine, generator) = makeEngine(mode: .secret, players: ids)

        playCard(&engine, sides: [.a, .a, .b])
        engine.next(using: &generator)
        XCTAssertFalse(engine.scores.canUndo)
    }

    func testUndoingARevealGivesBackPointsAndSurvivors() {
        let ids = players(3)
        var (engine, _) = makeEngine(mode: .survival, players: ids)

        engine.vote(.a, by: ids[0])
        engine.vote(.a, by: ids[1])
        engine.vote(.b, by: ids[2])
        engine.reveal()

        XCTAssertEqual(engine.eliminated, [ids[2]])
        XCTAssertEqual(engine.scores.score(for: ids[0]), 1)
        XCTAssertEqual(engine.cardsPlayed, 1)

        XCTAssertTrue(engine.undoReveal())
        XCTAssertEqual(engine.phase, .dilemma)
        XCTAssertEqual(engine.survivors, ids, "Le revenant reprend sa place dans l'ordre du roster")
        XCTAssertTrue(engine.eliminated.isEmpty)
        XCTAssertEqual(engine.scores.score(for: ids[0]), 0)
        XCTAssertEqual(engine.cardsPlayed, 0)
        XCTAssertEqual(engine.votes.count, 3, "Les votes déjà saisis restent : on corrige, on ne recommence pas")
    }

    func testUndoIsRefusedOutsideTheSplit() {
        var (engine, _) = makeEngine(mode: .debate)
        XCTAssertFalse(engine.undoReveal())
    }

    // MARK: - Mode survie

    func testSurvivalDropsTheMinorityAndKeepsTheRosterOrder() {
        let ids = players(5)
        var (engine, _) = makeEngine(mode: .survival, players: ids)

        engine.vote(.b, by: ids[0])
        engine.vote(.a, by: ids[1])
        engine.vote(.a, by: ids[2])
        engine.vote(.a, by: ids[3])
        engine.vote(.b, by: ids[4])
        let outcome = engine.reveal()

        XCTAssertEqual(outcome?.eliminated, [ids[0], ids[4]])
        XCTAssertEqual(engine.survivors, [ids[1], ids[2], ids[3]])
        XCTAssertEqual(engine.eliminated, [ids[0], ids[4]])
        // Un éliminé n'est jamais retiré de la partie : la grille le montre encore.
        XCTAssertEqual(engine.players.count, 5)
    }

    /// Checklist §4 : « l'égalité en mode survie n'élimine personne ».
    func testAPerfectTieEliminatesNobodyInSurvival() {
        let ids = players(4)
        var (engine, generator) = makeEngine(mode: .survival, players: ids)

        engine.vote(.a, by: ids[0])
        engine.vote(.a, by: ids[1])
        engine.vote(.b, by: ids[2])
        engine.vote(.b, by: ids[3])
        let outcome = engine.reveal()

        XCTAssertTrue(outcome?.isTie == true)
        XCTAssertTrue(outcome?.eliminated.isEmpty == true, "Sinon la partie s'arrête sur un coup de dé")
        XCTAssertEqual(engine.survivors.count, 4)
        XCTAssertFalse(engine.isOver)

        engine.next(using: &generator)
        XCTAssertEqual(engine.phase, .dilemma, "On passe simplement à la carte suivante")
    }

    /// Unanimité : le côté minoritaire n'a aucun votant, personne ne saute.
    func testAUnanimousVoteEliminatesNobody() {
        let ids = players(4)
        var (engine, _) = makeEngine(mode: .survival, players: ids)

        for id in ids { engine.vote(.a, by: id) }
        let outcome = engine.reveal()

        XCTAssertFalse(outcome?.isTie == true)
        XCTAssertEqual(outcome?.tally.minority, .b)
        XCTAssertTrue(outcome?.eliminated.isEmpty == true)
        XCTAssertEqual(outcome?.scored.count, 4, "Tout le monde était avec la table")
    }

    /// Un éliminé ne vote plus, et la carte suivante ne l'attend pas.
    func testAnEliminatedPlayerStopsVoting() {
        let ids = players(3)
        var (engine, generator) = makeEngine(mode: .survival, players: ids)

        engine.vote(.a, by: ids[0])
        engine.vote(.a, by: ids[1])
        engine.vote(.b, by: ids[2])
        engine.reveal()
        engine.next(using: &generator)

        XCTAssertEqual(engine.voters, [ids[0], ids[1]])
        XCTAssertFalse(engine.vote(.a, by: ids[2]))
        XCTAssertEqual(engine.pendingVoters, [ids[0], ids[1]])
    }

    /// Spec §4.5 : le nombre de cartes est ignoré en mode survie.
    func testTheCardLimitIsIgnoredInSurvival() {
        let ids = players(4)
        var (engine, generator) = makeEngine(mode: .survival, limit: .cards(1), players: ids)

        for _ in 0..<6 {
            // Un seul joueur d'un côté : il saute tant qu'ils sont au moins
            // trois, et la partie continue quand même à deux.
            let voters = engine.voters
            engine.vote(.a, by: voters[0])
            for voter in voters.dropFirst() { engine.vote(.b, by: voter) }
            XCTAssertNotNil(engine.reveal())
            engine.next(using: &generator)
        }
        XCTAssertEqual(engine.survivors.count, 2, "Deux éliminations ont bien eu lieu en chemin")
        XCTAssertFalse(engine.isOver, "Seul le dernier debout arrête une partie de survie")
        XCTAssertEqual(engine.phase, .dilemma)
    }

    /// Spec §4.5 : « deux survivants et égalité, on passe la carte,
    /// indéfiniment s'il le faut ».
    func testTwoSurvivorsInPermanentTieKeepDrawingCards() {
        let ids = players(2)
        var (engine, generator) = makeEngine(mode: .survival, limit: .cards(1), players: ids)

        for _ in 0..<40 {
            engine.vote(.a, by: ids[0])
            engine.vote(.b, by: ids[1])
            let outcome = engine.reveal()
            XCTAssertTrue(outcome?.eliminated.isEmpty == true)
            XCTAssertEqual(engine.survivors.count, 2)
            XCTAssertFalse(engine.isOver)
            engine.next(using: &generator)
            XCTAssertEqual(engine.phase, .dilemma)
        }
    }

    /// À deux, **aucun vote ne peut plus éliminer** : 1-1 est une égalité, et
    /// 2-0 laisse le côté minoritaire vide. La spec annonce un « dernier
    /// debout » que sa propre règle ne peut pas produire ; le moteur expose
    /// l'impasse au lieu d'inventer un départage.
    func testTheFinalDuelCannotBeSettledByAVote() {
        let ids = players(2)
        var (engine, generator) = makeEngine(mode: .survival, players: ids)
        XCTAssertTrue(engine.isFinalDuel)

        // Les deux du même côté : la minorité est vide.
        engine.vote(.a, by: ids[0])
        engine.vote(.a, by: ids[1])
        XCTAssertTrue(engine.reveal()?.eliminated.isEmpty == true)
        XCTAssertEqual(engine.survivors.count, 2)
        engine.next(using: &generator)

        // Chacun de son côté : égalité parfaite.
        engine.vote(.a, by: ids[0])
        engine.vote(.b, by: ids[1])
        XCTAssertTrue(engine.reveal()?.eliminated.isEmpty == true)
        XCTAssertEqual(engine.survivors.count, 2)

        // La seule sortie est celle de la table.
        engine.finish()
        XCTAssertEqual(engine.phase, .finished)
        XCTAssertEqual(engine.champions, ids, "Les deux derniers sont ex æquo")
    }

    /// Quelqu'un part avant la fin (spec §2.2) : il sort des votants sans être
    /// éliminé, et la carte en cours peut se conclure sans lui.
    func testAPlayerWhoLeavesIsNotEliminated() {
        let ids = players(4)
        var (engine, _) = makeEngine(mode: .survival, players: ids)

        engine.withdraw(ids[3])
        XCTAssertEqual(engine.voters, [ids[0], ids[1], ids[2]])
        XCTAssertFalse(engine.eliminated.contains(ids[3]))
        XCTAssertEqual(engine.players.count, 4, "Il reste dans l'historique de la partie")

        engine.vote(.a, by: ids[0])
        engine.vote(.a, by: ids[1])
        engine.vote(.b, by: ids[2])
        XCTAssertTrue(engine.isReadyToReveal, "La carte ne doit pas attendre un joueur parti")

        let outcome = engine.reveal()
        XCTAssertEqual(outcome?.eliminated, [ids[2]])
    }

    func testTheLastOneStandingEndsTheGame() {
        let ids = players(3)
        var (engine, generator) = makeEngine(mode: .survival, players: ids)

        engine.vote(.a, by: ids[0])
        engine.vote(.a, by: ids[1])
        engine.vote(.b, by: ids[2])
        engine.reveal()
        engine.next(using: &generator)

        // Un départ ramène le duel à un seul joueur : la partie s'arrête là.
        engine.withdraw(ids[1])
        XCTAssertTrue(engine.isOver)
        XCTAssertEqual(engine.champions, [ids[0]])
    }

    // MARK: - Répartition

    func testAnEmptyTallyKeepsBothHalvesEven() {
        let tally = WouldYouRatherEngine.Tally(a: 0, b: 0)
        XCTAssertEqual(tally.share(.a), 0.5, accuracy: 0.0001)
        XCTAssertEqual(tally.share(.b), 0.5, accuracy: 0.0001)
        XCTAssertNil(tally.majority)
        XCTAssertNil(tally.minority)
    }

    func testSharesFollowTheCounts() {
        let tally = WouldYouRatherEngine.Tally(a: 3, b: 1)
        XCTAssertEqual(tally.share(.a), 0.75, accuracy: 0.0001)
        XCTAssertEqual(tally.share(.b), 0.25, accuracy: 0.0001)
        XCTAssertEqual(tally.count(.a), 3)
        XCTAssertEqual(tally.majority, .a)
        XCTAssertEqual(tally.minority, .b)
    }

    // MARK: - Réglages

    /// Spec §4.5 : 8 · 15 · 25 · sans fin, et rien d'autre. Un réglage proposé
    /// mais absent du défaut laisserait la partie démarrer sur une longueur que
    /// personne n'a choisie.
    func testTheOfferedLengthsAreTheOnesTheSpecLists() {
        XCTAssertEqual(WouldYouRatherLimit.choices, [.cards(8), .cards(15), .cards(25), .endless])
        XCTAssertEqual(WouldYouRatherLimit.choices.map(\.total), [8, 15, 25, nil])
        XCTAssertTrue(WouldYouRatherLimit.choices.contains(.standard), "Le défaut doit être un choix proposé")
    }

    /// Spec §4.5 : le débat se lance sans prénoms, les deux autres non — l'un
    /// fait circuler le téléphone, l'autre élimine, et ni l'un ni l'autre ne
    /// peut le faire sans savoir qui est à table.
    func testOnlyTheDebateModeRunsWithoutNames() {
        XCTAssertFalse(WouldYouRatherMode.debate.identifiesVoters)
        XCTAssertEqual(WouldYouRatherMode.debate.minimumPlayers, 0)

        for mode in [WouldYouRatherMode.secret, .survival] {
            XCTAssertTrue(mode.identifiesVoters, "\(mode) nomme ses votants")
            XCTAssertEqual(mode.minimumPlayers, 2)
        }
    }

    // MARK: - Le paquet

    /// Le paquet réel, pas un paquet de test : 200 tirages d'affilée sans
    /// qu'aucune carte ne ressorte avant 70 % du paquet (spec §2.4).
    func testTheRealDeckNeverRepeatsBeforeSeventyPercent() {
        let size = WouldYouRatherBank.all.count
        let minimumGap = (size * 7) / 10
        var generator = SeededGenerator(seed: 31)
        var deck = WouldYouRatherEngine.makeDeck(store: MemoryDeckStore())

        var lastSeen: [String: Int] = [:]
        for turn in 0..<200 {
            guard let draw = deck.draw(using: &generator) else { return XCTFail("Paquet vide") }
            if let previous = lastSeen[draw.item.id] {
                XCTAssertGreaterThanOrEqual(turn - previous, minimumGap, "\(draw.item.id) revient trop tôt")
            }
            lastSeen[draw.item.id] = turn
        }
    }

    // MARK: - Intégrité du contenu

    func testTheDeckHoldsTheBaseDilemmas() {
        XCTAssertEqual(WouldYouRatherBank.all.count, 7)
    }

    func testEveryIdentifierIsUniqueAndWellFormed() {
        var seen = Set<String>()
        for card in WouldYouRatherBank.all {
            XCTAssertTrue(seen.insert(card.id).inserted, "Identifiant en double : \(card.id)")
            XCTAssertEqual(card.id.count, 7, "Format attendu wyr_000 : \(card.id)")
            XCTAssertTrue(card.id.hasPrefix("wyr_"), "Format attendu wyr_000 : \(card.id)")
            XCTAssertNotNil(Int(card.id.dropFirst(4)), "Les trois derniers caractères sont un nombre : \(card.id)")
        }
    }

    /// Deux options identiques, ou une carte déjà écrite ailleurs, tuent le
    /// débat aussi sûrement qu'une option évidente.
    func testNoDilemmaIsADuplicate() {
        var seenOptions = Set<String>()
        var seenPairs = Set<String>()

        for card in WouldYouRatherBank.all {
            let left = normalized(card.a)
            let right = normalized(card.b)

            XCTAssertNotEqual(left, right, "\(card.id) propose deux fois la même chose")
            XCTAssertTrue(seenOptions.insert(left).inserted, "Option déjà écrite : \(card.a)")
            XCTAssertTrue(seenOptions.insert(right).inserted, "Option déjà écrite : \(card.b)")

            let pair = [left, right].sorted().joined(separator: "||")
            XCTAssertTrue(seenPairs.insert(pair).inserted, "Carte déjà écrite : \(card.id)")
        }
    }

    func testEveryOptionIsShortAndCleanlyWritten() {
        for card in WouldYouRatherBank.all {
            for text in [card.a, card.b] {
                XCTAssertFalse(text.isEmpty, "\(card.id) : option vide")
                XCTAssertLessThanOrEqual(text.count, 60, "\(card.id) trop long : \(text)")
                XCTAssertFalse(text.hasSuffix("."), "\(card.id) : pas de point final — \(text)")
                let first = text.first.map(String.init) ?? ""
                XCTAssertEqual(first, first.uppercased(), "\(card.id) commence sans majuscule : \(text)")
                XCTAssertEqual(text.trimmingCharacters(in: .whitespacesAndNewlines), text, "\(card.id) : espace parasite")
            }
        }
    }

    /// L'app est classée 4+ et tutoie tout le monde (spec §7.5 et §8). Un mot
    /// interdit glissé dans une carte ne se voit pas en relecture de PR : il se
    /// voit ici.
    func testNoCardBreaksTheFourPlusRating() {
        let forbidden: Set<String> = [
            "alcool", "biere", "vin", "champagne", "cocktail", "apero", "ivre",
            "cigarette", "clope", "tabac", "fumer", "drogue",
            "sexe", "sexuel", "sexy", "erotique",
            "tuer", "mort", "mourir", "meurtre", "sang", "arme", "fusil",
            "frapper", "gifle", "bagarre", "violence", "guerre",
            "vous", "votre", "vos"
        ]

        for card in WouldYouRatherBank.all {
            for text in [card.a, card.b] {
                for word in words(of: text) {
                    XCTAssertFalse(forbidden.contains(word), "\(card.id) contient « \(word) » : \(text)")
                }
            }
        }
    }

    // MARK: Outils de lecture du contenu

    /// `.lowercased()` explicite en plus du repli de casse : le repli seul
    /// dépend de la locale, et un test qui ne compare plus rien passe toujours.
    private func normalized(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
    }

    /// Découpe en mots pour comparer des mots entiers : « mer » ne doit pas
    /// déclencher sur « mercredi », ni « vin » sur « quatre-vingts ».
    private func words(of text: String) -> [String] {
        normalized(text)
            .split { !$0.isLetter }
            .map(String.init)
    }

    // MARK: - Pack Extrême (18+)

    /// L'Extrême s'ajoute au paquet de base, il ne le remplace pas.
    func testTheExtremePackStaysBehindTheAgeGate() {
        XCTAssertEqual(WouldYouRatherBank.all.count, 28)
        XCTAssertEqual(WouldYouRatherBank.extreme.count, 9)

        XCTAssertEqual(WouldYouRatherBank.dilemmas(adultUnlocked: false, extremeEnabled: true).count, 7,
                       "Sans confirmation d'âge, l'interrupteur seul ne suffit pas")
        XCTAssertEqual(WouldYouRatherBank.dilemmas(adultUnlocked: true, extremeEnabled: false).count, 7,
                       "L'âge confirmé n'active rien tant que la table n'a pas choisi")
        XCTAssertEqual(WouldYouRatherBank.dilemmas(adultUnlocked: true, extremeEnabled: true).count, 16)

        let ids = Set(WouldYouRatherBank.extreme.map(\.id))
        XCTAssertEqual(ids.count, 9, "Identifiants uniques")
        XCTAssertTrue(WouldYouRatherBank.extreme.allSatisfy { $0.a.count <= 60 && $0.b.count <= 60 })
    }

    /// Un identifiant n'est jamais réattribué : une carte retirée emporte son
    /// numéro, sinon la mémoire du paquet ferait ressortir aussitôt une carte
    /// vue hier soir sous un texte neuf. Ce test interdit la renumérotation.
    func testNoIdentifierIsEverReused() {
        let tous = WouldYouRatherBank.all + WouldYouRatherBank.extreme
        XCTAssertEqual(Set(tous.map(\.id)).count, tous.count, "Un numéro sert deux fois")

        for paquet in [WouldYouRatherBank.all, WouldYouRatherBank.extreme] {
            let numeros = paquet.compactMap { Int($0.id.dropFirst(4)) }
            XCTAssertEqual(numeros.count, paquet.count, "Identifiant illisible dans le paquet")
            XCTAssertEqual(numeros, numeros.sorted(), "Les cartes doivent rester en ordre de numéro")
        }
    }

    /// Les deux paquets se jouent ensemble : une option écrite dans l'Extrême
    /// ne doit pas déjà exister dans le paquet de base, sinon la même carte
    /// ressort deux fois dans la même soirée.
    func testTheTwoPacksNeverRepeatEachOther() {
        var vues = Set<String>()
        for card in WouldYouRatherBank.all + WouldYouRatherBank.extreme {
            for text in [card.a, card.b] {
                XCTAssertTrue(vues.insert(normalized(text)).inserted, "Option déjà écrite : \(text)")
            }
        }
    }
}
