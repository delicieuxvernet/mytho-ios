import XCTest
@testable import Mytho

final class ScoreBoardTests: XCTestCase {

    private let lea = UUID()
    private let tom = UUID()
    private let ines = UUID()

    private func makeBoard() -> ScoreBoard {
        ScoreBoard(playerIDs: [lea, tom, ines])
    }

    // MARK: Cumul

    func testPointsAccumulate() {
        var board = makeBoard()
        board.award(1, to: lea)
        board.award(2, to: lea)
        board.award(1, to: tom)

        XCTAssertEqual(board.score(for: lea), 3)
        XCTAssertEqual(board.score(for: tom), 1)
        XCTAssertEqual(board.score(for: ines), 0)
    }

    func testABaremeCanTakePointsAway() {
        var board = makeBoard()
        board.award(2, to: lea)
        board.award(-1, to: lea)
        XCTAssertEqual(board.score(for: lea), 1)
    }

    func testAnUnknownPlayerIsRegisteredOnTheFly() {
        var board = ScoreBoard()
        let sarah = UUID()
        board.award(1, to: sarah)

        XCTAssertEqual(board.score(for: sarah), 1)
        XCTAssertEqual(board.standings.map(\.playerID), [sarah])
    }

    func testANewcomerJoinsWithoutResettingTheTable() {
        var board = makeBoard()
        board.award(2, to: lea)
        let sarah = UUID()
        board.register([sarah])

        XCTAssertEqual(board.score(for: lea), 2)
        XCTAssertEqual(board.score(for: sarah), 0)
        XCTAssertEqual(board.standings.count, 4)
    }

    func testRegisteringAnExistingPlayerKeepsHisPoints() {
        var board = makeBoard()
        board.award(3, to: tom)
        board.register([tom, lea])

        XCTAssertEqual(board.score(for: tom), 3)
        XCTAssertEqual(board.standings.count, 3)
    }

    // MARK: Annulation

    func testUndoRemovesTheLastActionOnly() {
        var board = makeBoard()
        board.award(1, to: lea)
        board.award(1, to: tom)

        XCTAssertTrue(board.canUndo)
        XCTAssertTrue(board.undoLast())
        XCTAssertEqual(board.score(for: tom), 0)
        XCTAssertEqual(board.score(for: lea), 1, "L'action précédente reste acquise")
    }

    /// Un « ex æquo » distribue en une action : il s'annule en une action.
    func testUndoOfAnExAequoTakesBackEveryPoint() {
        var board = makeBoard()
        board.award(1, to: [lea, tom])
        XCTAssertEqual(board.score(for: lea), 1)
        XCTAssertEqual(board.score(for: tom), 1)

        XCTAssertTrue(board.undoLast())
        XCTAssertEqual(board.score(for: lea), 0)
        XCTAssertEqual(board.score(for: tom), 0)
        XCTAssertFalse(board.canUndo)
    }

    func testUndoDoesNothingOnAFreshBoard() {
        var board = makeBoard()
        XCTAssertFalse(board.canUndo)
        XCTAssertFalse(board.undoLast())
        XCTAssertEqual(board.score(for: lea), 0)
    }

    func testUndoTwiceGoesBackTwoActions() {
        var board = makeBoard()
        board.award(1, to: lea)
        board.award(5, to: ines)
        board.undoLast()
        board.undoLast()

        XCTAssertEqual(board.score(for: lea), 0)
        XCTAssertEqual(board.score(for: ines), 0)
        XCTAssertFalse(board.canUndo)
    }

    func testStartingARoundClosesTheUndoWindow() {
        var board = makeBoard()
        board.award(1, to: lea)
        board.startRound()

        XCTAssertFalse(board.canUndo)
        XCTAssertFalse(board.undoLast())
        XCTAssertEqual(board.score(for: lea), 1, "Les points marqués restent, seule l'annulation expire")
    }

    func testResetKeepsTheRosterAndClearsEverythingElse() {
        var board = makeBoard()
        board.award(3, to: lea)
        board.resetPoints()

        XCTAssertEqual(board.score(for: lea), 0)
        XCTAssertFalse(board.canUndo)
        XCTAssertEqual(board.standings.count, 3)
    }

    // MARK: Tri

    func testStandingsAreSortedByPoints() {
        var board = makeBoard()
        board.award(1, to: lea)
        board.award(5, to: ines)

        let standings = board.standings
        XCTAssertEqual(standings.map(\.playerID), [ines, lea, tom])
        XCTAssertEqual(standings.map(\.points), [5, 1, 0])
        XCTAssertEqual(standings.map(\.rank), [1, 2, 3])
    }

    func testTiesShareTheSameRankAndKeepTheRosterOrder() {
        var board = makeBoard()
        board.award(3, to: [lea, tom])

        let standings = board.standings
        XCTAssertEqual(standings.map(\.playerID), [lea, tom, ines])
        XCTAssertEqual(standings.map(\.rank), [1, 1, 3], "Deux premiers, puis un troisième")
        XCTAssertEqual(board.leaders, [lea, tom])
    }

    func testAnEmptyBoardHasNoLeader() {
        let board = ScoreBoard()
        XCTAssertTrue(board.standings.isEmpty)
        XCTAssertTrue(board.leaders.isEmpty)
    }

    func testEveryoneAtZeroIsTiedAtTheTop() {
        // Cas de la manche où tout le monde tombe en même temps : personne ne
        // doit être arbitrairement désigné premier.
        let board = makeBoard()
        XCTAssertEqual(board.leaders, [lea, tom, ines])
        XCTAssertEqual(board.standings.map(\.rank), [1, 1, 1])
    }

    // MARK: Sauvegarde

    func testTheBoardSurvivesAnEncodeDecodeRoundTrip() throws {
        var board = makeBoard()
        board.award(4, to: ines)
        board.award(1, to: [lea, tom])

        let data = try JSONEncoder().encode(board)
        let restored = try JSONDecoder().decode(ScoreBoard.self, from: data)

        XCTAssertEqual(restored, board)
        XCTAssertTrue(restored.canUndo)
        XCTAssertEqual(restored.score(for: ines), 4)
    }
}
