import XCTest
@testable import Mytho

/// Mémoire volatile : les tests ne doivent rien laisser dans les réglages du
/// simulateur, et deux tests ne doivent pas hériter du paquet l'un de l'autre.
private final class VolatileDeckMemory: DeckMemoryStore {
    private var storage: [String: DeckMemorySnapshot] = [:]

    func memory(forDeck deckID: String) -> DeckMemorySnapshot { storage[deckID] ?? .empty }
    func save(_ memory: DeckMemorySnapshot, forDeck deckID: String) { storage[deckID] = memory }
    func clear(deckID: String) { storage[deckID] = nil }
    func clearAll() { storage.removeAll() }
}

private struct DeckTestCard: Identifiable, Hashable {
    let id: String
}

final class DeckTests: XCTestCase {

    private func cards(_ count: Int) -> [DeckTestCard] {
        (1...count).map { DeckTestCard(id: "c\($0)") }
    }

    private func makeDeck(_ count: Int, store: any DeckMemoryStore) -> Deck<DeckTestCard> {
        Deck(id: "test", items: cards(count), store: store)
    }

    // MARK: La règle des 70 %

    /// Le test exigé par la checklist du socle : 200 tirages d'affilée, et aucune
    /// carte ne doit ressortir avant que 70 % du paquet ait défilé.
    func testNoCardComesBackBeforeSeventyPercentOfTheDeck() {
        let size = 20
        let minimumGap = (size * 7) / 10
        var generator = SeededGenerator(seed: 42)
        var deck = makeDeck(size, store: VolatileDeckMemory())

        var lastSeen: [String: Int] = [:]
        for turn in 0..<200 {
            guard let draw = deck.draw(using: &generator) else { return XCTFail("Paquet vide") }
            if let previous = lastSeen[draw.item.id] {
                XCTAssertGreaterThanOrEqual(
                    turn - previous, minimumGap,
                    "\(draw.item.id) ressort après \(turn - previous) tirages sur un paquet de \(size)"
                )
            }
            lastSeen[draw.item.id] = turn
        }
        XCTAssertEqual(lastSeen.count, size, "Toutes les cartes doivent avoir servi en 200 tirages")
    }

    /// Même garantie sur un petit paquet, celui où la règle est la plus dure à
    /// tenir : les gages d'Action ou vérité ne sont qu'une trentaine.
    func testTheRuleHoldsOnASmallDeck() {
        let size = 8
        let minimumGap = (size * 7) / 10
        var generator = SeededGenerator(seed: 77)
        var deck = makeDeck(size, store: VolatileDeckMemory())

        var lastSeen: [String: Int] = [:]
        for turn in 0..<200 {
            guard let draw = deck.draw(using: &generator) else { return XCTFail("Paquet vide") }
            if let previous = lastSeen[draw.item.id] {
                XCTAssertGreaterThanOrEqual(turn - previous, minimumGap)
            }
            lastSeen[draw.item.id] = turn
        }
    }

    // MARK: Tour de paquet

    func testAFullLapIsAnnouncedOnceThenTheDeckReshuffles() {
        let size = 12
        var generator = SeededGenerator(seed: 3)
        var deck = makeDeck(size, store: VolatileDeckMemory())

        var lap: [String] = []
        for _ in 0..<size {
            guard let draw = deck.draw(using: &generator) else { return XCTFail("Paquet vide") }
            XCTAssertFalse(draw.startsNewLap, "Le tour n'est pas fini, il n'y a rien à annoncer")
            lap.append(draw.item.id)
        }
        // Un paquet, pas un tirage au sort : chaque carte sort une fois par tour.
        XCTAssertEqual(Set(lap).count, size)
        XCTAssertEqual(deck.remainingCount, 0)

        guard let opening = deck.draw(using: &generator) else { return XCTFail("Paquet vide") }
        XCTAssertTrue(opening.startsNewLap, "« Tu as fait le tour du paquet » s'affiche ici")
        XCTAssertEqual(deck.remainingCount, size - 1)

        for _ in 0..<(size - 1) {
            guard let draw = deck.draw(using: &generator) else { return XCTFail("Paquet vide") }
            XCTAssertFalse(draw.startsNewLap, "Le message ne s'affiche qu'une fois par tour")
        }
    }

    func testTheFirstCardOfANewLapIsNotTheLastOneSeen() {
        let size = 10
        var generator = SeededGenerator(seed: 21)
        var deck = makeDeck(size, store: VolatileDeckMemory())

        var lap: [String] = []
        for _ in 0..<size {
            guard let draw = deck.draw(using: &generator) else { return XCTFail("Paquet vide") }
            lap.append(draw.item.id)
        }
        guard let opening = deck.draw(using: &generator) else { return XCTFail("Paquet vide") }
        // Le remélange ne suffit pas : sans report, la dernière carte du tour
        // précédent pourrait ouvrir le suivant.
        XCTAssertFalse(lap.suffix(deck.cooldown).contains(opening.item.id))
    }

