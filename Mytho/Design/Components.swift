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

// MARK: - Bandeau 18+

/// Le pack adulte en bandeau rose, cerclé d'encre sur ombre franche, au milieu
/// de réglages restés sur papier — maquette B validée par Arthur le 17 août.
/// Verrouillé, tout le bandeau est la porte d'âge ; déverrouillé, un appui
/// n'importe où bascule l'interrupteur jaune. L'alerte d'âge reste au site
/// d'appel : chaque jeu décide quoi cocher une fois l'âge confirmé.
struct AdultPackBanner: View {
    @Environment(\.skin) private var skin

    let title: String
    let subtitle: String
    let unlocked: Bool
    @Binding var isOn: Bool
    let onUnlock: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            if unlocked { isOn.toggle() } else { onUnlock() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: unlocked ? "flame.fill" : "lock.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.amber)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Theme.night)
                            .overlay(Circle().strokeBorder(skin.outline, lineWidth: 2))
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.body(16))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(Theme.caption(12))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                if unlocked {
                    Capsule()
                        .fill(Theme.night)
                        .frame(width: 44, height: 26)
                        .overlay(alignment: isOn ? .trailing : .leading) {
                            Circle()
                                .fill(isOn ? Theme.amber : Color.white.opacity(0.5))
                                .frame(width: 20, height: 20)
                                .padding(3)
                        }
                        .overlay(Capsule().strokeBorder(skin.outline, lineWidth: 2))
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            // L'ombre porte le fond seul, jamais le contenu : une ombre à
            // rayon nul poserait sinon une seconde copie du texte 5 pt plus bas.
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.rose)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(skin.outline, lineWidth: Theme.stroke)
                    )
                    .shadow(color: skin.outline, radius: 0, y: Theme.drop)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressedStyle())
        .padding(.bottom, Theme.drop)
        .animation(.easeOut(duration: 0.15), value: isOn)
        .accessibilityLabel(unlocked ? title : "Débloquer : \(title), réservé aux adultes")
        .accessibilityValue(unlocked ? (isOn ? "activé" : "désactivé") : "verrouillé")
        .accessibilityAddTraits(unlocked && isOn ? AccessibilityTraits.isSelected : [])
        .accessibilityHint(subtitle)
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

/// Rappel du pouvoir d'un joueur, lu en même temps que son mot et donc à
/// l'abri des regards. Partagé par la pioche et par « Ma carte » : le joueur
/// qui relit doit retrouver exactement ce qu'il a vu la première fois.
struct SpecialRoleNote: View {
    @Environment(\.skin) private var skin

    let role: SpecialRole

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: role.symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.amber)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(role.displayName)
                    .font(Theme.caption(14))
                    .foregroundStyle(Theme.amber)
                Text(role.briefing)
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .fill(Theme.amber.opacity(0.10))
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

/// Le sens d'un changement d'écran. « Retour » ressort par où l'on est entré :
/// un écran qui reviendrait par la droite se lirait comme un écran de plus.
enum NavDirection: Sendable {
    case forward
    case backward
}

extension AnyTransition {
    /// Entrée par la droite, sortie par la gauche : la progression du jeu se lit
    /// comme un enchaînement, pas comme des sauts.
    static var forward: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Le miroir exact de `forward`, pour « Retour ».
    static var backward: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    /// La transition d'un changement d'écran, dans un sens donné. En
    /// animations réduites, un fondu : jamais un glissement.
    static func screen(_ direction: NavDirection, reduced: Bool = false) -> AnyTransition {
        guard !reduced else { return .opacity }
        return direction == .forward ? .forward : .backward
    }

    /// Apparition centrée, pour les révélations.
    static var reveal: AnyTransition {
        .scale(scale: 0.86).combined(with: .opacity)
    }
}

/// Recule d'un écran en glissant vers la droite.
///
/// SwiftUI retient la transition de sortie d'un écran au dernier rendu où il
/// était encore là : changer de sens et d'écran dans le même geste ferait donc
/// sortir l'écran avec l'ancien sens. Le sens change d'abord, l'écran au tour
/// suivant, puis le sens revient à « avancer » pour le prochain geste.
@MainActor
func navigateBack(
    direction: Binding<NavDirection>,
    animation: Animation?,
    _ change: @escaping () -> Void
) {
    direction.wrappedValue = .backward
    DispatchQueue.main.async {
        withAnimation(animation) { change() }
        DispatchQueue.main.async { direction.wrappedValue = .forward }
    }
}

// MARK: - Retournement de carte

/// Une carte qui se retourne autour de l'axe vertical, en changeant de face
/// **exactement à 90°**, quand elle se présente par la tranche.
///
/// Un fondu croisé des deux faces sur toute la rotation montrait, à mi-course,
/// le dos et le mot superposés. Ici l'angle est interpolé image par image
/// (`Animatable`), et chaque image ne montre qu'une seule face.
struct FlipCard<Front: View, Back: View>: View, Animatable {
    /// 0 : la face est visible. 180 : le dos est visible.
    var angle: Double
    var perspective: CGFloat = 0.45
    @ViewBuilder let front: Front
    @ViewBuilder let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var showsFront: Bool { abs(angle.truncatingRemainder(dividingBy: 360)) < 90 }

