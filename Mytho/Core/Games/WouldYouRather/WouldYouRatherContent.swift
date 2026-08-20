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

/// Les 41 dilemmes de « Tu préfères ? » (17 de base + 24 Extrême) : vérifié à
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

        // Vague du 20 août 2026. Douze cartes sont parties : du dégoût posé
        // côte à côte sans torsion (piscine de caca, haleine de vomi), et des
        // dilemmes où toute la table choisissait pareil — un choix évident
        // n'est pas un choix. Ce qui arrive vise le miroir, la figure du pack
        // Extrême validée par Arthur : les deux moitiés inversent les mêmes
        // éléments et coûtent exactement le même prix.
        Dilemma(id: "wyr_065", a: "Chier dix fois par jour, trente secondes", b: "Chier une fois par semaine, mais trois heures"),
        // Vague du 20 août 2026, ecrite au registre des cartes qu'Arthur a
        // gardees : permutation corporelle, substitution de matiere, chiffre.
        // Le registre « pire moment social » en est absent, il l'a balaye.
        Dilemma(id: "wyr_264", a: "Haleine de poubelle, dents parfaites", b: "Dents pourries, haleine de menthe"),
        Dilemma(id: "wyr_265", a: "Des pets muets qui sentent les enfers", b: "Des pets bruyants qui ne sentent rien"),
        Dilemma(id: "wyr_268", a: "Tes doigts sentent le poisson à vie", b: "Ton haleine sent l'ail à vie"),
        // Vague 2 du 20 août 2026 : le corps REEL, celui que tout le monde a
        // deja subi. Le corps imaginaire (nombril, coude, aisselle) et la
        // substitution alimentaire ont ete jetes en bloc au tri precedent.
        Dilemma(id: "wyr_293", a: "Ne plus jamais fermer la porte des toilettes", b: "Ne plus jamais pouvoir tirer la chasse"),
        Dilemma(id: "wyr_294", a: "Puer sans jamais t'en rendre compte", b: "Le savoir et ne rien pouvoir y faire"),
        Dilemma(id: "wyr_295", a: "N'aller qu'aux toilettes publiques, toute ta vie", b: "N'y aller que chez les autres, jamais chez toi"),
        Dilemma(id: "wyr_296", a: "Que tes pets sortent avec le son de ta voix", b: "Que ta voix sorte avec le bruit d'un pet"),
        Dilemma(id: "wyr_297", a: "Faire pipi au lit une fois par mois", b: "Une petite fuite en public une fois par an"),
        Dilemma(id: "wyr_298", a: "Perdre une dent par an, elle repousse en un mois", b: "Garder toutes tes dents, mais bien jaunes à vie"),
        Dilemma(id: "wyr_299", a: "Un monosourcil bien épais, à vie", b: "Plus aucun sourcil, ni cils, à vie")
    ]

    // MARK: Pack Extrême (18+)

    /// 25 dilemmes 18+, hors du paquet de base : dégoût assumé, honte
    /// sociale, intime cru, absurde corporel. Verrouillé derrière la
    /// confirmation d'âge — et jamais graphique (règle 1.1.4).
    static let extreme: [Dilemma] = [
        Dilemma(id: "wyr_026", a: "Boire un litre de règles", b: "Boire un litre de sperme"),
        Dilemma(id: "wyr_030", a: "Un pénis de la taille d'un téton", b: "Des tétons de la taille d'un pénis"),
        Dilemma(id: "wyr_036", a: "Revivre ta pire cuite chaque samedi", b: "Ne plus jamais boire une goutte"),
        Dilemma(id: "wyr_037", a: "Dire ton nombre exact à tes parents", b: "Que tes parents te disent le leur"),
        Dilemma(id: "wyr_038", a: "Que ta peuff ait un goût de paff", b: "Que ta paff ait un goût de peuff"),
        Dilemma(id: "wyr_039", a: "Pleurer bruyamment à chaque orgasme", b: "Rire aux éclats à chaque enterrement"),
        Dilemma(id: "wyr_041", a: "Que ça dure 30 secondes à vie", b: "Que ça dure 3 heures obligatoires"),
        Dilemma(id: "wyr_050", a: "Zéro préliminaires pour toujours", b: "Rien que ça, jamais la suite"),

        // Vague du 20 août 2026. Une seule carte est partie (« fonds de verre /
        // comptoir du bar » : du dégoût posé, sans inversion) — ce pack est la
        // référence de goût validée par Arthur, on y ajoute plus qu'on n'y
        // coupe. Les neuf qui arrivent sont toutes bâties sur le miroir ou sur
        // le chiffre, les deux ressorts de ses cartes préférées.
        Dilemma(id: "wyr_067", a: "Crier le prénom de ton ex pendant l'amour", b: "Que l'autre crie celui de son ex"),
        // Vague du 20 août 2026 : les cinq ressorts, en version 18+.
        Dilemma(id: "wyr_273", a: "Ton nez à la place de ton sexe", b: "Ton sexe à la place de ton nez"),
        Dilemma(id: "wyr_277", a: "Des poils de cul à la place des cheveux", b: "Des cheveux à la place des poils de cul"),
        Dilemma(id: "wyr_278", a: "Que chaque orgasme te fasse péter", b: "Que chaque pet te fasse jouir"),
        Dilemma(id: "wyr_286", a: "Coucher une fois tous les dix ans", b: "Six fois par jour, sans jamais finir"),
        Dilemma(id: "wyr_288", a: "Une gueule de bois de trois jours chaque mois", b: "Une petite gueule de bois tous les matins"),
        // Vague 2 du 20 août 2026 : la vie sexuelle reelle — frequence, duree,
        // ratages, bruits, lendemains. Rien d'invente.
        Dilemma(id: "wyr_300", a: "Une panne à chaque première fois", b: "Finir en dix secondes à chaque première fois"),
        Dilemma(id: "wyr_301", a: "Simuler à chaque fois, toute ta vie", b: "Savoir que l'autre a toujours simulé"),
        Dilemma(id: "wyr_302", a: "Que tout l'immeuble t'entende jouir", b: "Ne plus jamais pouvoir faire le moindre bruit"),
        Dilemma(id: "wyr_303", a: "Te réveiller chaque dimanche sans savoir où", b: "Te souvenir de tout ce que tu fais bourré"),
        Dilemma(id: "wyr_304", a: "Un bruit de pet à chaque coup de reins", b: "Un rot sonore à chaque baiser"),
        Dilemma(id: "wyr_305", a: "Ne plus jamais changer de position", b: "Ne jamais pouvoir refaire la même deux fois"),
        Dilemma(id: "wyr_306", a: "Être celui qui pleure à chaque soirée", b: "Être celui qui gerbe à chaque soirée"),
        Dilemma(id: "wyr_307", a: "Que ce soit toujours trop sec", b: "Que ce soit toujours trop mouillé"),
        Dilemma(id: "wyr_308", a: "Perdre un cheveu à chaque orgasme", b: "Perdre un cheveu à chaque verre d'alcool"),
        Dilemma(id: "wyr_309", a: "Que ton haleine sente toujours le sexe", b: "Que ton sexe sente l'haleine du matin")
    ]

    /// Le paquet effectivement joué : la base, plus l'Extrême si l'âge est
    /// confirmé ET que la table l'a activé. Le verrou se vérifie ici, pas dans
    /// la vue — un réglage sauvegardé ne rouvre pas un pack refermé.
    static func dilemmas(adultUnlocked: Bool, extremeEnabled: Bool) -> [Dilemma] {
        guard adultUnlocked, extremeEnabled else { return all }
        return all + extreme
    }
}
