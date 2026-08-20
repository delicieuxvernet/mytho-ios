import XCTest
@testable import Mytho

/// Le secret des cartes, verrouillé par des tests.
///
/// Incident du 20 août 2026, en soirée : un joueur oublie son mot, la table
/// appuie sur « Retour », et l'app rouvre la carte du **dernier joueur servi**.
/// Ces tests rejouent ce chemin exact et exigent qu'il ne mène plus nulle part.
@MainActor
final class CardSecrecyTests: XCTestCase {

    private func session(players: Int = 5) -> GameSession {
        let session = GameSession()
        session.config = GameConfig(
            playerNames: (1...players).map { "J\($0)" },
            undercoverCount: 1,
            mrWhiteCount: 1
        )
        session.startRound()
        return session
    }

    /// Distribue toutes les cartes, comme une vraie tablée.
    private func deal(_ session: GameSession) {
        while let engine = session.engine, engine.isDealing {
            guard let free = engine.deck.firstIndex(where: { $0 != nil }) else { break }
            session.pickCard(at: free)
            session.advanceDealing()
        }
    }

    func testNoStepBackWhileTheCardsAreGoingAround() {
        let session = session()

        XCTAssertFalse(session.canGoBack, "Rien à annuler avant la première pioche")

        session.pickCard(at: 0)
        XCTAssertFalse(session.canGoBack, "Pas de retour une fois sa carte en main")

        session.advanceDealing()
        XCTAssertFalse(session.canGoBack, "Le joueur suivant ne doit pas pouvoir rouvrir la précédente")
    }

    /// Le scénario de la soirée : la distribution est finie, la partie commence,
    /// et quelqu'un appuie sur « Retour ».
    func testBackNeverReopensADealtCard() {
        let session = session()
        deal(session)

        guard let engine = session.engine else { return XCTFail("Manche perdue") }
        XCTAssertFalse(engine.isDealing, "La distribution doit être terminée")
        XCTAssertFalse(session.canGoBack, "Aucun retour possible vers la distribution")

        // Même en insistant : le geste ne doit rien ramener à l'écran.
        session.goBack()
        XCTAssertFalse(session.engine?.isDealing ?? true, "Le retour a rouvert une carte")
    }

    /// Le « Retour » garde tout son sens une fois la partie lancée — c'est
    /// seulement la distribution qu'il ne doit plus jamais rembobiner.
    func testBackStillUndoesInGameActions() {
        let session = session()
        deal(session)

        session.startVote()
        XCTAssertTrue(session.canGoBack, "Un vote lancé trop vite doit pouvoir s'annuler")

        session.goBack()
        guard let phase = session.engine?.phase else { return XCTFail("Manche perdue") }
        if case .describing = phase {} else {
            XCTFail("Le retour doit ramener à la description, phase : \(phase)")
        }
    }

    /// « Ma carte » ne s'offre que quand il y a une carte à relire.
    func testPeekIsOfferedOnlyOnceACardHasBeenDealt() {
        let session = session()
        XCTAssertFalse(session.canPeekCards, "Personne n'a encore pioché")

        session.pickCard(at: 0)
        XCTAssertTrue(session.canPeekCards, "Le premier servi doit pouvoir relire son mot")

        session.endRound()
        XCTAssertFalse(session.canPeekCards, "Plus de manche, plus de carte à relire")
    }

    /// Ce que « Ma carte » affiche : le mot du joueur choisi, et lui seul.
    func testEachPlayerGetsBackTheirOwnWord() {
        let session = session()
        deal(session)
        guard let engine = session.engine else { return XCTFail("Manche perdue") }

        for player in engine.players {
            let word = player.word(civilianWord: engine.civilianWord, undercoverWord: engine.undercoverWord)
            switch player.role {
            case .civilian: XCTAssertEqual(word, engine.civilianWord)
            case .undercover: XCTAssertEqual(word, engine.undercoverWord)
            case .mrWhite: XCTAssertNil(word, "Mr. White n'a pas de mot")
            case nil: XCTFail("\(player.name) n'a pas de rôle après la distribution")
            }
        }
    }
}
