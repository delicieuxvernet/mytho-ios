import Foundation

// MARK: - Carte

/// Une carte du « plus susceptible de… ».
///
/// Le préfixe « Le plus susceptible de… » vit dans l'interface et **jamais dans
/// la donnée** (spec §3.5) : le texte commence par un verbe à l'infinitif, sans
/// majuscule ni point final. Une carte qui ne passe pas ce test est mal écrite —
/// et `MostLikelyTests` le vérifie.
///
/// `Identifiable` en plus de la forme donnée par la spec : c'est ce qui permet à
/// `Deck` de mémoriser les cartes vues sans qu'on ait à lui fournir une clé.
struct MostLikelyCard: Identifiable, Hashable, Sendable {
    let id: String
    let text: String
}

// MARK: - Packs

/// Les deux paquets du jeu (écrémage d'Arthur du 17 août) : peu de cartes,
/// que des essentielles. Le contenu se stocke en Swift et pas en JSON
/// (spec §1.2) : vérifié à la compilation, relisible en diff de PR.
enum MostLikelyPack: String, CaseIterable, Identifiable, Sendable {
    /// 20 cartes tout public : les hontes physiques qu'on nie en public.
    case potes
    /// 25 cartes 18+ : la soirée qui dérape, assumée.
    case soiree

    var id: String { rawValue }

    var name: String {
        switch self {
        case .potes: return "Entre potes"
        case .soiree: return "Soirée"
        }
    }

    var subtitle: String {
        switch self {
        case .potes: return "Les hontes physiques qu'on nie en public."
        case .soiree: return "Interdit aux mineurs. La soirée qui dérape, assumée."
        }
    }

    var symbol: String {
        switch self {
        case .potes: return "person.3.fill"
        case .soiree: return "flame.fill"
        }
    }

    /// Seul « Soirée » est verrouillé. Le déverrouillage passe par la
    /// confirmation d'âge des réglages — la fiche App Store est classée 17+.
    var isLocked: Bool { self == .soiree }

    var cards: [MostLikelyCard] {
        switch self {
        case .potes: return MostLikelyBank.potesCards
        case .soiree: return MostLikelyBank.soireeCards
        }
    }

    /// Le paquet ouvert est pré-coché ; « Soirée » se choisit par le bandeau.
    static let defaultSelection: Set<MostLikelyPack> = [.potes]

    /// Un paquet verrouillé n'est pas seulement grisé : il n'apparaît pas.
    static func available(unlockedExtras: Bool) -> [MostLikelyPack] {
        allCases.filter { unlockedExtras || !$0.isLocked }
    }
}

// MARK: - Banque

/// Même forme que `WordBank` : des tableaux statiques, aucun décodage à
/// l'exécution, aucune erreur de parsing possible.
enum MostLikelyBank {

    static var all: [MostLikelyCard] { MostLikelyPack.allCases.flatMap(\.cards) }

    /// Les cartes des paquets choisis. Un réglage sauvegardé qui ne pointe plus
    /// sur rien retombe sur le paquet de base plutôt que de rendre une partie
    /// injouable.
    static func cards(for packs: Set<MostLikelyPack>) -> [MostLikelyCard] {
        let selected = MostLikelyPack.allCases
            .filter { packs.contains($0) }
            .flatMap(\.cards)
        return selected.isEmpty ? potesCards : selected
    }

    // MARK: - Entre potes

