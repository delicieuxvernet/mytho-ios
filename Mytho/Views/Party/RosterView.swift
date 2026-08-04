import SwiftUI

/// Les prénoms de la soirée (spec §2.2). Ils se saisissent **une fois** : les
/// cinq jeux les reprennent, et re-saisir la table entre deux jeux casserait
/// l'enchaînement de la soirée.
struct RosterView: View {
    /// Toujours la peau jour : tout le monde est autour de la table, personne
    /// ne cache rien. Fixée ici, pas lue dans l'environnement — l'écran doit
    /// être clair quel que soit le jeu qui l'appelle.
    private let skin = Skin.day

    @ObservedObject var store: RosterStore
    /// Le minimum du jeu qu'on s'apprête à lancer (`game.players.lowerBound`).
    /// Ramené au plancher du roster s'il est plus bas : deux joueurs sont un
    /// strict minimum pour une soirée.
    var minimumPlayers: Int = RosterStore.minPlayers
    var startTitle: String = "C'est parti"
    let onStart: () -> Void

    @State private var draft = ""
    @State private var errorMessage: String?
    @State private var editMode: EditMode = .inactive
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        ZStack {
            Backdrop(skin: skin, accent: Theme.brand)

            VStack(spacing: 12) {
                header
                addField

                if store.isEmpty {
                    emptyState
                    Spacer(minLength: 0)
                } else {
                    list
                }
            }
            .padding(.top, 8)
        }
        .environment(\.skin, skin)
        // Le mode édition est piloté par notre propre bouton : `EditButton`
        // arrive avec son libellé et son style système, hors DA.
        .environment(\.editMode, $editMode)
        .preferredColorScheme(skin.colorScheme)
        .safeAreaInset(edge: .bottom) { startBar }
    }

    // MARK: En-tête

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Qui joue ?")
                    .font(Theme.title(32))
                    .foregroundStyle(skin.ink)
                    .accessibilityAddTraits(.isHeader)

                Text(countLabel)
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if store.count > 1 { reorderToggle }
        }
        .padding(.horizontal, Theme.gutter)
    }

    private var countLabel: String {
        guard store.count > 0 else { return "Aucun prénom pour l'instant." }

        let paused = store.count - store.activePlayers.count
        let base = "\(store.count) prénom\(store.count > 1 ? "s" : "")"
        return paused > 0 ? "\(base) · \(paused) en pause" : base
    }

    /// Bascule le mode édition : c'est lui qui fait apparaître les poignées de
    /// déplacement et les boutons de retrait de la liste.
    private var reorderToggle: some View {
        Button {
            Haptics.tap()
            addFieldFocused = false
            withAnimation(Theme.snap) {
                editMode = editMode.isEditing ? .inactive : .active
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: editMode.isEditing ? "checkmark" : "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .accessibilityHidden(true)
                Text(editMode.isEditing ? "Terminé" : "Ranger")
                    .font(Theme.caption(13))
            }
            .foregroundStyle(skin.ink)
            .padding(.horizontal, 13)
            .frame(height: Theme.touchTarget)
            .background(
                Capsule()
                    .fill(editMode.isEditing ? Theme.brandLight : skin.panel)
                    .overlay(Capsule().strokeBorder(skin.outline, lineWidth: 2))
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityLabel(editMode.isEditing ? "Terminer le rangement" : "Réordonner ou retirer des joueurs")
    }

    // MARK: Ajout

    private var addField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(skin.inkMuted)
                    .accessibilityHidden(true)

                TextField("Ajouter un prénom", text: $draft)
                    .font(Theme.body(16))
                    .foregroundStyle(skin.ink)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($addFieldFocused)
                    .onSubmit(submitDraft)
                    .accessibilityLabel("Prénom à ajouter")

                if !trimmedDraft.isEmpty {
                    Button(action: submitDraft) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Theme.brand)
                            .frame(width: Theme.touchTarget, height: Theme.touchTarget)
                    }
                    .buttonStyle(PressedStyle())
                    .accessibilityLabel("Ajouter ce prénom")
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, trimmedDraft.isEmpty ? 14 : 4)
            .frame(minHeight: 56)
            // L'ombre franche porte sur la forme de fond seule : appliquée au
            // champ entier, un rayon nul recopierait le texte 5 pt plus bas.
            .background(fieldBackground)
            .padding(.bottom, Theme.drop)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(Theme.caption(12))
                    // Le corail vif tombe a 3,1:1 sur le papier : le signal
                    // reste dans l'icone, le texte passe a l'encre.
                    .foregroundStyle(skin.ink.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, Theme.gutter)
        // Pendant le rangement, la liste bouge sous les doigts : ajouter un
        // prénom au même moment ferait sauter la ligne qu'on tient.
        .disabled(editMode.isEditing)
        .opacity(editMode.isEditing ? 0.35 : 1)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
            .fill(skin.panel)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(skin.outline, lineWidth: Theme.stroke)
            )
            .shadow(color: skin.outline, radius: 0, y: Theme.drop)
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submitDraft() {
        let name = trimmedDraft
        guard !name.isEmpty else { return }

        // Le store répond `nil` sans dire pourquoi : les deux refus courants
        // sont testés ici pour que le message nomme la vraie raison.
        if store.isFull {
            fail("La table est complète à \(RosterStore.maxPlayers) joueurs.")
            return
        }
        if isAlreadyTaken(name) {
            fail("\(name) est déjà à table.")
            return
        }

        let added = withAnimation(Theme.spring) { store.add(name) }
        guard added != nil else {
            fail("Ce prénom n'a pas pu être ajouté.")
            return
        }

        Haptics.tap()
        draft = ""
        errorMessage = nil
        // Le champ garde le focus : une table de huit se saisit d'une traite.
        addFieldFocused = true
    }

    private func fail(_ message: String) {
        Haptics.warning()
        withAnimation(Theme.snap) { errorMessage = message }
    }

    /// Même comparaison que le store (insensible à la casse, sensible aux
    /// accents) : « Lea » et « Léa » restent deux joueurs distincts.
    private func isAlreadyTaken(_ name: String) -> Bool {
        store.names.contains { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    // MARK: Liste

    private var list: some View {
        List {
            ForEach(store.participants) { participant in
                RosterRow(store: store, participant: participant, table: store.names)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: 3,
                        leading: Theme.gutter,
                        bottom: 3,
                        trailing: Theme.gutter
                    ))
            }
            .onMove(perform: moveRows)
            .onDelete(perform: deleteRows)

            // `safeAreaInset` décale déjà le contenu au-dessus du bandeau de
            // lancement ; cette ligne ne sert qu'à ce que le dernier prénom ne
            // colle pas au trait.
            Color.clear
                .frame(height: 24)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        // La liste ne pose pas son propre fond : le papier crème du `Backdrop`
        // traverse.
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func moveRows(from source: IndexSet, to destination: Int) {
        Haptics.tap()
        store.reorder(fromOffsets: source, toOffset: destination)
    }

    private func deleteRows(at offsets: IndexSet) {
        // Le sort du joueur appartient au store : supprimé hors manche,
        // seulement désactivé si une manche est en cours (spec §2.2).
        let ids = offsets.compactMap { store.participants[safe: $0]?.id }
        Haptics.tap()
        withAnimation(Theme.spring) {
            for id in ids { store.remove(id) }

            // Vider la liste en mode rangement ferait disparaître le bouton
            // « Terminé » avec les lignes, et le champ d'ajout resterait
            // désactivé : plus aucune sortie.
            if store.count <= 1 { editMode = .inactive }
        }
    }

    private var emptyState: some View {
        Panel {
            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.brandLight)
                    .accessibilityHidden(true)

                Text("Personne à table")
                    .font(Theme.heading(18))
                    .foregroundStyle(skin.ink)

                Text("Ajoute les prénoms une fois : tous les jeux de la soirée les reprennent.")
                    .font(Theme.body(14))
                    .foregroundStyle(skin.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 4)
    }

    // MARK: Lancement

    private var startBar: some View {
        VStack(spacing: 6) {
            if !isReady {
                Text(missingLabel)
                    .font(Theme.caption(13))
                    .foregroundStyle(skin.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            PrimaryButton(title: startTitle, systemImage: "play.fill", isEnabled: isReady) {
                addFieldFocused = false
                onStart()
            }
            .accessibilityIdentifier("roster-start")
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
        // Bandeau plein et trait encré plutôt qu'un fondu : la DA n'a aucun
        // dégradé, et il faut bien masquer les lignes qui passent dessous.
        .background(
            skin.background
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(skin.outline)
                        .frame(height: 2)
                }
                .ignoresSafeArea()
        )
    }

    /// Le plancher du roster reste une borne dure : un jeu annoncé jouable à
    /// deux ne peut pas descendre en dessous.
    private var requiredPlayers: Int {
        max(minimumPlayers, RosterStore.minPlayers)
    }

    private var isReady: Bool {
        store.activePlayers.count >= requiredPlayers
    }

    private var missingLabel: String {
        let missing = requiredPlayers - store.activePlayers.count
        return missing <= 1
            ? "Encore un joueur avant de lancer."
            : "Encore \(missing) joueurs avant de lancer."
    }
}

// MARK: - Une ligne du roster

/// Prénom modifiable sur place. Le renommage ne crée pas de nouveau joueur :
/// l'identifiant reste le même, donc les points de la soirée le suivent.
private struct RosterRow: View {
    @Environment(\.skin) private var skin
    @Environment(\.editMode) private var editMode

    /// Référence simple et non `@ObservedObject` : c'est la vue parente qui
    /// observe le store et redistribue un `participant` à jour.
    let store: RosterStore
    let participant: Participant
    let table: [String]

    @State private var draft: String
    @FocusState private var isFocused: Bool

    init(store: RosterStore, participant: Participant, table: [String]) {
        self.store = store
        self.participant = participant
        self.table = table
        _draft = State(initialValue: participant.name)
    }

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                name: participant.name,
                size: 36,
                dimmed: !participant.isActive,
                table: table
            )

            TextField("Prénom", text: $draft)
                .font(Theme.body(16))
                .foregroundStyle(participant.isActive ? skin.ink : skin.inkMuted)
                // Grisé, barré ET annoncé : l'absence ne se lit jamais à la
                // seule couleur (spec §2.8).
                .strikethrough(!participant.isActive, color: skin.inkMuted)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                // Pendant le rangement, la ligne se déplace : la saisie
                // rentrerait en conflit avec le geste de glissement.
                .disabled(isEditing)
                .onSubmit(commit)
                .onChange(of: isFocused) { _, focused in
                    if !focused { commit() }
                }
                .accessibilityLabel(
                    participant.isActive
                        ? "Prénom de \(participant.name)"
                        : "Prénom de \(participant.name), en pause"
                )

            if !participant.isActive {
                Button {
                    Haptics.tap()
                    withAnimation(Theme.snap) { store.reactivate(participant.id) }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 15, weight: .bold))
                        // Encre sur pastille pleine cerclee, comme CounterRow :
                        // la menthe seule ne fait que 1,6:1 sur le papier.
                        .foregroundStyle(Theme.night)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Theme.mint)
                                .overlay(Circle().strokeBorder(skin.outline, lineWidth: 2))
                        )
                        .frame(width: Theme.touchTarget, height: Theme.touchTarget)
                }
                .buttonStyle(PressedStyle())
                .accessibilityLabel("Remettre \(participant.name) dans la partie")
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, participant.isActive ? 12 : 2)
        .frame(minHeight: 56)
        .background(rowBackground)
        // Réserve la place de l'ombre, sinon la ligne suivante la recouvre.
        .padding(.bottom, 4)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
            .fill(participant.isActive ? skin.panel : skin.panelSoft)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(
                        skin.outline.opacity(participant.isActive ? 1 : 0.45),
                        lineWidth: Theme.stroke
                    )
            )
            .shadow(
                color: skin.outline.opacity(participant.isActive ? 1 : 0.35),
                radius: 0,
                y: 4
            )
    }

    /// Un renommage refusé (prénom vide ou déjà pris) rend son ancien prénom au
    /// champ : laisser la saisie à l'écran ferait croire qu'elle est enregistrée.
    private func commit() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name != participant.name else { return }

        if store.rename(participant.id, to: name) {
            Haptics.tap()
            // Le store tronque au-delà de 20 caractères : le champ doit montrer
            // ce qui a réellement été retenu.
            draft = store.participant(id: participant.id)?.name ?? name
        } else {
            Haptics.warning()
            draft = participant.name
        }
    }
}

#if DEBUG
/// Roster jetable : une prévisualisation ne doit pas écrire dans les réglages
/// réels du simulateur.
private func previewRoster(_ names: [String], key: String) -> RosterStore {
    let store = RosterStore(
        defaults: UserDefaults(suiteName: "mytho.previews") ?? .standard,
        storageKey: key
    )
    store.seed(names: names)
    return store
}

#Preview("Roster — 4 joueurs") {
    RosterView(store: previewRoster(["Léa", "Tom", "Nino", "Sarah"], key: "preview.roster.full")) {}
}

#Preview("Roster — vide") {
    RosterView(store: previewRoster([], key: "preview.roster.empty")) {}
}
#endif
