import SwiftUI

/// Le contrat qu'un jeu de la soirée remplit pour exister dans l'app (spec §2.1).
/// Ajouter un jeu revient à ajouter une entrée dans `GameRegistry.all` : aucun
/// écran n'interroge un identifiant, donc aucun écran n'est à rouvrir.
protocol PartyGame: Identifiable {
    /// Stable et jamais renommé : il sert de clé de navigation et de mémoire de
    /// paquet. « most-likely », « wavelength »…
    var id: String { get }
    var title: String { get }
    /// Une ligne, pas deux : la tuile n'a pas la place d'expliquer les règles.
    var tagline: String { get }
    /// SF Symbol.
    var symbol: String { get }
    /// Toujours pris dans `Theme` : aucune couleur n'est créée pour un jeu.
    var accent: Color { get }
    var players: ClosedRange<Int> { get }
    /// Durée typique d'une partie, en minutes.
    var minutes: Int { get }
    /// Impose la saisie du roster avant de lancer.
    var needsNames: Bool { get }
}

/// Ce qu'une tuile de l'accueil dessine en grand. Porté par la donnée plutôt
/// que par un test sur l'identifiant : ajouter un jeu ne doit obliger à toucher
/// aucun écran existant (spec §2.1).
enum GameArtwork: Hashable {
    /// Le symbole SF du jeu, en grand sur son aplat.
    case symbol
    /// L'œil reptilien dessiné, signature d'Undercover.
    case reptileEye
}

/// Une entrée du catalogue : strictement ce qu'il faut pour dessiner une tuile.
///
/// Le catalogue reste un tableau de valeurs concrètes et non de `any PartyGame` :
/// un existentiel ne conforme pas `Identifiable` (exigence `Self`), donc
/// `ForEach(GameRegistry.all)` ne compilerait plus. Le protocole reste le contrat
/// de référence, `GameEntry` en est la seule implémentation nécessaire tant que
/// les jeux n'ont pas de comportement propre à porter.
struct GameEntry: PartyGame, Hashable {
    let id: String
    let title: String
    let tagline: String
    let symbol: String
    let accent: Color
    let players: ClosedRange<Int>
    let minutes: Int
    let needsNames: Bool
    /// Faux tant que le jeu n'est pas jouable : la tuile s'affiche quand même,
    /// c'est ce qui donne à la soirée l'envie de revenir.
    let isAvailable: Bool
    var artwork: GameArtwork = .symbol
}

/// Catalogue des jeux de l'app. Un jeu de plus = une ligne de plus ici.
enum GameRegistry {

    /// Les identifiants sont nommés plutôt que recopiés en dur : l'aiguillage
    /// (`PartyGameFlow`) et `RootView` s'appuient dessus, et une coquille dans
    /// une chaîne ouvrirait silencieusement le mauvais écran au lieu de casser
    /// à la compilation.
    static let undercoverID = "undercover"
    static let mostLikelyID = "most-likely"
    static let wouldYouRatherID = "would-you-rather"
    static let neverHaveIEverID = "never-have-i-ever"

    static let all: [GameEntry] = [
        GameEntry(
            id: undercoverID,
            title: "Undercover",
            tagline: "Un mot pour tous, sauf pour les infiltrés.",
            symbol: "eye.fill",
            accent: Theme.brand,
            players: Composition.minPlayers...Composition.maxPlayers,
            minutes: 15,
            // Undercover saisit ses propres noms dans ses réglages : lui imposer
            // le roster ferait saisir la table deux fois.
            needsNames: false,
            isAvailable: true,
            artwork: .reptileEye
        ),
        GameEntry(
            id: mostLikelyID,
            title: "Le plus susceptible de…",
            tagline: "Au décompte, tout le monde pointe du doigt.",
            symbol: "hand.point.up.left.fill",
            accent: Theme.amber,
            // Plancher du moteur (`MostLikelyEngine.minimumPlayers`) : en dessous,
            // pointer du doigt ne départage plus personne.
            players: 3...12,
            minutes: 10,
            // Ses réglages savent dire qu'il manque des prénoms, pas les saisir :
            // le flux ouvre « Qui joue ? » avant de lui rendre la main.
            needsNames: true,
            isAvailable: true
        ),
        GameEntry(
            id: wouldYouRatherID,
            title: "Tu préfères ?",
            tagline: "Deux options, aucune bonne réponse.",
            symbol: "arrow.triangle.branch",
            // Le violet du côté A (§4) : la tuile doit annoncer la couleur de
            // l'écran qu'elle ouvre. L'ambre est celle du côté B, elle n'a pas
            // sa place sur une vignette qui ne montre qu'un aplat.
            accent: Theme.brand,
            players: 2...12,
            minutes: 10,
            // Le mode débat, celui par défaut, se lance sans prénoms (§4.5) :
            // c'est le mode survie qui les réclame, au moment où on le choisit.
            // L'écran de réglages porte d'ailleurs sa propre entrée « Modifier
            // les prénoms », donc le flux n'a pas à la précéder.
            needsNames: false,
            isAvailable: true
        ),
        GameEntry(
            id: neverHaveIEverID,
            title: "Je n'ai jamais",
            tagline: "Cinq vies chacun, le dernier debout gagne.",
            symbol: "hand.raised.fill",
            accent: Theme.mint,
            // Plancher du moteur (`NeverHaveIEverEngine.minPlayers`).
            players: 3...12,
            minutes: 15,
            needsNames: true,
            isAvailable: true
        ),
        GameEntry(
            id: "wavelength",
            title: "Longueur d'onde",
            tagline: "Un indice, une cible cachée, un curseur.",
            symbol: "waveform",
            accent: Theme.brandLight,
            players: 2...12,
            minutes: 15,
            needsNames: true,
            isAvailable: false
        ),
        GameEntry(
            id: "truth-or-dare",
            title: "Action ou vérité",
            tagline: "La bouteille désigne, tu t'exécutes.",
            symbol: "flame.fill",
            accent: Theme.crimson,
            players: 3...12,
            minutes: 20,
            needsNames: true,
            isAvailable: false
        )
    ]
}
