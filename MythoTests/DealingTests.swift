import XCTest
@testable import Mytho

/// La distribution est le seul moment où le joueur peut revenir en arrière.
/// Ces tests couvrent le blocage constaté à l'audit : un « Retour » laissait
/// le joueur repiocher, vidait le paquet, et la manche ne démarrait jamais.
final class DealingTests: XCTestCase {

    private func makeEngine(players: Int = 5, seed: UInt64 = 11) -> GameEngine {
        var generator = SeededGenerator(seed: seed)
        let config = GameConfig(
            playerNames: (1...players).map { "J\($0)" },
            undercoverCount: 1,
            mrWhiteCount: 1
        )
        return GameEngine(config: config, pair: WordPair(a: "Chat", b: "Chien"), using: &generator)
    }

    func testAPlayerCannotDrawTwice() {
        var engine = makeEngine()

        XCTAssertNotNil(engine.pickCard(at: 0), "La première pioche doit passer")
        XCTAssertNil(engine.pickCard(at: 1), "Le même joueur ne repioche pas")

        XCTAssertEqual(engine.deck.compactMap { $0 }.count, engine.players.count - 1,
                       "Une seule carte doit avoir quitté le paquet")
        XCTAssertEqual(engine.players[0].pickedCardIndex, 0)
    }

    func testDeckAlwaysHasACardLeftForTheLastPlayer() {
        var engine = makeEngine()
        var generator = SeededGenerator(seed: 3)

        for expected in 0..<engine.players.count {
            guard case .dealing(let index) = engine.phase else {
                return XCTFail("Distribution interrompue au joueur \(expected)")
            }
            XCTAssertEqual(index, expected)

            let free = engine.deck.firstIndex { $0 != nil }
            XCTAssertNotNil(free, "Le joueur \(expected) doit trouver une carte")
            engine.pickCard(at: free!)
            // Le geste répété d'un joueur pressé ne doit rien consommer de plus.
            engine.pickCard(at: 0)
            engine.advanceDealing(using: &generator)
        }

        XCTAssertTrue(engine.deck.allSatisfy { $0 == nil }, "Le paquet doit être vide")
        XCTAssertTrue(engine.players.allSatisfy { $0.role != nil }, "Chacun a un rôle")
        if case .describing = engine.phase {} else {
            XCTFail("La manche doit démarrer après la distribution, phase : \(engine.phase)")
        }
    }

    func testEveryRoleIsDealtExactlyOnce() {
        var engine = makeEngine(players: 6)
        var generator = SeededGenerator(seed: 8)

        while case .dealing = engine.phase {
            guard let free = engine.deck.firstIndex(where: { $0 != nil }) else { break }
            engine.pickCard(at: free)
            engine.advanceDealing(using: &generator)
        }

        let dealt = engine.players.compactMap(\.role)
        XCTAssertEqual(dealt.count, 6)
        XCTAssertEqual(dealt.filter { $0 == .undercover }.count, engine.config.undercoverCount)
        XCTAssertEqual(dealt.filter { $0 == .mrWhite }.count, engine.config.mrWhiteCount)
        XCTAssertEqual(dealt.filter { $0 == .civilian }.count, engine.config.civilianCount)
    }
}