    static let potesCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_001", text: "se gratter l'entrejambe ou les fesses en public"),
        MostLikelyCard(id: "mst_002", text: "péter très fort en pleine conversation"),
        MostLikelyCard(id: "mst_003", text: "avoir déjà chié dans son pantalon en soirée"),
        MostLikelyCard(id: "mst_004", text: "avoir déjà pissé dans la douche de quelqu'un d'autre"),
        MostLikelyCard(id: "mst_005", text: "manger un truc immonde pour 10 euros"),
        MostLikelyCard(id: "mst_006", text: "renifler ses vêtements pour décider de les remettre"),
        MostLikelyCard(id: "mst_007", text: "se curer le nez au feu rouge en se croyant invisible"),
        MostLikelyCard(id: "mst_008", text: "péter dans l'ascenseur et accuser quelqu'un d'autre"),
        MostLikelyCard(id: "mst_009", text: "se gratter puis renifler ses doigts"),
        MostLikelyCard(id: "mst_010", text: "tirer la chasse avec le pied dans les toilettes publiques"),
        MostLikelyCard(id: "mst_011", text: "manger un truc tombé bien au-delà des cinq secondes"),
        MostLikelyCard(id: "mst_012", text: "roter l'alphabet sur demande"),
        MostLikelyCard(id: "mst_013", text: "garder le même caleçon deux jours « par logistique »"),
        MostLikelyCard(id: "mst_014", text: "faire semblant de se laver les mains quand il y a du monde"),
        MostLikelyCard(id: "mst_015", text: "boucher les toilettes d'une soirée et partir sans rien dire"),
        MostLikelyCard(id: "mst_016", text: "vomir et reprendre la soirée comme si de rien n'était"),
        MostLikelyCard(id: "mst_017", text: "se moucher dans son tee-shirt en festival"),
        MostLikelyCard(id: "mst_018", text: "avoir une odeur de pieds qui arrive avant lui"),
        MostLikelyCard(id: "mst_019", text: "lécher son assiette au restaurant"),
        MostLikelyCard(id: "mst_020", text: "uriner dans une bouteille en covoiturage")
    ]

    // MARK: - Soirée (18+)

    static let soireeCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_021", text: "coucher avec l'ex de quelqu'un de cette table"),
        MostLikelyCard(id: "mst_022", text: "finir dans le lit de quelqu'un de cette pièce ce soir"),
        MostLikelyCard(id: "mst_023", text: "envoyer un sexto pendant ce jeu"),
        MostLikelyCard(id: "mst_024", text: "avoir déjà simulé — et le nier maintenant"),
        MostLikelyCard(id: "mst_025", text: "draguer le serveur ou la serveuse devant tout le monde"),
        MostLikelyCard(id: "mst_026", text: "repartir avec quelqu'un ce soir"),
        MostLikelyCard(id: "mst_027", text: "avoir un plan cul régulier depuis des années"),
        MostLikelyCard(id: "mst_028", text: "avoir un contact enregistré sous un faux nom"),
        MostLikelyCard(id: "mst_029", text: "répondre à un « tu dors ? » ce soir même"),
        MostLikelyCard(id: "mst_030", text: "connaître son nombre exact — et mentir dessus"),
        MostLikelyCard(id: "mst_031", text: "avoir une sextape quelque part"),
        MostLikelyCard(id: "mst_032", text: "coucher le premier soir sans aucun regret"),
        MostLikelyCard(id: "mst_033", text: "embrasser quelqu'un ici si un gage le demandait"),
        MostLikelyCard(id: "mst_034", text: "finir bourré au mariage de quelqu'un d'autre"),
        MostLikelyCard(id: "mst_035", text: "pleurer bourré sur un ex"),
        MostLikelyCard(id: "mst_036", text: "appeler son ex après deux verres"),
        MostLikelyCard(id: "mst_037", text: "finir la soirée torse nu"),
        MostLikelyCard(id: "mst_038", text: "se réveiller avec un tatouage surprise"),
        MostLikelyCard(id: "mst_039", text: "se réveiller dans la mauvaise ville"),
        MostLikelyCard(id: "mst_040", text: "finir en garde à vue un soir de fête"),
        MostLikelyCard(id: "mst_041", text: "se faire attraper en train de se toucher aux toilettes"),
        MostLikelyCard(id: "mst_042", text: "avoir un historique porno à nettoyer en panique"),
        MostLikelyCard(id: "mst_043", text: "vomir dans un taxi et laisser 2 euros de pourboire"),
        MostLikelyCard(id: "mst_044", text: "dormir nu et se réveiller dans un lit inconnu"),
        MostLikelyCard(id: "mst_045", text: "se faire surprendre en train de se branler ou se doigter")
    ]
}
