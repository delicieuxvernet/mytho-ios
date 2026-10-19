import XCTest
@testable import Mytho

/// La banque de mots est saisie à la main : ces tests attrapent les coquilles
/// (doublon, mot vide, paire identique) avant qu'elles n'arrivent en partie.
final class WordBankTests: XCTestCase {

    /// Chaque thème doit tenir une partie : en dessous de cinq paires, autant
    /// le fusionner avec un autre.
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

    // MARK: - Catégorie 18+

    func testThereIsExactlyOneAdultCategoryAndItIsNotFirst() {
        XCTAssertEqual(WordBank.categories.filter(\.isAdult).count, 1)
        XCTAssertEqual(WordBank.adultCategory?.id, WordBank.hotID)
        XCTAssertFalse(WordBank.categories[0].isAdult, "La première catégorie sert de défaut : tout public")
        XCTAssertFalse(WordBank.publicCategories.contains { $0.isAdult })
    }

    /// « Tous » veut dire tous les thèmes tout public : jamais le 18+, même
    /// une fois l'âge confirmé. Il faut le cocher.
    func testAllNeverIncludesTheAdultCategory() {
        let hot = Set(WordBank.adultCategory?.pairs ?? [])
        for _ in 0..<300 {
            XCTAssertFalse(hot.contains(WordBank.randomPair(from: [], adultUnlocked: true)))
        }
    }

    /// Cochée mais verrou fermé (réglage sauvegardé, âge refermé depuis) : la
    /// catégorie 18+ ne sort pas, la pioche retombe sur le tout public.
    func testTheAdultCategoryStaysLockedWithoutTheAgeGate() {
        let hot = Set(WordBank.adultCategory?.pairs ?? [])
        let publicPairs = Set(WordBank.publicPairs)
        for _ in 0..<300 {
            let pair = WordBank.randomPair(from: [WordBank.hotID], adultUnlocked: false)
            XCTAssertFalse(hot.contains(pair))
            XCTAssertTrue(publicPairs.contains(pair))
        }
    }

    func testTheAdultCategoryPlaysOnceCheckedAndUnlocked() {
        let hot = Set(WordBank.adultCategory?.pairs ?? [])
        for _ in 0..<100 {
            XCTAssertTrue(hot.contains(WordBank.randomPair(from: [WordBank.hotID], adultUnlocked: true)))
        }
    }

    func testUnknownCategoryIdentifierIsIgnoredRatherThanCrashing() {
        // Un identifiant obsolète en réglages sauvegardés ne doit pas vider le tirage.
        let pair = WordBank.randomPair(from: ["categorie-supprimee"])
        XCTAssertFalse(pair.a.isEmpty)
        XCTAssertFalse(pair.b.isEmpty)
    }
}
