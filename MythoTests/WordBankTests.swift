import XCTest
@testable import Mytho

/// La banque de mots est saisie à la main : ces tests attrapent les coquilles
/// (doublon, mot vide, paire identique) avant qu'elles n'arrivent en partie.
final class WordBankTests: XCTestCase {

    /// Depuis l'écrémage du 17 août, la banque assume d'être petite : peu de
    /// paires, que des essentielles. Le tirage par défaut pioche dans toutes
    /// les catégories à la fois, la variété vient du total, pas de chacune.
    func testEveryCategoryHasEnoughPairs() {
        XCTAssertFalse(WordBank.categories.isEmpty)
        for category in WordBank.categories {
            XCTAssertGreaterThanOrEqual(
                category.pairs.count, 5,
                "\(category.name) : catégorie squelettique, autant la fusionner"
            )
        }
    }

    func testCategoryIdentifiersAreUnique() {
        let ids = WordBank.categories.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testNoPairRepeatsAcrossTheWholeBank() {
        var seen = Set<String>()
        for pair in WordBank.allPairs {
            // Une paire inversée reste la même paire.
            let key = [pair.a.lowercased(), pair.b.lowercased()].sorted().joined(separator: "|")
            XCTAssertTrue(seen.insert(key).inserted, "Paire en double : \(pair.a) / \(pair.b)")
        }
    }

    func testPairsAreWellFormed() {
        for pair in WordBank.allPairs {
            XCTAssertFalse(pair.a.trimmingCharacters(in: .whitespaces).isEmpty)
            XCTAssertFalse(pair.b.trimmingCharacters(in: .whitespaces).isEmpty)
            XCTAssertNotEqual(
                pair.a.lowercased(), pair.b.lowercased(),
                "Les deux mots d'une paire doivent différer : \(pair.a)"
            )
        }
    }

    func testRandomPairRespectsTheSelectedCategories() {
        guard let category = WordBank.categories.first else { return XCTFail("Banque vide") }
        for _ in 0..<200 {
            let pair = WordBank.randomPair(from: [category.id])
            XCTAssertTrue(category.pairs.contains(pair), "\(pair.a) n'appartient pas à \(category.name)")
        }
    }

    func testEmptySelectionDrawsFromEverything() {
        let all = Set(WordBank.allPairs)
        for _ in 0..<200 {
            XCTAssertTrue(all.contains(WordBank.randomPair(from: [])))
        }
    }

    func testRecentPairsAreAvoidedWhenPossible() {
        guard let category = WordBank.categories.first else { return XCTFail("Banque vide") }
        // On exclut toutes les paires sauf une : c'est forcément celle-là qui sort.
        let expected = category.pairs[0]
        let recent = Array(category.pairs.dropFirst())

        for _ in 0..<50 {
            XCTAssertEqual(WordBank.randomPair(from: [category.id], excluding: recent), expected)
        }
    }

    func testUnknownCategoryIdentifierIsIgnoredRatherThanCrashing() {
        // Un identifiant obsolète en réglages sauvegardés ne doit pas vider le tirage.
        let pair = WordBank.randomPair(from: ["categorie-supprimee"])
        XCTAssertFalse(pair.a.isEmpty)
        XCTAssertFalse(pair.b.isEmpty)
    }
}
