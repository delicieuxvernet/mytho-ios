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
    /// 30 cartes tout public : les hontes du quotidien, désignées au doigt.
    case potes
    /// 30 cartes 18+ : la soirée qui dérape, assumée.
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
        case .potes: return "Les hontes du quotidien, désignées au doigt."
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
        MostLikelyCard(id: "mst_001", text: "oublier son propre anniversaire"),
        MostLikelyCard(id: "mst_002", text: "arriver en retard à son mariage"),
        MostLikelyCard(id: "mst_003", text: "faire un signe à quelqu'un qui saluait la personne derrière"),
        MostLikelyCard(id: "mst_004", text: "répondre « toi aussi » au serveur"),
        MostLikelyCard(id: "mst_005", text: "reposer discrètement l'objet qu'il vient de casser"),
        MostLikelyCard(id: "mst_006", text: "garder un yaourt périmé depuis six mois"),
        MostLikelyCard(id: "mst_007", text: "faire rire toute une salle par accident"),
        MostLikelyCard(id: "mst_008", text: "raconter la même histoire deux fois à la même personne"),
        MostLikelyCard(id: "mst_009", text: "regarder la suite de la série en douce sans l'avouer"),
        MostLikelyCard(id: "mst_010", text: "relancer la même série pour la huitième fois"),
        MostLikelyCard(id: "mst_011", text: "répondre à un message six jours plus tard"),
        MostLikelyCard(id: "mst_012", text: "envoyer « il est relou » à la personne concernée"),
        MostLikelyCard(id: "mst_013", text: "laisser un vocal de huit minutes sans aucune information"),
        MostLikelyCard(id: "mst_014", text: "laisser cent onglets ouverts"),
        MostLikelyCard(id: "mst_015", text: "réinitialiser son mot de passe à chaque connexion"),
        MostLikelyCard(id: "mst_016", text: "avoir toujours trois pour cent de batterie"),
        MostLikelyCard(id: "mst_017", text: "chercher son téléphone avec la lampe torche du téléphone"),
        MostLikelyCard(id: "mst_018", text: "régler douze réveils et tous les ignorer"),
        MostLikelyCard(id: "mst_019", text: "mettre « vu » et répondre dans sa tête"),
        MostLikelyCard(id: "mst_020", text: "se tromper de prénom en pleine phrase"),
        MostLikelyCard(id: "mst_021", text: "raconter un secret « à une seule personne » — puis à cinq"),
        MostLikelyCard(id: "mst_022", text: "se perdre avec le GPS allumé"),
        MostLikelyCard(id: "mst_023", text: "googler ses symptômes et se croire condamné"),
        MostLikelyCard(id: "mst_024", text: "pleurer devant une pub"),
        MostLikelyCard(id: "mst_025", text: "chanter faux avec une confiance totale"),
        MostLikelyCard(id: "mst_026", text: "parler à son animal comme à un humain"),
        MostLikelyCard(id: "mst_027", text: "supprimer une story dix minutes après"),
        MostLikelyCard(id: "mst_028", text: "s'inventer une vie devant le coiffeur"),
        MostLikelyCard(id: "mst_029", text: "mentir sur son temps d'écran"),
        MostLikelyCard(id: "mst_030", text: "finir une série en une nuit et le regretter à l'aube")
    ]

    // MARK: - Soirée (18+)

    static let soireeCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_031", text: "coucher avec l'ex de quelqu'un de cette table"),
        MostLikelyCard(id: "mst_032", text: "finir dans le lit de quelqu'un de cette pièce ce soir"),
        MostLikelyCard(id: "mst_033", text: "envoyer un sexto pendant ce jeu"),
        MostLikelyCard(id: "mst_034", text: "avoir déjà simulé — et le nier maintenant"),
        MostLikelyCard(id: "mst_035", text: "draguer le serveur ou la serveuse devant tout le monde"),
        MostLikelyCard(id: "mst_036", text: "repartir avec quelqu'un ce soir"),
        MostLikelyCard(id: "mst_037", text: "avoir un plan cul régulier depuis des années"),
        MostLikelyCard(id: "mst_038", text: "avoir un contact enregistré sous un faux nom"),
        MostLikelyCard(id: "mst_039", text: "répondre à un « tu dors ? » ce soir même"),
        MostLikelyCard(id: "mst_040", text: "connaître son nombre exact — et mentir dessus"),
        MostLikelyCard(id: "mst_041", text: "avoir une sextape quelque part"),
        MostLikelyCard(id: "mst_042", text: "coucher le premier soir sans aucun regret"),
        MostLikelyCard(id: "mst_043", text: "tomber amoureux d'un coup d'un soir"),
        MostLikelyCard(id: "mst_044", text: "confondre deux prénoms au pire moment"),
        MostLikelyCard(id: "mst_045", text: "draguer par vengeance"),
        MostLikelyCard(id: "mst_046", text: "embrasser quelqu'un ici si un gage le demandait"),
        MostLikelyCard(id: "mst_047", text: "rougir si on lisait son historique à voix haute"),
        MostLikelyCard(id: "mst_048", text: "finir bourré au mariage de quelqu'un d'autre"),
        MostLikelyCard(id: "mst_049", text: "pleurer bourré sur un ex"),
        MostLikelyCard(id: "mst_050", text: "appeler son ex après deux verres"),
        MostLikelyCard(id: "mst_051", text: "finir la soirée torse nu"),
        MostLikelyCard(id: "mst_052", text: "se réveiller avec un tatouage surprise"),
        MostLikelyCard(id: "mst_053", text: "se réveiller dans la mauvaise ville"),
        MostLikelyCard(id: "mst_054", text: "vomir dans un endroit qui ne se raconte pas"),
        MostLikelyCard(id: "mst_055", text: "tenir l'alcool moins bien qu'il le prétend"),
        MostLikelyCard(id: "mst_056", text: "resquiller la boîte et se faire sortir dix minutes après"),
        MostLikelyCard(id: "mst_057", text: "finir en garde à vue un soir de fête"),
        MostLikelyCard(id: "mst_058", text: "révéler un secret de quelqu'un pendant ce jeu"),
        MostLikelyCard(id: "mst_059", text: "quitter la soirée avec le pull d'un inconnu"),
        MostLikelyCard(id: "mst_060", text: "jurer « dernière soirée » avant la prochaine")
    ]
}
