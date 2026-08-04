import Foundation
import XCTest
@testable import Mytho

/// Le roster est la seule donnée partagée par les cinq jeux : une régression ici
/// se voit sur toute la soirée, pas sur un écran.
final class RosterStoreTests: XCTestCase {

    // Jamais `UserDefaults.standard` : les tests écriraient dans les réglages
    // réels du simulateur et se pollueraient les uns les autres.
    private var suiteName: String = ""
    private var defaults: UserDefaults!

    private let key = "mytho.tests.roster"

    override func setUp() {
        super.setUp()
        suiteName = "fr.mytho.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeStore() -> RosterStore {
        RosterStore(defaults: defaults, storageKey: key)
    }

    // MARK: Ajout

    func testAddKeepsInsertionOrder() {
        let store = makeStore()
        store.add("Léa")
        store.add("Tom")
        store.add("Inès")

        XCTAssertEqual(store.names, ["Léa", "Tom", "Inès"])
        XCTAssertEqual(store.count, 3)
    }

    func testAddRejectsEmptyNames() {
        let store = makeStore()

        XCTAssertNil(store.add(""))
        XCTAssertNil(store.add("   "))
        XCTAssertTrue(store.isEmpty)
    }

    func testAddTrimsAndCapsTheName() throws {
        let store = makeStore()

        let trimmed = try XCTUnwrap(store.add("  Léa  "))
        XCTAssertEqual(trimmed.name, "Léa")

        let long = String(repeating: "a", count: RosterStore.maxNameLength + 10)
        let capped = try XCTUnwrap(store.add(long))
        XCTAssertEqual(capped.name.count, RosterStore.maxNameLength)
    }

    func testAddRejectsADuplicateWhateverTheCase() {
        let store = makeStore()
        store.add("Tom")

        XCTAssertNil(store.add("TOM"))
        XCTAssertNil(store.add("  tom "))
        XCTAssertEqual(store.count, 1)
    }

    // MARK: Bornes

    func testRosterStopsAtMaxPlayers() {
        let store = makeStore()
        for index in 1...RosterStore.maxPlayers {
            store.add("Joueur \(index)")
        }

        XCTAssertTrue(store.isFull)
        XCTAssertNil(store.add("Un de trop"))
        XCTAssertEqual(store.count, RosterStore.maxPlayers)
    }

    func testMaxPlayersMatchesTheUndercoverBound() {
        // Un roster valide pour la soirée doit l'être dans chacun des jeux.
        XCTAssertEqual(RosterStore.maxPlayers, Composition.maxPlayers)
    }

    func testTwoActivePlayersAreEnoughToStart() throws {
        let store = makeStore()
        XCTAssertEqual(RosterStore.minPlayers, 2)

        store.add("Léa")
        XCTAssertFalse(store.hasEnoughPlayers)

        let tom = try XCTUnwrap(store.add("Tom"))
        XCTAssertTrue(store.hasEnoughPlayers)

        // Un joueur désactivé ne compte plus dans les effectifs jouables.
        store.beginRound()
        store.remove(tom.id)
        XCTAssertFalse(store.hasEnoughPlayers)
    }

    // MARK: Renommage

    func testRenameKeepsTheIdentity() throws {
        let store = makeStore()
        let lea = try XCTUnwrap(store.add("Léa"))

        XCTAssertTrue(store.rename(lea.id, to: "Léa B."))
        XCTAssertEqual(store.participant(id: lea.id)?.name, "Léa B.")
        XCTAssertEqual(store.count, 1)
    }

    func testRenameRejectsAnExistingNameButAcceptsItsOwn() throws {
        let store = makeStore()
        let lea = try XCTUnwrap(store.add("Léa"))
        store.add("Tom")

        XCTAssertFalse(store.rename(lea.id, to: "tom"))
        XCTAssertEqual(store.participant(id: lea.id)?.name, "Léa")

        // Corriger la casse de son propre prénom doit rester possible.
        XCTAssertTrue(store.rename(lea.id, to: "LÉA"))
        XCTAssertEqual(store.participant(id: lea.id)?.name, "LÉA")
    }

    func testRenameRejectsAnEmptyName() throws {
        let store = makeStore()
        let lea = try XCTUnwrap(store.add("Léa"))

        XCTAssertFalse(store.rename(lea.id, to: "  "))
        XCTAssertEqual(store.participant(id: lea.id)?.name, "Léa")
    }

