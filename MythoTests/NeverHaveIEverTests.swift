import XCTest
@testable import Mytho

/// Mémoire volatile : un test ne doit rien laisser dans les réglages du
/// simulateur, et deux tests ne doivent pas hériter du paquet l'un de l'autre.
private final class NeverDeckMemory: DeckMemoryStore {
    private var storage: [String: DeckMemorySnapshot] = [:]

    func memory(forDeck deckID: String) -> DeckMemorySnapshot { storage[deckID] ?? .empty }
    func save(_ memory: DeckMemorySnapshot, forDeck deckID: String) { storage[deckID] = memory }
    func clear(deckID: String) { storage[deckID] = nil }
    func clearAll() { storage.removeAll() }
}

final class NeverHaveIEverTests: XCTestCase {

    // MARK: Outils

    private func makeIDs(_ count: Int) -> [UUID] { (0..<count).map { _ in UUID() } }

    private func makeCards(_ count: Int) -> [ConfessionCard] {
        (1...count).map { ConfessionCard(id: "t\($0)", text: "carte \($0)") }
    }

    private func makeEngine(
        ids: [UUID],
        rules: NeverHaveIEverEngine.Rules = .init(),
        cards: Int = 40,
        seed: UInt64 = 4
    ) -> NeverHaveIEverEngine {
        var engine = NeverHaveIEverEngine(
            playerIDs: ids,
            rules: rules,
            deck: Deck(id: "test.nhie", items: makeCards(cards), store: NeverDeckMemory())
        )
        var generator = SeededGenerator(seed: seed)
        engine.start(using: &generator)
        return engine
    }

    /// Une carte jouée à l'honneur : on désigne, on valide.
    private func playCard(_ engine: inout NeverHaveIEverEngine, confessing: [UUID]) {
        engine.beginConfessions()
        for id in confessing { engine.toggle(id) }
        engine.validate()
    }

    // MARK: Vies

    func testTheGameOpensOnACard() {
        let ids = makeIDs(4)
        let engine = makeEngine(ids: ids)

        XCTAssertEqual(engine.phase, .card)
        XCTAssertNotNil(engine.card)
        XCTAssertEqual(engine.cardNumber, 1)
        XCTAssertEqual(engine.survivorCount, 4)
        XCTAssertTrue(engine.players.allSatisfy { $0.lives == NeverHaveIEverEngine.defaultLives })
    }

    func testAConfessionCostsExactlyOneLife() {
        let ids = makeIDs(4)
        var engine = makeEngine(ids: ids)
        playCard(&engine, confessing: [ids[0], ids[2]])

        XCTAssertEqual(engine.player(ids[0])?.lives, 4)
        XCTAssertEqual(engine.player(ids[2])?.lives, 4)
        XCTAssertEqual(engine.player(ids[1])?.lives, 5, "Personne ne perd de vie sans avoir été désigné")
        XCTAssertEqual(engine.player(ids[0])?.confessions, 1)
        XCTAssertEqual(engine.phase, .aftermath)
    }

