import Foundation
import SwiftUI

// MARK: - Participant

/// Un prénom de la soirée.
///
/// L'identifiant est stable pour toute la durée de la soirée : les manches
/// désignent les joueurs par `id`, jamais par leur position ni par leur prénom.
/// Sans ça, un renommage ou un départ en cours de partie déplacerait les points
/// d'un joueur sur un autre.
struct Participant: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    /// Un joueur parti avant la fin est désactivé, jamais retiré de la liste :
    /// la manche en cours le cite encore (points marqués, votes, éliminations).
    var isActive: Bool

    init(id: UUID = UUID(), name: String, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.isActive = isActive
    }
}

// MARK: - Roster

/// Les prénoms de la soirée, saisis **une fois** et repris par tous les jeux
/// (spec §2.2). Re-saisir entre deux jeux casse l'enchaînement de la soirée.
///
/// `ObservableObject` plutôt que la macro `@Observable` annoncée par la spec :
/// `GameSession` est un `ObservableObject`, et mélanger les deux systèmes
/// d'observation dans une même hiérarchie de vues produit des rafraîchissements
/// manqués très difficiles à diagnostiquer. Écart assumé, à lever le jour où
/// `GameSession` migrera.
///
/// Pas de `@MainActor` non plus : le store reste un modèle appelable depuis un
/// `XCTestCase` ordinaire, alors que les vues qui le pilotent sont déjà sur le
/// main thread.
final class RosterStore: ObservableObject {

    // MARK: Bornes

    /// Deux joueurs suffisent à jouer — Longueur d'onde tourne avec un médium et
    /// un devineur. C'est plus bas que `Composition.minPlayers` (3), qui est la
    /// borne d'Undercover et non celle de la soirée.
    static let minPlayers = 2

    /// Même plafond qu'Undercover : un roster valide ici l'est dans tous les jeux.
    static let maxPlayers = Composition.maxPlayers

    /// Au-delà, le prénom déborde d'une grille à deux colonnes. On tronque au
    /// lieu de refuser : personne ne comprend un champ qui rejette sa saisie.
    static let maxNameLength = 20

    static let defaultStorageKey = "mytho.roster"

    // MARK: État

    @Published private(set) var participants: [Participant] = [] {
        didSet { persist() }
    }

    /// Vrai entre `beginRound()` et `endRound()`. Pendant cette fenêtre, retirer
    /// un joueur le désactive au lieu de le supprimer.
    ///
    /// Volontairement non persisté : une app relancée n'a plus de manche en cours.
    @Published private(set) var isRoundInProgress = false

    private let defaults: UserDefaults
    private let storageKey: String

    init(defaults: UserDefaults = .standard, storageKey: String = RosterStore.defaultStorageKey) {
        self.defaults = defaults
        self.storageKey = storageKey

        // Les captures d'écran automatisées doivent partir d'un roster propre,
        // quel que soit ce qu'une exécution précédente a laissé sur le simulateur.
        let fresh = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        self.participants = fresh ? [] : Self.load(from: defaults, key: storageKey)
    }

    // MARK: Lecture

    var count: Int { participants.count }
    var isEmpty: Bool { participants.isEmpty }
    var isFull: Bool { participants.count >= Self.maxPlayers }

    /// Les joueurs encore de la partie : c'est cette liste que les jeux affichent
    /// et sur laquelle ils distribuent les rôles.
    var activePlayers: [Participant] { participants.filter(\.isActive) }
    var activeNames: [String] { activePlayers.map(\.name) }
    var names: [String] { participants.map(\.name) }

    /// Faux tant que la soirée n'a pas assez de monde pour lancer quoi que ce soit.
    var hasEnoughPlayers: Bool { activePlayers.count >= Self.minPlayers }

    func participant(id: UUID) -> Participant? {
        participants.first { $0.id == id }
    }

    // MARK: Écriture

    /// Ajoute un prénom. Renvoie `nil` si la saisie est vide, déjà prise ou si le
    /// roster est plein — l'écran de saisie s'appuie dessus pour signaler l'échec.
    @discardableResult
    func add(_ rawName: String) -> Participant? {
        guard !isFull else { return nil }
        let name = Self.normalize(rawName)
        guard !name.isEmpty, !isTaken(name, excluding: nil) else { return nil }

        let participant = Participant(name: name)
        participants.append(participant)
        return participant
    }

    /// Renomme un joueur sans toucher à son identifiant : ses points de la soirée
    /// le suivent. Renvoie `false` si le nouveau prénom est vide ou déjà pris.
    @discardableResult
    func rename(_ id: UUID, to rawName: String) -> Bool {
        let name = Self.normalize(rawName)
        guard !name.isEmpty,
              let index = participants.firstIndex(where: { $0.id == id }),
              !isTaken(name, excluding: id) else { return false }

        participants[index].name = name
        return true
    }

    /// Retire un joueur. **En cours de manche il est seulement désactivé** : la
    /// manche le référence encore, le supprimer effacerait des points déjà
    /// marqués et des votes déjà exprimés (spec §2.2).
    func remove(_ id: UUID) {
        guard let index = participants.firstIndex(where: { $0.id == id }) else { return }

        if isRoundInProgress {
            participants[index].isActive = false
        } else {
            participants.remove(at: index)
        }
    }

    /// Un joueur revenu à table reprend sa place — et ses points, puisqu'il n'a
    /// jamais quitté la liste.
    func reactivate(_ id: UUID) {
        guard let index = participants.firstIndex(where: { $0.id == id }) else { return }
        participants[index].isActive = true
    }

    /// Déplacement à l'index près, calé sur la signature attendue par `.onMove`.
    func reorder(fromOffsets source: IndexSet, toOffset destination: Int) {
        participants.move(fromOffsets: source, toOffset: destination)
    }

    /// Vide le roster : nouvelle soirée, nouveaux prénoms. La manche en cours n'a
    /// plus personne à citer, elle est donc close du même geste.
    func clear() {
        participants.removeAll()
        isRoundInProgress = false
    }

    /// Initialise le roster depuis une simple liste de prénoms — reprise de
    /// `GameConfig.playerNames`, jeu de démonstration des captures d'écran.
    /// Les prénoms vides, en double ou au-delà du plafond sont ignorés.
    func seed(names: [String]) {
        participants.removeAll()
        for name in names { add(name) }
    }

    // MARK: Fenêtre de manche

    /// Ouvre la fenêtre pendant laquelle un retrait désactive au lieu de supprimer.
    func beginRound() { isRoundInProgress = true }

    func endRound() { isRoundInProgress = false }

    // MARK: Outils

    /// Comparaison insensible à la casse : « lea » et « Léa » restent deux
    /// prénoms distincts, mais « TOM » et « Tom » sont le même joueur saisi deux fois.
    private func isTaken(_ name: String, excluding id: UUID?) -> Bool {
        participants.contains {
            $0.id != id && $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }
    }

    private static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxNameLength else { return trimmed }
        return String(trimmed.prefix(maxNameLength))
    }

    // MARK: Persistance

    private func persist() {
        guard let data = try? JSONEncoder().encode(participants) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [Participant] {
        guard let data = defaults.data(forKey: key),
              let saved = try? JSONDecoder().decode([Participant].self, from: data) else { return [] }
        return saved
    }
}