    // MARK: Retrait

    func testRemoveOutsideARoundDeletesTheEntry() throws {
        let store = makeStore()
        store.add("Léa")
        let tom = try XCTUnwrap(store.add("Tom"))

        store.remove(tom.id)

        XCTAssertEqual(store.names, ["Léa"])
        XCTAssertNil(store.participant(id: tom.id))
    }

    func testRemoveDuringARoundKeepsTheEntryInactive() throws {
        let store = makeStore()
        store.add("Léa")
        let tom = try XCTUnwrap(store.add("Tom"))

        store.beginRound()
        store.remove(tom.id)

        // Tom est sorti du jeu mais la manche en cours le cite encore.
        XCTAssertEqual(store.count, 2)
        XCTAssertEqual(store.participant(id: tom.id)?.isActive, false)
        XCTAssertEqual(store.activeNames, ["Léa"])
    }

    func testAPlayerRemovedDuringARoundCanComeBack() throws {
        let store = makeStore()
        let tom = try XCTUnwrap(store.add("Tom"))
        store.add("Léa")

        store.beginRound()
        store.remove(tom.id)
        store.reactivate(tom.id)

        XCTAssertEqual(store.activeNames, ["Tom", "Léa"])
    }

    func testRemoveDeletesAgainOnceTheRoundIsOver() throws {
        let store = makeStore()
        let tom = try XCTUnwrap(store.add("Tom"))

        store.beginRound()
        store.remove(tom.id)
        store.endRound()
        store.remove(tom.id)

        XCTAssertTrue(store.isEmpty)
    }

    // MARK: Réordonnancement

    func testReorderMovesForward() {
        let store = makeStore()
        store.seed(names: ["A", "B", "C", "D"])

        store.reorder(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        XCTAssertEqual(store.names, ["B", "C", "A", "D"])
    }

    func testReorderMovesBackward() {
        let store = makeStore()
        store.seed(names: ["A", "B", "C", "D"])

        store.reorder(fromOffsets: IndexSet(integer: 3), toOffset: 1)

        XCTAssertEqual(store.names, ["A", "D", "B", "C"])
    }

    // MARK: Vidage et initialisation

    func testClearEmptiesTheRosterAndClosesTheRound() {
        let store = makeStore()
        store.seed(names: ["Léa", "Tom"])
        store.beginRound()

        store.clear()

        XCTAssertTrue(store.isEmpty)
        XCTAssertFalse(store.isRoundInProgress)
    }

    func testSeedReplacesEverythingAndFiltersBadNames() {
        let store = makeStore()
        store.add("Ancien")

        store.seed(names: ["Léa", "", "Tom", "léa", "   "])

        XCTAssertEqual(store.names, ["Léa", "Tom"])
    }

    // MARK: Persistance

    func testRosterSurvivesRelaunch() {
        let store = makeStore()
        store.seed(names: ["Léa", "Tom", "Inès"])
        store.reorder(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        let reopened = makeStore()

        XCTAssertEqual(reopened.names, ["Inès", "Léa", "Tom"])
    }

    func testIdentifiersAndInactiveFlagSurviveRelaunch() throws {
        let store = makeStore()
        let tom = try XCTUnwrap(store.add("Tom"))
        store.add("Léa")
        store.beginRound()
        store.remove(tom.id)

        let reopened = makeStore()

        XCTAssertEqual(reopened.count, 2)
        XCTAssertEqual(reopened.participant(id: tom.id)?.name, "Tom")
        XCTAssertEqual(reopened.participant(id: tom.id)?.isActive, false)
        // La manche, elle, ne se rejoue pas : l'app relancée n'en a plus.
        XCTAssertFalse(reopened.isRoundInProgress)
    }

    func testClearSurvivesRelaunch() {
        let store = makeStore()
        store.seed(names: ["Léa", "Tom"])
        store.clear()

        XCTAssertTrue(makeStore().isEmpty)
    }

    func testTwoStoresOnDifferentKeysDoNotShareTheirRoster() {
        let soiree = makeStore()
        soiree.add("Léa")

        let autre = RosterStore(defaults: defaults, storageKey: "mytho.tests.roster.autre")

        XCTAssertTrue(autre.isEmpty)
        XCTAssertEqual(soiree.names, ["Léa"])
    }
}
