import SwiftUI

/// L'accueil de l'app : on choisit d'abord un jeu, comme on choisit un profil
/// en ouvrant Netflix. Les jeux à venir restent affichés — c'est ce qui donne à
/// la soirée l'envie de rouvrir l'app.
struct GameHubView: View {
    @Environment(\.skin) private var skin
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let onSelect: (GameEntry) -> Void

    private var columns: [GridItem] {
        // Aux tailles d'accessibilité, deux colonnes tronquent les titres longs
        // (« Le plus susceptible de… ») : on repasse à une seule.
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(GameRegistry.all) { game in
                        GameTile(game: game) { onSelect(game) }
                    }
                }

                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 8)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Mytho")
                .font(Theme.title(38))
                .foregroundStyle(skin.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Choisis ton jeu")
                .font(Theme.body(15))
                .foregroundStyle(skin.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tuile de jeu

/// Vignette carrée, nom, accroche : la tuile se lit d'un coup d'œil à bout de
/// bras, téléphone posé au milieu de la table.
private struct GameTile: View {
    @Environment(\.skin) private var skin

    let game: GameEntry
    let onTap: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                vignette

                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title)
                        .font(Theme.heading(16))
                        .foregroundStyle(skin.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(game.tagline)
                        .font(Theme.caption(12))
                        .foregroundStyle(secondaryInk)
                        .lineLimit(2)
                    Text(metaLabel)
                        .font(Theme.caption(11))
                        .foregroundStyle(secondaryInk)
                        .lineLimit(1)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            // Les tuiles d'une même ligne prennent la hauteur de la plus haute :
            // sans ça, les fonds ne s'alignent pas d'une colonne à l'autre.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // L'ombre franche est portée par la forme de fond seule : appliquée à
            // la tuile entière, un rayon nul dédoublerait les textes.
            .background(tileBackground)
        }
        .buttonStyle(PressedStyle())
        .disabled(!game.isAvailable)
        // Réserve la place de l'ombre, sinon la ligne suivante la recouvre.
        .padding(.bottom, Theme.drop)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel)
    }

    // MARK: Morceaux

    private var vignette: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .fill(game.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .strokeBorder(skin.outline, lineWidth: 2)
                )

            artwork
        }
        .frame(height: 118)
        .saturation(game.isAvailable ? 1 : 0.1)
        .opacity(game.isAvailable ? 1 : 0.5)
        // Le badge se pose après la désaturation : lui doit rester lisible.
        .overlay(alignment: .topTrailing) {
            if !game.isAvailable {
                PhasePill(text: "Bientôt", tint: skin.panel, darkText: true)
                    .padding(7)
            }
        }
    }

    @ViewBuilder
    private var artwork: some View {
        switch game.artwork {
        case .reptileEye:
            ReptileEyeView(size: 78, blinking: game.isAvailable)
        case .symbol:
            Image(systemName: game.symbol)
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(Theme.night)
                .accessibilityHidden(true)
        }
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
            .fill(game.isAvailable ? skin.panel : skin.panelSoft)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .strokeBorder(
                        skin.outline.opacity(game.isAvailable ? 1 : 0.45),
                        lineWidth: Theme.stroke
                    )
            )
            .shadow(
                color: skin.outline.opacity(game.isAvailable ? 1 : 0.35),
                radius: 0,
                y: Theme.drop
            )
    }

    /// Une tuile « Bientôt » reste une tuile qui se lit. Atténuer son texte
    /// cumulait deux opacités et tombait à 2:1 de contraste — l'indisponibilité
    /// est déjà dite par la vignette désaturée, le badge et VoiceOver.
    private var secondaryInk: Color {
        skin.ink.opacity(0.75)
    }

    private var metaLabel: String {
        "\(game.players.lowerBound)-\(game.players.upperBound) joueurs · \(game.minutes) min"
    }

    /// La disponibilité est annoncée en toutes lettres : la tuile grisée ne dit
    /// rien à VoiceOver.
    private var voiceOverLabel: String {
        let availability = game.isAvailable ? "" : " Bientôt disponible."
        let range = "De \(game.players.lowerBound) à \(game.players.upperBound) joueurs"
        return "\(game.title).\(availability) \(game.tagline) \(range), environ \(game.minutes) minutes."
    }
}
