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
    /// Catégorie 18+ : hors de « Tous », invisible et injouable tant que l'âge
    /// n'est pas confirmé — même doctrine que les paquets des autres jeux.
    var isAdult: Bool = false
}

enum WordBank {

    // MARK: - Catégories

    /// Les thèmes jeunes d'abord (version 2.0, « pas encore fun et jeune »),
    /// puis les classiques du genre gardés par Arthur en août, puis le 18+.
    /// La première catégorie doit rester tout public : c'est elle que les
    /// tests tirent par défaut.
    static let categories: [WordCategory] = [
        WordCategory(id: "spicy", name: "Soirée", symbol: "party.popper.fill", pairs: spicyPairs),
        WordCategory(id: "love", name: "Love & dates", symbol: "heart.fill", pairs: lovePairs),
        WordCategory(id: "youth", name: "Vie de jeune", symbol: "graduationcap.fill", pairs: youthPairs),
        WordCategory(id: "screens", name: "Écrans", symbol: "iphone", pairs: screensPairs),
        WordCategory(id: "food", name: "Bouffe", symbol: "fork.knife", pairs: foodPairs),
        WordCategory(id: "general", name: "Classiques", symbol: "sparkles", pairs: generalPairs),
        WordCategory(id: "animals", name: "Animaux", symbol: "pawprint.fill", pairs: animalsPairs),
        WordCategory(id: "sport", name: "Sport", symbol: "figure.run", pairs: sportPairs),
        WordCategory(id: "places", name: "Lieux & voyage", symbol: "airplane", pairs: placesPairs),
        WordCategory(id: "culture", name: "Ciné, musique & culture", symbol: "film.fill", pairs: culturePairs),
        WordCategory(id: "objects", name: "Objets du quotidien", symbol: "lamp.desk.fill", pairs: objectsPairs),
        WordCategory(id: hotID, name: "Hot", symbol: "flame.fill", pairs: hotPairs, isAdult: true)
    ]

    /// Identifiant de la catégorie 18+.
    static let hotID = "hot"

    /// Les thèmes qu'affichent les puces et que « Tous » recouvre.
    static var publicCategories: [WordCategory] { categories.filter { !$0.isAdult } }

    /// La catégorie 18+, présentée en bandeau et jamais parmi les puces.
    static var adultCategory: WordCategory? { categories.first(where: \.isAdult) }

    /// Toutes les paires, toutes catégories confondues, 18+ compris.
    static var allPairs: [WordPair] { categories.flatMap(\.pairs) }

    /// Les paires jouables sans confirmation d'âge.
    static var publicPairs: [WordPair] { publicCategories.flatMap(\.pairs) }

    static func category(id: String) -> WordCategory? { categories.first { $0.id == id } }

    /// Tire une paire au hasard parmi les catégories demandées, en évitant
    /// autant que possible les paires déjà utilisées récemment.
    ///
    /// Une sélection vide veut dire « Tous » : tous les thèmes **tout public**.
    /// La catégorie 18+ ne sort que cochée explicitement **et** l'âge confirmé —
    /// le verrou vit ici, pas dans la vue : un réglage sauvegardé ne rouvre pas
    /// une catégorie que les réglages ont refermée depuis.
    static func randomPair(
        from categoryIDs: Set<String>,
        excluding recent: [WordPair] = [],
        adultUnlocked: Bool = false
    ) -> WordPair {
        let playable = categories.filter { !$0.isAdult || adultUnlocked }
        var pool = categoryIDs.isEmpty
            ? publicPairs
            : playable.filter { categoryIDs.contains($0.id) }.flatMap(\.pairs)
        // Réglages sauvegardés pointant sur une catégorie supprimée depuis, ou
        // 18+ seul refermé : on repart des thèmes tout public plutôt que de
        // rendre un mot par défaut.
        if pool.isEmpty { pool = publicPairs }

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
        WordPair(a: "Pomme", b: "Poire"),
        // Version 2.0 : la bouffe qu'on mange vraiment à 20 ans.
        WordPair(a: "Kebab", b: "Tacos"),
        WordPair(a: "Raclette", b: "Fondue"),
        WordPair(a: "Sushi", b: "Maki"),
        WordPair(a: "Burger", b: "Hot-dog"),
        WordPair(a: "Carbonara", b: "Bolognaise"),
        WordPair(a: "Nuggets", b: "Tenders"),
        WordPair(a: "Frites", b: "Potatoes"),
        WordPair(a: "Bubble tea", b: "Smoothie"),
        WordPair(a: "Ramen", b: "Nouilles instantanées"),
        WordPair(a: "Pizza", b: "Calzone"),
        WordPair(a: "Cookie", b: "Brownie"),
        WordPair(a: "Cordon bleu", b: "Escalope panée"),
        WordPair(a: "Pâte à tartiner", b: "Confiture"),
        WordPair(a: "Huître", b: "Moule")
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
        WordPair(a: "Ex", b: "Crush"),
        // Version 2.0 : la soirée, du before à la gueule de bois.
        WordPair(a: "Vodka", b: "Tequila"),
        WordPair(a: "Before", b: "After"),
        WordPair(a: "Boîte de nuit", b: "Rave"),
        WordPair(a: "Videur", b: "Vigile"),
        WordPair(a: "DJ", b: "Barman"),
        WordPair(a: "Shot", b: "Cul sec"),
        WordPair(a: "Apéro", b: "Brunch"),
        WordPair(a: "Chicha", b: "Vapoteuse"),
        WordPair(a: "Fête de village", b: "Festival"),
        WordPair(a: "Sangria", b: "Punch"),
        WordPair(a: "Afterwork", b: "Pot de départ"),
        WordPair(a: "Rosé", b: "Champagne"),
        WordPair(a: "EVG", b: "EVJF"),
        WordPair(a: "Soirée pyjama", b: "Nuit blanche"),
        WordPair(a: "Jeu à boire", b: "Action ou vérité")
    ]

