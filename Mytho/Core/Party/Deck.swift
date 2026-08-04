import Foundation

// MARK: - Mémoire persistée

/// Ce qu'un paquet garde entre deux lancements : les cartes déjà sorties pendant
/// le tour en cours, et la fin du tour précédent encore interdite de sortie.
struct DeckMemorySnapshot: Codable, Equatable, Sendable {
    /// Identifiants sortis depuis le début du tour, du plus ancien au plus récent.
    var drawn: [String]
    /// Report du tour précédent : ces cartes viennent d'être vues, elles doivent
    /// attendre que le nouveau tour ait défilé avant de pouvoir revenir.
    var carried: [String]

    init(drawn: [String] = [], carried: [String] = []) {
        self.drawn = drawn
        self.carried = carried
    }

    static let empty = DeckMemorySnapshot()
}

/// Où la mémoire d'un paquet est rangée. L'abstraction existe pour que les tests
/// n'écrivent jamais dans les réglages réels du simulateur.
protocol DeckMemoryStore: AnyObject {
    func memory(forDeck deckID: String) -> DeckMemorySnapshot
    func save(_ memory: DeckMemorySnapshot, forDeck deckID: String)
    func clear(deckID: String)
    /// « Réinitialiser les paquets » des réglages : tous les jeux d'un coup.
    func clearAll()
}

/// Stockage réel. `UserDefaultsDeckMemory.shared.clearAll()` est le point
/// d'entrée du bouton de purge des réglages.
final class UserDefaultsDeckMemory: DeckMemoryStore, @unchecked Sendable {

    static let shared = UserDefaultsDeckMemory()

    /// Préfixe commun : c'est lui qui permet de tout purger sans tenir la liste
    /// des jeux à jour ici. Volontairement identique à
    /// `AppSettings.deckStoragePrefix` — le bouton « réinitialiser les paquets »
    /// des réglages balaie par ce préfixe. Changer l'un oblige à changer l'autre.
    /// Même préfixe que les réglages : c'est ce qui permet à « réinitialiser
    /// les paquets » de balayer réellement toutes les mémoires.
    private static let prefix = AppSettings.deckStoragePrefix

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(_ deckID: String) -> String { Self.prefix + deckID }

    func memory(forDeck deckID: String) -> DeckMemorySnapshot {
        guard let data = defaults.data(forKey: key(deckID)),
              let memory = try? JSONDecoder().decode(DeckMemorySnapshot.self, from: data)
        else { return .empty }
        return memory
    }

    func save(_ memory: DeckMemorySnapshot, forDeck deckID: String) {
        guard let data = try? JSONEncoder().encode(memory) else { return }
        defaults.set(data, forKey: key(deckID))
    }

    func clear(deckID: String) {
        defaults.removeObject(forKey: key(deckID))
    }

    func clearAll() {
        for storedKey in defaults.dictionaryRepresentation().keys where storedKey.hasPrefix(Self.prefix) {
            defaults.removeObject(forKey: storedKey)
        }
    }
}

// MARK: - Pioche

/// Pioche sans répétition, générique et rejouable. Généralise ce que
/// `WordBank.randomPair(from:excluding:)` fait déjà, en ajoutant la mémoire
/// persistée des cartes vues, par jeu.
///
/// Le paquet se comporte comme un vrai paquet : chaque carte sort **une fois par
/// tour**. Au remélange, la fin du tour précédent reste bloquée le temps que 70 %
/// du paquet défile — revoir la même carte deux fois dans une soirée casse
/// l'illusion de profondeur, quel que soit le volume réel de contenu.
///
/// Le générateur aléatoire s'injecte, comme dans `GameEngine` : c'est ce qui rend
/// une soirée rejouable à l'identique en test.
struct Deck<Item> {

    /// Résultat d'une pioche.
    struct Draw {
        let item: Item
        /// Vrai uniquement sur la première carte d'un nouveau tour. C'est le seul
        /// moment où « tu as fait le tour du paquet » doit s'afficher : l'appelant
        /// n'a rien à mémoriser pour ne le montrer qu'une fois.
        let startsNewLap: Bool
    }

