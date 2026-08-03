import SwiftUI

/// Écran d'accueil : joueurs, composition, options, catégories.
struct SetupView: View {
    @EnvironmentObject private var session: GameSession
    @FocusState private var focusedField: Int?
    @State private var showAdvanced = false
    @State private var showRules = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                playersPanel
                compositionPanel
                categoriesPanel
                advancedPanel
                if session.totalScores.values.contains(where: { $0 > 0 }) {
                    leaderboardPanel
                }
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Distribuer les cartes", systemImage: "sparkles") {
                focusedField = nil
                session.startRound()
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 10)
            .background(
                LinearGradient(
                    colors: [Theme.nightDeep.opacity(0), Theme.nightDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 130)
                .allowsHitTesting(false)
                .ignoresSafeArea()
            )
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Terminé") { focusedField = nil }
                    .font(Theme.body(16))
            }
        }
        .sheet(isPresented: $showRules) { RulesView() }
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 6) {
            Text("Mytho")
                .font(Theme.title(38))
                .foregroundStyle(Theme.ink)
            Text("Un mot pour tous, sauf pour les infiltrés.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)

            Button {
                Haptics.tap()
                showRules = true
            } label: {
                Label("Comment jouer", systemImage: "questionmark.circle.fill")
                    .font(Theme.caption(14))
                    .foregroundStyle(Theme.brandLight)
                    .padding(.horizontal, 14)
                    .frame(height: Theme.touchTarget)
            }
            .buttonStyle(PressedStyle())
        }
        .padding(.vertical, 4)
    }

    private var playersPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Joueurs", systemImage: "person.2.fill")
                        .font(Theme.heading(17))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(session.playerCount)")
                        .font(Theme.heading(17))
                        .foregroundStyle(Theme.brandLight)
                        .contentTransition(.numericText())
                }

                ForEach(Array(session.config.playerNames.enumerated()), id: \.offset) { index, _ in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(Theme.caption(13))
                            .foregroundStyle(Theme.inkFaint)
                            .frame(width: 20, alignment: .leading)

                        TextField(
                            "Joueur \(index + 1)",
                            text: Binding(
                                get: { session.config.playerNames[safe: index] ?? "" },
                                set: { session.config.playerNames[safe: index] = $0 }
                            )
                        )
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.ink)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: index)
                        .onSubmit { focusedField = index + 1 < session.playerCount ? index + 1 : nil }
                        .accessibilityLabel("Nom du joueur \(index + 1)")

                        if session.playerCount > Composition.minPlayers {
                            Button {
                                Haptics.tap()
                                withAnimation(Theme.spring) { session.removePlayer(at: index) }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Theme.inkFaint)
                                    .frame(width: Theme.touchTarget, height: Theme.touchTarget)
                            }
                            .buttonStyle(PressedStyle())
                            .accessibilityLabel("Retirer le joueur \(index + 1)")
                        }
                    }
                    .padding(.vertical, 2)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Theme.hairline).frame(height: 0.5)
                    }
                }

                Button {
                    Haptics.tap()
                    withAnimation(Theme.spring) { session.addPlayer() }
                } label: {
                    Label("Ajouter un joueur", systemImage: "plus.circle.fill")
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.brandLight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: Theme.touchTarget)
                }
                .buttonStyle(PressedStyle())
                .disabled(session.playerCount >= Composition.maxPlayers)
                .opacity(session.playerCount >= Composition.maxPlayers ? 0.4 : 1)
            }
        }
    }

    private var compositionPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Composition", systemImage: "dial.medium.fill")
                        .font(Theme.heading(17))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button("Suggérée") {
                        Haptics.tap()
                        withAnimation(Theme.snap) { session.applySuggestedComposition() }
                    }
                    .font(Theme.caption(13))
                    .foregroundStyle(Theme.brandLight)
                }

                CounterRow(
                    title: "Undercover",
                    symbol: Role.undercover.symbol,
                    tint: Theme.color(for: .undercover),
                    value: session.config.undercoverCount,
                    canDecrement: session.config.undercoverCount > 0 && session.config.infiltratorCount > 1,
                    canIncrement: session.canAddInfiltrator
                ) { delta in
                    withAnimation(Theme.snap) { session.adjustUndercover(by: delta) }
                }

                CounterRow(
                    title: "Mr. White",
                    symbol: Role.mrWhite.symbol,
                    tint: Theme.color(for: .mrWhite),
                    value: session.config.mrWhiteCount,
                    canDecrement: session.config.mrWhiteCount > 0 && session.config.infiltratorCount > 1,
                    canIncrement: session.canAddInfiltrator
                ) { delta in
                    withAnimation(Theme.snap) { session.adjustMrWhite(by: delta) }
                }

                Text(compositionSummary)
                    .font(Theme.caption(13))
                    .foregroundStyle(Theme.inkMuted)
            }
        }
    }

    private var compositionSummary: String {
        let civilians = session.config.civilianCount
        var parts = ["\(civilians) civil\(civilians > 1 ? "s" : "")"]
        if session.config.undercoverCount > 0 {
            parts.append("\(session.config.undercoverCount) undercover")
        }
        if session.config.mrWhiteCount > 0 {
            parts.append("\(session.config.mrWhiteCount) Mr. White")
        }
        return parts.joined(separator: " · ")
    }

    private var categoriesPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Thèmes", systemImage: "square.grid.2x2.fill")
                        .font(Theme.heading(17))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(session.config.categoryIDs.isEmpty ? "Tous" : "\(session.config.categoryIDs.count)")
                        .font(Theme.caption(13))
                        .foregroundStyle(Theme.inkMuted)
                }

                FlowLayout(spacing: 8) {
                    ForEach(WordBank.categories) { category in
                        CategoryChip(
                            category: category,
                            isOn: session.config.categoryIDs.isEmpty
                                || session.config.categoryIDs.contains(category.id)
                        ) {
                            Haptics.tap()
                            withAnimation(Theme.snap) { toggle(category) }
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ category: WordCategory) {
        var ids = session.config.categoryIDs
        // Vide signifie « toutes » : on matérialise la sélection avant de retirer.
        if ids.isEmpty { ids = Set(WordBank.categories.map(\.id)) }

        if ids.contains(category.id) {
            ids.remove(category.id)
        } else {
            ids.insert(category.id)
        }
        // Aucune catégorie sélectionnée n'aurait plus de mots : on repasse à toutes.
        session.config.categoryIDs = ids.isEmpty || ids.count == WordBank.categories.count ? [] : ids
    }

    private var advancedPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    Haptics.tap()
                    withAnimation(Theme.spring) { showAdvanced.toggle() }
                } label: {
                    HStack {
                        Label("Options avancées", systemImage: "slider.horizontal.3")
                            .font(Theme.heading(17))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.inkMuted)
                            .rotationEffect(.degrees(showAdvanced ? 0 : -90))
                    }
                    .frame(height: Theme.touchTarget)
                }
                .buttonStyle(PressedStyle())

                if showAdvanced {
                    VStack(spacing: 14) {
                        OptionToggle(
                            title: "Mr. White peut commencer",
                            subtitle: "Sans indice préalable, il part avec un vrai handicap.",
                            isOn: $session.config.mrWhiteCanStart
                        )
                        OptionToggle(
                            title: "Mode facile",
                            subtitle: "Chaque joueur voit son rôle en plus de son mot.",
                            isOn: $session.config.easyMode
                        )
                        OptionToggle(
                            title: "Mode aléatoire",
                            subtitle: "Le nombre d'infiltrés change à chaque manche.",
                            isOn: $session.config.randomMode
                        )

                        divider(label: "Pouvoirs (un joueur tiré au sort)")
                        ForEach(SpecialRole.allCases) { role in
                            let playable = session.playerCount >= role.minimumPlayers
                            OptionToggle(
                                title: role.displayName,
                                subtitle: playable
                                    ? role.summary
                                    : "\(role.summary) Dès \(role.minimumPlayers) joueurs.",
                                isOn: binding(for: role)
                            )
                            .disabled(!playable)
                            .opacity(playable ? 1 : 0.45)
                        }

                        divider(label: "Variantes de table")
                        ForEach(TableRule.allCases) { rule in
                            OptionToggle(
                                title: rule.displayName,
                                subtitle: rule.summary,
                                isOn: binding(for: rule)
                            )
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func divider(label: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(Theme.caption(12))
                .foregroundStyle(Theme.inkFaint)
            Rectangle().fill(Theme.hairline).frame(height: 0.5)
        }
        .padding(.top, 4)
    }

    private func binding(for role: SpecialRole) -> Binding<Bool> {
        Binding(
            get: { session.config.specialRoles.contains(role) },
            set: { isOn in
                if isOn { session.config.specialRoles.insert(role) }
                else { session.config.specialRoles.remove(role) }
            }
        )
    }

    private func binding(for rule: TableRule) -> Binding<Bool> {
        Binding(
            get: { session.config.tableRules.contains(rule) },
            set: { isOn in
                if isOn { session.config.tableRules.insert(rule) }
                else { session.config.tableRules.remove(rule) }
            }
        )
    }

    private var leaderboardPanel: some View {
        Panel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Classement", systemImage: "trophy.fill")
                        .font(Theme.heading(17))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button("Remettre à zéro") {
                        Haptics.tap()
                        withAnimation(Theme.spring) { session.resetScores() }
                    }
                    .font(Theme.caption(13))
                    .foregroundStyle(Theme.inkMuted)
                }
                LeaderboardList(rows: session.leaderboard)
            }
        }
    }
}

