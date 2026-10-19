import SwiftUI

/// L'unique écran de réglages de l'app (spec §2.6), atteint depuis l'accueil.
///
/// Il existe d'abord pour rendre la main : refermer le contenu 18+ avant de
/// prêter le téléphone, couper les vibrations, oublier les cartes déjà vues.
/// Ensuite pour la vie de l'app : la noter, la partager, joindre le support.
struct SettingsView: View {
    /// Toujours la peau jour : rien de secret ici.
    private let skin = Skin.day

    @ObservedObject var settings: AppSettings
    /// Retour au catalogue.
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var showAgeGate = false
    @State private var confirmReset = false
    @State private var resetDone = false

    var body: some View {
        ZStack {
            Backdrop(skin: skin, accent: Theme.brand)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Réglages")
                        .font(Theme.title(32))
                        .foregroundStyle(skin.ink)
                        .accessibilityAddTraits(.isHeader)

                    section("Contenu") { adultBanner }
                    section("Confort") { comfortPanel }
                    section("Paquets") { decksPanel }
                    section("Mytho") { appPanel }

                    Text(versionLabel)
                        .font(Theme.caption(12))
                        .foregroundStyle(skin.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .environment(\.skin, skin)
        .preferredColorScheme(skin.colorScheme)
    }

    // MARK: Barre

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tap()
                onClose()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .accessibilityHidden(true)
                    Text("Jeux")
                        .font(Theme.caption(13))
                }
                .foregroundStyle(skin.ink)
                .padding(.horizontal, 13)
                .frame(height: Theme.touchTarget)
                .background(
                    Capsule()
                        .fill(skin.panel)
                        .overlay(Capsule().strokeBorder(skin.outline, lineWidth: 2))
                )
            }
            .buttonStyle(PressedStyle())
            .accessibilityLabel("Revenir au choix des jeux")
            .accessibilityIdentifier("settings-close")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    // MARK: Contenu 18+

