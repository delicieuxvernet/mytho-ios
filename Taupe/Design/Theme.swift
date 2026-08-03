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
    /// Ambre : Mr. White, alertes, dernière chance.
    static let amber = Color(red: 0.976, green: 0.702, blue: 0.263)
    /// Vert : victoire des civils.
    static let mint = Color(red: 0.204, green: 0.827, blue: 0.600)
    /// Rouge : élimination.
    static let crimson = Color(red: 0.937, green: 0.325, blue: 0.365)

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

/// Fond dégradé + halo de marque, posé sous chaque écran.
struct Backdrop: View {
    var body: some View {
        ZStack {
            Theme.backdrop
            Circle()
                .fill(Theme.brand.opacity(0.28))
                .frame(width: 420, height: 420)
                .blur(radius: 130)
                .offset(x: -110, y: -260)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
