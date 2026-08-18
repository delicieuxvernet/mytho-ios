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
    /// habitudes de téléphone. Toujours tout public — l'app est classée 4+.
    private static let potesCards: [ConfessionCard] = [
        card(1, "mangé mes crottes de nez"),
        card(2, "pété au lit avec quelqu'un et fait semblant de rien"),
        card(3, "fait caca dans mon pantalon"),
        card(4, "eu la diarrhée chez quelqu'un d'autre"),
        card(5, "embrassé quelqu'un juste après avoir vomi"),
        card(6, "pissé dans la douche en me disant que c'était plus écolo"),
        card(7, "fait la grosse commission et filé sans me laver les mains"),
        card(8, "vomi sur quelqu'un"),
        card(9, "vomi dans un endroit très mal choisi"),
        card(10, "dormi aux toilettes en soirée"),
        card(11, "pété en croyant être seul"),
        card(12, "reniflé mes chaussettes pour décider de les remettre"),
        card(13, "remis un caleçon sale faute de mieux"),
        card(14, "tiré la chasse en même temps pour couvrir le bruit"),
        card(15, "bouché les toilettes chez quelqu'un et rien dit"),
        card(16, "essuyé mes doigts sur le canapé de quelqu'un"),
        card(17, "mangé un truc périmé depuis plus d'un mois"),
        card(18, "gardé les mêmes draps plus de deux mois"),
        card(19, "rincé un verre sale vite fait pour un invité"),
        card(20, "pété dans un ascenseur juste avant de sortir")
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
        card(21, "envoyé un sexto au mauvais contact"),
        card(22, "fantasmé sur quelqu'un dans cette pièce"),
        card(23, "fait ça avec quelqu'un de cette pièce"),
        card(24, "menti sur mon nombre"),
        card(25, "simulé pour que ça finisse plus vite"),
        card(26, "eu un plan d'un soir dont j'avais oublié le prénom au réveil"),
        card(27, "gardé les nudes d'un ex « au cas où »"),
        card(28, "fouillé le téléphone de l'autre pendant sa douche"),
        card(29, "fait semblant d'être célibataire en soirée"),
        card(30, "répondu à un « tu dors ? » à 3h en sachant très bien pourquoi"),
        card(31, "fait ça le soir du premier rencard"),
        card(32, "été menotté — pas par la police"),
        card(33, "dit « c'était une erreur » en le refaisant la semaine d'après"),
        card(34, "écrit à mon ex en sachant très bien comment ça finirait"),
        card(35, "présenté un plan à mes parents comme « un ami »"),
        card(36, "répondu « on se refait ça » en bloquant dans la foulée"),
        card(37, "fait ça dans les toilettes d'une soirée"),
        card(38, "dit « je t'aime » pendant, sans le penser"),
        card(39, "embrassé quelqu'un pour rendre jaloux quelqu'un d'autre"),
        card(40, "stalké l'ex de mon ex jusqu'en 2019"),
        card(41, "trouvé quelqu'un de cette pièce sur une app de rencontre"),
        card(42, "regardé du porno pendant que quelqu'un dormait à côté"),
        card(43, "eu un orgasme en pensant à quelqu'un de totalement interdit"),
        card(44, "envoyé une photo de mes parties intimes par erreur"),
        card(45, "couché le premier soir")
    ]
}