    /// Le même bandeau rose que dans les jeux : l'app n'a qu'une façon de
    /// parler du contenu adulte. Ici, il ouvre et referme le verrou lui-même.
    private var adultBanner: some View {
        AdultPackBanner(
            title: "Contenu 18+",
            subtitle: settings.adultContentUnlocked
                ? "Ouvert. Le refermer cache les paquets 18+ de tous les jeux."
                : "Fermé. Les paquets 18+ restent invisibles dans tous les jeux.",
            unlocked: true,
            isOn: adultBinding,
            onUnlock: {}
        )
        .alert("Réservé aux adultes", isPresented: $showAgeGate) {
            Button("J'ai 18 ans ou plus") {
                settings.setAdultContent(true, ageConfirmed: true)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Les paquets 18+ contiennent des thèmes sexuels crus et des références à l'alcool.")
        }
    }

    /// Ouvrir passe toujours par la confirmation d'âge ; refermer, jamais :
    /// on ne fait pas confirmer quelqu'un qui protège un téléphone qu'il prête.
    private var adultBinding: Binding<Bool> {
        Binding(
            get: { settings.adultContentUnlocked },
            set: { isOn in
                if isOn {
                    showAgeGate = true
                } else {
                    settings.setAdultContent(false, ageConfirmed: false)
                }
            }
        )
    }

    // MARK: Confort

    private var comfortPanel: some View {
        Panel(padding: 14) {
            VStack(alignment: .leading, spacing: 14) {
                OptionToggle(
                    title: "Vibrations",
                    subtitle: "Au passage du téléphone, aux votes et aux éliminations.",
                    isOn: $settings.hapticsEnabled
                )
                .accessibilityIdentifier("settings-haptics")

                Rectangle()
                    .fill(skin.hairline)
                    .frame(height: 1)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Animations")
                        .font(Theme.body(15))
                        .foregroundStyle(skin.ink)
                    motionPicker
                    Text(motionHint)
                        .font(Theme.caption(12))
                        .foregroundStyle(skin.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var motionPicker: some View {
        HStack(spacing: 0) {
            ForEach(ReducedMotionSetting.allCases, id: \.self) { option in
                let isSelected = settings.reducedMotion == option
                Button {
                    Haptics.tap()
                    withAnimation(Theme.snap) { settings.reducedMotion = option }
                } label: {
                    Text(label(for: option))
                        .font(Theme.caption(13))
                        .foregroundStyle(isSelected ? .white : skin.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.touchTarget)
                        .background(isSelected ? Theme.brand : Color.clear)
                }
                .buttonStyle(PressedStyle())
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
            }
        }
        .background(skin.panelSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(skin.outline, lineWidth: 2)
        )
    }

    private func label(for option: ReducedMotionSetting) -> String {
        switch option {
        case .system: return "Comme l'iPhone"
        case .forced: return "Réduites"
        case .disabled: return "Toutes"
        }
    }

    private var motionHint: String {
        switch settings.reducedMotion {
        case .system: return "Suit le réglage « Réduire les animations » de l'iPhone."
        case .forced: return "Des fondus à la place des glissements, ni confettis ni pulsations."
        case .disabled: return "Toutes les animations, quel que soit le réglage de l'iPhone."
        }
    }

    // MARK: Paquets

    private var decksPanel: some View {
        Panel(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    Haptics.tap()
                    confirmReset = true
                } label: {
                    HStack(spacing: 10) {
                        Text("Oublier les cartes déjà vues")
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.crimson)
                        Spacer(minLength: 8)
                        Image(systemName: resetDone ? "checkmark" : "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(resetDone ? skin.ink : Theme.crimson)
                            .contentTransition(.symbolEffect(.replace))
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: Theme.touchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressedStyle())
                .accessibilityIdentifier("settings-reset-decks")

                Text(resetDone
                     ? "C'est fait : toutes les cartes peuvent ressortir dès la prochaine partie."
                     : "Une carte tirée ne revient pas avant que 70 % du paquet soit passé. Ceci efface cette mémoire, dans tous les jeux.")
                    .font(Theme.caption(12))
                    .foregroundStyle(skin.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .alert("Oublier les cartes déjà vues ?", isPresented: $confirmReset) {
            Button("Oublier", role: .destructive) {
                settings.resetDecks()
                Haptics.success()
                withAnimation(Theme.snap) { resetDone = true }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Les cartes déjà tirées pourront ressortir, dans tous les jeux.")
        }
    }

    // MARK: Mytho

    private var appPanel: some View {
        Panel(padding: 6) {
            VStack(spacing: 0) {
                linkRow("Noter Mytho", symbol: "star.fill") {
                    openURL(AppLinks.writeReview)
                }
                divider
                ShareLink(
                    item: AppLinks.appStore,
                    subject: Text("Mytho"),
                    message: Text("Six jeux de soirée sur un seul téléphone. Télécharge Mytho :")
                ) {
                    rowLabel("Partager Mytho", symbol: "square.and.arrow.up")
                }
                .buttonStyle(PressedStyle())
                divider
                linkRow("Aide et contact", symbol: "questionmark.bubble.fill") {
                    openURL(AppLinks.support)
                }
                divider
                linkRow("Confidentialité", symbol: "lock.fill") {
                    openURL(AppLinks.privacy)
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(skin.hairline)
            .frame(height: 1)
            .padding(.horizontal, 10)
            .accessibilityHidden(true)
    }

    private func linkRow(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            rowLabel(title, symbol: symbol)
        }
        .buttonStyle(PressedStyle())
    }

    private func rowLabel(_ title: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.night)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Theme.amber)
                        .overlay(Circle().strokeBorder(skin.outline, lineWidth: 2))
                )
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.body(16))
                .foregroundStyle(skin.ink)
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(skin.inkMuted)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    // MARK: Pièces communes

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Theme.caption(12))
                .tracking(1.1)
                .foregroundStyle(skin.inkMuted)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private var versionLabel: String {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Mytho \(AppSettings.currentVersion) · build \(build)"
    }
}

// MARK: - Liens de l'app

/// Les adresses publiques de Mytho. Une seule source : la fiche, le site et
/// l'app ne doivent jamais diverger sur où trouver de l'aide.
enum AppLinks {
    static let appStoreID = "6797652496"
    // Les URL sont des littéraux valides : le repli sur la racine ne sert qu'à
    // éviter un `!` dans le code de l'app.
    static let appStore = URL(string: "https://apps.apple.com/app/id\(appStoreID)") ?? root
    static let writeReview = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review") ?? root
    static let support = URL(string: "https://delicieuxvernet.github.io/mytho-site/support.html") ?? root
    static let privacy = URL(string: "https://delicieuxvernet.github.io/mytho-site/confidentialite.html") ?? root
    private static let root = URL(fileURLWithPath: "/")
}

#if DEBUG
#Preview("Réglages") {
    SettingsView(
        settings: AppSettings(defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard),
        onClose: {}
    )
}
#endif
