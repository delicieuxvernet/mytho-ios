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

        // On élimine le premier joueur proposé.
        let firstCandidate = app.buttons["Chloé"].exists ? app.buttons["Chloé"] : app.buttons.element(boundBy: 1)
        tap(firstCandidate, timeout: 5)
        tap(app.buttons["Éliminer"], timeout: 5)
        capture("elimination")
    }

    // MARK: Outils

    /// Numérote les captures pour que l'ordre de lecture soit celui du jeu.
    private func capture(_ name: String) {
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
