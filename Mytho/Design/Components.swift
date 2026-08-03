import SwiftUI

// MARK: - Bouton principal

/// Le CTA de l'app. Un seul par écran.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = Theme.brand
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
                        // Purement décoratif : sans ça VoiceOver annonce le nom
                        // du symbole avant le libellé du bouton.
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(Theme.heading(18))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(tint)
                    .shadow(color: tint.opacity(0.45), radius: 18, y: 8)
            )
        }
        .buttonStyle(PressedStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

/// Bouton secondaire, discret, sans fond plein.
struct GhostButton: View {
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
            .foregroundStyle(Theme.inkMuted)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.touchTarget)
        }
        .buttonStyle(PressedStyle())
    }
}

/// Enfoncement standard iOS : léger, immédiat, jamais mou.
struct PressedStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.snap, value: configuration.isPressed)
    }
}

// MARK: - Surfaces

/// Carte de contenu translucide, la brique de mise en page de l'app.
struct Panel<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )
            )
    }
}

/// Petite étiquette de phase, en haut des écrans de jeu.
struct PhasePill: View {
    let text: String
    var tint: Color = Theme.brandLight

    var body: some View {
        Text(text.uppercased())
            .font(Theme.caption(12))
            .tracking(1.2)
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(tint.opacity(0.16)))
    }
}

// MARK: - Compteur +/-

/// Réglage d'un nombre d'infiltrés. Cibles tactiles à 44 pt.
struct CounterRow: View {
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
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.16)))

            Text(title)
                .font(Theme.body(16))
                .foregroundStyle(Theme.ink)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                counterButton("minus", enabled: canDecrement) { onChange(-1) }
                Text("\(value)")
                    .font(Theme.heading(19))
                    .foregroundStyle(Theme.ink)
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
                .foregroundStyle(enabled ? Theme.ink : Theme.inkFaint)
                .frame(width: Theme.touchTarget, height: Theme.touchTarget)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Theme.surfaceStrong)
                )
        }
        .buttonStyle(PressedStyle())
        .disabled(!enabled)
        .accessibilityLabel(icon == "plus" ? "Augmenter \(title)" : "Diminuer \(title)")
    }
}

// MARK: - Interrupteur d'option

struct OptionToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.caption(12))
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(Theme.brand)
    }
}

// MARK: - Badge de rôle

/// Révélation du rôle d'un joueur, après élimination ou en fin de manche.
struct RoleBadge: View {
    let role: Role
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: role.symbol)
                .font(.system(size: compact ? 11 : 13, weight: .bold))
            Text(role.displayName)
                .font(Theme.caption(compact ? 12 : 14))
        }
        .foregroundStyle(Theme.color(for: role))
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 5 : 7)
        .background(Capsule().fill(Theme.color(for: role).opacity(0.16)))
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