    /// Le mauvais tap se rattrape sur place : un second tap retire le prénom.
    func testTappingTwiceCancelsTheDesignation() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids)
        engine.beginConfessions()

        engine.toggle(ids[0])
        XCTAssertTrue(engine.isSelected(ids[0]))
        XCTAssertEqual(engine.confessionCount, 1)

        engine.toggle(ids[0])
        XCTAssertFalse(engine.isSelected(ids[0]))
        XCTAssertEqual(engine.confessionCount, 0)

        engine.validate()
        XCTAssertEqual(engine.player(ids[0])?.lives, 5)
    }

    func testDesignationIsIgnoredOutsideTheTallyPhase() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids)

        // Encore sur la carte : personne n'a commencé à désigner.
        engine.toggle(ids[0])
        XCTAssertEqual(engine.confessionCount, 0)
        XCTAssertFalse(engine.isSelected(ids[0]))
    }

    func testValidatingOutsideAConfessionPhaseDoesNothing() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids)

        engine.validate()
        XCTAssertEqual(engine.phase, .card, "Valider depuis la carte n'a aucun sens")
        XCTAssertTrue(engine.players.allSatisfy { $0.lives == 5 })
    }

    // MARK: Éliminations

    func testAPlayerOutOfLivesIsEliminatedOnThatVeryCard() {
        let ids = makeIDs(4)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1))
        playCard(&engine, confessing: [ids[0]])

        XCTAssertEqual(engine.lastEliminated, [ids[0]])
        XCTAssertEqual(engine.player(ids[0])?.eliminatedOnCard, 1)
        XCTAssertEqual(engine.survivorCount, 3)
        XCTAssertFalse(engine.isGameOver)
    }

    /// Un joueur éliminé continue de voir les cartes : il n'est **jamais**
    /// retiré de la liste (spec §5.6). Il n'est simplement plus désignable.
    func testAnEliminatedPlayerStaysInTheGameAndCannotBeDesignated() {
        let ids = makeIDs(4)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1))
        playCard(&engine, confessing: [ids[0]])
        engine.nextCard()

        XCTAssertEqual(engine.players.count, 4)
        XCTAssertNotNil(engine.player(ids[0]))

        engine.beginConfessions()
        engine.toggle(ids[0])
        XCTAssertFalse(engine.isSelected(ids[0]))
        XCTAssertEqual(engine.confessionCount, 0)

        engine.validate()
        XCTAssertEqual(engine.player(ids[0])?.lives, 0, "Il ne peut pas descendre en dessous de zéro")
        XCTAssertEqual(engine.player(ids[0])?.eliminatedOnCard, 1, "Il reste éliminé sur sa carte d'origine")
    }

    func testLivesDropOneCardAtATimeUntilElimination() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 3))

        for expected in [2, 1, 0] {
            playCard(&engine, confessing: [ids[0]])
            XCTAssertEqual(engine.player(ids[0])?.lives, expected)
            if expected > 0 {
                XCTAssertTrue(engine.lastEliminated.isEmpty)
                engine.nextCard()
            }
        }
        XCTAssertEqual(engine.lastEliminated, [ids[0]])
        XCTAssertEqual(engine.player(ids[0])?.eliminatedOnCard, 3)
    }

    // MARK: Fin de partie

    func testTheLastStandingWins() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1))
        playCard(&engine, confessing: [ids[0], ids[1]])

        XCTAssertTrue(engine.isGameOver)
        XCTAssertEqual(engine.winners, [ids[2]])
        XCTAssertEqual(engine.phase, .aftermath, "L'élimination a droit à sa seconde à l'écran")

        engine.nextCard()
        XCTAssertEqual(engine.phase, .finished)
        XCTAssertTrue(engine.isFinished)
    }

    /// Le cas limite de la checklist §5 : tous les survivants tombent à zéro sur
    /// la même carte. Personne ne survit, donc tout le monde gagne.
    func testEveryoneFallingOnTheSameCardWinsExAequo() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1))
        playCard(&engine, confessing: ids)

        XCTAssertEqual(engine.survivorCount, 0)
        XCTAssertTrue(engine.isGameOver)
        XCTAssertEqual(Set(engine.winners), Set(ids))
        XCTAssertEqual(engine.lastEliminated.count, 3)
    }

    /// Même règle quand la table est déjà entamée : seuls ceux qui tombent sur
    /// la **dernière** carte sont vainqueurs, pas les sortis d'avant.
    func testOnlyThoseFallingOnTheFinalCardShareTheWin() {
        let ids = makeIDs(4)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1))

        playCard(&engine, confessing: [ids[0]])
        engine.nextCard()
        playCard(&engine, confessing: [ids[1], ids[2], ids[3]])

        XCTAssertTrue(engine.isGameOver)
        XCTAssertEqual(Set(engine.winners), Set([ids[1], ids[2], ids[3]]))
        XCTAssertFalse(engine.winners.contains(ids[0]))
    }

    func testRankingPutsSurvivorsFirstThenTheLatestEliminations() {
        let ids = makeIDs(4)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1))

        playCard(&engine, confessing: [ids[0]])
        engine.nextCard()
        playCard(&engine, confessing: [ids[1]])

        XCTAssertEqual(
            engine.ranking.map(\.id),
            [ids[2], ids[3], ids[1], ids[0]],
            "Les deux survivants dans l'ordre du roster, puis le dernier sorti, puis le premier"
        )
    }

    // MARK: Mode sans élimination

    func testWithoutEliminationConfessionsAreCountedAndNobodyLeaves() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(eliminates: false, cardLimit: 2))

        playCard(&engine, confessing: [ids[0], ids[1]])
        XCTAssertEqual(engine.player(ids[0])?.lives, NeverHaveIEverEngine.defaultLives, "Aucune vie ne se perd")
        XCTAssertEqual(engine.player(ids[0])?.confessions, 1)
        XCTAssertTrue(engine.lastEliminated.isEmpty)
        XCTAssertEqual(engine.survivorCount, 3)
        XCTAssertFalse(engine.isGameOver)

        engine.nextCard()
        playCard(&engine, confessing: [ids[0]])

        XCTAssertTrue(engine.isGameOver, "Deux cartes demandées, deux cartes jouées")
        XCTAssertEqual(engine.winners, [ids[0]], "Le plus gros total d'aveux gagne")
        XCTAssertEqual(engine.ranking.map(\.id), [ids[0], ids[1], ids[2]])
    }

    func testWithoutEliminationTiesShareTheWin() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(eliminates: false, cardLimit: 1))
        playCard(&engine, confessing: [ids[0], ids[2]])

        XCTAssertEqual(Set(engine.winners), Set([ids[0], ids[2]]))
    }

    func testAnEndlessGameOnlyStopsWhenTheTableSaysSo() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(eliminates: false, cardLimit: nil))

        // Sans cette sortie, l'écran n'aurait aucun bouton menant au classement.
        XCTAssertTrue(engine.isEndless)

        for _ in 0..<12 {
            playCard(&engine, confessing: [ids[0]])
            XCTAssertFalse(engine.isGameOver)
            engine.nextCard()
        }

        engine.finishNow()
        XCTAssertEqual(engine.phase, .finished)
        XCTAssertEqual(engine.winners, [ids[0]], "Le plus gros total d'aveux gagne")
    }

    /// L'inverse : dès qu'une condition de fin existe, l'écran ne doit pas
    /// proposer d'arrêter la partie à la main.
    func testAGameWithAnEndIsNeverEndless() {
        let ids = makeIDs(3)
        XCTAssertFalse(makeEngine(ids: ids).isEndless, "Les éliminations closent la partie")
        XCTAssertFalse(
            makeEngine(ids: ids, rules: .init(eliminates: false, cardLimit: 15)).isEndless,
            "La limite de cartes close la partie"
        )
    }

    // MARK: Aveu secret

    /// Le point dur de la checklist §5 : aucune identité ne sort avant que le
    /// groupe n'appuie sur « Révéler ».
    func testSecretConfessionNeverExposesIdentitiesBeforeReveal() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(mode: .secret))

        engine.beginConfessions()
        XCTAssertEqual(engine.phase, .secretPass(0))

        for (index, id) in ids.enumerated() {
            XCTAssertEqual(engine.currentVoterID, id)
            XCTAssertEqual(engine.currentVoterPosition, index + 1)

            engine.openSecretVote()
            XCTAssertEqual(engine.phase, .secretVote(index))

            // Les deux premiers avouent, le dernier non.
            engine.answerSecret(index < 2)
            XCTAssertTrue(engine.confessors.isEmpty, "Aucun prénom ne sort pendant la tournée")
        }

        XCTAssertEqual(engine.phase, .secretCount)
        XCTAssertEqual(engine.confessionCount, 2, "Le compte, lui, s'affiche en grand")
        XCTAssertEqual(engine.voterCount, 3)
        XCTAssertTrue(engine.confessors.isEmpty)
        XCTAssertFalse(engine.isSecretRevealed)

        engine.reveal()
        XCTAssertTrue(engine.isSecretRevealed)
        XCTAssertEqual(engine.confessors, [ids[0], ids[1]])
        XCTAssertEqual(engine.phase, .secretReveal)
    }

    func testKeepingTheDoubtStillCostsLivesButNamesNobody() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(mode: .secret))

        engine.beginConfessions()
        for index in ids.indices {
            engine.openSecretVote()
            engine.answerSecret(index == 0)
        }
        engine.validate()

        XCTAssertEqual(engine.phase, .aftermath)
        XCTAssertEqual(engine.player(ids[0])?.lives, 4, "La vie part quand même")
        XCTAssertEqual(engine.player(ids[1])?.lives, 5)
        XCTAssertTrue(engine.lastConfessors.isEmpty, "La grille ne doit pas trahir ce que le compte a tu")
        XCTAssertTrue(engine.confessors.isEmpty)
    }

    /// Une élimination ne se cache pas : un joueur sans vie est sorti, le groupe
    /// doit le savoir même s'il a choisi de laisser le doute.
    func testAnEliminationIsAnnouncedEvenWhenTheDoubtIsKept() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1, mode: .secret))

        engine.beginConfessions()
        for index in ids.indices {
            engine.openSecretVote()
            engine.answerSecret(index == 0)
        }
        engine.validate()

        XCTAssertEqual(engine.lastEliminated, [ids[0]])
        XCTAssertTrue(engine.lastConfessors.isEmpty)
    }

    func testRevealedConfessionsAreNamedOnTheGridAfterValidation() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(mode: .secret))

        engine.beginConfessions()
        for index in ids.indices {
            engine.openSecretVote()
            engine.answerSecret(index == 0)
        }
        engine.reveal()
        engine.validate()

        XCTAssertEqual(engine.lastConfessors, [ids[0]])
    }

    func testAnEliminatedPlayerIsNotPartOfTheSecretRotation() {
        let ids = makeIDs(4)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1, mode: .secret))

        engine.beginConfessions()
        for index in ids.indices {
            engine.openSecretVote()
            engine.answerSecret(index == 0)
        }
        engine.validate()
        engine.nextCard()

        engine.beginConfessions()
        XCTAssertEqual(engine.voterCount, 3, "L'éliminé ne reçoit plus le téléphone")
        XCTAssertEqual(engine.currentVoterID, ids[1])
    }

    func testTheSecretIsResetBetweenTwoCards() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(mode: .secret))

        engine.beginConfessions()
        for index in ids.indices {
            engine.openSecretVote()
            engine.answerSecret(index == 0)
        }
        engine.reveal()
        engine.validate()
        engine.nextCard()

        XCTAssertFalse(engine.isSecretRevealed, "La carte suivante repart secrète")
        XCTAssertEqual(engine.confessionCount, 0)
        XCTAssertTrue(engine.confessors.isEmpty)
    }

    // MARK: Annulation

    func testUndoGivesBackLivesAndCancelsEliminations() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids, rules: .init(startingLives: 1))
        playCard(&engine, confessing: [ids[0]])

        XCTAssertTrue(engine.canUndo)
        XCTAssertTrue(engine.undo())

        XCTAssertEqual(engine.player(ids[0])?.lives, 1)
        XCTAssertNil(engine.player(ids[0])?.eliminatedOnCard)
        XCTAssertEqual(engine.survivorCount, 3)
        XCTAssertEqual(engine.phase, .tally, "On revient sur la désignation, pas sur la carte")
        XCTAssertTrue(engine.isSelected(ids[0]), "La sélection est rendue telle quelle, à corriger")
        XCTAssertFalse(engine.canUndo)
    }

    func testACorrectedTallyCanBeValidatedAgain() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids)
        playCard(&engine, confessing: [ids[0]])
        engine.undo()

        engine.toggle(ids[0])
        engine.toggle(ids[1])
        engine.validate()

        XCTAssertEqual(engine.player(ids[0])?.lives, 5)
        XCTAssertEqual(engine.player(ids[1])?.lives, 4)
    }

    func testUndoIsUnavailableOutsideTheAftermath() {
        let ids = makeIDs(3)
        var engine = makeEngine(ids: ids)

        XCTAssertFalse(engine.canUndo)
        XCTAssertFalse(engine.undo())

        engine.beginConfessions()
        XCTAssertFalse(engine.canUndo)
    }

    // MARK: Pioche

    /// Exigence §9 : 200 manches sans qu'aucune carte ne ressorte avant que
    /// 70 % du paquet ait défilé.
    func testTwoHundredCardsWithoutAnEarlyRepeat() {
        let size = 20
        let ids = makeIDs(3)
        var generator = SeededGenerator(seed: 17)
        var engine = makeEngine(
            ids: ids,
            rules: .init(eliminates: false, cardLimit: nil),
            cards: size
        )

        var lastSeen: [String: Int] = [:]
        for turn in 0..<200 {
            guard let card = engine.card else { return XCTFail("Le moteur doit toujours avoir une carte") }
            if let previous = lastSeen[card.id] {
                XCTAssertGreaterThanOrEqual(
                    turn - previous, (size * 7) / 10,
                    "\(card.id) ressort après \(turn - previous) cartes"
                )
            }
            lastSeen[card.id] = turn

            engine.beginConfessions()
            engine.validate()
            engine.nextCard(using: &generator)
        }
        XCTAssertEqual(lastSeen.count, size, "Toutes les cartes doivent avoir servi")
    }

    func testAnEmptyDeckClosesTheGameRatherThanLooping() {
        var engine = NeverHaveIEverEngine(
            playerIDs: makeIDs(3),
            deck: Deck<ConfessionCard>(id: "vide", items: [], store: NeverDeckMemory())
        )
        engine.start()

        XCTAssertNil(engine.card)
        XCTAssertEqual(engine.phase, .finished)
    }

    // MARK: Réglages

    func testRulesRefuseAZeroLifeGame() {
        XCTAssertEqual(NeverHaveIEverEngine.Rules(startingLives: 0).startingLives, 1)
        XCTAssertEqual(NeverHaveIEverEngine.defaultLives, 5)
        XCTAssertEqual(NeverHaveIEverEngine.livesChoices, [3, 5, 7])
        XCTAssertEqual(NeverHaveIEverEngine.minPlayers, 3)
        XCTAssertEqual(NeverHaveIEverEngine.Rules().mode, .honour)
        XCTAssertTrue(NeverHaveIEverEngine.Rules().eliminates)
    }

    // MARK: Contenu

    func testTheAnnouncedVolumeIsThere() {
        XCTAssertEqual(NeverHaveIEverBank.pack(id: "soft")?.cards.count, 20)
        XCTAssertEqual(NeverHaveIEverBank.pack(id: "potes")?.cards.count, 20)
        XCTAssertEqual(NeverHaveIEverBank.allCards.count, 75)
    }

    /// Le pack épicé est 18+ : verrouillé tant que l'âge n'est pas confirmé,
    /// jouable ensuite. 35 cartes depuis l'écrémage du 17 août.
    func testTheSpicyPackIsLockedButFull() {
        let epice = NeverHaveIEverBank.pack(id: "epice")
        XCTAssertEqual(epice?.isLocked, true)
        XCTAssertEqual(epice?.cards.count, 35)

        XCTAssertFalse(NeverHaveIEverBank.selectablePacks(adultUnlocked: false).contains { $0.id == "epice" })
        XCTAssertTrue(
            NeverHaveIEverBank.selectablePacks(adultUnlocked: true).contains { $0.id == "epice" },
            "Une fois l'âge confirmé, le pack doit apparaître"
        )
    }

    func testPackSelectionFallsBackRatherThanShippingAnEmptyDeck() {
        XCTAssertEqual(NeverHaveIEverBank.cards(in: ["soft"], adultUnlocked: false).count, 20)
        XCTAssertEqual(NeverHaveIEverBank.cards(in: ["soft", "potes"], adultUnlocked: false).count, 40)
        XCTAssertEqual(NeverHaveIEverBank.cards(in: ["soft", "potes", "epice"], adultUnlocked: false).count, 40, "Le verrou retire les cartes 18+ même si le réglage sauvegardé les liste")
        XCTAssertEqual(NeverHaveIEverBank.cards(in: ["soft", "potes", "epice"], adultUnlocked: true).count, 75)
        XCTAssertEqual(
            NeverHaveIEverBank.cards(in: [], adultUnlocked: false).count, 40,
            "Une sélection vide retombe sur les paquets par défaut"
        )
        XCTAssertEqual(
            NeverHaveIEverBank.cards(in: ["epice"], adultUnlocked: true).count, 35,
            "Le pack 18+ seul est une sélection valable une fois l'âge confirmé"
        )
        XCTAssertEqual(
            NeverHaveIEverBank.cards(in: ["disparu"], adultUnlocked: false).count, 40,
            "Une sélection qui ne pointe plus sur rien retombe sur les paquets par défaut"
        )
    }

    func testEveryCardIsUniqueAndWellFormed() {
        let cards = NeverHaveIEverBank.allCards

        XCTAssertEqual(Set(cards.map(\.id)).count, cards.count, "Deux cartes portent le même identifiant")
        XCTAssertEqual(Set(cards.map(\.text)).count, cards.count, "Deux cartes portent le même texte")

        for card in cards {
            guard let first = card.text.first else {
                XCTFail("\(card.id) est vide")
                continue
            }
            // La donnée est un participe passé qui se lit après « Je n'ai
            // jamais… » : ni majuscule, ni point final (spec §5.5).
            XCTAssertFalse(first.isUppercase, "\(card.id) commence par une majuscule")
            XCTAssertFalse(card.text.hasSuffix("."), "\(card.id) finit par un point")
            XCTAssertEqual(
                card.text.trimmingCharacters(in: .whitespacesAndNewlines), card.text,
                "\(card.id) traîne une espace"
            )
        }
    }

    /// L'app est classée **4+** et a été soumise en déclarant aucune référence à
    /// l'alcool, au tabac, aux drogues ni au sexe. Un pack ajouté plus tard ne
    /// doit pas pouvoir invalider cette classification en silence.
    /// Les packs publics restent jouables sans la porte d'âge : pas d'alcool,
    /// pas de drogue, pas de sexe. Le registre « hontes vécues » (embrasser la
    /// mauvaise personne, un crush dans le groupe) y est, lui, assumé depuis
    /// l'écrémage du 17 août — l'app est classée 17+.
    func testNoCardBreaksTheFourPlusRating() {
        let banned: Set<String> = [
            "alcool", "alcoolisé", "alcoolisée", "bière", "bières", "vin", "vins",
            "vodka", "whisky", "rhum", "champagne", "cocktail", "apéro", "apéritif",
            "ivre", "ivresse", "bourré", "bourrée", "cuite", "trinqué", "trinquer",
            "cigarette", "cigarettes", "clope", "clopes", "fumé", "fumée", "fumer",
            "tabac", "joint", "drogue", "drogué", "droguée",
            "sexe", "sexuel", "sexuelle", "nu", "nue", "nus", "nues", "seins",
            "préservatif", "baiser", "couché", "coucher",
            "porno", "casino", "pari", "parié", "parier", "arme", "armes"
        ]

        // Seuls les packs accessibles SANS confirmation d'âge portent la
        // promesse tout public : le pack Épicé vit derrière le verrou 17+ et
        // a son propre test.
        let publicCards = NeverHaveIEverBank.cards(in: ["soft", "potes"], adultUnlocked: false)
        for card in publicCards {
            let words = card.text
                .lowercased()
                .components(separatedBy: CharacterSet.letters.inverted)
                .filter { !$0.isEmpty }

            for word in words {
                XCTAssertFalse(banned.contains(word), "\(card.id) contient « \(word) » : « \(card.text) »")
            }
        }
    }

    /// Le pack 18+ a ses propres lignes rouges — plus courtes, mais absolues :
    /// rien de graphiquement explicite, rien sans consentement, aucun mineur,
    /// aucune marque. Le cru et l'alcool y sont, eux, assumés.
    func testTheAdultPackKeepsItsOwnRedLines() {
        let banned: Set<String> = [
            "viol", "violée", "violer", "mineur", "mineure", "mineurs", "inceste",
            "cocaïne", "héroïne", "crack", "seringue",
            "tiktok", "instagram", "netflix", "tinder", "snapchat", "uber"
        ]
        let adult = NeverHaveIEverBank.pack(id: "epice")?.cards ?? []
        XCTAssertEqual(adult.count, 35)
        for card in adult {
            let words = card.text
                .lowercased()
                .components(separatedBy: CharacterSet.letters.inverted)
                .filter { !$0.isEmpty }
            for word in words {
                XCTAssertFalse(banned.contains(word), "\(card.id) contient « \(word) »")
            }
        }
    }
}
