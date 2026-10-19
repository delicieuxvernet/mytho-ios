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
    static let deckID = "never-have-i-ever.v3"

    static let packs: [ConfessionPack] = [
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

    static let defaultPackIDs: Set<String> = ["potes"]

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

    // MARK: - Pack « Entre potes »

    /// Gênant plutôt que sage : petits mensonges sociaux, mauvaise foi,
    /// habitudes de téléphone. Trash corporel assumé, mais jouable sans la
    /// confirmation d'âge : ni sexe, ni alcool, ni drogue (l'app est en 17+,
    /// c'est la porte d'âge interne qui sépare les deux étages).
    private static let potesCards: [ConfessionCard] = [
        card(5, "embrassé quelqu'un juste après avoir vomi"),
        card(8, "pissé dans une bouteille et l'avoir oubliée dans ma chambre"),
        card(9, "oublié le prénom de quelqu'un qui venait de m'appeler par le mien"),
        card(14, "lu les messages de quelqu'un pendant qu'il dormait"),
        card(15, "fait pipi dans la piscine pendant que les autres nageaient"),

        // Version 2.0 (octobre 2026) : l'aveu brut, sans pirouette, comme
        // Arthur l'a réécrit en août — mais plus jeune : crush, date, ex,
        // coloc, soirées, et la table elle-même prise à partie.
        card(251, "fait caca chez un date"),
        card(252, "pété pendant un câlin"),
        card(253, "vomi par le nez"),
        card(254, "vomi dans le sac de quelqu'un"),
        card(255, "fait pipi dans un lavabo"),
        card(256, "pissé contre une voiture qui n'était pas la mienne"),
        card(257, "repris un chewing-gum déjà mâché"),
        card(258, "reniflé mes chaussettes pour savoir si je pouvais les remettre"),
        card(259, "reniflé mon aisselle en plein date"),
        card(260, "senti mes doigts après m'être gratté les fesses"),
        card(261, "collé une crotte de nez sous une table"),
        card(262, "accusé le chien d'un pet que j'avais fait"),
        card(263, "pété en cours et laissé quelqu'un d'autre se faire accuser"),
        card(264, "gardé le même slip trois jours d'affilée"),
        card(265, "dormi dans une baignoire"),
        card(266, "vomi sur mes propres chaussures"),
        card(267, "eu des auréoles de transpi en plein oral"),
        card(268, "éternué sur la nourriture de quelqu'un sans rien dire"),
        card(269, "lâché un pet dans un ascenseur plein"),
        card(270, "fait un bisou à un chien sur la bouche"),
        card(271, "dormi avec une peluche après mes dix-huit ans"),
        card(272, "eu des poux après mes quinze ans"),
        card(273, "léché un truc dégueu pour cinq euros"),
        card(274, "bu l'eau d'un vase"),
        card(275, "porté un vêtement avec l'étiquette pour le rendre après"),
        card(276, "mangé le repas de mon coloc dans le frigo"),
        card(277, "laissé la vaisselle moisir plus d'une semaine"),
        card(278, "séché un cours pour dormir"),
        card(279, "triché à un examen"),
        card(280, "fait une sieste dans les toilettes du boulot ou de la fac"),
        card(281, "dormi en cours au point de baver sur ma table"),
        card(282, "été viré d'un cours"),
        card(283, "inventé un décès dans ma famille pour excuser un retard"),
        card(284, "imité la voix de ma daronne pour appeler l'école"),
        card(285, "piqué de l'argent dans le porte-monnaie de mes parents"),
        card(286, "cassé un truc chez quelqu'un sans rien dire"),
        card(287, "accusé mon frère ou ma sœur d'une bêtise que j'avais faite"),
        card(288, "lu le journal intime de quelqu'un"),
        card(289, "fouillé le téléphone de quelqu'un que je fréquentais"),
        card(290, "volé un truc en magasin"),
        card(291, "dépensé tout mon salaire le jour où je l'ai reçu"),
        card(292, "pleuré devant une téléréalité"),
        card(293, "pleuré à un mariage où je ne connaissais personne"),
        card(294, "eu un fou rire à un enterrement"),
        card(295, "dansé tout seul au milieu d'une piste vide"),
        card(296, "fait le mur pour aller en soirée"),
        card(297, "fait rentrer quelqu'un en douce chez mes parents"),
        card(298, "dormi chez quelqu'un que je connaissais depuis deux heures"),
        card(299, "perdu mes chaussures en soirée"),
        card(300, "pleuré en soirée sans savoir pourquoi"),
        card(301, "dit « je t'aime » à un inconnu en soirée"),
        card(302, "piqué un verre en souvenir dans un bar"),
        card(303, "vomi par la fenêtre d'une voiture"),
        card(304, "réveillé toute la maison en rentrant à six heures"),
        card(305, "fait une sieste en pleine soirée dans une chambre au hasard"),
        card(306, "mangé un kebab assis par terre à cinq heures du matin"),
        card(307, "été recalé à l'entrée d'une boîte"),
        card(308, "lâché un pote en soirée pour suivre un crush"),
        card(309, "dit du mal de quelqu'un assis à cette table"),
        card(310, "été jaloux de quelqu'un ici"),
        card(311, "gardé un secret sur quelqu'un de cette table"),
        card(312, "eu honte d'un de mes potes présents ce soir"),
        card(313, "stalké quelqu'un de cette table avant de le rencontrer"),
        card(314, "matché avec quelqu'un de cette table"),
        card(315, "mis un vent à quelqu'un de cette table"),
        card(316, "embrassé quelqu'un assis à cette table"),
        card(317, "rêvé de quelqu'un de cette table"),
        card(318, "oublié l'anniversaire de mon meilleur pote"),
        card(319, "stalké un ex jusqu'à ses photos d'il y a dix ans"),
        card(320, "liké une vieille photo de mon crush en le stalkant"),
        card(321, "ghosté quelqu'un après un date"),
        card(322, "écrit à mon ex en pleine nuit"),
        card(323, "relu toute une conversation avec mon ex"),
        card(324, "posté une photo juste pour rendre jaloux mon ex"),
        card(325, "eu un crush sur le crush de mon meilleur pote"),
        card(326, "fait un bisou à quelqu'un pour gagner un défi"),
        card(327, "embrassé quelqu'un dont je ne connaissais pas le prénom"),
        card(328, "inventé un faux appel pour fuir un date"),
        card(329, "dit « je t'aime » en premier sans jamais avoir de réponse"),
        card(330, "pleuré dans les toilettes d'une soirée"),
        card(331, "menti sur mon âge pour impressionner quelqu'un"),
        card(332, "demandé à un pote de faire passer un message à mon crush"),
        card(333, "pécho l'ex d'un pote"),
        card(334, "eu un crush sur la daronne ou le daron d'un pote"),
        card(335, "rompu par message"),
        card(336, "rompu juste avant les vacances pour être tranquille"),
        card(337, "swipé sur le profil d'un pote par erreur"),
        card(338, "fait semblant d'être en couple pour me débarrasser de quelqu'un"),
        card(339, "embrassé quelqu'un dans un ascenseur"),
        card(340, "fait semblant de dormir pour ne pas parler à quelqu'un"),
        card(341, "gardé un sweat de mon ex pour dormir avec"),
        card(342, "regardé le profil de mon ex tous les jours pendant un mois"),
        card(343, "caché un crush à mes potes pendant plus d'un an"),
        card(344, "envoyé un message à mon crush puis éteint mon téléphone de stress"),
        card(345, "choisi les prénoms de nos futurs enfants après un seul date"),
        card(346, "dormi dans le même lit que mon crush sans qu'il se passe rien")
    ]

    // MARK: - Pack verrouillé

    /// Le pack « Épicé », 18+ : verrouillé derrière la confirmation d'âge,
    /// jamais coché d'office. Registre cru, suggestif, alcool assumé. Les
    /// limites qui ne se franchissent pas : rien de graphiquement explicite
    /// (règle 1.1.4), rien sans consentement, rien impliquant des mineurs.
    private static let epiceCards: [ConfessionCard] = [
        card(21, "fantasmé sur quelqu'un dans cette pièce"),
        card(22, "regardé du porno pendant que quelqu'un dormait à côté"),
        card(23, "eu un orgasme en pensant au frère ou à la sœur d'un pote"),
        card(24, "envoyé une photo de mes parties intimes par erreur"),
        card(25, "vomi sur quelqu'un"),
        card(26, "pensé à quelqu'un de cette table en me touchant"),
        card(27, "couché avec l'ex de quelqu'un qui est là ce soir"),
        card(28, "classé les gens de cette pièce du plus au moins baisable"),
        card(29, "eu envie d'embrasser la personne assise à ma droite"),
        card(32, "simulé un orgasme"),
        card(33, "trompé mon/ma partenaire"),
        card(34, "surpris un couple"),
        card(35, "fini en 30 secondes"),
        card(36, "regardé l'heure en plein rapport"),
        card(39, "laissé un vocal de quatre minutes à mon ex, bourré"),
        card(40, "dit je t'aime sans le penser"),
        card(42, "gardé quelqu'un en réserve au cas où l'autre me lâche"),
        card(44, "fait semblant de dormir pour éviter la deuxième fois"),
        card(45, "menti sur mon nombre de partenaires"),

        // Version 2.0 (octobre 2026) : le vécu cru des 18-30 ans, sans
        // jamais être graphique (règle 1.1.4), ni non consenti, ni
        // impliquer un mineur.
        card(347, "fait l'amour dans une voiture"),
        card(348, "fait l'amour dans des toilettes publiques"),
        card(349, "couché avec quelqu'un dont je n'ai jamais su le prénom"),
        card(350, "envoyé un nude"),
        card(351, "reçu un nude sans l'avoir demandé"),
        card(352, "eu un plan à trois"),
        card(353, "couché avec quelqu'un de cette table"),
        card(354, "fait l'amour chez mes parents pendant qu'ils dormaient"),
        card(355, "été surpris en plein acte"),
        card(356, "fait un strip-tease"),
        card(357, "couché avec quelqu'un moins d'une heure après l'avoir rencontré"),
        card(358, "couché avec un ex après la rupture"),
        card(359, "eu un plan cul pendant plus d'un an"),
        card(360, "envoyé un sexto pendant un repas de famille"),
        card(361, "fait l'amour sur une plage"),
        card(362, "couché avec quelqu'un beaucoup plus vieux que moi"),
        card(363, "pleuré après l'amour"),
        card(364, "ri au mauvais moment pendant l'amour"),
        card(365, "eu une panne au pire moment"),
        card(366, "eu un suçon que j'ai dû cacher à mes parents"),
        card(367, "fait une sextape"),
        card(368, "couché avec quelqu'un pour en oublier un autre"),
        card(369, "envoyé un sexto à la mauvaise personne"),
        card(370, "fait l'amour plus de cinq fois dans la même nuit"),
        card(371, "filé à l'anglaise après une nuit, sans un mot"),
        card(372, "embrassé deux personnes de cette table"),
        card(373, "dragué la mère ou le père d'un pote"),
        card(374, "couché avec quelqu'un du boulot ou de la fac"),
        card(375, "fait l'amour dans le lit de quelqu'un d'autre sans qu'il le sache"),
        card(376, "pensé à quelqu'un d'autre pendant l'amour"),
        card(377, "fait l'amour dans la chambre d'amis pendant une soirée"),
        card(378, "été le plan d'un soir de quelqu'un en couple"),
        card(379, "couché avec quelqu'un juste parce qu'il avait un bel appart"),
        card(380, "crié le mauvais prénom au lit"),
        card(381, "noté mes partenaires dans les notes de mon téléphone"),
        card(382, "testé une position et fini avec une crampe"),
        card(383, "fait l'amour au bureau"),
        card(384, "eu une relation avec deux personnes en même temps"),
        card(385, "couché avec mon meilleur pote ou ma meilleure pote"),
        card(386, "fait l'amour dans un train ou dans un avion"),
        card(387, "envoyé un message à mon ex pendant que quelqu'un était dans mon lit"),
        card(388, "dragué quelqu'un de cette table devant son copain ou sa copine"),
        card(389, "joué à action ou vérité jusqu'à ce que ça dégénère"),
        card(390, "regardé du porno au travail"),
        card(391, "couché avec un coloc"),
        card(392, "fait une déclaration bourré que j'ai regrettée le lendemain"),
        card(393, "fini la nuit avec quelqu'un que je trouvais moche en début de soirée"),
        card(394, "été bourré au point de rentrer sans aucun souvenir du trajet"),
        card(395, "pris une cuite la veille d'un examen"),
        card(396, "fini une soirée en pleurant dans les bras d'un inconnu"),
        card(397, "fait semblant d'être bourré pour embrasser quelqu'un"),
        card(398, "vomi dans un taxi"),
        card(399, "dormi tout habillé, chaussures aux pieds, après une soirée"),
        card(400, "appelé mes parents bourré pour leur dire que je les aimais"),
        card(401, "fini une soirée chez des gens dont je ne connaissais personne")
    ]
}