    // MARK: Persistance

    func testMemorySurvivesANewInstance() {
        let store = VolatileDeckMemory()
        var generator = SeededGenerator(seed: 7)
        var first = makeDeck(20, store: store)

        var seen: [String] = []
        for _ in 0..<5 {
            guard let draw = first.draw(using: &generator) else { return XCTFail("Paquet vide") }
            seen.append(draw.item.id)
        }
        XCTAssertEqual(first.remainingCount, 15)

        // Nouvelle instance, même paquet : la soirée reprend où elle s'est arrêtée.
        var second = makeDeck(20, store: store)
        XCTAssertEqual(second.remainingCount, 15)
        for _ in 0..<5 {
            guard let draw = second.draw(using: &generator) else { return XCTFail("Paquet vide") }
            XCTAssertFalse(seen.contains(draw.item.id), "\(draw.item.id) avait déjà été vue avant la fermeture")
        }
    }

    func testMemorySurvivesInUserDefaults() throws {
        let suite = "mytho.tests.deck.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        var generator = SeededGenerator(seed: 11)
        var deck = Deck(id: "packA", items: cards(20), store: UserDefaultsDeckMemory(defaults: defaults))
        let first = deck.draw(using: &generator)
        XCTAssertNotNil(first)

        let reopened = Deck(id: "packA", items: cards(20), store: UserDefaultsDeckMemory(defaults: defaults))
        XCTAssertEqual(reopened.remainingCount, 19)

        // Un autre paquet du même jeu garde sa propre mémoire.
        let other = Deck(id: "packB", items: cards(20), store: UserDefaultsDeckMemory(defaults: defaults))
        XCTAssertEqual(other.remainingCount, 20)

        // « Réinitialiser les paquets » dans les réglages.
        UserDefaultsDeckMemory(defaults: defaults).clearAll()
        let purged = Deck(id: "packA", items: cards(20), store: UserDefaultsDeckMemory(defaults: defaults))
        XCTAssertEqual(purged.remainingCount, 20)
    }

    func testResetEmptiesTheMemory() {
        let store = VolatileDeckMemory()
        var generator = SeededGenerator(seed: 5)
        var deck = makeDeck(10, store: store)
        for _ in 0..<4 { _ = deck.draw(using: &generator) }
        XCTAssertEqual(deck.remainingCount, 6)

        deck.reset()
        XCTAssertEqual(deck.remainingCount, 10)
        XCTAssertEqual(makeDeck(10, store: store).remainingCount, 10, "La purge doit aussi vider le stockage")
    }

    // MARK: Déterminisme

    func testSameSeedDrawsTheSameCards() {
        var left = SeededGenerator(seed: 99)
        var right = SeededGenerator(seed: 99)
        var first = makeDeck(30, store: VolatileDeckMemory())
        var second = makeDeck(30, store: VolatileDeckMemory())

        for _ in 0..<60 {
            let a = first.draw(using: &left)
            let b = second.draw(using: &right)
            XCTAssertEqual(a?.item.id, b?.item.id)
            XCTAssertEqual(a?.startsNewLap, b?.startsNewLap)
        }
    }

    // MARK: Cas limites

    func testEmptyDeckDrawsNothing() {
        var generator = SeededGenerator(seed: 1)
        var deck = Deck<DeckTestCard>(id: "vide", items: [], store: VolatileDeckMemory())
        XCTAssertNil(deck.draw(using: &generator))
    }

    func testSingleCardDeckKeepsDrawingIt() {
        var generator = SeededGenerator(seed: 2)
        var deck = makeDeck(1, store: VolatileDeckMemory())
        for _ in 0..<5 {
            XCTAssertEqual(deck.draw(using: &generator)?.item.id, "c1")
        }
    }

    /// Une carte sans identité propre — comme `WordPair` — se pioche en donnant
    /// la clé à l'init : c'est ce qui rend le paquet générique.
    func testACustomIdentifierWorksForItemsWithoutIdentity() {
        var generator = SeededGenerator(seed: 8)
        let pairs = [WordPair(a: "Chat", b: "Chien"), WordPair(a: "Soleil", b: "Lune")]
        var deck = Deck(
            id: "mots",
            items: pairs,
            identify: { "\($0.a)|\($0.b)" },
            store: VolatileDeckMemory()
        )
        let first = deck.draw(using: &generator)?.item
        let second = deck.draw(using: &generator)?.item
        XCTAssertNotNil(first)
        XCTAssertNotEqual(first, second)
    }
}
