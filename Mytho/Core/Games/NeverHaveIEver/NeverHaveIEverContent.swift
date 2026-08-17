import Foundation

// MARK: - Carte

/// Une affirmation de « Je n'ai jamais » (spec §5.5).
///
/// Le préfixe « Je n'ai jamais… » vit dans l'interface, **jamais dans la
/// donnée** : le texte est un participe passé, sans majuscule ni point final.
/// Une carte qui ne se lit pas après le préfixe est mal écrite.
struct ConfessionCard: Identifiable, Hashable, Sendable {
    let id: String
    let text: String
}

/// Un paquet de cartes. Même forme que `WordCategory` (§1.2) : du Swift, pas de
/// JSON — vérifié à la compilation et relisible en diff de PR.
struct ConfessionPack: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// SF Symbol.
    let symbol: String
    /// Un pack verrouillé n'est ni jouable ni visible tant que le contenu
    /// adulte n'est pas déverrouillé dans les réglages (spec §7.2, annexe §8).
    let isLocked: Bool
    let cards: [ConfessionCard]
}

// MARK: - Banque

enum NeverHaveIEverBank {

    /// Mémoire de pioche du jeu (spec §2.4). Un seul paquet : changer de packs
    /// en cours de soirée ne doit pas rendre au hasard les cartes déjà vues.
    static let deckID = "never-have-i-ever"

    static let packs: [ConfessionPack] = [
        ConfessionPack(
            id: "soft",
            name: "Tout public",
            symbol: "sun.max.fill",
            isLocked: false,
            cards: softCards
        ),
        ConfessionPack(
            id: "potes",
            name: "Entre potes",
            symbol: "person.2.fill",
            isLocked: false,
            cards: potesCards
        ),
        ConfessionPack(
            id: "epice",
            name: "Épicé",
            symbol: "flame.fill",
            isLocked: true,
            cards: epiceCards
        )
    ]

    static let defaultPackIDs: Set<String> = ["soft", "potes"]

    static var allCards: [ConfessionCard] { packs.flatMap(\.cards) }

    static func pack(id: String) -> ConfessionPack? { packs.first { $0.id == id } }

    /// Les packs qu'un écran de réglages a le droit de montrer : le verrouillé
    /// reste invisible tant qu'il ne l'est plus, et un paquet vide n'a rien à
    /// faire dans une liste de choix.
    static func selectablePacks(adultUnlocked: Bool) -> [ConfessionPack] {
        packs.filter { (!$0.isLocked || adultUnlocked) && !$0.cards.isEmpty }
    }

    /// Les cartes des packs retenus. Le verrou est appliqué **ici** et pas dans
    /// la vue : un réglage sauvegardé ne doit pas pouvoir rouvrir un pack que
    /// les réglages ont refermé depuis.
    static func cards(in packIDs: Set<String>, adultUnlocked: Bool) -> [ConfessionCard] {
        let retained = packs.filter { packIDs.contains($0.id) && (!$0.isLocked || adultUnlocked) }
        let cards = retained.flatMap(\.cards)
        // Sélection pointant sur un pack retiré depuis, ou table qui a tout
        // décoché : mieux vaut les packs par défaut qu'une partie sans carte.
        guard cards.isEmpty else { return cards }
        return packs.filter { defaultPackIDs.contains($0.id) }.flatMap(\.cards)
    }

    static func deck(
        packIDs: Set<String>,
        adultUnlocked: Bool,
        store: any DeckMemoryStore = UserDefaultsDeckMemory.shared
    ) -> Deck<ConfessionCard> {
        Deck(id: deckID, items: cards(in: packIDs, adultUnlocked: adultUnlocked), store: store)
    }

    /// Le numéro est écrit à la main et jamais dérivé de la position : insérer
    /// une carte au milieu du paquet ne doit pas renommer toutes les suivantes,
    /// sinon la mémoire des cartes déjà vues repart de zéro chez les joueurs.
    private static func card(_ number: Int, _ text: String) -> ConfessionCard {
        ConfessionCard(id: String(format: "nhie_%03d", number), text: text)
    }

    // MARK: - Pack « Tout public »

