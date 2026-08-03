import SwiftUI
import UIKit

/// Source de vérité visuelle. Toute couleur, taille ou animation de l'app vient
/// d'ici — aucune valeur en dur dans les vues.
enum Theme {

    // MARK: Couleurs

    /// Nuit profonde : le fond de toute l'app.
    static let night = Color(red: 0.055, green: 0.067, blue: 0.176)
    static let nightDeep = Color(red: 0.027, green: 0.035, blue: 0.110)
    /// Violet de marque, sur les actions principales.
    static let brand = Color(red: 0.400, green: 0.353, blue: 0.906)
    static let brandLight = Color(red: 0.576, green: 0.537, blue: 0.976)
    /// Ambre : Mr. White, alertes, dernière chance, révélations.
    static let amber = Color(red: 0.976, green: 0.702, blue: 0.263)
    /// Vert : les infiltrés et leurs victoires — la couleur de l'œil reptilien.
    static let mint = Color(red: 0.204, green: 0.827, blue: 0.600)
    /// Rouge corail : vote et élimination.
    static let crimson = Color(red: 0.937, green: 0.325, blue: 0.365)
    /// Bleu ciel : la phase de description.
    static let sky = Color(red: 0.298, green: 0.788, blue: 0.941)

    /// Chaque phase du jeu a sa température : c'est ce qui donne le rythme
    /// d'une app de soirée sans quitter la base nuit.
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

    // MARK: Avatars

    /// Couleurs franches et joyeuses, façon cartoon. L'attribution par nom est
    /// déterministe : un joueur garde son avatar d'un écran et d'une manche à
    /// l'autre. (`String.hashValue` est aléatoire à chaque lancement — on somme
    /// les scalaires à la place.)
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

    static func avatarColor(for name: String) -> Color {
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return avatarPalette[sum % avatarPalette.count]
    }

    static let ink = Color.white
    static let inkMuted = Color.white.opacity(0.62)
    static let inkFaint = Color.white.opacity(0.38)

    static let surface = Color.white.opacity(0.07)
    static let surfaceStrong = Color.white.opacity(0.12)
    static let hairline = Color.white.opacity(0.14)

    /// Dégradé de fond, commun à tous les écrans.
    static var backdrop: LinearGradient {
        LinearGradient(
            colors: [night, nightDeep],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Couleur associée à un rôle, pour les révélations.
    static func color(for role: Role) -> Color {
        switch role {
        case .civilian: return mint
        case .undercover: return brandLight
        case .mrWhite: return amber
        }
    }

    // MARK: Typographie

    /// Titres : arrondis et gras, l'identité d'un jeu de société.
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
    static let cardRatio: CGFloat = 0.68   // largeur / hauteur d'une carte
    static let touchTarget: CGFloat = 44
    static let gutter: CGFloat = 20

    // MARK: Animations

    /// Ressort standard : réactif, sans rebond mou. Utilisé pour toutes les
    /// transitions d'écran et apparitions.
    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.82)
    /// Ressort court pour les retours tactiles (appui, sélection).
    static let snap = Animation.spring(response: 0.28, dampingFraction: 0.75)
    /// Retournement de carte : lent au début, net à la fin.
    static let flip = Animation.spring(response: 0.55, dampingFraction: 0.78)
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

/// Fond dégradé + halos colorés, posé sous chaque écran. Le halo principal
/// prend la couleur de la phase en cours : l'ambiance change avec le jeu.
struct Backdrop: View {
    var accent: Color = Theme.brand

    var body: some View {
        ZStack {
            Theme.backdrop
            Circle()
                .fill(accent.opacity(0.30))
                .frame(width: 420, height: 420)
                .blur(radius: 130)
                .offset(x: -110, y: -260)
            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 340, height: 340)
                .blur(radius: 120)
                .offset(x: 150, y: 330)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: accentKey)
    }

    /// Color n'est pas Equatable au sens utile : on anime sur sa description.
    private var accentKey: String { accent.description }
}
