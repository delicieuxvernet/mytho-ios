import XCTest
@testable import Taupe

/// La composition est la règle la plus facile à casser sans s'en rendre compte :
/// une manche où les infiltrés sont déjà majoritaires se termine avant d'avoir
/// commencé.
final class CompositionTests: XCTestCase {

    func testSuggestedCompositionIsPlayableForEveryTableSize() {
        for count in Composition.minPlayers...Composition.maxPlayers {
            let suggested = Composition.suggested(playerCount: count)
            let infiltrators = suggested.undercover + suggested.mrWhite
            let civilians = count - infiltrators

            XCTAssertGreaterThanOrEqual(infiltrators, 1, "\(count) joueurs : il faut au moins un infiltré")
            XCTAssertGreaterThan(civilians, infiltrators, "\(count) joueurs : les civils doivent être majoritaires")
        }
    }

    func testClampKeepsCiviliansStrictlyInMajority() {
        for count in Composition.minPlayers...Composition.maxPlayers {
            for undercover in 0...count {
                for mrWhite in 0...count {
                    let clamped = Composition.clamp(
                        undercover: undercover,
                        mrWhite: mrWhite,
                        playerCount: count
                    )
                    let infiltrators = clamped.undercover + clamped.mrWhite
                    XCTAssertGreaterThanOrEqual(infiltrators, 1)
                    XCTAssertGreaterThan(
                        count - infiltrators,
                        infiltrators,
                        "\(count) joueurs, demande \(undercover)/\(mrWhite) -> \(clamped)"
                    )
                }
            }
        }
    }

    func testClampReducesMrWhiteBeforeUndercover() {
        // Mr. White est le rôle le plus déséquilibrant : c'est lui qui saute d'abord.
        let clamped = Composition.clamp(undercover: 2, mrWhite: 3, playerCount: 6)
        XCTAssertEqual(clamped.undercover, 2)
        XCTAssertEqual(clamped.mrWhite, 0)
    }

    func testClampAlwaysKeepsAtLeastOneInfiltrator() {
        let clamped = Composition.clamp(undercover: 0, mrWhite: 0, playerCount: 8)
        XCTAssertEqual(clamped.undercover + clamped.mrWhite, 1)
    }

    func testMaxInfiltratorsMatchesTheMajorityRule() {
        XCTAssertEqual(Composition.maxInfiltrators(playerCount: 3), 1)
        XCTAssertEqual(Composition.maxInfiltrators(playerCount: 5), 2)
        XCTAssertEqual(Composition.maxInfiltrators(playerCount: 8), 3)
        XCTAssertEqual(Composition.maxInfiltrators(playerCount: 20), 9)
    }
}
