import Foundation
import SwiftUI

// MARK: - Animations réduites

/// Trois états et non un booléen : le réglage système est un défaut, pas une
/// fatalité. Quelqu'un qui coupe les animations partout dans iOS peut vouloir
/// les garder ici — une soirée se joue sur les animations —, et l'inverse est
/// vrai aussi (mal des transports déclenché par une seule app).
enum ReducedMotionSetting: String, CaseIterable, Sendable {
    /// Suit `accessibilityReduceMotion`.
    case system
    /// Animations réduites, quoi qu'en dise le système.
    case forced
    /// Animations complètes, quoi qu'en dise le système.
    case disabled
}

// MARK: - Réglages globaux

/// L'unique écran de réglages de l'app (spec §2.6) : son, haptiques, animations
/// réduites, contenu adulte, réinitialisation des paquets.
///
/// `ObservableObject` + `UserDefaults` comme `GameSession` et `RosterStore`.
/// Pas de `@MainActor`, pour la même raison que `RosterStore` : le modèle doit
/// rester appelable depuis un `XCTestCase` ordinaire, et les vues qui le
/// pilotent sont déjà sur le main thread.
final class AppSettings: ObservableObject {

    /// Préfixe des clés de mémoire des paquets. `Deck` (spec §2.4) s'y conforme :
    /// c'est ce qui permet à « réinitialiser les paquets » de tout purger sans
    /// connaître la liste des jeux qui existeront un jour.
    static let deckStoragePrefix = "mytho.deck."

    // MARK: État

    /// Aucun son n'est encore joué ; l'interrupteur existe pour que les jeux à
    /// venir n'aient pas à réinventer leur propre réglage.
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: SettingsKeys.sound) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: SettingsKeys.haptics) }
    }

    @Published var reducedMotion: ReducedMotionSetting {
        didSet { defaults.set(reducedMotion.rawValue, forKey: SettingsKeys.reducedMotion) }
    }

    /// Le pack verrouillé d'Action ou vérité (spec §7.2). Jamais actif par
    /// défaut, jamais visible tant qu'il ne l'est pas.
    @Published private(set) var adultContentUnlocked: Bool {
        didSet { defaults.set(adultContentUnlocked, forKey: SettingsKeys.adultContent) }
    }

    /// Incrémenté à chaque « réinitialiser les paquets ». Un `Deck` déjà chargé
    /// en mémoire ne verrait rien passer si on se contentait de vider le disque :
    /// il observe ce compteur pour se remélanger sur-le-champ.
    @Published private(set) var deckResetToken: Int = 0

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Les captures d'écran automatisées doivent partir de réglages propres,
        // quel que soit ce qu'une exécution précédente a laissé sur le simulateur.
        let fresh = ProcessInfo.processInfo.arguments.contains("-uiTesting")

        // `bool(forKey:)` rend `false` pour une clé absente : impossible d'en
        // distinguer un réglage coupé volontairement d'un premier lancement.
        self.soundEnabled = fresh ? true : (defaults.object(forKey: SettingsKeys.sound) as? Bool ?? true)
        self.hapticsEnabled = fresh ? true : (defaults.object(forKey: SettingsKeys.haptics) as? Bool ?? true)
        self.adultContentUnlocked = fresh ? false : (defaults.object(forKey: SettingsKeys.adultContent) as? Bool ?? false)

        // Une valeur illisible (réglage retiré d'une version future) retombe sur
        // le système plutôt que de figer les animations d'un côté ou de l'autre.
        let stored: String? = fresh ? nil : defaults.string(forKey: SettingsKeys.reducedMotion)
        if let stored, let parsed = ReducedMotionSetting(rawValue: stored) {
            self.reducedMotion = parsed
        } else {
            self.reducedMotion = .system
        }
    }

    // MARK: Animations

    /// Le seul point de décision sur les animations : chaque écran passe la
    /// valeur de `@Environment(\.accessibilityReduceMotion)` et obtient la
    /// réponse, réglage utilisateur compris.
    func prefersReducedMotion(system: Bool) -> Bool {
        switch reducedMotion {
        case .system: return system
        case .forced: return true
        case .disabled: return false
        }
    }

    // MARK: Contenu adulte

    /// La confirmation d'âge est un argument et non un réglage voisin : on ne
    /// peut pas déverrouiller le pack en oubliant de la demander (spec §7.2).
    /// Reverrouiller, en revanche, ne se refuse jamais.
    ///
    /// Renvoie `false` si l'activation a été rejetée faute de confirmation.
    @discardableResult
    func setAdultContent(_ enabled: Bool, ageConfirmed: Bool) -> Bool {
        guard !enabled || ageConfirmed else { return false }
        adultContentUnlocked = enabled
        return true
    }

    // MARK: Paquets

    /// Purge la mémoire des cartes déjà vues, tous jeux confondus : c'est la
    /// sortie de secours quand un paquet a été épuisé et que la soirée veut
    /// repartir de zéro.
    ///
    /// Le balayage se fait par préfixe plutôt que par liste de clés connues :
    /// un jeu ajouté plus tard est purgé sans que ce fichier ait à changer.
    func resetDecks() {
        let deckKeys = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix(Self.deckStoragePrefix)
        }
        for key in deckKeys {
            defaults.removeObject(forKey: key)
        }
        deckResetToken &+= 1
    }
}

// MARK: - Clés de stockage

/// Hors de la classe : ces clés ne changent jamais et n'ont pas à être portées
/// par une instance.
private enum SettingsKeys {
    static let sound = "mytho.settings.sound"
    static let haptics = "mytho.settings.haptics"
    static let reducedMotion = "mytho.settings.reducedMotion"
    static let adultContent = "mytho.settings.adultContent"
}
