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

/// Les 200 dilemmes de « Tu préfères ? », en Swift et non en JSON : vérifié à
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
    static let all: [Dilemma] = {
        var cards: [Dilemma] = []
        cards += renunciations
        cards += sensations
        cards += powers
        cards += social
        cards += home
        cards += journeys
        cards += work
        cards += absurd
        cards += knowledge
        return cards
    }()

    // MARK: Renoncer à quelque chose

    private static let renunciations: [Dilemma] = [
        Dilemma(id: "wyr_001", a: "Que ta mère lise tous tes messages", b: "Que ton boss voie toutes tes stories"),
        Dilemma(id: "wyr_002", a: "Manger la même chose tous les jours", b: "Ne jamais manger deux fois pareil"),
        Dilemma(id: "wyr_003", a: "Avoir la même chanson en tête à vie", b: "Entendre un jingle avant chaque phrase"),
        Dilemma(id: "wyr_004", a: "Boire tous tes plats à la paille", b: "Manger toutes tes boissons à la cuillère"),
        Dilemma(id: "wyr_005", a: "Marcher pieds nus sur un jouet chaque matin", b: "Te cogner le petit orteil chaque soir"),
        Dilemma(id: "wyr_006", a: "Un ventre qui gargouille en entretien", b: "Un rire qui part au mauvais moment"),
        Dilemma(id: "wyr_007", a: "Faire chaque trajet debout", b: "Faire chaque trajet à côté des toilettes"),
        Dilemma(id: "wyr_008", a: "Un seul écouteur qui marche", b: "Un chargeur qui tient dans un angle précis"),
        Dilemma(id: "wyr_009", a: "Dormir chez tes beaux-parents chaque week-end", b: "Recevoir ta belle-famille chaque week-end"),
        Dilemma(id: "wyr_010", a: "Goûter les desserts des autres sans en avoir", b: "Manger ton dessert sous vingt regards"),
        Dilemma(id: "wyr_011", a: "Qu'on te chante joyeux anniversaire au resto", b: "Qu'on oublie ton anniversaire en famille"),
        Dilemma(id: "wyr_012", a: "Te faire spoiler chaque fin", b: "Ne jamais connaître la fin de rien"),
        Dilemma(id: "wyr_013", a: "Vivre décalé de deux heures sur tout le monde", b: "Vivre les lundis en double"),
        Dilemma(id: "wyr_014", a: "Applaudir à la fin de chaque phrase", b: "Faire un check à chaque au revoir"),
        Dilemma(id: "wyr_015", a: "Lire chaque notice en entier avant usage", b: "Signer chaque CGU après lecture complète"),
        Dilemma(id: "wyr_016", a: "Choisir entre fromage et dessert à vie", b: "Choisir entre entrée et rab à vie"),
        Dilemma(id: "wyr_017", a: "Garder ta coupe de sixième à vie", b: "Reporter ta tenue de classe verte à vie"),
        Dilemma(id: "wyr_018", a: "Rater une marche devant du monde chaque jour", b: "Tirer une porte marquée pousser chaque jour"),
        Dilemma(id: "wyr_019", a: "Recevoir les messages avec un jour de retard", b: "Un message au mauvais contact par mois"),
        Dilemma(id: "wyr_020", a: "Couper ta viande avec une cuillère", b: "Manger ta soupe à la fourchette"),
        Dilemma(id: "wyr_021", a: "Dormir dans des draps pleins de miettes", b: "Marcher sur du carrelage glacé au réveil"),
        Dilemma(id: "wyr_022", a: "Écrire comme un médecin sans le savoir", b: "Lire à voix haute tout ce que tu tapes"),
        Dilemma(id: "wyr_023", a: "Être réveillé chaque jour par une perceuse", b: "Être réveillé chaque jour par un moustique"),
        Dilemma(id: "wyr_024", a: "Croiser ton prof partout en vacances", b: "Croiser ton ex à chaque soirée"),
        Dilemma(id: "wyr_025", a: "Commander un plat au hasard à chaque resto", b: "Manger l'assiette de ton voisin d'en face")
    ]

    // MARK: Corps et sensations

    private static let sensations: [Dilemma] = [
        Dilemma(id: "wyr_026", a: "Avoir toujours un caillou dans la chaussure", b: "Avoir toujours une mèche dans l'œil"),
        Dilemma(id: "wyr_027", a: "Éternuer dix fois par heure", b: "Avoir le hoquet une heure par jour"),
        Dilemma(id: "wyr_028", a: "Avoir les mains toujours moites", b: "Avoir les lèvres toujours sèches"),
        Dilemma(id: "wyr_029", a: "Avoir toujours trop chaud aux pieds", b: "Avoir toujours froid aux mains"),
        Dilemma(id: "wyr_030", a: "Parler en criant tout le temps", b: "Parler en chuchotant tout le temps"),
        Dilemma(id: "wyr_031", a: "Marcher à reculons toute ta vie", b: "Sauter à cloche-pied toute ta vie"),
        Dilemma(id: "wyr_032", a: "Avoir des ongles qui poussent en une nuit", b: "Avoir des cheveux qui poussent en une nuit"),
        Dilemma(id: "wyr_033", a: "Ne jamais pouvoir te gratter", b: "Ne jamais pouvoir t'étirer"),
        Dilemma(id: "wyr_034", a: "Avoir une démarche de robot", b: "Avoir une voix de dessin animé"),
        Dilemma(id: "wyr_035", a: "Voir tout en noir et blanc", b: "Entendre tout avec un écho"),
        Dilemma(id: "wyr_036", a: "Bâiller toutes les cinq minutes", b: "Cligner des yeux deux fois plus vite"),
        Dilemma(id: "wyr_037", a: "Avoir une chanson coincée dans la tête", b: "Avoir une phrase qui tourne en boucle"),
        Dilemma(id: "wyr_038", a: "Entendre ta mastication très fort", b: "Entendre ta respiration très fort"),
        Dilemma(id: "wyr_039", a: "Avoir les cheveux mouillés en permanence", b: "Avoir les chaussettes humides en permanence"),
        Dilemma(id: "wyr_040", a: "Devoir tousser avant chaque phrase", b: "Devoir claquer des doigts après chaque phrase"),
        Dilemma(id: "wyr_041", a: "Avoir un rire très bruyant", b: "Avoir un rire complètement silencieux"),
        Dilemma(id: "wyr_042", a: "Devoir marcher très lentement", b: "Devoir marcher très vite"),
        Dilemma(id: "wyr_043", a: "Avoir faim une heure après manger", b: "Avoir soif une heure après boire"),
        Dilemma(id: "wyr_044", a: "Avoir les yeux qui pleurent au vent", b: "Avoir le nez qui coule au froid"),
        Dilemma(id: "wyr_045", a: "Devoir lever la main pour parler", b: "Devoir te lever pour répondre"),
        Dilemma(id: "wyr_046", a: "Avoir la peau qui brille comme un miroir", b: "Avoir les cheveux qui changent de couleur"),
        Dilemma(id: "wyr_047", a: "Sentir la lavande en permanence", b: "Sentir la pizza en permanence"),
        Dilemma(id: "wyr_048", a: "Avoir les mains qui collent au tissu", b: "Avoir les pieds qui glissent sur le carrelage"),
        Dilemma(id: "wyr_049", a: "Devoir dormir assis", b: "Devoir dormir avec la lumière allumée"),
        Dilemma(id: "wyr_050", a: "Avoir la voix qui déraille quand tu es content", b: "Avoir le fou rire quand tu es sérieux")
    ]

    // MARK: Pouvoirs

    private static let powers: [Dilemma] = [
        Dilemma(id: "wyr_051", a: "Pouvoir voler", b: "Pouvoir devenir invisible"),
        Dilemma(id: "wyr_052", a: "Pouvoir respirer sous l'eau", b: "Pouvoir marcher sur les murs"),
        Dilemma(id: "wyr_053", a: "Parler toutes les langues", b: "Parler avec les animaux"),
        Dilemma(id: "wyr_054", a: "Arrêter le temps dix secondes", b: "Revenir dix secondes en arrière"),
        Dilemma(id: "wyr_055", a: "Lire dans les pensées", b: "Voir une minute dans le futur"),
        Dilemma(id: "wyr_056", a: "Te téléporter dans un lieu connu", b: "Courir aussi vite qu'une voiture"),
        Dilemma(id: "wyr_057", a: "Avoir sommeil à chaque réunion", b: "Éternuer à chaque photo de groupe"),
        Dilemma(id: "wyr_058", a: "Retenir tout ce que tu lis", b: "Comprendre tout ce que tu regardes"),
        Dilemma(id: "wyr_059", a: "Changer la météo d'une journée", b: "Choisir tes rêves chaque nuit"),
        Dilemma(id: "wyr_060", a: "Soigner une plante d'un toucher", b: "Réparer un objet d'un toucher"),
        Dilemma(id: "wyr_061", a: "Sauter aussi haut qu'un immeuble", b: "Soulever une voiture"),
        Dilemma(id: "wyr_062", a: "Devenir minuscule à volonté", b: "Devenir géant à volonté"),
        Dilemma(id: "wyr_063", a: "Te dédoubler une heure par jour", b: "Ne jamais avoir besoin de dormir"),
        Dilemma(id: "wyr_064", a: "Savoir toujours l'heure exacte", b: "Savoir toujours où tu te trouves"),
        Dilemma(id: "wyr_065", a: "Faire apparaître un repas chaud", b: "Faire apparaître un endroit où dormir"),
        Dilemma(id: "wyr_066", a: "Respirer dans l'espace", b: "Supporter le froid polaire"),
        Dilemma(id: "wyr_067", a: "Parler à ton toi de dix ans", b: "Parler à ton toi de quatre-vingts ans"),
        Dilemma(id: "wyr_068", a: "Deviner le prénom de tout le monde", b: "Deviner l'âge de tout le monde"),
        Dilemma(id: "wyr_069", a: "Faire pousser une forêt en une nuit", b: "Faire jaillir une source d'eau"),
        Dilemma(id: "wyr_070", a: "Être toujours de bonne humeur", b: "Rendre les autres de bonne humeur"),
        Dilemma(id: "wyr_071", a: "Voir dans le noir", b: "Entendre à un kilomètre"),
        Dilemma(id: "wyr_072", a: "Marcher sur l'eau", b: "Traverser les murs"),
        Dilemma(id: "wyr_073", a: "Commander au vent", b: "Commander à la pluie"),
        Dilemma(id: "wyr_074", a: "Rejouer une journée autant que tu veux", b: "Sauter les journées qui t'ennuient"),
        Dilemma(id: "wyr_075", a: "Comprendre les bébés", b: "Comprendre les chats")
    ]

    // MARK: Vie sociale et gêne

    private static let social: [Dilemma] = [
        Dilemma(id: "wyr_076", a: "Rire à un moment très sérieux", b: "Bâiller pendant qu'on te parle"),
        Dilemma(id: "wyr_077", a: "Oublier le prénom de tout le monde", b: "Oublier le visage de tout le monde"),
        Dilemma(id: "wyr_078", a: "Chanter faux devant toute la classe", b: "Danser seul devant toute la classe"),
        Dilemma(id: "wyr_079", a: "Appeler ton prof « papa »", b: "Appeler ton ami par le prénom de son frère"),
        Dilemma(id: "wyr_080", a: "Faire tomber ton plateau à la cantine", b: "Glisser devant l'arrêt de bus"),
        Dilemma(id: "wyr_081", a: "Répondre à côté à chaque question", b: "Répéter deux fois chaque phrase"),
        Dilemma(id: "wyr_082", a: "Avoir un surnom ridicule à vie", b: "N'avoir jamais aucun surnom"),
        Dilemma(id: "wyr_083", a: "Raconter la fin des films à tout le monde", b: "Te faire raconter la fin de chaque film"),
        Dilemma(id: "wyr_084", a: "Être en avance d'une heure partout", b: "Être en retard de dix minutes partout"),
        Dilemma(id: "wyr_085", a: "Rire de toutes les blagues même mauvaises", b: "Ne comprendre aucune blague"),
        Dilemma(id: "wyr_086", a: "Parler très fort au téléphone en public", b: "Chuchoter au point qu'on te fasse répéter"),
        Dilemma(id: "wyr_087", a: "Dire la vérité même quand ça gêne", b: "Ne jamais pouvoir donner ton avis"),
        Dilemma(id: "wyr_088", a: "Être toujours le premier à parler", b: "Être toujours le dernier à qui on demande"),
        Dilemma(id: "wyr_089", a: "Avoir une photo ratée de toi partout", b: "N'avoir aucune photo de toi"),
        Dilemma(id: "wyr_090", a: "Saluer quelqu'un qui ne te saluait pas", b: "Ignorer quelqu'un qui te saluait"),
        Dilemma(id: "wyr_091", a: "Chanter au lieu de parler pendant un jour", b: "Danser à chaque fois que tu marches"),
        Dilemma(id: "wyr_092", a: "Devoir dire bonjour à chaque personne croisée", b: "Ne pouvoir dire bonjour à personne"),
        Dilemma(id: "wyr_093", a: "Ne jamais pouvoir mentir", b: "Ne jamais être cru"),
        Dilemma(id: "wyr_094", a: "Avoir toujours un truc entre les dents", b: "Avoir toujours une tache sur le t-shirt"),
        Dilemma(id: "wyr_095", a: "Que ton téléphone sonne au pire moment", b: "Que ton réveil ne sonne jamais au bon moment"),
        Dilemma(id: "wyr_096", a: "Être toujours celui qui organise tout", b: "N'être jamais invité en premier"),
        Dilemma(id: "wyr_097", a: "Vivre avec quelqu'un qui parle sans arrêt", b: "Vivre avec quelqu'un qui ne dit rien"),
        Dilemma(id: "wyr_098", a: "Devoir applaudir après chaque phrase des autres", b: "Devoir t'incliner en entrant dans une pièce"),
        Dilemma(id: "wyr_099", a: "Avoir un ami qui arrive toujours en retard", b: "Avoir un ami qui repart toujours trop tôt"),
        Dilemma(id: "wyr_100", a: "Être connu pour une bêtise", b: "N'être connu de personne")
    ]

    // MARK: Maison et quotidien

    private static let home: [Dilemma] = [
        Dilemma(id: "wyr_101", a: "Vivre sans réfrigérateur", b: "Vivre sans machine à laver"),
        Dilemma(id: "wyr_102", a: "Vivre dans une maison sans fenêtre", b: "Vivre dans une maison sans porte"),
        Dilemma(id: "wyr_103", a: "Avoir un lit beaucoup trop dur", b: "Avoir un lit beaucoup trop mou"),
        Dilemma(id: "wyr_104", a: "Vivre dans une pièce toujours en désordre", b: "Devoir tout ranger deux fois par jour"),
        Dilemma(id: "wyr_105", a: "Un robinet qui goutte la nuit", b: "Un voisin qui déplace ses meubles la nuit"),
        Dilemma(id: "wyr_106", a: "Ne plus avoir d'eau chaude", b: "Ne plus avoir de chauffage"),
        Dilemma(id: "wyr_107", a: "Faire la vaisselle de tout le monde", b: "Passer l'aspirateur tous les jours"),
        Dilemma(id: "wyr_108", a: "Une chaise qui grince à chaque mouvement", b: "Une porte qui claque à chaque courant d'air"),
        Dilemma(id: "wyr_109", a: "Perdre tes clés chaque semaine", b: "Perdre ton téléphone chaque mois"),
        Dilemma(id: "wyr_110", a: "Un téléphone toujours à cinq pour cent", b: "Un ordinateur toujours très lent"),
        Dilemma(id: "wyr_111", a: "Un stylo qui fuit dans chaque poche", b: "Un ticket de caisse long d'un mètre"),
        Dilemma(id: "wyr_112", a: "Vivre avec une lumière qui clignote", b: "Vivre avec un plancher qui craque"),
        Dilemma(id: "wyr_113", a: "Devoir tout faire avec des gants", b: "Devoir tout faire pieds nus"),
        Dilemma(id: "wyr_114", a: "Ranger tes affaires par couleur", b: "Ranger tes affaires par taille"),
        Dilemma(id: "wyr_115", a: "Avoir une chambre minuscule", b: "Avoir une chambre immense et vide"),
        Dilemma(id: "wyr_116", a: "Une montre qui avance de sept minutes", b: "Un GPS qui recalcule sans arrêt"),
        Dilemma(id: "wyr_117", a: "Habiter au dernier étage sans ascenseur", b: "Habiter au rez-de-chaussée sur la rue"),
        Dilemma(id: "wyr_118", a: "Devoir refaire ton lit dix fois par jour", b: "Devoir plier tes vêtements après chaque usage"),
        Dilemma(id: "wyr_119", a: "Un frigo toujours vide", b: "Un placard rempli d'une seule chose"),
        Dilemma(id: "wyr_120", a: "Devoir sortir les poubelles chaque nuit", b: "Devoir arroser un jardin chaque matin"),
        Dilemma(id: "wyr_121", a: "Une douche toujours froide", b: "Une douche toujours trop courte"),
        Dilemma(id: "wyr_122", a: "Perdre une chaussette à chaque lessive", b: "Trouver du sable partout chez toi"),
        Dilemma(id: "wyr_123", a: "Un stylo qui marche une fois sur deux", b: "Un cahier dont les pages se déchirent"),
        Dilemma(id: "wyr_124", a: "Des voisins qui font la fête le dimanche", b: "Des voisins qui passent l'aspirateur à 7h"),
        Dilemma(id: "wyr_125", a: "Une sonnette qui sonne toute seule", b: "Un chien qui aboie toute la nuit à côté")
    ]

    // MARK: Voyage et aventure

    private static let journeys: [Dilemma] = [
        Dilemma(id: "wyr_126", a: "Traverser un désert à pied", b: "Traverser un océan en bateau"),
        Dilemma(id: "wyr_127", a: "Passer une nuit seul en forêt", b: "Passer une nuit seul dans une grotte"),
        Dilemma(id: "wyr_128", a: "Vivre un an sur une île déserte", b: "Vivre un an au sommet d'une montagne"),
        Dilemma(id: "wyr_129", a: "Voyager sans jamais prendre de photo", b: "Photographier sans jamais te souvenir"),
        Dilemma(id: "wyr_130", a: "Dormir dans un hamac chaque nuit", b: "Dormir sous une tente chaque nuit"),
        Dilemma(id: "wyr_131", a: "Voir toutes les capitales du monde", b: "Voir tous les volcans du monde"),
        Dilemma(id: "wyr_132", a: "Rater ton train à chaque voyage", b: "Attendre trois heures à chaque escale"),
        Dilemma(id: "wyr_133", a: "Voyager toujours seul", b: "Voyager toujours en grand groupe"),
        Dilemma(id: "wyr_134", a: "Partir sans aucun bagage", b: "Partir avec une valise trop lourde"),
        Dilemma(id: "wyr_135", a: "Explorer le fond des océans", b: "Explorer une planète inconnue"),
        Dilemma(id: "wyr_136", a: "Vivre une semaine sans montre", b: "Vivre une semaine sans carte"),
        Dilemma(id: "wyr_137", a: "Marcher mille kilomètres", b: "Nager dix kilomètres"),
        Dilemma(id: "wyr_138", a: "Camper sous la pluie", b: "Camper sous un soleil brûlant"),
        Dilemma(id: "wyr_139", a: "Passer six mois en bateau", b: "Faire le tour du monde à vélo"),
        Dilemma(id: "wyr_140", a: "Ne visiter qu'un seul pays", b: "Changer de pays chaque année"),
        Dilemma(id: "wyr_141", a: "Dormir dans un train toutes les nuits", b: "Dormir dans un aéroport toutes les nuits"),
        Dilemma(id: "wyr_142", a: "Être guide de montagne", b: "Être gardien de phare"),
        Dilemma(id: "wyr_143", a: "Découvrir une grotte inconnue", b: "Découvrir une épave au fond de l'eau"),
        Dilemma(id: "wyr_144", a: "Partir dans le passé sans revenir", b: "Partir dans le futur sans revenir"),
        Dilemma(id: "wyr_145", a: "Marcher une heure sur la Lune", b: "Passer une semaine au fond de la mer")
    ]

    // MARK: Travail et école

    private static let work: [Dilemma] = [
        Dilemma(id: "wyr_146", a: "Travailler très tôt le matin", b: "Travailler très tard le soir"),
        Dilemma(id: "wyr_147", a: "Un métier passionnant mal payé", b: "Un métier ennuyeux bien payé"),
        Dilemma(id: "wyr_148", a: "Avoir un chef qui vérifie tout", b: "Avoir un chef introuvable"),
        Dilemma(id: "wyr_149", a: "Refaire toute ta scolarité", b: "Passer un examen chaque année à vie"),
        Dilemma(id: "wyr_150", a: "Devoir tout apprendre par cœur", b: "Devoir tout réexpliquer aux autres"),
        Dilemma(id: "wyr_151", a: "Corriger des copies toute la journée", b: "Ranger une bibliothèque toute la journée"),
        Dilemma(id: "wyr_152", a: "Travailler toujours seul", b: "Travailler toujours en équipe"),
        Dilemma(id: "wyr_153", a: "Répondre au téléphone toute la journée", b: "Écrire des messages toute la journée"),
        Dilemma(id: "wyr_154", a: "Faire trois heures de trajet par jour", b: "Travailler chez toi sans jamais sortir"),
        Dilemma(id: "wyr_155", a: "Ne jamais avoir de week-end", b: "Ne jamais avoir de vacances d'été"),
        Dilemma(id: "wyr_156", a: "Présenter un exposé chaque semaine", b: "Rendre un devoir chaque jour"),
        Dilemma(id: "wyr_157", a: "Porter un uniforme obligatoire", b: "Changer de tenue chaque jour"),
        Dilemma(id: "wyr_158", a: "Faire des maths toute la journée", b: "Faire de l'orthographe toute la journée"),
        Dilemma(id: "wyr_159", a: "Être toujours interrogé le premier", b: "Être toujours interrogé le dernier"),
        Dilemma(id: "wyr_160", a: "Un métier dehors par tous les temps", b: "Un métier enfermé sans fenêtre"),
        Dilemma(id: "wyr_161", a: "Tout écrire à la main au travail", b: "Tout dicter à voix haute"),
        Dilemma(id: "wyr_162", a: "Diriger une équipe de vingt personnes", b: "N'avoir aucun collègue"),
        Dilemma(id: "wyr_163", a: "Enchaîner les réunions sans fin", b: "Remplir des tableaux de chiffres sans fin"),
        Dilemma(id: "wyr_164", a: "Réviser toute la nuit", b: "Te lever à quatre heures pour réviser"),
        Dilemma(id: "wyr_165", a: "Être noté par tes collègues", b: "Devoir noter tes collègues")
    ]

    // MARK: Absurde et imaginaire

    private static let absurd: [Dilemma] = [
        Dilemma(id: "wyr_166", a: "Avoir un dragon minuscule chez toi", b: "Avoir un éléphant de la taille d'un chat"),
        Dilemma(id: "wyr_167", a: "Que tout ait un goût de banane", b: "Que tout ait une odeur de menthe"),
        Dilemma(id: "wyr_168", a: "Vivre dans un dessin animé", b: "Vivre dans un jeu vidéo"),
        Dilemma(id: "wyr_169", a: "Que ton ombre bouge toute seule", b: "Que ton reflet ait une seconde de retard"),
        Dilemma(id: "wyr_170", a: "Que la pluie tombe vers le haut", b: "Que le vent souffle toujours dans ton dos"),
        Dilemma(id: "wyr_171", a: "Avoir un nuage qui te suit", b: "Avoir un arc-en-ciel au-dessus de la tête"),
        Dilemma(id: "wyr_172", a: "Parler en rimes toute ta vie", b: "Devoir mimer chaque phrase"),
        Dilemma(id: "wyr_173", a: "Que les objets répondent quand tu leur parles", b: "Que les animaux commentent tes journées"),
        Dilemma(id: "wyr_174", a: "Que ton lit flotte à un mètre du sol", b: "Que ta chaise avance toute seule"),
        Dilemma(id: "wyr_175", a: "Vivre dans un monde en deux dimensions", b: "Vivre dans un monde à l'envers"),
        Dilemma(id: "wyr_176", a: "Que chaque porte mène à une pièce au hasard", b: "Que chaque escalier monte toujours"),
        Dilemma(id: "wyr_177", a: "Avoir un double qui fait tes corvées", b: "Avoir un robot qui fait tes devoirs"),
        Dilemma(id: "wyr_178", a: "Qu'une musique joue quand tu entres quelque part", b: "Que des applaudissements suivent chaque phrase"),
        Dilemma(id: "wyr_179", a: "Que les nuages soient en coton", b: "Que la neige ait le goût du sucre"),
        Dilemma(id: "wyr_180", a: "Vivre une journée en accéléré", b: "Vivre une journée au ralenti"),
        Dilemma(id: "wyr_181", a: "Que ton chat parle une heure par jour", b: "Que ton chien écrive ce qu'il pense"),
        Dilemma(id: "wyr_182", a: "Que les livres se lisent tout seuls à voix haute", b: "Que les films se rejouent dans ta tête"),
        Dilemma(id: "wyr_183", a: "Devenir un personnage de conte", b: "Devenir une statue de ville pendant un an"),
        Dilemma(id: "wyr_184", a: "Que les escaliers soient des toboggans", b: "Que les trottoirs soient des tapis roulants"),
        Dilemma(id: "wyr_185", a: "Habiter dans un arbre", b: "Habiter dans un moulin")
    ]

    // MARK: Savoir et mémoire

    private static let knowledge: [Dilemma] = [
        Dilemma(id: "wyr_186", a: "Savoir ce que les autres pensent de toi", b: "Ne rien savoir de ce qu'on dit de toi"),
        Dilemma(id: "wyr_187", a: "Tout oublier chaque nuit", b: "Ne jamais rien pouvoir oublier"),
        Dilemma(id: "wyr_188", a: "Connaître toutes les réponses sans les dire", b: "Poser des questions sans obtenir de réponse"),
        Dilemma(id: "wyr_189", a: "Retenir toutes les recettes du monde", b: "Retenir toutes les chansons du monde"),
        Dilemma(id: "wyr_190", a: "Apprendre un instrument en une nuit", b: "Apprendre une langue en une nuit"),
        Dilemma(id: "wyr_191", a: "Connaître la fin de toutes les histoires", b: "Ne connaître la fin d'aucune histoire"),
        Dilemma(id: "wyr_192", a: "Te souvenir de chacun de tes rêves", b: "Ne plus jamais rêver"),
        Dilemma(id: "wyr_193", a: "Savoir toujours quand on te ment", b: "Savoir toujours ce qui va te plaire"),
        Dilemma(id: "wyr_194", a: "Devenir champion d'un sport", b: "Devenir virtuose d'un instrument"),
        Dilemma(id: "wyr_195", a: "Comprendre parfaitement les mathématiques", b: "Dessiner parfaitement tout ce que tu vois"),
        Dilemma(id: "wyr_196", a: "Te souvenir de ton premier jour d'école", b: "Te souvenir de ton premier mot"),
        Dilemma(id: "wyr_197", a: "Connaître un secret de chaque personne", b: "Que chacun connaisse un secret sur toi"),
        Dilemma(id: "wyr_198", a: "Savoir tout réparer", b: "Savoir tout cuisiner"),
        Dilemma(id: "wyr_199", a: "Retenir chaque visage croisé", b: "Retenir chaque conversation entendue"),
        Dilemma(id: "wyr_200", a: "Devenir très sage", b: "Devenir très drôle")
    ]

    // MARK: Pack Extrême (18+)

    /// 60 dilemmes 18+, hors du paquet de base : dégoût assumé, honte
    /// sociale, intime cru, absurde corporel. Verrouillé derrière la
    /// confirmation d'âge — et jamais graphique (règle 1.1.4).
    static let extreme: [Dilemma] = [
        Dilemma(id: "wyr_201", a: "Transpirer de l'huile de friture", b: "Sentir le fromage fondu en permanence"),
        Dilemma(id: "wyr_202", a: "Lécher la rampe du métro", b: "Boire l'eau d'un vase d'une semaine"),
        Dilemma(id: "wyr_203", a: "Manger un insecte croustillant par jour", b: "Un ver vivant par semaine"),
        Dilemma(id: "wyr_204", a: "Marcher pieds nus dans des toilettes publiques", b: "Dormir dans des draps jamais lavés"),
        Dilemma(id: "wyr_205", a: "Roter l'odeur de ton dernier repas", b: "Péter en fumée colorée"),
        Dilemma(id: "wyr_206", a: "Des mains qui sentent le poisson", b: "Des cheveux qui sentent le tabac froid"),
        Dilemma(id: "wyr_207", a: "Mâcher un chewing-gum trouvé", b: "Finir le verre d'un inconnu"),
        Dilemma(id: "wyr_208", a: "Une douche par mois", b: "Un brossage de dents par semaine"),
        Dilemma(id: "wyr_209", a: "Vomir devant ton crush", b: "Que ton crush vomisse sur toi"),
        Dilemma(id: "wyr_210", a: "Garder le même caleçon un mois", b: "Les mêmes chaussettes trois mois"),
        Dilemma(id: "wyr_211", a: "Ton historique affiché en soirée", b: "Tes vocaux en haut-parleur au travail"),
        Dilemma(id: "wyr_212", a: "Arriver nu à un repas de famille", b: "En pyjama licorne à un entretien"),
        Dilemma(id: "wyr_213", a: "Péter bruyamment à un enterrement", b: "Avoir un fou rire à ton propre mariage"),
        Dilemma(id: "wyr_214", a: "Crier le prénom de ton ex à ton mariage", b: "Pleurer au mariage de ton ex"),
        Dilemma(id: "wyr_215", a: "Tes recherches de la semaine rendues publiques", b: "Tes pensées audibles une journée"),
        Dilemma(id: "wyr_216", a: "T'étaler sur scène devant mille personnes", b: "Bégayer ta demande en mariage"),
        Dilemma(id: "wyr_217", a: "Envoyer un nude au groupe familial", b: "En recevoir un devant ta mère"),
        Dilemma(id: "wyr_218", a: "Un suçon visible à un entretien", b: "Une braguette ouverte en conférence"),
        Dilemma(id: "wyr_219", a: "Des débuts géniaux qui finissent mal", b: "Des histoires tièdes qui durent"),
        Dilemma(id: "wyr_220", a: "Un an d'abstinence", b: "Un an sans téléphone"),
        Dilemma(id: "wyr_221", a: "Lire les pensées de ton ou ta partenaire", b: "Qu'il ou elle lise les tiennes"),
        Dilemma(id: "wyr_222", a: "Tes ex réunis pour te débriefer", b: "Ton journal intime lu à voix haute"),
        Dilemma(id: "wyr_223", a: "Retenter avec ton ex et regretter", b: "Ne jamais savoir ce que ça aurait donné"),
        Dilemma(id: "wyr_224", a: "Gémir au moindre étirement", b: "Rougir à chaque prénom de ton passé"),
        Dilemma(id: "wyr_225", a: "Ta mère trouve ton tiroir secret", b: "Ton coloc raconte ta nuit à table"),
        Dilemma(id: "wyr_226", a: "Revivre ta première fois en pire", b: "La vidéo de ta pire soirée en famille"),
        Dilemma(id: "wyr_227", a: "Des doigts en saucisses cocktail", b: "Des genoux qui klaxonnent"),
        Dilemma(id: "wyr_228", a: "Un bruit de klaxon en t'asseyant", b: "Un bruit de velcro en te levant"),
        Dilemma(id: "wyr_229", a: "Un générique triste quand tu sors d'une pièce", b: "Des applaudissements quand tu vas aux toilettes"),
        Dilemma(id: "wyr_230", a: "Transpirer des paillettes", b: "Pleurer de la sauce piquante"),
        Dilemma(id: "wyr_231", a: "Un troisième bras dans le dos", b: "Un œil derrière la tête"),
        Dilemma(id: "wyr_232", a: "Parler uniquement en rimes", b: "Chanter tout ce que tu dis"),
        Dilemma(id: "wyr_233", a: "Sentir la frite en boîte de nuit", b: "Le chlore en rendez-vous galant"),
        Dilemma(id: "wyr_234", a: "Hoqueter à chaque mensonge", b: "Éternuer à chaque pensée coquine"),
        Dilemma(id: "wyr_235", a: "Connaître la date de ta mort", b: "La cause, sans la date"),
        Dilemma(id: "wyr_236", a: "Revivre la même journée un an", b: "Sauter un an de ta vie"),
        Dilemma(id: "wyr_237", a: "Être oublié après ta mort", b: "Célèbre pour une honte"),
        Dilemma(id: "wyr_238", a: "Savoir tout ce qui se dit sur toi", b: "Ne jamais rien savoir"),
        Dilemma(id: "wyr_239", a: "Oublier toutes tes soirées", b: "Que les autres se souviennent de tout"),
        Dilemma(id: "wyr_240", a: "Riche mais détesté", b: "Adoré mais fauché"),
        Dilemma(id: "wyr_241", a: "Une cuite mémorable sans souvenirs", b: "Tous les souvenirs d'une soirée honteuse"),
        Dilemma(id: "wyr_242", a: "Une gueule de bois éternelle", b: "Un lundi éternel"),
        Dilemma(id: "wyr_243", a: "Ne boire que des shots tièdes", b: "Que de la bière éventée"),
        Dilemma(id: "wyr_244", a: "Danser sobre au milieu des gens bourrés", b: "Être le seul bourré au brunch de famille"),
        Dilemma(id: "wyr_245", a: "Être recalé par le videur devant tout le monde", b: "Vomir dans la file du kebab"),
        Dilemma(id: "wyr_246", a: "Perdre ton téléphone à chaque soirée", b: "Ta carte à chaque addition"),
        Dilemma(id: "wyr_247", a: "Karaoké obligatoire à chaque soirée", b: "Discours obligatoire à chaque dîner"),
        Dilemma(id: "wyr_248", a: "Un after qui ne finit jamais", b: "Des soirées finies à vingt-deux heures"),
        Dilemma(id: "wyr_249", a: "Un rencard avec l'ex de ton meilleur pote", b: "Ton pote en couple avec ton ex"),
        Dilemma(id: "wyr_250", a: "Un rencard parfait qui ne rappelle jamais", b: "Dix rencards moyens qui rappellent trop"),
        Dilemma(id: "wyr_251", a: "Épouser ton premier crush", b: "La dernière personne que tu as ghostée"),
        Dilemma(id: "wyr_252", a: "Tes parents choisissent tes rencards", b: "Tes potes gèrent tes messages"),
        Dilemma(id: "wyr_253", a: "Ne dater que des sosies de ton ex", b: "Ne plus jamais avoir de type"),
        Dilemma(id: "wyr_254", a: "Annoncer ton nombre exact à table", b: "Laisser la table deviner et voter"),
        Dilemma(id: "wyr_255", a: "Un smoothie des restes du frigo", b: "Une soupe de fin de kebab"),
        Dilemma(id: "wyr_256", a: "Entendre tes voisins tous les soirs", b: "Qu'ils t'entendent tous les soirs"),
        Dilemma(id: "wyr_257", a: "Un cheveu dans chaque plat", b: "Un ongle dans un seul plat mystère"),
        Dilemma(id: "wyr_258", a: "Serrer des mains moites à vie", b: "Faire la bise à des joues humides"),
        Dilemma(id: "wyr_259", a: "Ton dentiste commente ta vie amoureuse", b: "Ton coiffeur commente tes finances"),
        Dilemma(id: "wyr_260", a: "Un tatouage choisi par ta belle-mère", b: "Un tatouage choisi par ton pire ennemi")
    ]

    /// Le paquet effectivement joué : la base, plus l'Extrême si l'âge est
    /// confirmé ET que la table l'a activé. Le verrou se vérifie ici, pas dans
    /// la vue — un réglage sauvegardé ne rouvre pas un pack refermé.
    static func dilemmas(adultUnlocked: Bool, extremeEnabled: Bool) -> [Dilemma] {
        guard adultUnlocked, extremeEnabled else { return all }
        return all + extreme
    }
}
