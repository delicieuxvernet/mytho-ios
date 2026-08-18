import Foundation

// MARK: - La carte

/// Un dilemme : deux options, aucune bonne réponse (spec §4.4).
///
/// **Critère de tri d'une carte.** Les deux options doivent être aussi mauvaises
/// — ou aussi désirables — l'une que l'autre. Si la réponse est évidente pour
/// tout le monde, la carte est ratée : pas de débat, donc pas de jeu. Test :
/// faire voter cinq personnes ; si les cinq choisissent pareil, la carte dégage.
struct Dilemma: Identifiable, Hashable, Sendable {
    /// Stable et jamais réattribué : c'est lui que la mémoire du paquet retient
    /// pour ne pas ressortir la carte avant 70 % du tour (spec §2.4). Réordonner
    /// le contenu ne doit donc jamais décaler les identifiants.
    let id: String
    let a: String
    let b: String

    func text(_ side: DilemmaSide) -> String { side == .a ? a : b }
}

// MARK: - Le paquet

/// Les 50 dilemmes de « Tu préfères ? » (25 de base + 25 Extrême) : vérifié à
/// la compilation, relisible en diff de PR (spec §1.2).
///
/// **Règles d'écriture appliquées** (spec §8) : une carte = une idée, tutoiement
/// systématique, aucune référence datée, aucune personne réelle, rien qui vise
/// une caractéristique protégée. L'app est classée 4+ : aucune mention d'alcool,
/// de tabac, de drogue, de sexe ni de violence, dans aucune carte.
///
/// Pas de packs ici, contrairement au « plus susceptible de » (§3.5) et à « je
/// n'ai jamais » (§5.5) : la spec n'en prévoit pas pour ce jeu, et un paquet
/// unique de 200 tient déjà treize soirées sans répétition.
enum WouldYouRatherBank {

    /// Le paquet complet, dans l'ordre des identifiants.
    ///
    /// Assemblé en plusieurs affectations plutôt qu'en une addition de neuf
    /// tableaux : le vérificateur de types s'étrangle sur les expressions
    /// littérales trop longues.
    /// Le paquet complet, dans l'ordre des identifiants.
    static let all: [Dilemma] = base

    // MARK: Paquet de base

    private static let base: [Dilemma] = [
        Dilemma(id: "wyr_001", a: "Nager dans une piscine de caca mou", b: "Nager dans une piscine de vomi"),
        Dilemma(id: "wyr_002", a: "Vomir des limaces", b: "Chier des cafards qui te gratouillent l'anus"),
        Dilemma(id: "wyr_003", a: "Lécher le sol des toilettes d'une boîte", b: "Boire l'eau d'un vase de trois semaines"),
        Dilemma(id: "wyr_004", a: "Plus jamais de papier toilette", b: "Plus jamais te brosser les dents"),
        Dilemma(id: "wyr_005", a: "Transpirer de la mayonnaise en permanence", b: "Pleurer du vinaigre"),
        Dilemma(id: "wyr_006", a: "Une haleine de vomi permanente", b: "Sentir le poisson pourri en permanence"),
        Dilemma(id: "wyr_007", a: "Chier de la confiture", b: "Pisser de la mayonnaise"),
        Dilemma(id: "wyr_008", a: "La langue d'un chien", b: "Les dents d'un cheval"),
        Dilemma(id: "wyr_009", a: "Ton prochain pet est un vrai caca", b: "Ton prochain rot est du vomi"),
        Dilemma(id: "wyr_010", a: "Manger une couche usagée", b: "Boire un verre de pipi de quelqu'un d'ici"),
        Dilemma(id: "wyr_011", a: "Péter par la bouche", b: "Roter par les fesses"),
        Dilemma(id: "wyr_012", a: "Des ongles à la place des dents", b: "Des dents à la place des ongles"),
        Dilemma(id: "wyr_013", a: "Ton visage sur tes fesses", b: "Tes fesses sur ton visage"),
        Dilemma(id: "wyr_014", a: "Que tes crottes de nez aient un goût de chips", b: "Que les chips aient un goût de crotte de nez"),
        Dilemma(id: "wyr_015", a: "Péter dès que tu ris", b: "Rire dès que tu pètes"),
        Dilemma(id: "wyr_016", a: "Transpirer de la morve", b: "Te moucher de la sueur"),
        Dilemma(id: "wyr_017", a: "Sentir l'aisselle de tous les gens d'ici", b: "Que tous sentent la tienne, un par un"),
        Dilemma(id: "wyr_018", a: "Que tes cheveux poussent dans ton nez", b: "Que tes poils de nez poussent sur ta tête"),
        Dilemma(id: "wyr_019", a: "Que ton ventre gargouille pendant un enterrement", b: "Roter pendant le discours des mariés"),
        Dilemma(id: "wyr_020", a: "Que ton pet réveille tout l'avion", b: "Que ton voisin pète sur toi pendant huit heures"),
        Dilemma(id: "wyr_021", a: "Tomber amoureux tous les jours, jamais en retour", b: "Une seule fois, mais l'autre ne le saura jamais"),
        Dilemma(id: "wyr_022", a: "Des oreilles à la place des orteils", b: "Des orteils à la place des oreilles"),
        Dilemma(id: "wyr_023", a: "Que ta sueur sente le fromage", b: "Que ton fromage sente la sueur"),
        Dilemma(id: "wyr_024", a: "Pleurer par le nez", b: "Se moucher par les yeux"),
        Dilemma(id: "wyr_025", a: "Baver sur l'épaule de ton patron en dormant", b: "Que ton patron bave sur la tienne")
    ]

