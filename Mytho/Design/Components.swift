import SwiftUI

// MARK: - Bouton principal

/// Le CTA de l'app, façon carton de jeu : aplat franc, contour encré, ombre
/// franche décalée. Un seul par écran.
struct PrimaryButton: View {
    @Environment(\.skin) private var skin

    let title: String
    var systemImage: String?
    var tint: Color = Theme.brand
    /// À passer en sombre sur les teintes claires (ambre, ciel, menthe) :
    /// le blanc n'y tient pas le contraste.
    var foreground: Color = .white
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.medium)
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(Theme.heading(18))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(skin.outline, lineWidth: Theme.stroke)
                    )
                    .shadow(color: skin.outline, radius: 0, y: Theme.drop)
            )
        }
        .buttonStyle(PressedStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .padding(.bottom, Theme.drop)
    }
}

/// Bouton secondaire, discret, sans fond plein.
struct GhostButton: View {
    @Environment(\.skin) private var skin

    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(title).font(Theme.body(16))
            }
            .foregroundStyle(skin.inkMuted)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.touchTarget)
        }
        .buttonStyle(PressedStyle())
    }
}

/// Enfoncement cartoon : le bouton descend dans son ombre.
struct PressedStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 3 : 0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(Theme.snap, value: configuration.isPressed)
    }
}

// MARK: - Surfaces

/// Carte de contenu opaque, contour encré, ombre franche. La brique de mise en
/// page de l'app — plus aucune translucidité.
struct Panel<Content: View>: View {
    @Environment(\.skin) private var skin

    var padding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(skin.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(skin.outline, lineWidth: Theme.stroke)
                    )
                    .shadow(color: skin.outline, radius: 0, y: Theme.drop)
            )
            .padding(.bottom, Theme.drop)
    }
}

/// Étiquette de phase : autocollant plein aux couleurs du moment.
struct PhasePill: View {
    @Environment(\.skin) private var skin

    let text: String
    var tint: Color = Theme.brandLight
    /// Vrai sur les teintes claires (ciel, ambre, menthe).
    var darkText: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(Theme.caption(12))
            .tracking(1.2)
            .foregroundStyle(darkText ? Theme.night : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(tint)
                    .overlay(Capsule().strokeBorder(skin.outline, lineWidth: 2))
            )
    }
}

// MARK: - Compteur +/-

/// Réglage d'un nombre d'infiltrés. Cibles tactiles à 44 pt.
struct CounterRow: View {
    @Environment(\.skin) private var skin

    let title: String
    let symbol: String
    let tint: Color
    let value: Int
    var canDecrement: Bool = true
    var canIncrement: Bool = true
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.night)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(tint)
                        .overlay(Circle().strokeBorder(skin.outline, lineWidth: 2))
                )
                .accessibilityHidden(true)

            Text(title)
                .font(Theme.body(16))
                .foregroundStyle(skin.ink)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                counterButton("minus", enabled: canDecrement) { onChange(-1) }
                Text("\(value)")
                    .font(Theme.heading(19))
                    .foregroundStyle(skin.ink)
                    .frame(minWidth: 26)
                    .contentTransition(.numericText())
                counterButton("plus", enabled: canIncrement) { onChange(1) }
            }
        }
    }

    private func counterButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? skin.ink : skin.inkFaint)
                .frame(width: Theme.touchTarget, height: Theme.touchTarget)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(skin.panelStrong)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(skin.outline.opacity(enabled ? 1 : 0.3), lineWidth: 2)
                        )
                )
        }
        .buttonStyle(PressedStyle())
        .disabled(!enabled)
        .accessibilityLabel(icon == "plus" ? "Augmenter \(title)" : "Diminuer \(title)")
    }
}

// MARK: - Interrupteur d'option

struct OptionToggle: View {
    @Environment(\.skin) private var skin

    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.body(15))
                    .foregroundStyle(skin.ink)
                Text(subtitle)
                    .font(Theme.caption(12))
                    .foregroundStyle(skin.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(Theme.brand)
    }
}

