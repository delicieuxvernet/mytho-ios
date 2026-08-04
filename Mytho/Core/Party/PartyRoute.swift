import Foundation

/// Le chemin typé du `NavigationStack` unique de la soirée (spec §2.7).
///
/// **Rien n'est encore branché dessus.** `RootView` continue de piloter
/// Undercover par la phase du moteur : la v1.0 est en validation chez Apple, on
/// ne refond pas la navigation d'un jeu soumis. Le type est posé pour que le 2e
/// jeu arrive dans un empilement déjà décidé, pas pour être câblé aujourd'hui.
///
/// Un seul empilement, et **aucune `sheet` par-dessus une partie** : une feuille
/// se referme d'un glissement, et ce glissement rejouerait une révélation déjà
/// vue. La soirée est un enchaînement linéaire, pas une arborescence.
enum Route: Hashable {
    /// Prénoms de la soirée, saisis une fois et repris par les cinq jeux.
    case roster
    /// Règles du jeu : quatre écrans au maximum, toujours sautables.
    case rules(gameID: String)
    /// Packs, options, nombre de manches.
    case setup(gameID: String)
    case play(gameID: String)
    case results(gameID: String)
    case settings

    /// Le jeu visé, quand la destination en vise un. Évite à chaque appelant de
    /// réécrire un `switch` complet pour retrouver l'identifiant — et évite
    /// surtout qu'il le devine à partir de la position dans le chemin.
    var gameID: String? {
        switch self {
        case .roster, .settings:
            return nil
        case .rules(let id), .setup(let id), .play(let id), .results(let id):
            return id
        }
    }
}
