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
        card(15, "fait pipi dans la piscine pendant que les autres nageaient")
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
        card(21, "fantasmé sur quelqu'un dans cette pièce"),
        card(22, "regardé du porno pendant que quelqu'un dormait à côté"),
        card(23, "eu un orgasme en pensant au frère ou à la sœur d'un pote"),
        card(24, "envoyé une photo de mes parties intimes par erreur"),
        card(25, "vomi sur quelqu'un"),
        card(26, "pensé à quelqu'un de cette table en me touchant"),
        card(27, "couché avec l'ex de quelqu'un qui est là ce soir"),
        card(28, "classé les gens de cette pièce du plus au moins baisable"),
        card(29, "eu envie d'embrasser la personne assise à ma droite"),
        card(32, "simulé un orgasme, l'autre simulait aussi"),
        card(33, "trompé quelqu'un qui me trompait déjà"),
        card(34, "surpris un couple puis été surpris par eux la même nuit"),
        card(35, "fini avant que l'autre ait enlevé son pantalon"),
        card(36, "regardé l'heure par-dessus son épaule en plein rapport"),
        card(39, "laissé un vocal de quatre minutes à mon ex, bourré"),
        card(40, "dit je t'aime juste pour finir la nuit chez quelqu'un"),
        card(42, "gardé quelqu'un en réserve au cas où l'autre me lâche"),
        card(44, "fait semblant de dormir pour éviter la deuxième fois"),
        card(45, "menti sur mon nombre de partenaires et entendu pire en face")
    ]
}
