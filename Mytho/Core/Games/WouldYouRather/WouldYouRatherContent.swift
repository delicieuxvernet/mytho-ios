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

/// Les 61 dilemmes de « Tu préfères ? » (28 de base + 33 Extrême) : vérifié à
/// la compilation, relisible en diff de PR (spec §1.2).
///
/// Les identifiants ne sont **jamais réattribués** : une carte retirée emporte
/// son numéro dans la tombe, une carte qui arrive prend le numéro suivant. D'où
/// les trous dans la suite. C'est ce qui permet à la mémoire du paquet de rester
/// juste pour toutes les cartes conservées — renuméroter reviendrait à faire
/// ressortir aussitôt des cartes vues hier soir.
///
/// **Règles d'écriture appliquées** (spec §8) : une carte = une idée, tutoiement
/// systématique, aucune référence datée, aucune personne réelle, rien qui vise
/// une caractéristique protégée. L'app est classée 17+ : le paquet de base
/// assume le trash corporel mais reste jouable sans la confirmation d'âge —
/// ni sexe, ni alcool, ni drogue — et tout le cru vit dans l'Extrême.
///
/// Deux paquets, comme les deux autres jeux de cartes : le verrou d'âge se
/// vérifie dans `dilemmas(adultUnlocked:extremeEnabled:)`, jamais dans la vue.
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
        Dilemma(id: "wyr_004", a: "Plus jamais de papier toilette", b: "Plus jamais te brosser les dents"),
        Dilemma(id: "wyr_007", a: "Chier de la confiture", b: "Pisser de la mayonnaise"),
        Dilemma(id: "wyr_009", a: "Ton prochain pet est un vrai caca", b: "Ton prochain rot est du vomi"),
        Dilemma(id: "wyr_011", a: "Péter par la bouche", b: "Roter par les fesses"),
        Dilemma(id: "wyr_012", a: "Des ongles à la place des dents", b: "Des dents à la place des ongles"),
        Dilemma(id: "wyr_013", a: "Ton visage sur tes fesses", b: "Tes fesses sur ton visage"),
        Dilemma(id: "wyr_014", a: "Que tes crottes de nez aient un goût de chips", b: "Que les chips aient un goût de crotte de nez"),
        Dilemma(id: "wyr_015", a: "Péter dès que tu ris", b: "Rire dès que tu pètes"),
        Dilemma(id: "wyr_016", a: "Transpirer de la morve", b: "Te moucher de la sueur"),
        Dilemma(id: "wyr_017", a: "Sentir l'aisselle de tous les gens d'ici", b: "Que tous sentent la tienne, un par un"),
        Dilemma(id: "wyr_018", a: "Que tes cheveux poussent dans ton nez", b: "Que tes poils de nez poussent sur ta tête"),
        Dilemma(id: "wyr_022", a: "Des oreilles à la place des orteils", b: "Des orteils à la place des oreilles"),
        Dilemma(id: "wyr_025", a: "Baver sur l'épaule de ton patron en dormant", b: "Que ton patron bave sur la tienne"),

        // Vague du 20 août 2026. Douze cartes sont parties : du dégoût posé
        // côte à côte sans torsion (piscine de caca, haleine de vomi), et des
        // dilemmes où toute la table choisissait pareil — un choix évident
        // n'est pas un choix. Ce qui arrive vise le miroir, la figure du pack
        // Extrême validée par Arthur : les deux moitiés inversent les mêmes
        // éléments et coûtent exactement le même prix.
        Dilemma(id: "wyr_051", a: "Surprendre ton coloc assis sur les toilettes", b: "Que ton coloc te surprenne sur les toilettes"),
        Dilemma(id: "wyr_052", a: "Éternuer dans la bouche de ton crush", b: "Que ton crush éternue dans la tienne"),
        Dilemma(id: "wyr_053", a: "Une langue de la taille d'un bras", b: "Des bras de la taille d'une langue"),
        Dilemma(id: "wyr_054", a: "Que ta peau ait la texture d'une langue", b: "Que ta langue ait la texture d'une peau"),
        Dilemma(id: "wyr_055", a: "Que ta bouche sente les pieds", b: "Que tes pieds sentent la bouche"),
        Dilemma(id: "wyr_056", a: "Manger ta soupe dans la cuvette des toilettes", b: "Faire caca dans ton assiette préférée"),
        Dilemma(id: "wyr_057", a: "Utiliser la brosse à dents de quelqu'un d'ici", b: "Que quelqu'un d'ici utilise la tienne"),
        Dilemma(id: "wyr_058", a: "Faire pipi dans le lit de ton meilleur ami", b: "Qu'il fasse pipi dans le tien"),
        Dilemma(id: "wyr_059", a: "Te faire moucher par ta mère devant tes potes", b: "Devoir moucher ta mère devant tes potes"),
        Dilemma(id: "wyr_060", a: "Ne plus jamais pouvoir péter", b: "Ne plus jamais pouvoir t'arrêter de péter"),
        Dilemma(id: "wyr_061", a: "Un bouton sur le nez chaque jour à vie", b: "Cent boutons d'un coup une fois par an"),
        Dilemma(id: "wyr_062", a: "Te faire dessus pendant ton entretien d'embauche", b: "Vomir pendant ton discours de témoin de mariage"),
        Dilemma(id: "wyr_063", a: "Péter très fort pendant la minute de silence", b: "Éternuer plein de morve sur le cercueil"),
        Dilemma(id: "wyr_064", a: "Boucher les toilettes chez ton crush", b: "Que ton crush t'entende depuis le salon"),
        Dilemma(id: "wyr_065", a: "Chier dix fois par jour, trente secondes", b: "Chier une fois par semaine, mais trois heures")
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
        Dilemma(id: "wyr_032", a: "Un an d'abstinence totale", b: "Une nuit avec quelqu'un d'ici, s'il est d'accord"),
        Dilemma(id: "wyr_033", a: "Gémir à chaque éternuement", b: "Éternuer à chaque moment intime"),
        Dilemma(id: "wyr_034", a: "Ton plan d'hier devient ton boss lundi", b: "Le rencard de ta mère samedi"),
        Dilemma(id: "wyr_036", a: "Revivre ta pire cuite chaque samedi", b: "Ne plus jamais boire une goutte"),
        Dilemma(id: "wyr_037", a: "Dire ton nombre exact à tes parents", b: "Que tes parents te disent le leur"),
        Dilemma(id: "wyr_038", a: "Que ta peuff ait un goût de paff", b: "Que ta paff ait un goût de peuff"),
        Dilemma(id: "wyr_039", a: "Pleurer bruyamment à chaque orgasme", b: "Rire aux éclats à chaque enterrement"),
        Dilemma(id: "wyr_040", a: "Une seule fois par an, mais parfaite", b: "Tous les jours, toujours moyen"),
        Dilemma(id: "wyr_041", a: "Que ça dure 30 secondes à vie", b: "Que ça dure 3 heures obligatoires"),
        Dilemma(id: "wyr_042", a: "Que tes beaux-parents t'entendent une seule fois", b: "Les entendre à chaque fois"),
        Dilemma(id: "wyr_043", a: "Refaire ta pire nuit devant témoins", b: "La raconter en détail à toute la table"),
        Dilemma(id: "wyr_044", a: "Roter au premier baiser", b: "Éternuer dans le cou à chaque câlin"),
        Dilemma(id: "wyr_045", a: "Péter pendant un massage en couple", b: "Pendant une demande en mariage"),
        Dilemma(id: "wyr_046", a: "Faire ça dans le lit de tes parents", b: "Que tes parents le fassent dans le tien"),
        Dilemma(id: "wyr_047", a: "Vomir sur ton crush", b: "Que ton crush vomisse sur toi"),
        Dilemma(id: "wyr_048", a: "Danser nu une minute en boîte", b: "Courir nu autour du pâté de maisons"),
        Dilemma(id: "wyr_049", a: "Passer une nuit menotté à un inconnu", b: "À ton ex le plus toxique"),
        Dilemma(id: "wyr_050", a: "Zéro préliminaires pour toujours", b: "Rien que ça, jamais la suite"),

        // Vague du 20 août 2026. Une seule carte est partie (« fonds de verre /
        // comptoir du bar » : du dégoût posé, sans inversion) — ce pack est la
        // référence de goût validée par Arthur, on y ajoute plus qu'on n'y
        // coupe. Les neuf qui arrivent sont toutes bâties sur le miroir ou sur
        // le chiffre, les deux ressorts de ses cartes préférées.
        Dilemma(id: "wyr_066", a: "Pisser à chaque fois que tu jouis", b: "Jouir à chaque fois que tu pisses"),
        Dilemma(id: "wyr_067", a: "Crier le prénom de ton ex pendant l'amour", b: "Que l'autre crie celui de son ex"),
        Dilemma(id: "wyr_068", a: "Que ta belle-mère trouve ton sextoy", b: "Trouver celui de ta belle-mère"),
        Dilemma(id: "wyr_069", a: "Pisser au lit chez ton plan d'un soir", b: "Que ton plan pisse au lit chez toi"),
        Dilemma(id: "wyr_070", a: "Boire uniquement dans le verre des autres", b: "Que tout le monde boive dans le tien"),
        Dilemma(id: "wyr_071", a: "Un corps de 20 ans, une libido de 80 ans", b: "Un corps de 80 ans, une libido de 20 ans"),
        Dilemma(id: "wyr_072", a: "Devoir annoncer chaque pet 10 secondes avant", b: "Annoncer chaque orgasme 10 secondes avant"),
        Dilemma(id: "wyr_073", a: "Laisser flotter ton étron chez ton crush", b: "Lui demander un débouche-chiottes"),
        Dilemma(id: "wyr_074", a: "Puer le sexe au baptême de ton neveu", b: "Puer la merde à ton premier rencard")
    ]

    /// Le paquet effectivement joué : la base, plus l'Extrême si l'âge est
    /// confirmé ET que la table l'a activé. Le verrou se vérifie ici, pas dans
    /// la vue — un réglage sauvegardé ne rouvre pas un pack refermé.
    static func dilemmas(adultUnlocked: Bool, extremeEnabled: Bool) -> [Dilemma] {
        guard adultUnlocked, extremeEnabled else { return all }
        return all + extreme
    }
}
