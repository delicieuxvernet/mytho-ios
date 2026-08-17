import Foundation

/// Une paire de mots proches : les civils reçoivent l'un, les infiltrés l'autre.
struct WordPair: Hashable, Codable, Sendable {
    let a: String
    let b: String
}

/// Catégorie thématique de paires de mots.
struct WordCategory: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let symbol: String   // nom de SF Symbol
    let pairs: [WordPair]
}

enum WordBank {

    // MARK: - Catégories

    static let categories: [WordCategory] = [
        WordCategory(id: "general", name: "Tout public", symbol: "sparkles", pairs: generalPairs),
        WordCategory(id: "food", name: "Nourriture", symbol: "fork.knife", pairs: foodPairs),
        WordCategory(id: "animals", name: "Animaux", symbol: "pawprint.fill", pairs: animalsPairs),
        WordCategory(id: "sport", name: "Sport", symbol: "figure.run", pairs: sportPairs),
        WordCategory(id: "places", name: "Lieux & voyage", symbol: "airplane", pairs: placesPairs),
        WordCategory(id: "culture", name: "Ciné, musique & culture", symbol: "film.fill", pairs: culturePairs),
        WordCategory(id: "objects", name: "Objets du quotidien", symbol: "lamp.desk.fill", pairs: objectsPairs),
        WordCategory(id: "spicy", name: "Soirée", symbol: "flame.fill", pairs: spicyPairs)
    ]

    /// Toutes les paires, toutes catégories confondues.
    static var allPairs: [WordPair] { categories.flatMap(\.pairs) }

    static func category(id: String) -> WordCategory? { categories.first { $0.id == id } }

    /// Tire une paire au hasard parmi les catégories demandées, en évitant
    /// autant que possible les paires déjà utilisées récemment.
    static func randomPair(from categoryIDs: Set<String>, excluding recent: [WordPair] = []) -> WordPair {
        var pool = categoryIDs.isEmpty
            ? allPairs
            : categories.filter { categoryIDs.contains($0.id) }.flatMap(\.pairs)
        // Réglages sauvegardés pointant sur une catégorie supprimée depuis :
        // on repart de la banque entière plutôt que de rendre un mot par défaut.
        if pool.isEmpty { pool = allPairs }

        let recentSet = Set(recent)
        let fresh = pool.filter { !recentSet.contains($0) }
        return (fresh.isEmpty ? pool : fresh).randomElement() ?? WordPair(a: "Chat", b: "Chien")
    }

    // MARK: - Tout public

    private static let generalPairs: [WordPair] = [
        WordPair(a: "Chat", b: "Chien"),
        WordPair(a: "Soleil", b: "Lune"),
        WordPair(a: "Hiver", b: "Automne"),
        WordPair(a: "Étoile", b: "Planète"),
        WordPair(a: "Éclair", b: "Tonnerre")
    ]

    // MARK: - Nourriture

    private static let foodPairs: [WordPair] = [
        WordPair(a: "Café", b: "Thé"),
        WordPair(a: "Fraise", b: "Framboise"),
        WordPair(a: "Crêpe", b: "Gaufre"),
        WordPair(a: "Glace", b: "Sorbet"),
        WordPair(a: "Poulet", b: "Dinde"),
        WordPair(a: "Sel", b: "Poivre"),
        WordPair(a: "Omelette", b: "Œuf dur"),
        WordPair(a: "Pastèque", b: "Melon"),
        WordPair(a: "Ketchup", b: "Mayonnaise"),
        WordPair(a: "Croissant", b: "Pain au chocolat"),
        WordPair(a: "Pomme", b: "Poire")
    ]

    // MARK: - Animaux

    private static let animalsPairs: [WordPair] = [
        WordPair(a: "Souris", b: "Rat"),
        WordPair(a: "Chaton", b: "Chiot"),
        WordPair(a: "Lion", b: "Tigre"),
        WordPair(a: "Loup", b: "Renard"),
        WordPair(a: "Requin", b: "Dauphin"),
        WordPair(a: "Abeille", b: "Guêpe"),
        WordPair(a: "Tortue", b: "Escargot")
    ]

    // MARK: - Sport

    private static let sportPairs: [WordPair] = [
        WordPair(a: "Football", b: "Rugby"),
        WordPair(a: "Ski", b: "Snowboard"),
        WordPair(a: "Boxe", b: "Judo"),
        WordPair(a: "Tennis", b: "Badminton"),
        WordPair(a: "Vélo", b: "Trottinette"),
        WordPair(a: "Pétanque", b: "Bowling")
    ]

    // MARK: - Lieux & voyage

    private static let placesPairs: [WordPair] = [
        WordPair(a: "Piscine", b: "Mer"),
        WordPair(a: "Plage", b: "Désert"),
        WordPair(a: "Avion", b: "Train"),
        WordPair(a: "Passeport", b: "Carte d'identité"),
        WordPair(a: "Japon", b: "Chine"),
        WordPair(a: "Espagne", b: "Portugal"),
        WordPair(a: "Alpes", b: "Pyrénées"),
        WordPair(a: "Taxi", b: "Bus"),
        WordPair(a: "Ascenseur", b: "Escalator"),
        WordPair(a: "Hôtel", b: "Auberge"),
        WordPair(a: "Métro", b: "Tramway")
    ]

    // MARK: - Ciné, musique & culture

    private static let culturePairs: [WordPair] = [
        WordPair(a: "Cinéma", b: "Théâtre"),
        WordPair(a: "Magicien", b: "Clown"),
        WordPair(a: "Super-héros", b: "Méchant"),
        WordPair(a: "Livre", b: "Bande dessinée"),
        WordPair(a: "Guitare", b: "Piano"),
        WordPair(a: "Film", b: "Série")
    ]

    // MARK: - Objets du quotidien

    private static let objectsPairs: [WordPair] = [
        WordPair(a: "Fourchette", b: "Cuillère"),
        WordPair(a: "Règle", b: "Équerre"),
        WordPair(a: "Colle", b: "Ruban adhésif"),
        WordPair(a: "Marteau", b: "Tournevis"),
        WordPair(a: "Perceuse", b: "Scie"),
        WordPair(a: "Clou", b: "Vis"),
        WordPair(a: "Allumette", b: "Briquet"),
        WordPair(a: "Savon", b: "Shampoing"),
        WordPair(a: "Parapluie", b: "Parasol")
    ]

    // MARK: - Soirée

    private static let spicyPairs: [WordPair] = [
        WordPair(a: "Bière", b: "Panaché"),
        WordPair(a: "Mojito", b: "Spritz"),
        WordPair(a: "Karaoké", b: "Blind test"),
        WordPair(a: "Gueule de bois", b: "Migraine"),
        WordPair(a: "Ex", b: "Crush")
    ]
}
