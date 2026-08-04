import SwiftUI
import UIKit

/// Source de vérité visuelle. DA v2 « jeu de société dessiné », validée par
/// Arthur le 4 août 2026 : aplats francs, gros contours encrés, ombres franches
/// décalées — zéro flou, zéro transparence, zéro dégradé de verre.
///
/// L'app vit en deux peaux : le **jour** (papier crème — on discute, on vote)
/// et la **nuit** (encre sombre — on pioche en secret, on révèle). Chaque écran
/// choisit sa peau via l'environnement (`\.skin`).
enum Theme {

    // MARK: Accents (identiques jour et nuit)

    /// Violet de marque : la pioche et les actions principales.
    static let brand = Color(red: 0.424, green: 0.361, blue: 0.941)
    static let brandLight = Color(red: 0.576, green: 0.537, blue: 0.976)
    /// Ambre : Mr. White, dernière chance, révélations.
    static let amber = Color(red: 1.000, green: 0.757, blue: 0.271)
    /// Vert : les infiltrés et leurs victoires — la couleur de l'œil reptilien.
    static let mint = Color(red: 0.204, green: 0.827, blue: 0.600)
    /// Rouge corail : vote et élimination.
    static let crimson = Color(red: 0.937, green: 0.325, blue: 0.365)
    /// Bleu ciel : la phase de description.
    static let sky = Color(red: 0.298, green: 0.788, blue: 0.941)

    /// Chaque phase du jeu a sa température.
    static func accent(for phase: GamePhase?) -> Color {
        switch phase {
        case .dealing: return brand
        case .describing: return sky
        case .voting: return crimson
        case .elimination, .avengerStrike, .mrWhiteGuess: return amber
        case .finished: return mint
        case nil: return brand
        }
    }

    // MARK: Couleurs héritées (compat)

    /// Fond nuit — aussi la couleur de lancement et du texte sur teintes claires.
    static let night = Color(red: 0.082, green: 0.098, blue: 0.212)
    static let nightDeep = Color(red: 0.059, green: 0.067, blue: 0.161)

    /// Anciennes valeurs de la peau nuit, encore référencées ponctuellement.
    static let ink = Color.white
    static let inkMuted = Color.white.opacity(0.62)
    static let inkFaint = Color.white.opacity(0.38)
    static let surface = Color.white.opacity(0.07)
    static let surfaceStrong = Color.white.opacity(0.12)
    static let hairline = Color.white.opacity(0.14)

    /// Couleur associée à un rôle, pour les révélations.
    static func color(for role: Role) -> Color {
        switch role {
        case .civilian: return mint
        case .undercover: return brandLight
        case .mrWhite: return amber
        }
    }

    // MARK: Avatars

    /// Couleurs franches et joyeuses, façon cartoon.
    static let avatarPalette: [Color] = [
        Color(red: 1.000, green: 0.420, blue: 0.420),   // corail
        Color(red: 0.298, green: 0.788, blue: 0.941),   // ciel
        Color(red: 1.000, green: 0.757, blue: 0.271),   // ambre
        Color(red: 0.204, green: 0.827, blue: 0.600),   // menthe
        Color(red: 0.957, green: 0.447, blue: 0.714),   // rose
        Color(red: 0.545, green: 0.361, blue: 0.965),   // violet
        Color(red: 0.984, green: 0.573, blue: 0.235),   // orange
        Color(red: 0.176, green: 0.831, blue: 0.749),   // turquoise
    ]

    /// La position à table garantit des couleurs toutes distinctes jusqu'à
    /// 8 joueurs ; le repli par somme de scalaires couvre les noms hors table
    /// (`String.hashValue` est aléatoire à chaque lancement, inutilisable).
    static func avatarColor(for name: String, table: [String] = []) -> Color {
        if let index = table.firstIndex(of: name) {
            return avatarPalette[index % avatarPalette.count]
        }
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return avatarPalette[sum % avatarPalette.count]
    }