    /// Maladresses, habitudes, école, voyages, famille, technologie, sport,
    /// nourriture. Rien qui empêche de jouer avec des enfants à table.
    private static let softCards: [ConfessionCard] = [
        card(1, "menti sur mon âge"),
        card(2, "oublié l'anniversaire d'un proche"),
        card(3, "servi un repas raté en jurant que c'était voulu"),
        card(4, "dormi pendant un film au cinéma"),
        card(5, "donné un concert avec une brosse à cheveux en guise de micro"),
        card(6, "parlé tout seul dans la rue"),
        card(7, "retrouvé mes clés dans une poche déjà fouillée trois fois"),
        card(8, "mangé le dernier morceau sans demander"),
        card(9, "fait semblant d'aimer un cadeau"),
        card(10, "envoyé un message à la mauvaise personne"),
        card(11, "répondu « oui oui » sans savoir à quoi je disais oui"),
        card(12, "oublié le prénom de quelqu'un en pleine conversation"),
        card(13, "eu un fou rire dans un silence total"),
        card(14, "renversé un verre d'eau sur un clavier"),
        card(15, "mis un vêtement à l'envers toute la journée"),
        card(16, "trottiné dignement après un bus qui partait"),
        card(17, "raté mon arrêt pour ne pas déranger mon voisin de siège"),
        card(18, "dormi plus de douze heures d'affilée"),
        card(19, "mangé des céréales pour le dîner"),
        card(20, "nettoyé uniquement la partie visible depuis la porte"),
        card(21, "caché du désordre dans un placard"),
        card(22, "laissé une casserole « à tremper » une semaine entière"),
        card(23, "fait sonner l'alarme en grillant du pain"),
        card(24, "caché un paquet de gâteaux pour ne pas avoir à le partager"),
        card(25, "lu tout le menu pour commander la même chose que d'habitude"),
        card(26, "invoqué la règle des cinq secondes pour un aliment par terre"),
        card(27, "goûté de la pâte à gâteau crue"),
        card(28, "mis du ketchup sur un plat qui n'en demandait pas"),
        card(29, "mangé une pizza froide au petit-déjeuner"),
        card(30, "fait semblant d'être malade pour rester à la maison"),
        card(31, "séché un cours"),
        card(32, "copié sur mon voisin pendant un contrôle"),
        card(33, "récité une poésie en inventant la moitié"),
        card(34, "accusé l'imprimante pour un devoir que je n'avais pas fait"),
        card(35, "dormi en classe"),
        card(36, "été changé de place à cause des bavardages"),
        card(37, "été choisi en dernier pour une équipe"),
        card(38, "inventé une crampe pour sortir d'un match"),
        card(39, "marqué un but contre mon camp"),
        card(40, "abandonné un sport après trois séances"),
        card(41, "eu des courbatures pendant deux jours après un seul footing"),
        card(42, "acheté des baskets de course qui n'ont jamais couru"),
        card(43, "abandonné mon assiette en courant à cause d'une guêpe"),
        card(44, "voulu faire le malin et fini par me faire mal"),
        card(45, "cassé un objet chez quelqu'un et remis les morceaux en place"),
        card(46, "fait tomber quelque chose dans un magasin et quitté le rayon"),
        card(47, "possédé cinq parapluies sans jamais en avoir un sous la pluie"),
        card(48, "paniqué en ne sentant plus mon téléphone dans ma poche"),
        card(49, "raté un avion"),
        card(50, "applaudi à l'atterrissage d'un avion"),
        card(51, "actualisé la carte du livreur toutes les trente secondes"),
        card(52, "dit « yes yes » à l'étranger sans avoir compris la question"),
        card(53, "mangé un plat sans savoir ce que c'était"),
        card(54, "été malade sur un manège pour enfants"),
        card(55, "suivi mon GPS jusque dans un champ"),
        card(56, "refusé de demander mon chemin par fierté"),
        card(57, "confondu deux personnes qui ne se ressemblent pas"),
        card(58, "appelé une enseignante « maman »"),
        card(59, "rendu un salut qui ne m'était pas destiné"),
        card(60, "répondu « vous aussi » quand on me souhaitait bon voyage"),
        card(61, "tenu la porte à quelqu'un de si loin qu'il a dû courir"),
        card(62, "râlé contre le retard des autres depuis le mauvais endroit"),
        card(63, "oublié pourquoi j'entrais dans une pièce"),
        card(64, "cherché mon téléphone en le tenant à la main"),
        card(65, "cherché mes lunettes posées sur ma tête"),
        card(66, "rangé un objet dans un endroit trop sûr pour le retrouver"),
        card(67, "écrit une liste de courses et oublié de la prendre"),
        card(68, "acheté un truc inutile parce qu'il était en promo"),
        card(69, "entassé un plein tiroir de câbles mystérieux"),
        card(70, "fait la voix de mon animal pour répondre à sa place"),
        card(71, "parlé à un animal comme à une personne"),
        card(72, "été réveillé par un chat sur le visage"),
        card(73, "vérifié derrière le rideau de douche en rentrant"),
        card(74, "couru jusqu'à mon lit après avoir éteint la lumière"),
        card(75, "laissé une plante mourir de soif"),
        card(76, "fait mourir une plante en l'arrosant trop"),
        card(77, "encouragé mes plantes à voix haute"),
        card(78, "cuisiné « à l'instinct » un plat que personne n'a fini"),
        card(79, "photographié mon assiette pendant que les autres attendaient"),
        card(80, "senti un aliment douteux avant de le manger quand même"),
        card(81, "découvert une expérience scientifique au fond de mon frigo"),
        card(82, "fait les courses en ayant très faim"),
        card(83, "mangé debout devant le réfrigérateur ouvert"),
        card(84, "oublié les paroles en chantant devant tout le monde"),
        card(85, "dansé alors que personne d'autre ne dansait"),
        card(86, "supplié pour un instrument puis arrêté au bout d'un mois"),
        card(87, "préparé un discours de remerciement pour un prix imaginaire"),
        card(88, "commencé à écrire mes mémoires à dix ans"),
        card(89, "eu un frisson de gênance en relisant mon journal intime"),
        card(90, "archivé mes vieilles publications tellement c'était cringe"),
        card(91, "gardé un doudou bien plus longtemps que prévu"),
        card(92, "pleuré devant un dessin animé"),
        card(93, "revu toute une série au lieu d'en commencer une nouvelle"),
        card(94, "déplacé ma pile de livres « à lire » d'année en année"),
        card(95, "lu la dernière page d'un livre en premier"),
        card(96, "regardé le résumé d'un film au lieu du film"),
        card(97, "fait semblant d'avoir vu un film très connu"),
        card(98, "vécu des mois avec un écran de téléphone en toile d'araignée"),
        card(99, "envoyé un vocal de huit minutes pour une question simple"),
        card(100, "parlé dans le vide en visio avec le micro coupé")
    ]