    // MARK: Pack Extrême (18+)

    /// 25 dilemmes 18+, hors du paquet de base : dégoût assumé, honte
    /// sociale, intime cru, absurde corporel. Verrouillé derrière la
    /// confirmation d'âge — et jamais graphique (règle 1.1.4).
    static let extreme: [Dilemma] = [
        Dilemma(id: "wyr_026", a: "Boire un litre de règles", b: "Boire un litre de sperme"),
        Dilemma(id: "wyr_027", a: "Des bites à la place des dents", b: "Chier de la mayonnaise"),
        Dilemma(id: "wyr_028", a: "Que tes parents te surprennent en plein acte", b: "Surprendre tes parents en plein acte"),
        Dilemma(id: "wyr_029", a: "Des poils pubiens à la place des dents", b: "Des dents à la place des poils pubiens"),
        Dilemma(id: "wyr_030", a: "Un pénis de la taille d'un téton", b: "Des tétons de la taille d'un pénis"),
        Dilemma(id: "wyr_031", a: "Qu'on entende tes pensées pendant l'amour", b: "Entendre celles de l'autre sans pouvoir répondre"),
        Dilemma(id: "wyr_032", a: "Un an d'abstinence totale", b: "Une nuit avec quelqu'un d'ici, tiré au sort"),
        Dilemma(id: "wyr_033", a: "Gémir à chaque éternuement", b: "Éternuer à chaque moment intime"),
        Dilemma(id: "wyr_034", a: "Ton plan d'hier devient ton boss lundi", b: "Le rencard de ta mère samedi"),
        Dilemma(id: "wyr_035", a: "Finir tous les fonds de verre de la soirée", b: "Lécher le comptoir du bar en entier"),
        Dilemma(id: "wyr_036", a: "Revivre ta pire cuite chaque samedi", b: "Ne plus jamais boire une goutte"),
        Dilemma(id: "wyr_037", a: "Dire ton nombre exact à tes parents", b: "Que tes parents te disent le leur"),
        Dilemma(id: "wyr_038", a: "Que ta peuff ait un goût de paff", b: "Que ta paff ait un goût de peuff"),
        Dilemma(id: "wyr_039", a: "Pleurer bruyamment à chaque orgasme", b: "Rire aux éclats à chaque enterrement"),
        Dilemma(id: "wyr_040", a: "Une seule fois par an, mais parfaite", b: "Tous les jours, toujours moyen"),
        Dilemma(id: "wyr_041", a: "Que ça dure 30 secondes à vie", b: "Que ça dure 3 heures obligatoires"),
        Dilemma(id: "wyr_042", a: "Faire l'amour devant tes beaux-parents une fois", b: "Les entendre à chaque fois"),
        Dilemma(id: "wyr_043", a: "Refaire ta première fois devant témoins", b: "La raconter en détail à ta famille"),
        Dilemma(id: "wyr_044", a: "Roter au premier baiser", b: "Éternuer dans le cou à chaque câlin"),
        Dilemma(id: "wyr_045", a: "Péter pendant un massage en couple", b: "Pendant une demande en mariage"),
        Dilemma(id: "wyr_046", a: "Faire ça dans le lit de tes parents", b: "Que tes parents le fassent dans le tien"),
        Dilemma(id: "wyr_047", a: "Vomir sur ton crush", b: "Que ton crush vomisse sur toi"),
        Dilemma(id: "wyr_048", a: "Danser nu une minute en boîte", b: "Courir nu autour du pâté de maisons"),
        Dilemma(id: "wyr_049", a: "Passer une nuit menotté à un inconnu", b: "À ton ex le plus toxique"),
        Dilemma(id: "wyr_050", a: "Zéro préliminaires pour toujours", b: "Rien que ça, jamais la suite")
    ]

    /// Le paquet effectivement joué : la base, plus l'Extrême si l'âge est
    /// confirmé ET que la table l'a activé. Le verrou se vérifie ici, pas dans
    /// la vue — un réglage sauvegardé ne rouvre pas un pack refermé.
    static func dilemmas(adultUnlocked: Bool, extremeEnabled: Bool) -> [Dilemma] {
        guard adultUnlocked, extremeEnabled else { return all }
        return all + extreme
    }
}
