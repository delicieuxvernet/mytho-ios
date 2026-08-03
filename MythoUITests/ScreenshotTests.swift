import XCTest

/// Parcourt une manche complète sur le simulateur et capture chaque écran.
/// Seul moyen de contrôler le rendu réel depuis une machine sans Xcode : la CI
/// macOS exécute ce test et publie les PNG en artefact.
///
/// Ce test ne garde pas le jeu : il ne vérifie aucune règle (c'est le rôle des
/// tests unitaires). Il échoue seulement si un écran attendu ne s'affiche pas,
/// ce qui signale une navigation cassée.
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!
    private var stepIndex = 0

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    func testCaptureAFullRound() {
        capture("accueil")

        // Règles
        tap(app.buttons["Comment jouer"], timeout: 5)
        capture("regles")
        tap(app.buttons["Fermer"], timeout: 5)

        // Distribution : chaque joueur pioche puis mémorise son mot.
        tap(app.buttons["Distribuer les cartes"], timeout: 5)
        capture("passage-du-telephone")

        for player in 0..<5 {
            let handoff = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Je suis")).firstMatch
            tap(handoff, timeout: 5)
            if player == 0 { capture("pioche") }

            tap(app.buttons["Carte face cachée numéro 1"], timeout: 5, orAnyMatching: "Carte face cachée")
            if player == 0 { capture("mot-revele") }

            tap(app.buttons["C'est mémorisé"], timeout: 5)
        }

        // Description puis vote
        capture("ordre-de-parole")
        tap(app.buttons["Passer au vote"], timeout: 5)
        capture("vote")

        // On élimine le premier joueur encore en lice.
        tapAnyPlayerCard()
        tap(app.buttons["Éliminer"], timeout: 5)
        capture("elimination")

        playUntilTheRoundEnds()
        capture("fin-de-manche")
    }

    /// Les prénoms du profil de test injecté par `-uiTesting`.
    private static let testPlayers = ["Chloé", "Malik", "Inès", "Tom", "Sarah"]

    /// Touche la carte de vote du premier joueur encore en lice, jamais un
    /// bouton par index : lors du run 30810486415, `element(boundBy: 1)` avait
    /// attrapé la croix d'abandon et ouvert la boîte de confirmation, laissant
    /// la manche tourner à vide jusqu'au timeout.
    private func tapAnyPlayerCard() {
        for name in Self.testPlayers {
            let card = app.buttons[name]
            if card.exists && card.isHittable {
                card.tap()
                return
            }
        }
        XCTFail("Aucune carte de joueur touchable sur l'écran de vote")
    }

    /// Enchaîne éliminations et tours jusqu'à ce qu'un camp gagne. Vérifie au
    /// passage que la boucle de jeu se termine réellement sur un appareil, et
    /// pas seulement dans les tests unitaires du moteur.
    private func playUntilTheRoundEnds() {
        // Cinq joueurs : au pire 4 éliminations de ~4 actions chacune.
        for _ in 0..<20 {
            if app.buttons["Nouvelle manche"].exists { return }

            if app.buttons["Continuer"].exists {
                app.buttons["Continuer"].tap()
            } else if app.buttons["Il passe son tour"].exists {
                // Mr. White démasqué : on le fait échouer pour que la manche continue.
                app.buttons["Il passe son tour"].tap()
            } else if app.buttons["Passer au vote"].exists {
                app.buttons["Passer au vote"].tap()
            } else if app.buttons["Éliminer"].exists {
                app.buttons["Éliminer"].tap()
            } else {
                tapAnyPlayerCard()
            }
            _ = app.buttons.firstMatch.waitForExistence(timeout: 3)
        }

        XCTAssertTrue(
            app.buttons["Nouvelle manche"].waitForExistence(timeout: 5),
            "La manche ne s'est jamais terminée après 20 actions"
        )
    }

    // MARK: Outils

    /// Numérote les captures pour que l'ordre de lecture soit celui du jeu.
    ///
    /// L'attente n'est pas du confort : sans elle, chaque capture attrapait une
    /// transition en cours (deux écrans superposés, carte pas encore retournée)
    /// et ne permettait pas de juger le rendu réel.
    private func capture(_ name: String) {
        Thread.sleep(forTimeInterval: 1.0)
        stepIndex += 1
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = String(format: "%02d-%@", stepIndex, name)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Attend qu'un élément soit touchable, puis le touche. Un repli sur le
    /// premier bouton dont le libellé commence par `orAnyMatching` évite de
    /// casser tout le parcours si un libellé indexé change.
    private func tap(_ element: XCUIElement, timeout: TimeInterval, orAnyMatching prefix: String? = nil) {
        if element.waitForExistence(timeout: timeout) {
            element.tap()
            return
        }
        if let prefix {
            let fallback = app.buttons
                .matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
                .firstMatch
            if fallback.waitForExistence(timeout: timeout) {
                fallback.tap()
                return
            }
        }
        XCTFail("Élément introuvable après \(Int(timeout)) s : \(element.description)")
    }
}