// MARK: - Badge de rôle

/// Révélation du rôle d'un joueur : autocollant plein, texte encre.
struct RoleBadge: View {
    @Environment(\.skin) private var skin

    let role: Role
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: role.symbol)
                .font(.system(size: compact ? 11 : 13, weight: .bold))
                .accessibilityHidden(true)
            Text(role.displayName)
                .font(Theme.caption(compact ? 12 : 14))
        }
        .foregroundStyle(Theme.night)
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 5 : 7)
        .background(
            Capsule()
                .fill(Theme.color(for: role))
                .overlay(Capsule().strokeBorder(skin.outline, lineWidth: 2))
        )
    }
}

// MARK: - Avatars

/// Pastille colorée + initiale, cerclée comme un autocollant. Passer la table
/// garantit des couleurs toutes distinctes jusqu'à 8 joueurs.
struct AvatarView: View {
    @Environment(\.skin) private var skin

    let name: String
    var size: CGFloat = 34
    var dimmed: Bool = false
    var table: [String] = []

    private var initial: String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.avatarColor(for: name, table: table))
            Text(initial.isEmpty ? "?" : initial)
                .font(.system(size: size * 0.44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .overlay(Circle().strokeBorder(skin.outline, lineWidth: max(2, size * 0.06)))
        .frame(width: size, height: size)
        .saturation(dimmed ? 0.15 : 1)
        .opacity(dimmed ? 0.55 : 1)
        .accessibilityHidden(true)
    }
}

// MARK: - L'œil reptilien

/// La signature des infiltrés : un œil vert à pupille fendue, cerné d'un gros
/// contour encré. Vectoriel : net à toutes tailles.
struct ReptileEyeView: View {
    @Environment(\.skin) private var skin
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var size: CGFloat = 120
    var blinking: Bool = false

    @State private var pupilScale: CGFloat = 1

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.070, green: 0.230, blue: 0.165))
            Circle()
                .strokeBorder(skin.outline, lineWidth: max(3, size * 0.05))
            Circle()
                .strokeBorder(Theme.mint, lineWidth: max(2, size * 0.032))
                .padding(size * 0.05)
            Circle()
                .fill(Color(red: 0.487, green: 0.910, blue: 0.722))
                .frame(width: size * 0.56, height: size * 0.56)
                .overlay(
                    Circle().strokeBorder(skin.outline, lineWidth: max(2, size * 0.032))
                )
            Ellipse()
                .fill(Color(red: 0.016, green: 0.082, blue: 0.051))
                .frame(width: size * 0.13, height: size * 0.44)
                .scaleEffect(y: pupilScale)
            Ellipse()
                .fill(.white.opacity(0.55))
                .frame(width: size * 0.11, height: size * 0.07)
                .offset(x: -size * 0.08, y: -size * 0.12)
        }
        .frame(width: size, height: size)
        .onAppear { updateBlink() }
        // La lecture au seul onAppear laissait l'œil cligner quand le réglage
        // système était activé app ouverte.
        .onChange(of: reduceMotion) { _, _ in updateBlink() }
        .accessibilityLabel("Œil d'infiltré")
    }

    /// Un clignement lent : vivant sans être agité, et coupé net dès que
    /// l'utilisateur demande moins d'animations.
    private func updateBlink() {
        guard blinking, !reduceMotion else {
            withAnimation(.easeInOut(duration: 0.2)) { pupilScale = 1 }
            return
        }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            pupilScale = 0.82
        }
    }
}

// MARK: - Transitions d'écran

extension AnyTransition {
    /// Entrée par la droite, sortie par la gauche : la progression du jeu se lit
    /// comme un enchaînement, pas comme des sauts.
    static var forward: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Apparition centrée, pour les révélations.
    static var reveal: AnyTransition {
        .scale(scale: 0.86).combined(with: .opacity)
    }
}