    // MARK: - Pack « Entre potes »

    /// Gênant plutôt que sage : petits mensonges sociaux, mauvaise foi,
    /// habitudes de téléphone. Toujours tout public — l'app est classée 4+.
    private static let potesCards: [ConfessionCard] = [
        card(101, "fait semblant de ne pas voir quelqu'un dans la rue"),
        card(102, "fait semblant de ne pas voir un message pendant trois jours"),
        card(103, "annulé en prétextant la fatigue puis posté une story à minuit"),
        card(104, "espéré très fort que l'autre annule en premier"),
        card(105, "dit « on se rappelle » sans jamais rappeler"),
        card(106, "répondu « je découvre à l'instant » une semaine plus tard"),
        card(107, "ghosté une conversation puis repris comme si de rien n'était"),
        card(108, "dit « j'arrive » sans avoir quitté mon lit"),
        card(109, "été en retard à mon propre anniversaire"),
        card(110, "posé un lapin en ayant simplement oublié"),
        card(111, "programmé sept réveils et ignoré les sept"),
        card(112, "scrollé devant un film et demandé qui était ce personnage"),
        card(113, "préparé ma phrase suivante au lieu d'écouter la réponse"),
        card(114, "hoché la tête sans rien comprendre"),
        card(115, "raconté une histoire à la personne qui me l'avait racontée"),
        card(116, "ressorti la même anecdote à chaque soirée depuis des années"),
        card(117, "exagéré une histoire pour la rendre plus drôle"),
        card(118, "ri à une blague que je n'avais pas comprise"),
        card(119, "eu honte de mon bilan musical de fin d'année"),
        card(120, "prétendu aimer un plat pour ne vexer personne"),
        card(121, "prétendu avoir cuisiné un plat acheté tout prêt"),
        card(122, "mangé la nourriture de quelqu'un dans un frigo partagé"),
        card(123, "mangé « une dernière chips » pendant vingt minutes"),
        card(124, "commandé un dessert en disant que c'était pour partager"),
        card(125, "promis d'aller au lit tôt et veillé jusqu'à deux heures"),
        card(126, "annoncé un grand projet sans jamais m'y mettre"),
        card(127, "promis de me remettre au sport à chaque début de mois"),
        card(128, "payé un abonnement de sport sans jamais y aller"),
        card(129, "téléchargé une appli de sport ouverte une seule fois"),
        card(130, "prolongé une pause aux toilettes pour avoir la paix"),
        card(131, "cliqué sur « accepter » sans rien lire"),
        card(132, "utilisé le même mot de passe partout"),
        card(133, "retapé le même mot de passe plus lentement pour voir"),
        card(134, "envoyé une capture d'écran à la personne concernée"),
        card(135, "regretté un message une seconde après l'avoir envoyé"),
        card(136, "supprimé un message que tout le monde avait déjà lu"),
        card(137, "remonté un profil jusqu'en 2014 et liké par accident"),
        card(138, "stalké quelqu'un au point de connaître le nom de son chien"),
        card(139, "cherché mon propre nom sur internet"),
        card(140, "passé en mode avion en pleine dispute"),
        card(141, "simulé un appel pour échapper à une conversation"),
        card(142, "quitté une fête sans dire au revoir"),
        card(143, "annoncé mon départ une heure avant de vraiment partir"),
        card(144, "dit au revoir à tout le monde puis relancé une conversation"),
        card(145, "passé la soirée collé au buffet pour éviter de parler"),
        card(146, "confisqué l'enceinte convaincu d'avoir meilleur goût"),
        card(147, "adopté définitivement un chargeur qu'on m'avait prêté"),
        card(148, "offert un cadeau que j'avais moi-même reçu"),
        card(149, "oublié d'enlever l'étiquette de prix d'un cadeau"),
        card(150, "cherché le prix d'un cadeau qu'on m'avait offert"),
        card(151, "divisé le prix d'un achat par deux en le racontant à la maison"),
        card(152, "gardé une monnaie rendue en trop"),
        card(153, "fait semblant de chercher mon portefeuille"),
        card(154, "dit « c'est moi qui invite » et regretté aussitôt"),
        card(155, "triché à un jeu de société"),
        card(156, "changé les règles d'un jeu en pleine partie"),
        card(157, "renversé un plateau de jeu en perdant"),
        card(158, "eu le seum après avoir perdu à un jeu « juste pour rire »"),
        card(159, "laissé gagner un enfant sans le lui dire"),
        card(160, "fait exprès de perdre pour finir plus vite"),
        card(161, "regardé les cartes de mon voisin"),
        card(162, "juré que je n'avais pas triché alors que si"),
        card(163, "prétendu que gagner ne m'intéressait pas"),
        card(164, "crié tout seul devant un match à la télévision"),
        card(165, "commenté un sport dont je ne connais aucune règle"),
        card(166, "rejoué tout un clip seul dans ma chambre"),
        card(167, "chanté dans une voiture en croisant un regard"),
        card(168, "répété une danse tendance en secret pour avoir l'air spontané"),
        card(169, "pris cinquante photos pour n'en garder qu'une"),
        card(170, "recadré une photo pour en faire disparaître quelqu'un"),
        card(171, "utilisé un filtre en jurant que non"),
        card(172, "supprimé une story quarante secondes après l'avoir publiée"),
        card(173, "réécouté mon propre vocal juste après l'avoir envoyé"),
        card(174, "rédigé un pavé furieux pour finalement envoyer « ok »"),
        card(175, "eu la flemme d'une soirée que j'avais moi-même organisée"),
        card(176, "croisé quelqu'un d'une appli de rencontre et regardé ailleurs"),
        card(177, "veillé toute la nuit pour un épisode de plus"),
        card(178, "regardé en cachette l'épisode qu'on devait voir ensemble"),
        card(179, "révélé un rebondissement sans faire exprès"),
        card(180, "prétendu n'avoir jamais vu un épisode pour le revoir"),
        card(181, "chanté les mauvaises paroles d'une chanson pendant des années"),
        card(182, "découvert très tard que je déformais une expression connue"),
        card(183, "utilisé un mot sans en connaître le sens"),
        card(184, "corrigé quelqu'un et eu complètement tort"),
        card(185, "vérifié en douce sur mon téléphone qui avait raison"),
        card(186, "lancé un débat juste pour contredire"),
        card(187, "gardé un secret moins de dix minutes"),
        card(188, "répété un secret en précisant que c'en était un"),
        card(189, "commencé une phrase par « je ne devrais pas le dire mais »"),
        card(190, "fait semblant d'avoir compris une règle du jeu")
    ]

