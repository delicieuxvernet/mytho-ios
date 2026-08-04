import SwiftUI

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
struct GameEntry: Identifiable, Hashable {
    let id: String
    let title: String
    /// Une ligne, pas deux : la tuile n'a pas la place d'expliquer les règles.
    let tagline: String
    let symbol: String
    /// Toujours pris dans `Theme` : aucune couleur n'est créée pour un jeu.
    let accent: Color
    let players: ClosedRange<Int>
    /// Durée typique d'une partie, en minutes.
    let minutes: Int
    /// Faux tant que le jeu n'est pas jouable : la tuile s'affiche quand même,
    /// c'est ce qui donne à la soirée l'envie de revenir.
    let isAvailable: Bool
    var artwork: GameArtwork = .symbol
}

/// Catalogue des jeux de l'app. Un jeu de plus = une ligne de plus ici.
enum GameRegistry {

    /// Le seul jeu jouable à ce jour. Nommé plutôt que recopié en dur, pour que
    /// l'aiguillage refuse d'ouvrir Undercover quand un autre jeu est choisi.
    static let undercoverID = "undercover"

    static let all: [GameEntry] = [
        GameEntry(
            id: undercoverID,
            title: "Undercover",
            tagline: "Un mot pour tous, sauf pour les infiltrés.",
            symbol: "eye.fill",
            accent: Theme.brand,
            players: Composition.minPlayers...Composition.maxPlayers,
            minutes: 15,
            isAvailable: true,
            artwork: .reptileEye
        ),
        GameEntry(
            id: "most-likely",
            title: "Le plus susceptible de…",
            tagline: "Au décompte, tout le monde pointe du doigt.",
            symbol: "hand.point.up.left.fill",
            accent: Theme.amber,
            players: 3...12,
            minutes: 10,
            isAvailable: false
        ),
        GameEntry(
            id: "would-you-rather",
            title: "Tu préfères ?",
            tagline: "Deux options, aucune bonne réponse.",
            symbol: "arrow.triangle.branch",
            accent: Theme.sky,
            players: 2...12,
            minutes: 10,
            isAvailable: false
        ),
        GameEntry(
            id: "never-have-i-ever",
            title: "Je n'ai jamais",
            tagline: "Cinq vies chacun, le dernier debout gagne.",
            symbol: "hand.raised.fill",
            accent: Theme.mint,
            players: 3...12,
            minutes: 15,
            isAvailable: false
        ),
        GameEntry(
            id: "wavelength",
            title: "Longueur d'onde",
            tagline: "Un indice, une cible cachée, un curseur.",
            symbol: "waveform",
            accent: Theme.brandLight,
            players: 2...12,
            minutes: 15,
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
            isAvailable: false
        )
    ]
}
