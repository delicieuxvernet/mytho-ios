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
    static let deckID = "never-have-i-ever.v2"

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
        card(2, "fait semblant d'être malade pour rater un truc"),
        card(3, "chanté à tue-tête sous la douche"),
        card(4, "ri à un moment très mal choisi"),
        card(5, "fait tomber mon téléphone sur mon visage au lit"),
        card(6, "fait semblant de comprendre une blague"),
        card(7, "triché à un jeu de société"),
        card(8, "pleuré devant un dessin animé"),
        card(9, "mangé un truc tombé par terre"),
        card(10, "senti un vêtement pour savoir s'il était propre"),
        card(11, "fait semblant de connaître les paroles"),
        card(12, "oublié le prénom de quelqu'un en le présentant"),
        card(13, "stalké quelqu'un jusqu'à ses photos de 2015"),
        card(14, "liké une vieille photo par accident"),
        card(15, "envoyé un message au mauvais groupe"),
        card(16, "fait semblant de dormir pour éviter une discussion"),
        card(17, "dit « j'arrive » sans avoir bougé"),
        card(18, "annulé un plan pour rester en pyjama"),
        card(19, "cherché mon téléphone en l'ayant dans la main"),
        card(20, "fait pipi dans une piscine")
    ]

    // MARK: - Pack « Entre potes »

    /// Gênant plutôt que sage : petits mensonges sociaux, mauvaise foi,
    /// habitudes de téléphone. Toujours tout public — l'app est classée 4+.
    private static let potesCards: [ConfessionCard] = [
        card(21, "ghosté quelqu'un sans aucune raison"),
        card(22, "supprimé un message en priant qu'il n'ait pas été lu"),
        card(23, "menti à mes parents sur où je dormais"),
        card(24, "embrassé quelqu'un que je n'aurais pas dû"),
        card(25, "eu un crush sur quelqu'un du groupe"),
        card(26, "dragué en copiant-collant le même message"),
        card(27, "donné un faux numéro"),
        card(28, "lu une conversation par-dessus une épaule"),
        card(29, "dit du mal de quelqu'un juste avant qu'il arrive"),
        card(30, "envoyé une capture d'écran à la mauvaise personne"),
        card(31, "menti sur un score à un jeu"),
        card(32, "été jaloux sans raison valable"),
        card(33, "vomi dans un endroit très mal choisi"),
        card(34, "pété en croyant être seul"),
        card(35, "dormi aux toilettes en soirée"),
        card(36, "juré de garder un secret et l'avoir dit le soir même"),
        card(37, "inventé une excuse à base de grand-mère malade"),
        card(38, "eu envie de frapper quelqu'un ici présent"),
        card(39, "répondu à un ancien crush après minuit"),
        card(40, "quitté une soirée sans dire au revoir à personne")
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
        card(41, "envoyé un sexto au mauvais contact"),
        card(42, "fantasmé sur quelqu'un dans cette pièce"),
        card(43, "fait ça avec quelqu'un de cette pièce"),
        card(44, "menti sur mon nombre"),
        card(45, "simulé pour que ça finisse plus vite"),
        card(46, "eu un plan d'un soir dont j'avais oublié le prénom au réveil"),
        card(47, "gardé les nudes d'un ex « au cas où »"),
        card(48, "fouillé le téléphone de l'autre pendant sa douche"),
        card(49, "fait semblant d'être célibataire en soirée"),
        card(50, "répondu à un « tu dors ? » à 3h en sachant très bien pourquoi"),
        card(51, "fait ça le soir du premier rencard"),
        card(52, "été menotté — pas par la police"),
        card(53, "dit « c'était une erreur » en le refaisant la semaine d'après"),
        card(54, "écrit à mon ex en sachant très bien comment ça finirait"),
        card(55, "présenté un plan à mes parents comme « un ami »"),
        card(56, "répondu « on se refait ça » en bloquant dans la foulée"),
        card(57, "fait ça dans les toilettes d'une soirée"),
        card(58, "dit « je t'aime » pendant, sans le penser"),
        card(59, "embrassé quelqu'un pour rendre jaloux quelqu'un d'autre"),
        card(60, "stalké l'ex de mon ex jusqu'en 2019"),
        card(61, "trouvé quelqu'un de cette pièce sur une app de rencontre"),
        card(62, "couché le premier soir"),
        card(63, "tourné une vidéo coquine"),
        card(64, "envoyé un nude en premier"),
        card(65, "eu un plan à trois — ou sérieusement envisagé"),
        card(66, "couché avec quelqu'un de pris"),
        card(67, "embrassé quelqu'un du même sexe"),
        card(68, "eu un sex-friend"),
        card(69, "couché ailleurs que dans un lit"),
        card(70, "été surpris en pleine action"),
        card(71, "appelé un ex complètement bourré"),
        card(72, "bu jusqu'au trou noir complet"),
        card(73, "fumé de l'herbe"),
        card(74, "volé dans un magasin"),
        card(75, "couché avec deux personnes différentes en 24 heures")
    ]
}
