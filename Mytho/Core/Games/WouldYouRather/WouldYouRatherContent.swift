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

/// Les 90 dilemmes de « Tu préfères ? » (50 de base + 40 Extrême) : vérifié à
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
        Dilemma(id: "wyr_001", a: "Manger la même chose tous les jours", b: "Ne jamais manger deux fois pareil"),
        Dilemma(id: "wyr_002", a: "Marcher pieds nus sur un jouet chaque matin", b: "Te cogner le petit orteil chaque soir"),
        Dilemma(id: "wyr_003", a: "Un ventre qui gargouille en entretien", b: "Un rire qui part au mauvais moment"),
        Dilemma(id: "wyr_004", a: "Un seul écouteur qui marche", b: "Un chargeur qui tient dans un angle précis"),
        Dilemma(id: "wyr_005", a: "Te faire spoiler chaque fin", b: "Ne jamais connaître la fin de rien"),
        Dilemma(id: "wyr_006", a: "Garder ta coupe de sixième à vie", b: "Reporter ta tenue de classe verte à vie"),
        Dilemma(id: "wyr_007", a: "Dormir dans des draps pleins de miettes", b: "Marcher sur du carrelage glacé au réveil"),
        Dilemma(id: "wyr_008", a: "Écrire comme un médecin sans le savoir", b: "Lire à voix haute tout ce que tu tapes"),
        Dilemma(id: "wyr_009", a: "Être réveillé chaque jour par une perceuse", b: "Être réveillé chaque jour par un moustique"),
        Dilemma(id: "wyr_010", a: "Avoir toujours un caillou dans la chaussure", b: "Avoir toujours une mèche dans l'œil"),
        Dilemma(id: "wyr_011", a: "Éternuer dix fois par heure", b: "Avoir le hoquet une heure par jour"),
        Dilemma(id: "wyr_012", a: "Avoir les mains toujours moites", b: "Avoir les lèvres toujours sèches"),
        Dilemma(id: "wyr_013", a: "Avoir toujours trop chaud aux pieds", b: "Avoir toujours froid aux mains"),
        Dilemma(id: "wyr_014", a: "Parler en criant tout le temps", b: "Parler en chuchotant tout le temps"),
        Dilemma(id: "wyr_015", a: "Marcher à reculons toute ta vie", b: "Sauter à cloche-pied toute ta vie"),
        Dilemma(id: "wyr_016", a: "Avoir des ongles qui poussent en une nuit", b: "Avoir des cheveux qui poussent en une nuit"),
        Dilemma(id: "wyr_017", a: "Ne jamais pouvoir te gratter", b: "Ne jamais pouvoir t'étirer"),
        Dilemma(id: "wyr_018", a: "Avoir une démarche de robot", b: "Avoir une voix de dessin animé"),
        Dilemma(id: "wyr_019", a: "Voir tout en noir et blanc", b: "Entendre tout avec un écho"),
        Dilemma(id: "wyr_020", a: "Bâiller toutes les cinq minutes", b: "Cligner des yeux deux fois plus vite"),
        Dilemma(id: "wyr_021", a: "Avoir une chanson coincée dans la tête", b: "Avoir une phrase qui tourne en boucle"),
        Dilemma(id: "wyr_022", a: "Avoir les cheveux mouillés en permanence", b: "Avoir les chaussettes humides en permanence"),
        Dilemma(id: "wyr_023", a: "Devoir marcher très lentement", b: "Devoir marcher très vite"),
        Dilemma(id: "wyr_024", a: "Devoir dormir assis", b: "Devoir dormir avec la lumière allumée"),
        Dilemma(id: "wyr_025", a: "Avoir la voix qui déraille quand tu es content", b: "Avoir le fou rire quand tu es sérieux"),
        Dilemma(id: "wyr_026", a: "Pouvoir voler", b: "Pouvoir devenir invisible"),
        Dilemma(id: "wyr_027", a: "Pouvoir respirer sous l'eau", b: "Pouvoir marcher sur les murs"),
        Dilemma(id: "wyr_028", a: "Parler toutes les langues", b: "Parler avec les animaux"),
        Dilemma(id: "wyr_029", a: "Arrêter le temps dix secondes", b: "Revenir dix secondes en arrière"),
        Dilemma(id: "wyr_030", a: "Lire dans les pensées", b: "Voir une minute dans le futur"),
        Dilemma(id: "wyr_031", a: "Te téléporter dans un lieu connu", b: "Courir aussi vite qu'une voiture"),
        Dilemma(id: "wyr_032", a: "Retenir tout ce que tu lis", b: "Comprendre tout ce que tu regardes"),
        Dilemma(id: "wyr_033", a: "Sauter aussi haut qu'un immeuble", b: "Soulever une voiture"),
        Dilemma(id: "wyr_034", a: "Parler à ton toi de dix ans", b: "Parler à ton toi de quatre-vingts ans"),
        Dilemma(id: "wyr_035", a: "Être toujours de bonne humeur", b: "Rendre les autres de bonne humeur"),
        Dilemma(id: "wyr_036", a: "Voir dans le noir", b: "Entendre à un kilomètre"),
        Dilemma(id: "wyr_037", a: "Marcher sur l'eau", b: "Traverser les murs"),
        Dilemma(id: "wyr_038", a: "Rejouer une journée autant que tu veux", b: "Sauter les journées qui t'ennuient"),
        Dilemma(id: "wyr_039", a: "Retenir toutes les recettes du monde", b: "Retenir toutes les chansons du monde"),
        Dilemma(id: "wyr_040", a: "Devenir champion d'un sport", b: "Devenir virtuose d'un instrument"),
        Dilemma(id: "wyr_041", a: "Connaître un secret de chaque personne", b: "Que chacun connaisse un secret sur toi"),
        Dilemma(id: "wyr_042", a: "Toujours une heure en avance", b: "Toujours vingt minutes en retard"),
        Dilemma(id: "wyr_043", a: "Que de la junk food à vie", b: "Plus jamais tes plats préférés"),
        Dilemma(id: "wyr_044", a: "Fauché mais amoureux", b: "Plein aux as mais tout seul"),
        Dilemma(id: "wyr_045", a: "Un caca au goût de gâteau", b: "Un gâteau au goût de caca"),
        Dilemma(id: "wyr_046", a: "Roter sans aucun contrôle", b: "Péter sans aucun contrôle"),
        Dilemma(id: "wyr_047", a: "Sans internet un an", b: "Sans douche un mois"),
        Dilemma(id: "wyr_048", a: "Un frigo toujours vide", b: "Un frigo plein de trucs périmés"),
        Dilemma(id: "wyr_049", a: "Toujours perdre tes clés", b: "Toujours perdre ton téléphone"),
        Dilemma(id: "wyr_050", a: "Cent canards gros comme des poneys", b: "Un poney gros comme un canard")
    ]

    // MARK: Pack Extrême (18+)

    /// 40 dilemmes 18+, hors du paquet de base : dégoût assumé, honte
    /// sociale, intime cru, absurde corporel. Verrouillé derrière la
    /// confirmation d'âge — et jamais graphique (règle 1.1.4).
    static let extreme: [Dilemma] = [
        Dilemma(id: "wyr_051", a: "Qu'on entende tes pensées pendant l'amour", b: "Entendre celles de l'autre sans pouvoir répondre"),
        Dilemma(id: "wyr_052", a: "Un an d'abstinence totale", b: "Une nuit avec quelqu'un d'ici, tiré au sort"),
        Dilemma(id: "wyr_053", a: "Lécher l'assise des toilettes d'une boîte", b: "Porter le caleçon d'un inconnu une semaine"),
        Dilemma(id: "wyr_054", a: "Gémir à chaque éternuement", b: "Éternuer à chaque moment intime"),
        Dilemma(id: "wyr_055", a: "Un tatouage du prénom de chaque ex", b: "Un ex avec ton visage tatoué"),
        Dilemma(id: "wyr_056", a: "Ton plan d'hier devient ton boss lundi", b: "Le rencard de ta mère samedi"),
        Dilemma(id: "wyr_057", a: "Finir tous les fonds de verre de la soirée", b: "Lécher le comptoir du bar en entier"),
        Dilemma(id: "wyr_058", a: "Revivre ta pire cuite chaque samedi", b: "Ne plus jamais boire une goutte"),
        Dilemma(id: "wyr_059", a: "Faire l'amour en silence total à vie", b: "En commentant tout à voix haute"),
        Dilemma(id: "wyr_060", a: "Que ta mère commente tes stories de soirée", b: "Que ton boss like tes photos de vacances"),
        Dilemma(id: "wyr_061", a: "Dire ton nombre exact à tes parents", b: "Que tes parents te disent le leur"),
        Dilemma(id: "wyr_062", a: "Que ta peuff ait un goût de paff", b: "Que ta paff ait un goût de peuff"),
        Dilemma(id: "wyr_063", a: "Pleurer bruyamment à chaque orgasme", b: "Rire aux éclats à chaque enterrement"),
        Dilemma(id: "wyr_064", a: "Une seule fois par an, mais parfaite", b: "Tous les jours, toujours moyen"),
        Dilemma(id: "wyr_065", a: "Que ça dure 30 secondes à vie", b: "Que ça dure 3 heures obligatoires"),
        Dilemma(id: "wyr_066", a: "Ne plus jamais faire l'amour", b: "Plus jamais de câlins ni de bisous"),
        Dilemma(id: "wyr_067", a: "Crier le mauvais prénom une fois", b: "L'entendre à chaque fois"),
        Dilemma(id: "wyr_068", a: "Faire l'amour devant tes beaux-parents une fois", b: "Les entendre à chaque fois"),
        Dilemma(id: "wyr_069", a: "Un partenaire qui commente tout", b: "Un partenaire totalement muet"),
        Dilemma(id: "wyr_070", a: "Refaire ta première fois devant témoins", b: "La raconter en détail à ta famille"),
        Dilemma(id: "wyr_071", a: "Boire un shot de sueur de videur", b: "Lécher le sol des toilettes du bar"),
        Dilemma(id: "wyr_072", a: "Embrasser avec beaucoup trop de langue", b: "Sans aucune langue jamais"),
        Dilemma(id: "wyr_073", a: "Un suçon visible chaque lundi", b: "Un pantalon qui craque chaque vendredi"),
        Dilemma(id: "wyr_074", a: "Une nuit avec ton ou ta meilleure amie", b: "Un an sans se parler"),
        Dilemma(id: "wyr_075", a: "Que tes ex se réunissent une fois par an", b: "Qu'ils aient un groupe privé à ton nom"),
        Dilemma(id: "wyr_076", a: "Lire le journal intime de l'autre", b: "Que l'autre lise le tien"),
        Dilemma(id: "wyr_077", a: "Tomber sur les nudes de ton coloc", b: "Que ton coloc tombe sur les tiens"),
        Dilemma(id: "wyr_078", a: "Roter au premier baiser", b: "Éternuer dans le cou à chaque câlin"),
        Dilemma(id: "wyr_079", a: "Péter pendant un massage en couple", b: "Pendant une demande en mariage"),
        Dilemma(id: "wyr_080", a: "Faire ça dans le lit de tes parents", b: "Que tes parents le fassent dans le tien"),
        Dilemma(id: "wyr_081", a: "Vomir sur ton crush", b: "Que ton crush vomisse sur toi"),
        Dilemma(id: "wyr_082", a: "Danser nu une minute en boîte", b: "Courir nu autour du pâté de maisons"),
        Dilemma(id: "wyr_083", a: "Manger un kebab trouvé dans le bus", b: "Boire une bière ouverte trouvée en boîte"),
        Dilemma(id: "wyr_084", a: "Une cuite obligatoire chaque mercredi", b: "Plus une goutte même à ton mariage"),
        Dilemma(id: "wyr_085", a: "Griller tes parents en train de fumer", b: "Qu'ils te grillent en pleine soirée"),
        Dilemma(id: "wyr_086", a: "Coucher avec le sosie de ton ex", b: "Le sosie de ton boss"),
        Dilemma(id: "wyr_087", a: "Zéro préliminaires pour toujours", b: "Rien que ça, jamais la suite"),
        Dilemma(id: "wyr_088", a: "Passer une nuit menotté à un inconnu", b: "À ton ex le plus toxique"),
        Dilemma(id: "wyr_089", a: "Que la table vote avec qui tu finis ce soir", b: "Qu'elle lise tes trois derniers messages"),
        Dilemma(id: "wyr_090", a: "Un strip-tease au repas de Noël", b: "Un slow très collé avec ton patron")
    ]

    /// Le paquet effectivement joué : la base, plus l'Extrême si l'âge est
    /// confirmé ET que la table l'a activé. Le verrou se vérifie ici, pas dans
    /// la vue — un réglage sauvegardé ne rouvre pas un pack refermé.
    static func dilemmas(adultUnlocked: Bool, extremeEnabled: Bool) -> [Dilemma] {
        guard adultUnlocked, extremeEnabled else { return all }
        return all + extreme
    }
}