// MARK: - Puce de catégorie

private struct CategoryChip: View {
    let category: WordCategory
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.symbol)
                    .font(.system(size: 12, weight: .bold))
                Text(category.name)
                    .font(Theme.caption(13))
            }
            .foregroundStyle(isOn ? Theme.ink : Theme.inkFaint)
            .padding(.horizontal, 13)
            .frame(height: Theme.touchTarget)
            .background(
                Capsule()
                    .fill(isOn ? Theme.brand.opacity(0.32) : Theme.surface)
                    .overlay(
                        Capsule().strokeBorder(
                            isOn ? Theme.brandLight.opacity(0.6) : Theme.hairline,
                            lineWidth: 1
                        )
                    )
            )
        }
        .buttonStyle(PressedStyle())
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

// MARK: - Classement partagé

struct LeaderboardList: View {
    let rows: [(name: String, points: Int)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text("\(index + 1)")
                        .font(Theme.caption(13))
                        .foregroundStyle(index == 0 ? Theme.amber : Theme.inkFaint)
                        .frame(width: 22, alignment: .leading)
                    Text(row.name)
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text("\(row.points) pts")
                        .font(Theme.heading(15))
                        .foregroundStyle(index == 0 ? Theme.amber : Theme.inkMuted)
                        .contentTransition(.numericText())
                }
                .padding(.vertical, 9)
                .overlay(alignment: .bottom) {
                    if index < rows.count - 1 {
                        Rectangle().fill(Theme.hairline).frame(height: 0.5)
                    }
                }
            }
        }
    }
}

// MARK: - Mise en page fluide

/// Dispose les puces sur plusieurs lignes selon la largeur disponible.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += rowWidth > 0 ? spacing + size.width : size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Accès sûr aux tableaux

extension Array {
    subscript(safe index: Int) -> Element? {
        get { indices.contains(index) ? self[index] : nil }
        set {
            guard indices.contains(index), let newValue else { return }
            self[index] = newValue
        }
    }
}
