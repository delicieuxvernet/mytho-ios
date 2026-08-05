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
        card(3, "brûlé un plat que je préparais"),
        card(4, "dormi pendant un film au cinéma"),
        card(5, "chanté à tue-tête sous la douche"),
        card(6, "parlé tout seul dans la rue"),
        card(7, "perdu mes clés pendant plus d'une heure"),
        card(8, "mangé le dernier morceau sans demander"),
        card(9, "fait semblant d'aimer un cadeau"),
        card(10, "envoyé un message à la mauvaise personne"),
        card(11, "répondu à un message trois jours plus tard"),
        card(12, "oublié le prénom de quelqu'un en pleine conversation"),
        card(13, "ri au mauvais moment"),
        card(14, "renversé un verre d'eau sur un clavier"),
        card(15, "mis un vêtement à l'envers toute la journée"),
        card(16, "couru après un bus qui partait"),
        card(17, "raté mon arrêt en écoutant de la musique"),
        card(18, "dormi plus de douze heures d'affilée"),
        card(19, "mangé des céréales pour le dîner"),
        card(20, "rangé une pièce entière juste avant une visite"),
        card(21, "caché du désordre dans un placard"),
        card(22, "fait la vaisselle en dansant"),
        card(23, "oublié un plat au four"),
        card(24, "mangé une glace en plein hiver"),
        card(25, "commandé le même plat trois fois de suite"),
        card(26, "mangé quelque chose tombé par terre"),
        card(27, "goûté de la pâte à gâteau crue"),
        card(28, "mis du ketchup sur un plat qui n'en demandait pas"),
        card(29, "mangé une pizza froide au petit-déjeuner"),
        card(30, "fait semblant d'être malade pour rester à la maison"),
        card(31, "séché un cours"),
        card(32, "copié sur mon voisin pendant un contrôle"),
        card(33, "oublié mes devoirs à la maison"),
        card(34, "inventé une excuse pour justifier un retard"),
        card(35, "dormi en classe"),
        card(36, "été puni à l'école"),
        card(37, "été choisi en dernier pour une équipe"),
        card(38, "gagné une compétition sportive"),
        card(39, "marqué un but contre mon camp"),
        card(40, "abandonné un sport après trois séances"),
        card(41, "couru dix kilomètres d'une traite"),
        card(42, "fait du vélo sans les mains"),
        card(43, "été piqué par une abeille"),
        card(44, "grimpé tout en haut d'un arbre"),
        card(45, "cassé un objet chez quelqu'un d'autre"),
        card(46, "renversé une plante en passant"),
        card(47, "perdu un parapluie"),
        card(48, "oublié un sac dans un train"),
        card(49, "raté un avion"),
        card(50, "voyagé seul à l'étranger"),
        card(51, "dormi sous une tente en pleine pluie"),
        card(52, "visité un pays dont je ne parlais pas la langue"),
        card(53, "mangé un plat sans savoir ce que c'était"),
        card(54, "eu le mal de mer"),
        card(55, "pris la mauvaise direction pendant une heure"),
        card(56, "demandé mon chemin trois fois de suite"),
        card(57, "confondu deux personnes qui ne se ressemblent pas"),
        card(58, "appelé une enseignante « maman »"),
        card(59, "salué quelqu'un qui ne me disait pas bonjour"),
        card(60, "fait un grand signe à un inconnu par erreur"),
        card(61, "tenu une porte beaucoup trop longtemps"),
        card(62, "attendu au mauvais point de rendez-vous"),
        card(63, "oublié pourquoi j'entrais dans une pièce"),
        card(64, "cherché mon téléphone en le tenant à la main"),
        card(65, "cherché mes lunettes posées sur ma tête"),
        card(66, "rangé un objet dans un endroit trop sûr pour le retrouver"),
        card(67, "écrit une liste de courses et oublié de la prendre"),
        card(68, "acheté quelque chose dont je n'avais aucun besoin"),
        card(69, "gardé un objet cassé pendant des années"),
        card(70, "donné un surnom ridicule à un animal"),
        card(71, "parlé à un animal comme à une personne"),
        card(72, "été réveillé par un chat sur le visage"),
        card(73, "eu peur d'un bruit dans la maison"),
        card(74, "dormi avec la lumière allumée"),
        card(75, "laissé une plante mourir de soif"),
        card(76, "fait mourir une plante en l'arrosant trop"),
        card(77, "planté quelque chose qui a vraiment poussé"),
        card(78, "cuisiné un plat entier sans recette"),
        card(79, "suivi une recette et raté le résultat"),
        card(80, "mangé un aliment périmé sans le savoir"),
        card(81, "oublié un aliment au fond du réfrigérateur"),
        card(82, "fait les courses en ayant très faim"),
        card(83, "mangé debout devant le réfrigérateur ouvert"),
        card(84, "chanté devant un public"),
        card(85, "dansé alors que personne d'autre ne dansait"),
        card(86, "joué d'un instrument devant quelqu'un"),
        card(87, "dessiné quelque chose dont je suis encore fier"),
        card(88, "écrit un poème"),
        card(89, "tenu un journal intime"),
        card(90, "relu de vieux messages en cachette"),
        card(91, "gardé un dessin de mon enfance"),
        card(92, "pleuré devant un dessin animé"),
        card(93, "regardé la même série deux fois de suite"),
        card(94, "commencé un livre sans jamais le finir"),
        card(95, "lu la dernière page d'un livre en premier"),
        card(96, "raconté la fin d'un film à quelqu'un"),
        card(97, "fait semblant d'avoir vu un film très connu"),
        card(98, "cassé l'écran de mon téléphone"),
        card(99, "envoyé un message vocal de plus de trois minutes"),
        card(100, "oublié de couper mon micro pendant un appel")
    ]

    // MARK: - Pack « Entre potes »

    /// Gênant plutôt que sage : petits mensonges sociaux, mauvaise foi,
    /// habitudes de téléphone. Toujours tout public — l'app est classée 4+.
    private static let potesCards: [ConfessionCard] = [
        card(101, "fait semblant de ne pas voir quelqu'un dans la rue"),
        card(102, "traversé la rue pour éviter une conversation"),
        card(103, "inventé une excuse pour annuler un plan"),
        card(104, "annulé un rendez-vous à la dernière minute"),
        card(105, "dit « on se rappelle » sans jamais rappeler"),
        card(106, "laissé un message sans réponse pendant une semaine"),
        card(107, "répondu « je suis en route » sans avoir bougé"),
        card(108, "dit que j'arrivais dans cinq minutes en étant chez moi"),
        card(109, "été en retard à mon propre anniversaire"),
        card(110, "oublié un rendez-vous important"),
        card(111, "repoussé mon réveil trois fois de suite"),
        card(112, "regardé mon téléphone en pleine conversation"),
        card(113, "fait semblant d'écouter jusqu'au bout"),
        card(114, "hoché la tête sans rien comprendre"),
        card(115, "raconté une histoire à la personne qui me l'avait racontée"),
        card(116, "répété la même anecdote deux soirées de suite"),
        card(117, "exagéré une histoire pour la rendre plus drôle"),
        card(118, "ri à une blague que je n'avais pas comprise"),
        card(119, "fait semblant de connaître un groupe de musique"),
        card(120, "prétendu aimer un plat pour ne vexer personne"),
        card(121, "prétendu avoir cuisiné un plat acheté tout prêt"),
        card(122, "mangé la nourriture de quelqu'un dans un frigo partagé"),
        card(123, "fini un pot de glace à moi tout seul"),
        card(124, "commandé un dessert en disant que c'était pour partager"),
        card(125, "promis d'aller au lit tôt et veillé jusqu'à deux heures"),
        card(126, "annoncé un grand projet sans jamais m'y mettre"),
        card(127, "fait semblant de faire du sport pendant tout un mois"),
        card(128, "payé un abonnement de sport sans jamais y aller"),
        card(129, "abandonné une bonne résolution en moins d'une semaine"),
        card(130, "dit que j'avais lu les conditions d'utilisation"),
        card(131, "cliqué sur « accepter » sans rien lire"),
        card(132, "utilisé le même mot de passe partout"),
        card(133, "oublié un mot de passe le jour même où je l'ai choisi"),
        card(134, "envoyé un message à un groupe par erreur"),
        card(135, "regretté un message une seconde après l'avoir envoyé"),
        card(136, "supprimé un message beaucoup trop tard"),
        card(137, "aimé une très vieille publication par accident"),
        card(138, "regardé le profil de quelqu'un pendant une heure"),
        card(139, "cherché mon propre nom sur internet"),
        card(140, "fait semblant que mon téléphone n'avait plus de batterie"),
        card(141, "simulé un appel pour échapper à une conversation"),
        card(142, "quitté une fête sans dire au revoir"),
        card(143, "été le dernier à partir d'une soirée"),
        card(144, "dormi sur un canapé qui n'était pas le mien"),
        card(145, "perdu quelque chose d'important pendant une sortie"),
        card(146, "rendu un objet emprunté en très mauvais état"),
        card(147, "emprunté quelque chose sans jamais le rendre"),
        card(148, "offert un cadeau que j'avais moi-même reçu"),
        card(149, "oublié d'enlever l'étiquette de prix d'un cadeau"),
        card(150, "cherché le prix d'un cadeau qu'on m'avait offert"),
        card(151, "menti sur le prix de quelque chose"),
        card(152, "gardé une monnaie rendue en trop"),
        card(153, "fait semblant de chercher mon portefeuille"),
        card(154, "laissé quelqu'un d'autre payer exprès"),
        card(155, "triché à un jeu de société"),
        card(156, "changé les règles d'un jeu en pleine partie"),
        card(157, "renversé un plateau de jeu en perdant"),
        card(158, "boudé après avoir perdu"),
        card(159, "laissé gagner un enfant sans le lui dire"),
        card(160, "fait exprès de perdre pour finir plus vite"),
        card(161, "regardé les cartes de mon voisin"),
        card(162, "juré que je n'avais pas triché alors que si"),
        card(163, "prétendu que gagner ne m'intéressait pas"),
        card(164, "crié tout seul devant un match à la télévision"),
        card(165, "supporté une équipe uniquement pour ses couleurs"),
        card(166, "dansé seul dans mon salon"),
        card(167, "chanté dans une voiture en croisant un regard"),
        card(168, "répété une chorégraphie devant un miroir"),
        card(169, "pris cinquante photos pour n'en garder qu'une"),
        card(170, "recadré une photo pour en faire disparaître quelqu'un"),
        card(171, "utilisé un filtre en jurant que non"),
        card(172, "publié quelque chose puis tout effacé dans l'heure"),
        card(173, "relu mon message dix fois avant de l'envoyer"),
        card(174, "écrit un long message et tout effacé"),
        card(175, "fait semblant d'être occupé pour rester chez moi"),
        card(176, "annulé une sortie pour regarder une série"),
        card(177, "veillé toute la nuit pour un épisode de plus"),
        card(178, "regardé un épisode en avance sans attendre les autres"),
        card(179, "révélé un rebondissement sans faire exprès"),
        card(180, "prétendu n'avoir jamais vu un épisode pour le revoir"),
        card(181, "chanté les mauvaises paroles d'une chanson pendant des années"),
        card(182, "inventé le sens d'un mot en pleine discussion"),
        card(183, "utilisé un mot sans en connaître le sens"),
        card(184, "corrigé quelqu'un et eu complètement tort"),
        card(185, "été très sûr de moi et totalement à côté"),
        card(186, "lancé un débat juste pour contredire"),
        card(187, "gardé un secret moins de dix minutes"),
        card(188, "répété un secret en précisant que c'en était un"),
        card(189, "promis de n'en parler à personne et tout raconté"),
        card(190, "fait semblant d'avoir compris une règle du jeu")
    ]

    // MARK: - Pack verrouillé

    /// **Volontairement vide, et ce n'est pas un oubli.**
    ///
    /// L'app est classée **4+** et a été soumise à Apple en déclarant aucune
    /// référence à l'alcool, au tabac, aux drogues, au sexe ni à aucun thème
    /// mature. Livrer ce pack ferait basculer la fiche en 17+ **même verrouillé**
    /// (spec §8) et invaliderait la classification déjà déposée — or « la
    /// décision se prend avant la première soumission, pas après ».
    ///
    /// Le verrou, lui, est entièrement câblé : `isLocked` ici,
    /// `AppSettings.adultContentUnlocked` côté réglages, filtrage dans
    /// `cards(in:adultUnlocked:)`, pack absent de `selectablePacks`. Le jour où
    /// la classification sera tranchée, il n'y aura plus que des cartes à
    /// écrire à cet endroit.
    private static let epiceCards: [ConfessionCard] = []
}
