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
    ///
    /// Le verrou 18+ s'applique **ici** et pas seulement dans la vue : une table
    /// qui a coché « Soirée » puis refermé le contenu adulte dans les réglages
    /// ne doit plus en voir une seule carte. Le défaut est le verrou fermé —
    /// un appelant qui oublie l'argument obtient le paquet tout public.
    static func cards(for packs: Set<MostLikelyPack>, adultUnlocked: Bool = false) -> [MostLikelyCard] {
        let selected = MostLikelyPack.allCases
            .filter { packs.contains($0) && (!$0.isLocked || adultUnlocked) }
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
        MostLikelyCard(id: "mst_006", text: "avoir l'haleine qui sent les pieds et les pieds qui sentent l'haleine"),
        MostLikelyCard(id: "mst_007", text: "roter en croyant péter, et péter en croyant roter"),
        MostLikelyCard(id: "mst_008", text: "se plaindre que les autres mâchent fort en mangeant comme un aspirateur"),
        MostLikelyCard(id: "mst_009", text: "avoir des larmes qui sentent l'œuf dès qu'un film devient triste"),
        MostLikelyCard(id: "mst_010", text: "perdre assez de cheveux dans la douche pour tricoter un pull"),
        MostLikelyCard(id: "mst_011", text: "avoir des ongles de pieds qui trouent les draps en une nuit"),
        MostLikelyCard(id: "mst_012", text: "péter dans l'ascenseur et sortir juste avant que ça arrive aux autres"),
        MostLikelyCard(id: "mst_013", text: "péter pendant la minute de silence et faire semblant d'être ému"),
        MostLikelyCard(id: "mst_014", text: "postillonner sur toute la table dès qu'il raconte un truc passionnant"),
        MostLikelyCard(id: "mst_015", text: "se moucher dans la serviette de table et la reposer bien pliée"),
        MostLikelyCard(id: "mst_016", text: "se faire pipi dessus en riant et continuer la soirée comme si de rien"),
        MostLikelyCard(id: "mst_017", text: "vomir sur le gâteau juste après avoir soufflé les bougies"),
        MostLikelyCard(id: "mst_018", text: "se curer le nez au feu rouge en croyant que les vitres sont opaques"),
        MostLikelyCard(id: "mst_019", text: "avoir un bouton qui explose pile pendant une photo de groupe"),
        MostLikelyCard(id: "mst_020", text: "perdre une dent dans l'assiette de son voisin et continuer à manger")
    ]

    // MARK: - Soirée (18+)

    static let soireeCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_021", text: "se faire attraper en train de se toucher aux toilettes"),
        MostLikelyCard(id: "mst_022", text: "avoir un historique porno à nettoyer en panique"),
        MostLikelyCard(id: "mst_023", text: "vomir dans un taxi et laisser 2 euros de pourboire"),
        MostLikelyCard(id: "mst_024", text: "dormir nu et se réveiller dans un lit inconnu"),
        MostLikelyCard(id: "mst_025", text: "se faire surprendre en train de se branler ou se doigter"),
        MostLikelyCard(id: "mst_026", text: "envoyer un nude à la mauvaise personne et un bonjour poli à la bonne"),
        MostLikelyCard(id: "mst_027", text: "quitter quelqu'un par message et se faire quitter par le même message"),
        MostLikelyCard(id: "mst_028", text: "bloquer son ex à 2h, le débloquer à 4h, le rebloquer à 6h"),
        MostLikelyCard(id: "mst_029", text: "jurer à toute la table que c'est fini avec son ex et repartir chez son ex"),
        MostLikelyCard(id: "mst_030", text: "proposer un plan à trois à 4h du matin et le regretter à 4h02"),
        MostLikelyCard(id: "mst_031", text: "jurer de tenir très bien l'alcool et finir à genoux devant les toilettes"),
        MostLikelyCard(id: "mst_032", text: "rentrer avec quelqu'un ce soir et jurer demain qu'il ne s'est rien passé"),
        MostLikelyCard(id: "mst_033", text: "casser le lit de la chambre d'amis et le remonter en silence à 4h"),
        MostLikelyCard(id: "mst_034", text: "roter le prénom de quelqu'un de cette pièce"),
        MostLikelyCard(id: "mst_035", text: "jurer n'avoir bu que de l'eau et vomir bleu"),
        MostLikelyCard(id: "mst_036", text: "gémir tellement fort que les voisins tapent au mur avant le premier baiser"),
        MostLikelyCard(id: "mst_037", text: "avoir un hoquet qui ne s'arrête qu'après l'orgasme"),
        MostLikelyCard(id: "mst_038", text: "avoir déjà couché avec quelqu'un présent ce soir sans que la table le sache"),
        MostLikelyCard(id: "mst_039", text: "avoir simulé depuis le tout premier soir"),
        MostLikelyCard(id: "mst_040", text: "finir dans le lit de quelqu'un de cette pièce avant la fin de la soirée"),
        MostLikelyCard(id: "mst_041", text: "embrasser deux personnes de cette pièce dans la même soirée sans que ça se sache"),
        MostLikelyCard(id: "mst_042", text: "se réveiller à poil dans le couloir de l'immeuble, porte claquée"),
        MostLikelyCard(id: "mst_043", text: "se réveiller avec 47 messages envoyés à son ex et aucun souvenir"),
        MostLikelyCard(id: "mst_044", text: "tomber amoureux de la personne qui lui tient les cheveux au-dessus des toilettes"),
        MostLikelyCard(id: "mst_045", text: "promettre de ne rien dire et raconter sa nuit à toute la table au brunch")
    ]
}