    // MARK: Typographie

    static func title(_ size: CGFloat = 30) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    // MARK: Métriques

    static let radius: CGFloat = 18
    static let radiusLarge: CGFloat = 26
    static let cardRatio: CGFloat = 0.68
    static let touchTarget: CGFloat = 44
    static let gutter: CGFloat = 20
    /// Épaisseur des contours encrés.
    static let stroke: CGFloat = 2.5
    /// Décalage vertical de l'ombre franche (le « carton » sous les cartes).
    static let drop: CGFloat = 5

    // MARK: Animations

    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.82)
    static let snap = Animation.spring(response: 0.28, dampingFraction: 0.75)
    static let flip = Animation.spring(response: 0.55, dampingFraction: 0.78)
}

// MARK: - Les deux peaux

/// Jour = papier crème (discussion, vote). Nuit = encre sombre (secrets,
/// révélations). Tout est opaque : aucun matériau translucide.
enum Skin {
    case day
    case night

    /// Fond d'écran.
    var background: Color {
        switch self {
        case .day: return Color(red: 0.984, green: 0.953, blue: 0.894)
        case .night: return Theme.night
        }
    }

    /// Fond des cartes et panneaux.
    var panel: Color {
        switch self {
        case .day: return .white
        case .night: return Color(red: 0.133, green: 0.157, blue: 0.341)
        }
    }

    /// Remplissage discret (lignes au repos, fonds de puces).
    var panelSoft: Color {
        switch self {
        case .day: return Color(red: 0.949, green: 0.914, blue: 0.847)
        case .night: return Color(red: 0.106, green: 0.125, blue: 0.282)
        }
    }

    /// Remplissage appuyé (boutons secondaires, compteurs).
    var panelStrong: Color {
        switch self {
        case .day: return Color(red: 0.914, green: 0.871, blue: 0.784)
        case .night: return Color(red: 0.165, green: 0.192, blue: 0.400)
        }
    }

    /// Le trait : contours, ombres franches.
    var outline: Color {
        switch self {
        case .day: return Color(red: 0.133, green: 0.118, blue: 0.200)
        case .night: return Theme.nightDeep
        }
    }

    /// Texte principal.
    var ink: Color {
        switch self {
        case .day: return Color(red: 0.133, green: 0.118, blue: 0.200)
        case .night: return .white
        }
    }

    var inkMuted: Color { ink.opacity(self == .day ? 0.60 : 0.65) }
    var inkFaint: Color { ink.opacity(0.38) }
    var hairline: Color { ink.opacity(0.15) }

    var colorScheme: ColorScheme { self == .day ? .light : .dark }
}

private struct SkinKey: EnvironmentKey {
    static let defaultValue: Skin = .night
}

extension EnvironmentValues {
    var skin: Skin {
        get { self[SkinKey.self] }
        set { self[SkinKey.self] = newValue }
    }
}

// MARK: - Retours haptiques

/// Vibrations calées sur les moments clés : piocher, éliminer, gagner.
@MainActor
enum Haptics {
    private static let selection = UISelectionFeedbackGenerator()

    /// À appeler juste avant une salve d'appuis : sans ça, la première vibration
    /// arrive avec un retard perceptible.
    static func prepare() {
        selection.prepare()
    }

    static func tap() {
        selection.selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - Fond commun

/// Fond à plat, sans aucun motif : posées sur le papier crème, les formes
/// géométriques isolées se lisaient comme des artefacts d'affichage (le cercle
/// en haut à gauche chevauchait en plus les pastilles « Quitter » / « Retour »).
struct Backdrop: View {
    var skin: Skin = .night
    /// Rien ne s'appuie dessus tant que le fond est nu ; le paramètre reste là
    /// parce que les appelants passent la teinte de phase à chaque changement.
    var accent: Color = Theme.brand

    var body: some View {
        skin.background
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: skin == .day)
    }
}
