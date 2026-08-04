import Foundation
import XCTest
@testable import Mytho

/// Les réglages sont le seul endroit où l'utilisateur reprend la main sur l'app.
/// Un défaut qui se perd au relancement, ou un pack adulte qui s'ouvre sans
/// confirmation, se paie en revue App Store — pas en bug d'affichage.
final class AppSettingsTests: XCTestCase {

    // Jamais `UserDefaults.standard` : les tests écriraient dans les réglages
    // réels du simulateur et se pollueraient les uns les autres.
    private var suiteName: String = ""
    private var defaults: UserDefaults!

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

    private func makeSettings() -> AppSettings {
        AppSettings(defaults: defaults)
    }

    // MARK: Valeurs par défaut

    func testFirstLaunchLeavesSoundAndHapticsOn() {
        let settings = makeSettings()

        XCTAssertTrue(settings.soundEnabled)
        XCTAssertTrue(settings.hapticsEnabled)
    }

    func testFirstLaunchFollowsTheSystemForMotion() {
        XCTAssertEqual(makeSettings().reducedMotion, .system)
    }

    /// Le pack verrouillé ne s'ouvre jamais tout seul (spec §7.2).
    func testFirstLaunchKeepsAdultContentLocked() {
        XCTAssertFalse(makeSettings().adultContentUnlocked)
        XCTAssertEqual(makeSettings().deckResetToken, 0)
    }

    // MARK: Persistance

    func testEverySettingSurvivesANewInstance() {
        let settings = makeSettings()
        settings.soundEnabled = false
        settings.hapticsEnabled = false
        settings.reducedMotion = .forced
        settings.setAdultContent(true, ageConfirmed: true)

        let reopened = AppSettings(defaults: defaults)

        XCTAssertFalse(reopened.soundEnabled)
        XCTAssertFalse(reopened.hapticsEnabled)
        XCTAssertEqual(reopened.reducedMotion, .forced)
        XCTAssertTrue(reopened.adultContentUnlocked)
    }

    /// Les clés sont figées en dur : les renommer orphelinerait les réglages de
    /// tous ceux qui ont déjà l'app installée.
    func testStorageKeysStayStable() {
        let settings = makeSettings()
        settings.soundEnabled = false
        settings.reducedMotion = .disabled

        XCTAssertEqual(defaults.object(forKey: "mytho.settings.sound") as? Bool, false)
        XCTAssertEqual(defaults.string(forKey: "mytho.settings.reducedMotion"), "disabled")
    }

    /// Une valeur illisible (réglage supprimé dans une version future, fichier
    /// corrompu) ne doit pas figer les animations d'un côté ou de l'autre.
    func testUnknownStoredMotionValueFallsBackToTheSystem() {
        defaults.set("plein-regime", forKey: "mytho.settings.reducedMotion")

        XCTAssertEqual(makeSettings().reducedMotion, .system)
    }

    // MARK: Animations — suivi vs forçage

    func testMotionFollowsTheSystemBothWays() {
        let settings = makeSettings()

        XCTAssertTrue(settings.prefersReducedMotion(system: true))
        XCTAssertFalse(settings.prefersReducedMotion(system: false))
    }

    func testForcedMotionReducesEvenWhenTheSystemDoesNotAsk() {
        let settings = makeSettings()
        settings.reducedMotion = .forced

        XCTAssertTrue(settings.prefersReducedMotion(system: false))
        XCTAssertTrue(settings.prefersReducedMotion(system: true))
    }

    func testDisabledMotionKeepsAnimationsDespiteTheSystem() {
        let settings = makeSettings()
        settings.reducedMotion = .disabled

        XCTAssertFalse(settings.prefersReducedMotion(system: true))
        XCTAssertFalse(settings.prefersReducedMotion(system: false))
    }

    // MARK: Contenu adulte

    func testAdultContentStaysLockedWithoutAgeConfirmation() {
        let settings = makeSettings()

        XCTAssertFalse(settings.setAdultContent(true, ageConfirmed: false))
        XCTAssertFalse(settings.adultContentUnlocked)
    }

    func testAdultContentUnlocksWithAgeConfirmation() {
        let settings = makeSettings()

        XCTAssertTrue(settings.setAdultContent(true, ageConfirmed: true))
        XCTAssertTrue(settings.adultContentUnlocked)
    }

    /// Reverrouiller ne se refuse jamais : sinon on ne peut plus rendre l'app
    /// aux enfants une fois le pack ouvert.
    func testAdultContentLocksBackWithoutAnyConfirmation() {
        let settings = makeSettings()
        settings.setAdultContent(true, ageConfirmed: true)

        XCTAssertTrue(settings.setAdultContent(false, ageConfirmed: false))
        XCTAssertFalse(settings.adultContentUnlocked)
    }

    // MARK: Réinitialisation des paquets

    func testResetDecksPurgesDeckMemoryOnly() {
        let settings = makeSettings()
        settings.soundEnabled = false
        defaults.set(["mst_014"], forKey: AppSettings.deckStoragePrefix + "most-likely")
        defaults.set(["wl_007"], forKey: AppSettings.deckStoragePrefix + "wavelength")
        defaults.set(true, forKey: "mytho.roster")

        settings.resetDecks()

        XCTAssertNil(defaults.object(forKey: AppSettings.deckStoragePrefix + "most-likely"))
        XCTAssertNil(defaults.object(forKey: AppSettings.deckStoragePrefix + "wavelength"))
        // Ni le roster ni les réglages ne sont emportés par la purge.
        XCTAssertNotNil(defaults.object(forKey: "mytho.roster"))
        XCTAssertEqual(defaults.object(forKey: "mytho.settings.sound") as? Bool, false)
    }

    /// Un `Deck` déjà chargé en mémoire n'apprend la purge que par ce compteur.
    func testResetDecksBumpsTheToken() {
        let settings = makeSettings()

        settings.resetDecks()
        settings.resetDecks()

        XCTAssertEqual(settings.deckResetToken, 2)
    }
}