    // MARK: - Pack verrouillé

    /// **Volontairement vide, et ce n'est pas un oubli.**
    ///
    /// L'app est classée **4+** et a été soumise à Apple en déclarant aucune
    /// référence à l'alcool, au tabac, aux drogues, au sexe ni à aucun thème
    /// Pack 18+, demandé par Arthur pour la 1.1 — la fiche App Store bascule
    /// en 17+ avec cette version, la déclaration d'âge est mise à jour au même
    /// moment. Registre Picolo : cru, suggestif, alcool assumé. Les limites qui
    /// ne se franchissent pas, même en 17+ : rien de graphiquement explicite
    /// (règle 1.1.4), rien sans consentement, rien impliquant des mineurs.
    private static let epiceCards: [ConfessionCard] = [
        card(191, "fait ça ailleurs que dans un lit"),
        card(192, "appris son prénom sur le courrier de l'entrée"),
        card(193, "eu un plan dont je tairai le prénom jusqu'à ma mort"),
        card(194, "quitté une soirée en couple… pas le mien"),
        card(195, "eu une histoire avec quelqu'un du boulot en jurant que jamais"),
        card(196, "quitté un lit par la fenêtre, littéralement"),
        card(197, "été interrompu par un appel de ma mère au pire moment"),
        card(198, "utilisé « je vais prendre une douche » comme invitation"),
        card(199, "eu une aventure avec l'ex d'un pote"),
        card(200, "dit « c'était une erreur » et recommencé la semaine d'après"),
        card(201, "fait un pacte « si on est célibataires à trente ans »"),
        card(202, "envoyé le récap de ma nuit au mauvais groupe"),
        card(203, "recompté mes ex en retirant ceux qui ne comptent pas"),
        card(204, "gardé un vêtement d'un ex comme trophée de guerre"),
        card(205, "gardé les chaussettes"),
        card(206, "mis un mot de passe sur une app de galerie photo"),
        card(207, "été noté sur dix… et vexé du résultat"),
        card(208, "pris une douche à deux « pour économiser l'eau »"),
        card(209, "appelé mon plan régulier « juste un pote »"),
        card(210, "eu un crush sur quelqu'un présent autour de cette table"),
        card(211, "fait connaissance à l'horizontale avant le nom de famille"),
        card(212, "fait ça chez mes parents pendant qu'ils étaient là"),
        card(213, "planifié un « hasard » pour croiser mon crush"),
        card(214, "eu des sentiments pour mon plan et rien dit"),
        card(215, "vérifié si les voisins avaient entendu"),
        card(216, "donné un faux prénom du début à la fin"),
        card(217, "fini chez l'ostéo après une idée ambitieuse"),
        card(218, "fait ça en vacances avec quelqu'un de l'hôtel"),
        card(219, "répondu au téléphone au milieu"),
        card(220, "tenu un classement de mes ex avec des critères précis"),
        card(221, "répondu « pareil » à un « je t'aime »"),
        card(222, "été attiré par la personne que mon groupe déteste"),
        card(223, "embrassé quelqu'un pour gagner un pari"),
        card(224, "fini une soirée avec plus de suçons que de dignité"),
        card(225, "confondu deux prénoms… par écrit"),
        card(226, "calculé un lien de parenté en pleine soirée « au cas où »"),
        card(227, "accepté un rencard uniquement pour le buffet"),
        card(228, "été délogé d'un endroit public par un agent de sécurité"),
        card(229, "tenu un tableau comparatif, avec des colonnes"),
        card(230, "dit « je t'aime » pendant, sans le penser une seconde"),
        card(231, "fait ma déclaration au troisième verre et nié au quatrième"),
        card(232, "découvert une relation par une story"),
        card(233, "monté une story alibi pour couvrir ma vraie soirée"),
        card(234, "su que c'était une bêtise avant, pendant et après"),
        card(235, "gardé une boîte d'affaires d'ex comme un petit musée"),
        card(236, "accepté un rencard le lendemain d'un autre rencard"),
        card(237, "croisé ses parents en sortant de la salle de bain"),
        card(238, "prétexté une gastro pour caser deux rencards le même week-end"),
        card(239, "fait ça avec quelqu'un rencontré le soir même"),
        card(240, "laissé un vêtement exprès pour avoir une raison de revenir"),
        card(241, "demandé une photo « artistique » en retour"),
        card(242, "effacé une conversation entière pour protéger ma réputation"),
        card(243, "vidé mon historique avant de prêter mon téléphone"),
        card(244, "fait croire que c'était ma première fois"),
        card(245, "fait croire que ce n'était pas ma première fois"),
        card(246, "eu un plan avec quelqu'un de beaucoup trop connu du groupe"),
        card(247, "été le plan B en toute connaissance de cause"),
        card(248, "reçu un « c'était sympa » avec le mauvais prénom"),
        card(249, "eu besoin de me tenir au mur le lendemain d'une soirée jambes"),
        card(250, "juré fidélité à la tequila puis demandé pardon au gin")
    ]
}