    /// Identifiant du paquet — un par jeu, éventuellement un par sous-paquet
    /// (les gages d'Action ou vérité ont leur propre mémoire).
    let deckID: String
    let items: [Item]

    private let identify: (Item) -> String
    private let store: any DeckMemoryStore
    private var memory: DeckMemorySnapshot

    init(
        id deckID: String,
        items: [Item],
        identify: @escaping (Item) -> String,
        store: any DeckMemoryStore = UserDefaultsDeckMemory.shared
    ) {
        self.deckID = deckID
        self.items = items
        self.identify = identify
        self.store = store
        self.memory = store.memory(forDeck: deckID)
    }

    // MARK: État

    var count: Int { items.count }

    /// Cartes pas encore sorties dans le tour en cours.
    var remainingCount: Int {
        let seen = Set(memory.drawn)
        return items.filter { !seen.contains(identify($0)) }.count
    }

    /// Nombre de cartes qui doivent défiler avant qu'une carte sortie puisse
    /// revenir : 70 % du paquet. Borné à `count - 1` pour qu'il reste toujours au
    /// moins une carte piochable — sur un paquet minuscule, la règle des 70 % ne
    /// peut pas être tenue sans bloquer la partie.
    var cooldown: Int {
        guard items.count > 1 else { return 0 }
        // Arithmétique entière : `0.7 * Double(n)` arrondi vers le haut donne 8
        // au lieu de 7 pour n = 10, la valeur 0,7 n'étant pas représentable.
        return min(items.count - 1, (items.count * 7 + 9) / 10)
    }

    // MARK: Pioche

    mutating func draw(using generator: inout some RandomNumberGenerator) -> Draw? {
        guard !items.isEmpty else { return nil }

        var startsNewLap = false
        if remainingCount == 0 {
            // Paquet vidé : on remélange, mais la fin du tour qui s'achève reste
            // sous cooldown, sinon la toute dernière carte vue pourrait ressortir
            // en première position du tour suivant.
            memory.carried = Array(memory.drawn.suffix(cooldown))
            memory.drawn.removeAll()
            // Un paquet d'une seule carte boucle à chaque tirage : annoncer
            // « tu as fait le tour du paquet » à chaque fois n'aurait aucun sens.
            startsNewLap = items.count > 1
        }

        let seen = Set(memory.drawn)
        let blocked = Set((memory.carried + memory.drawn).suffix(cooldown))
        var pool = items.filter { item in
            let id = identify(item)
            return !seen.contains(id) && !blocked.contains(id)
        }
        // Le cooldown ne couvre que 70 % du paquet : il reste toujours de quoi
        // piocher. Le repli n'existe que pour le cas où la liste des cartes change
        // sous les pieds du paquet (pack désactivé en cours de partie).
        if pool.isEmpty {
            pool = items.filter { !seen.contains(identify($0)) }
        }
        guard let item = pool.randomElement(using: &generator) else { return nil }

        record(identify(item))
        return Draw(item: item, startsNewLap: startsNewLap)
    }

    /// Pioche avec le générateur du système. La partie réelle n'a pas de graine.
    mutating func draw() -> Draw? {
        var generator = SystemRandomNumberGenerator()
        return draw(using: &generator)
    }

    /// Vide la mémoire : le paquet repart comme au premier soir.
    mutating func reset() {
        memory = .empty
        store.clear(deckID: deckID)
    }

    private mutating func record(_ id: String) {
        memory.drawn.append(id)
        // Seules les `cooldown` dernières cartes comptent : le report du tour
        // précédent se purge au fur et à mesure que le nouveau tour avance.
        let overflow = memory.carried.count + memory.drawn.count - cooldown
        if overflow > 0 {
            memory.carried.removeFirst(min(overflow, memory.carried.count))
        }
        store.save(memory, forDeck: deckID)
    }
}

extension Deck where Item: Identifiable, Item.ID == String {
    /// Le cas courant : les cartes des cinq jeux portent toutes un `id` stable
    /// (« mst_014 »), qui est exactement ce que la mémoire persiste.
    init(
        id deckID: String,
        items: [Item],
        store: any DeckMemoryStore = UserDefaultsDeckMemory.shared
    ) {
        self.init(id: deckID, items: items, identify: { $0.id }, store: store)
    }
}
