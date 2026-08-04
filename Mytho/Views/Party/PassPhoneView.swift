import SwiftUI

// MARK: - Verrou des écrans secrets

extension View {
    /// Ferme toutes les sorties d'un écran secret (spec §2.3) : pas de bouton
    /// retour, pas de geste de retour depuis le bord, pas de feuille refermée
    /// d'un glissement. Une révélation ne se rejoue pas — revenir en arrière
    /// remontrerait au joueur suivant ce que le précédent vient de lire.
    ///
    /// Exposé plutôt qu'enfoui : tous les écrans de la séquence secrète (pioche,
    /// curseur caché, vote individuel) doivent porter le même verrou, pas
    /// seulement le passage du téléphone.
    func secretScreen() -> some View {
        self
            // Masquer le bouton retour suffit à couper le geste de bord dans un
            // `NavigationStack` ; la barre entière disparaît en plus pour que
            // l'écran soit vraiment plein.
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .interactiveDismissDisabled(true)
    }
}

// MARK: - Passage du téléphone

/// « Passe le téléphone à Léa. » La brique d'anti-triche de la soirée : elle
/// s'intercale entre deux secrets pour que personne ne lise celui du voisin.
///
/// Un seul bouton, et il porte le prénom : « Continuer » se tape par réflexe,
/// « Je suis Léa » demande de vérifier qui tient l'appareil.
///
/// À présenter avec un `.id(...)` propre à chaque joueur : sans changement
/// d'identité, `onAppear` ne se rejoue pas et le passage suivant arriverait sans
/// son retour haptique.
struct PassPhoneView: View {
    /// Toujours la peau nuit : c'est un moment de secret. Fixée ici plutôt que
    /// lue dans l'environnement — l'écran doit être sombre quel que soit le jeu
    /// qui le présente.
    private let skin = Skin.night

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Le joueur qui doit prendre l'appareil.
    let name: String
    /// La table complète : garantit à chacun la même pastille de couleur d'un
    /// écran à l'autre de la soirée.
    var table: [String] = []
    var instruction: String = "Personne d'autre ne regarde l'écran."
    let onReady: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Backdrop(skin: skin, accent: Theme.brand)

            VStack(spacing: 22) {
                Spacer(minLength: 0)

                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.brandLight)
                    .accessibilityHidden(true)

                nameCard

                Text(instruction)
                    .font(Theme.body(15))
                    .foregroundStyle(skin.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                PrimaryButton(title: "Je suis \(name)", systemImage: "hand.raised.fill") {
                    onReady()
                }
                .accessibilityIdentifier("pass-phone-confirm")
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.vertical, 20)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.96)
        }
        .environment(\.skin, skin)
        .preferredColorScheme(skin.colorScheme)
        .secretScreen()
        .onAppear(perform: enter)
    }

    // MARK: Morceaux

    private var nameCard: some View {
        Panel {
            VStack(spacing: 10) {
                AvatarView(name: name, size: 72, table: table)

                Text("Passe le téléphone à")
                    .font(Theme.body(16))
                    .foregroundStyle(skin.inkMuted)

                Text(name)
                    .font(Theme.title(34))
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        // Le bloc est lu d'un trait par VoiceOver : trois éléments séparés
        // feraient entendre le prénom deux fois sans dire qu'on entre dans un
        // moment secret.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Écran secret. Passe le téléphone à \(name).")
        .accessibilityAddTraits(.isHeader)
        // Ancre du test d'interface « le retour arrière est impossible sur un
        // écran secret » (checklist §2). Posée sur un élément unique : sur le
        // conteneur, l'identifiant se propagerait à tous les descendants.
        .accessibilityIdentifier("pass-phone")
    }

    // MARK: Entrée

    private func enter() {
        // Le porteur sent le changement d'écran sans avoir à le regarder :
        // c'est ce qui l'empêche de lire par-dessus l'épaule du précédent.
        Haptics.impact(.medium)

        guard !reduceMotion else {
            appeared = true
            return
        }
        withAnimation(Theme.spring) { appeared = true }
    }
}

#if DEBUG
#Preview("Passe le téléphone") {
    PassPhoneView(name: "Léa", table: ["Léa", "Tom", "Nino", "Sarah"]) {}
}

#Preview("Prénom long") {
    PassPhoneView(name: "Marie-Charlotte", table: ["Marie-Charlotte", "Tom"]) {}
}
#endif