    var body: some View {
        ZStack {
            front
                .opacity(showsFront ? 1 : 0)
            back
                // Sans ce miroir, le dos apparaîtrait inversé une fois retourné.
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showsFront ? 0 : 1)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: perspective)
    }
}

// MARK: - Pop

extension View {
    /// Un petit sursaut (1 → 1,18 → 1) chaque fois que `value` change : le
    /// compteur dit « j'ai compté » sans qu'on lise le chiffre. Rien en
    /// animations réduites, le chiffre change seul.
    func popOnChange<Value: Equatable>(of value: Value, reduced: Bool = false) -> some View {
        modifier(PopOnChange(value: value, reduced: reduced))
    }
}

private struct PopOnChange<Value: Equatable>: ViewModifier {
    let value: Value
    let reduced: Bool

    @State private var trigger = 0

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(1.18, duration: 0.12, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.32, spring: .bouncy)
                }
            }
            .onChange(of: value) { _, _ in
                guard !reduced else { return }
                trigger &+= 1
            }
    }
}

// MARK: - Entrée en cascade

extension View {
    /// Entrée décalée d'un élément de liste : 8 pt de montée et un fondu, avec
    /// 40 ms d'écart entre voisins. Décoratif : rien n'attend la fin pour
    /// devenir touchable. En animations réduites, l'élément est simplement là.
    func cascade(index: Int, appeared: Bool, reduced: Bool = false) -> some View {
        modifier(CascadeIn(index: index, appeared: appeared, reduced: reduced))
    }
}

private struct CascadeIn: ViewModifier {
    let index: Int
    let appeared: Bool
    let reduced: Bool

    func body(content: Content) -> some View {
        let hidden = !appeared && !reduced
        return content
            .opacity(hidden ? 0 : 1)
            .offset(y: hidden ? 8 : 0)
            .animation(
                reduced ? nil : Theme.spring.delay(Double(min(index, 12)) * 0.04),
                value: appeared
            )
    }
}

// MARK: - Confettis

extension View {
    /// Une salve de confettis par-dessus la vue, à son apparition puis à
    /// chaque changement de `trigger`. Réservée aux fins de partie : une
    /// victoire se mérite, un tap ordinaire non. Rien en animations réduites.
    func confettiBurst<Trigger: Equatable>(trigger: Trigger, enabled: Bool = true) -> some View {
        modifier(ConfettiBurstModifier(trigger: trigger, enabled: enabled))
    }
}

private struct ConfettiBurstModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let enabled: Bool

    @State private var start: Date?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let start {
                    ConfettiBurst(start: start)
                }
            }
            .task(id: trigger) {
                guard enabled else { return }
                start = Date()
                try? await Task.sleep(nanoseconds: UInt64(ConfettiBurst.duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                start = nil
            }
    }
}

/// 40 papiers dessinés dans un `Canvas`, 1,6 s, aucune bibliothèque (spec
/// §3.4). Contours encrés comme le reste de l'app : des confettis flous
/// trahiraient la direction artistique. Partagés par tous les jeux, pour que
/// toutes les victoires se fêtent de la même façon.
struct ConfettiBurst: View {
    @Environment(\.skin) private var skin

    static let duration: TimeInterval = 1.6
    static let count = 40

    let start: Date

    private let flakes: [Flake] = (0..<ConfettiBurst.count).map { _ in Flake() }

    struct Flake {
        let column = Double.random(in: 0.04...0.96)
        let drift = Double.random(in: -34...34)
        let delay = Double.random(in: 0...0.35)
        let size = Double.random(in: 8...15)
        let spin = Double.random(in: 0...(2 * Double.pi))
        let turns = Double.random(in: 1.5...4)
        let color = [Theme.amber, Theme.brand, Theme.brandLight, Theme.mint, Theme.sky, Theme.crimson]
            .randomElement() ?? Theme.amber
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                // Tout est calculé en `Double` puis converti une fois : mélanger
                // `CGFloat` et `Double` dans une même expression fait ramer le
                // vérificateur de types pour rien.
                let width = Double(size.width)
                let height = Double(size.height)

                for flake in flakes {
                    let span = Self.duration - flake.delay
                    guard span > 0 else { continue }
                    let progress = (elapsed - flake.delay) / span
                    guard progress > 0, progress < 1 else { continue }

                    let sway = sin(progress * 6 + flake.spin) * flake.drift
                    let x = flake.column * width + sway
                    // La chute accélère comme une vraie chute : `progress²`
                    // plutôt qu'une descente à vitesse constante.
                    let fall = progress * (0.55 + 0.45 * progress)
                    let y = -20 + fall * (height + 40)
                    let angle = flake.spin + progress * flake.turns * 2 * Double.pi

                    let rect = CGRect(
                        x: -flake.size / 2,
                        y: -flake.size / 4,
                        width: flake.size,
                        height: flake.size / 2
                    )
                    let transform = CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y))
                        .rotated(by: CGFloat(angle))
                    let path = Path(roundedRect: rect, cornerRadius: 1.5).applying(transform)

                    context.fill(path, with: .color(flake.color))
                    context.stroke(path, with: .color(skin.outline), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