    // MARK: - Love & dates

    private static let lovePairs: [WordPair] = [
        WordPair(a: "Premier date", b: "Entretien d'embauche"),
        WordPair(a: "Ghosting", b: "Râteau"),
        WordPair(a: "Bisou", b: "Câlin"),
        WordPair(a: "Situationship", b: "Couple libre"),
        WordPair(a: "Saint-Valentin", b: "Anniversaire de couple"),
        WordPair(a: "Demande en mariage", b: "Rupture"),
        WordPair(a: "Red flag", b: "Green flag"),
        WordPair(a: "Speed dating", b: "Appli de rencontre"),
        WordPair(a: "Mariage", b: "PACS"),
        WordPair(a: "Témoin de mariage", b: "Demoiselle d'honneur"),
        WordPair(a: "Lune de miel", b: "Week-end en amoureux"),
        WordPair(a: "Coup d'un soir", b: "Amour de vacances"),
        WordPair(a: "Dîner aux chandelles", b: "Pique-nique romantique")
    ]

    // MARK: - Vie de jeune

    private static let youthPairs: [WordPair] = [
        WordPair(a: "Coloc", b: "Internat"),
        WordPair(a: "Partiel", b: "Oral"),
        WordPair(a: "Stage", b: "Alternance"),
        WordPair(a: "Erasmus", b: "Colo"),
        WordPair(a: "Bac", b: "Permis de conduire"),
        WordPair(a: "Prof", b: "Surveillant"),
        WordPair(a: "Cantine", b: "Self"),
        WordPair(a: "Fac", b: "Lycée"),
        WordPair(a: "Job d'été", b: "Baby-sitting"),
        WordPair(a: "Gap year", b: "Tour du monde"),
        WordPair(a: "Premier appart", b: "Chambre d'ado"),
        WordPair(a: "Rattrapage", b: "Redoublement"),
        WordPair(a: "Daron", b: "Daronne"),
        WordPair(a: "Cours en amphi", b: "Cours en visio"),
        WordPair(a: "Pote", b: "Collègue")
    ]

    // MARK: - Écrans

    /// Aucune marque : le jeu parle des usages, jamais des applis.
    private static let screensPairs: [WordPair] = [
        WordPair(a: "Story", b: "Statut"),
        WordPair(a: "Selfie", b: "Photo de profil"),
        WordPair(a: "Vocal", b: "Appel vidéo"),
        WordPair(a: "Like", b: "Commentaire"),
        WordPair(a: "Influenceur", b: "Youtubeur"),
        WordPair(a: "Emoji", b: "Sticker"),
        WordPair(a: "Live", b: "Replay"),
        WordPair(a: "Mème", b: "GIF"),
        WordPair(a: "Filtre", b: "Retouche"),
        WordPair(a: "Abonné", b: "Ami"),
        WordPair(a: "Mode avion", b: "Ne pas déranger"),
        WordPair(a: "Wi-Fi", b: "5G"),
        WordPair(a: "Chargeur", b: "Batterie externe"),
        WordPair(a: "Hashtag", b: "Mention"),
        WordPair(a: "Notification", b: "Spam")
    ]

    // MARK: - Hot (18+)

    /// Derrière la confirmation d'âge, jamais dans « Tous » : cru mais jamais
    /// graphique (règle 1.1.4), aucune marque, aucun mineur.
    private static let hotPairs: [WordPair] = [
        WordPair(a: "Capote", b: "Lubrifiant"),
        WordPair(a: "Plan cul", b: "Relation sérieuse"),
        WordPair(a: "Menottes", b: "Bandeau"),
        WordPair(a: "Strip-tease", b: "Lap dance"),
        WordPair(a: "Préliminaires", b: "Massage"),
        WordPair(a: "Nude", b: "Sextape"),
        WordPair(a: "Sextoy", b: "Lingerie"),
        WordPair(a: "Levrette", b: "Missionnaire"),
        WordPair(a: "Orgasme", b: "Fou rire"),
        WordPair(a: "Body count", b: "Nombre d'ex"),
        WordPair(a: "Gémissement", b: "Soupir"),
        WordPair(a: "Simulation", b: "Panne"),
        WordPair(a: "Sexto", b: "Vocal coquin"),
        WordPair(a: "Porno", b: "Film érotique"),
        WordPair(a: "Fessée", b: "Chatouille"),
        WordPair(a: "String", b: "Tanga"),
        WordPair(a: "Hôtel à l'heure", b: "Love room"),
        WordPair(a: "Jacuzzi", b: "Bain moussant"),
        WordPair(a: "Quickie", b: "Marathon"),
        WordPair(a: "Sieste crapuleuse", b: "Grasse matinée"),
        WordPair(a: "Douche à deux", b: "Bain à deux"),
        WordPair(a: "Suçon", b: "Morsure")
    ]
}
