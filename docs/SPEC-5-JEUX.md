# SPEC — les 5 prochains jeux de Mytho

> **Statut** : spécification approuvée, prête à implémenter.
> **Portée** : Le plus susceptible de… · Longueur d'onde · Je n'ai jamais · Tu préfères · Action ou vérité.
> **Version** : 1 — 3 août 2026.

---

## Comment utiliser ce fichier

Ce document est écrit pour être implémenté section par section, pas d'un bloc.

1. **Le socle (§2) se fait en premier et se fait une fois.** Les cinq jeux en dépendent. L'écrire après le premier jeu garantit cinq implémentations divergentes du passage de téléphone et du roster.
2. **Un jeu = une PR.** Ne jamais ouvrir deux jeux en parallèle : ils touchent tous au socle.
3. **Chaque section de jeu est autosuffisante.** Pour implémenter Longueur d'onde, il suffit de lire §2 et §4.
4. **La checklist de fin de section fait foi.** Un jeu qui tourne mais dont la checklist n'est pas verte n'est pas fini.

### Ordre de construction

- [ ] §2 — Socle commun + écran d'accueil
- [ ] §3 — Le plus susceptible de… *(valide : grille de prénoms, décompte, barème simple)*
- [ ] §4 — Tu préfères ? *(valide : écran signature, 3 modes sur 1 moteur)*
- [ ] §5 — Je n'ai jamais *(valide : vies, éliminations, vote secret)*
- [ ] §6 — Longueur d'onde *(valide : passage du téléphone, geste analogique)*
- [ ] §7 — Action ou vérité *(valide : bouteille, packs verrouillés, signalement)*

---

## 1. Contraintes du repo — à lire avant d'écrire une ligne

| Contrainte | Conséquence pratique |
|---|---|
| **XcodeGen** (`project.yml`) | Un nouveau `.swift` n'a **jamais** besoin d'être ajouté à un `.pbxproj`. Il suffit de créer le fichier au bon endroit. Ne pas éditer, ni grepper, le pbxproj. |
| **Pas de Xcode local** (poste Windows) | La CI macOS est la **seule** preuve que le code compile. Aucun « ça build chez moi ». |
| **`.github/workflows/screenshots.yml`** | Workflow manuel : rejoue une manche sur simulateur et publie les PNG. **C'est le seul moyen de voir l'UI.** Le lancer avant tout verdict visuel, et l'étendre à chaque nouveau jeu. |
| **`.github/workflows/build-testflight.yml`** | Job de tests sur `macos-15`. Une PR rouge ne se merge pas. |
| **Hors ligne, zéro dépendance** | Aucun package externe, aucun appel réseau, aucun compte. Ça vaut aussi pour les confettis et les animations : tout est fait main. |

### Sources de vérité

| Sujet | Fichier | Règle |
|---|---|---|
| Couleurs, typo, métriques, ressorts | `Mytho/Design/Theme.swift` | Aucune valeur visuelle en dur ailleurs. |
| Composants d'interface | `Mytho/Design/Components.swift` | Réutiliser avant de créer. |
| Modèles de partie | `Mytho/Core/GameModels.swift` | Étendre, ne pas dupliquer. |
| Contenu | `Mytho/Core/WordBank.swift` | **Le patron à copier** pour tous les paquets de cartes. Voir §1.2. |

### 1.1 — Ce qui existe et ne doit pas être réécrit

| Symbole | Utiliser pour |
|---|---|
| `Theme.night` `.brand` `.brandLight` `.amber` `.mint` `.crimson` | Toutes les couleurs. Un jeu ne crée jamais de couleur. |
| `Theme.title()` `.heading()` `.body()` `.caption()` | Toute la typographie. |
| `Theme.radius` (18) · `.radiusLarge` (26) · `.touchTarget` (44) · `.gutter` (20) | Toutes les métriques. |
| `Theme.spring` (0,42 / 0,82) | Transitions d'écran et apparitions. |
| `Theme.snap` (0,28 / 0,75) | Retours tactiles : appui, sélection, incrément. |
| `Theme.flip` (0,55 / 0,78) | Retournements et révélations. |
| `Backdrop` | Fond de chaque écran. Aucun jeu ne pose son propre dégradé. |
| `PrimaryButton` | Le CTA. **Un seul par écran**, sans exception. |
| `GhostButton` | Action secondaire. |
| `Panel` | Surface de contenu translucide. |
| `PhasePill` | Étiquette de phase en haut d'écran. |
| `CounterRow` · `OptionToggle` | Tous les réglages numériques et booléens. |
| `PressedStyle` | Enfoncement 0,97 sur tout bouton personnalisé. |
| `Haptics.tap() .impact() .success() .warning()` | Vibrations. Appeler `Haptics.prepare()` avant une salve d'appuis. |
| `AnyTransition.forward` | Enchaînement d'écrans. |
| `AnyTransition.reveal` | Apparition centrée d'une révélation. |

### 1.2 — Le contenu se stocke en Swift, pas en JSON

`WordBank.swift` est le patron. Chaque jeu fournit son propre `…Bank` sur le même modèle :

```swift
struct WordCategory: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let symbol: String   // SF Symbol
    let pairs: [WordPair]
}
```

Pas de fichier JSON, pas de chargement de bundle, pas de décodage à l'exécution. Bénéfices : vérification à la compilation, aucune erreur de parsing possible, et le contenu se relit en diff de PR.

---

## 2. Socle commun

Fichiers à créer :

```
Mytho/Core/Party/PartyGame.swift      — protocole + registre des jeux
Mytho/Core/Party/RosterStore.swift    — prénoms de la soirée, persistés
Mytho/Core/Party/Deck.swift           — pioche sans répétition, générique
Mytho/Core/Party/ScoreBoard.swift     — points + annulation de la dernière action
Mytho/Core/Party/AppSettings.swift    — réglages globaux
Mytho/Views/Party/HomeView.swift      — grille des jeux
Mytho/Views/Party/RosterView.swift    — saisie des prénoms
Mytho/Views/Party/PassPhoneView.swift — « passe le téléphone à X »
```

### 2.1 — Registre des jeux

Ajouter un jeu doit revenir à ajouter une entrée dans un tableau. Aucun `if gameID == …` dans l'écran d'accueil.

```swift
protocol PartyGame: Identifiable {
    var id: String { get }              // "most-likely", "wavelength"…
    var title: String { get }
    var tagline: String { get }         // une ligne, affichée sur la tuile
    var symbol: String { get }          // SF Symbol
    var accent: Color { get }           // pris dans Theme, jamais une nouvelle couleur
    var players: ClosedRange<Int> { get }
    var minutes: Int { get }            // durée typique, affichée sur la tuile
    var needsNames: Bool { get }        // impose le roster avant de lancer
}

enum GameRegistry {
    static let all: [any PartyGame] = [ … ]
}
```

### 2.2 — Roster de la soirée

`RosterStore` : `@Observable`, persisté en `UserDefaults`. Les prénoms se saisissent **une fois** et les cinq jeux les reprennent. Re-saisir entre deux jeux casse l'enchaînement de la soirée.

API : `add`, `rename`, `remove`, `reorder`, `clear`.

Retirer un joueur en cours de partie est autorisé — quelqu'un part toujours en avance. Le joueur est marqué inactif, **jamais supprimé** de l'historique de la manche en cours.

### 2.3 — Passage du téléphone

`PassPhoneView` — brique d'anti-triche, utilisée par Longueur d'onde et par tous les modes de vote secret.

- Plein écran, rien d'autre : « Passe le téléphone à **Léa** ».
- Un seul bouton, libellé **« Je suis Léa »** — jamais « Continuer », qui se tape par réflexe.
- Le geste de retour iOS et le bouton retour sont **désactivés** pendant toute la séquence secrète. Une révélation ne se rejoue pas.
- `Haptics.impact(.medium)` à l'ouverture, pour que le porteur sente le changement d'écran sans regarder.

### 2.4 — Pioche sans répétition

`Deck<Item>` généralise ce que `WordBank.randomPair(from:excluding:)` fait déjà : mélange, plus **mémoire persistée des cartes vues**, par jeu.

- Une carte sortie ne revient pas tant que **70 %** du paquet n'est pas épuisé.
- Paquet vidé → remélange, et un message affiché **une seule fois** : « tu as fait le tour du paquet ».
- La mémoire survit à la fermeture de l'app (`UserDefaults`), et se vide depuis les réglages.

> C'est le seul détail qui sépare une app de soirée bien faite d'une app cheap. Revoir la même carte deux fois dans une soirée casse l'illusion de profondeur, quel que soit le volume réel de contenu.

### 2.5 — Tableau des scores

`ScoreBoard` : joueur → points, plus l'historique de la manche courante pour permettre **d'annuler la dernière action** (un mauvais tap arrive à chaque partie). Chaque jeu définit son barème ; l'affichage, le tri et l'animation d'incrément sont communs — `contentTransition(.numericText())`, déjà utilisé dans `CounterRow`.

### 2.6 — Réglages globaux

Un seul écran, atteignable depuis l'accueil : son, haptiques, animations réduites, contenu adulte, réinitialiser les paquets.

Les animations réduites suivent `accessibilityReduceMotion` par défaut, mais restent forçables manuellement.

### 2.7 — Navigation

Un `NavigationStack` unique piloté par un chemin typé. **Aucun jeu ne présente de `sheet` par-dessus une partie** : la soirée est un enchaînement linéaire, pas une arborescence.

```swift
enum Route: Hashable {
    case roster                  // prénoms de la soirée
    case rules(gameID: String)   // règles, 4 écrans max, sautables
    case setup(gameID: String)   // packs, options, nombre de manches
    case play(gameID: String)
    case results(gameID: String)
    case settings
}
```

L'écran de résultats propose **toujours** deux sorties : *Rejouer* et *Changer de jeu*. La seconde conserve le roster et les scores de la soirée.

### 2.8 — Accessibilité, sur les cinq jeux

- [ ] Toute cible tactile ≥ 44 × 44 pt (`Theme.touchTarget`).
- [ ] Aucune information portée par la couleur seule : un joueur éliminé est grisé **et** barré **et** annoncé.
- [ ] Toute animation en boucle coupée si `accessibilityReduceMotion` — les mouvements deviennent des fondus.
- [ ] Dynamic Type jusqu'à XXL sans troncature ; au-delà, les grilles de prénoms passent de 2 colonnes à 1.
- [ ] Les écrans secrets sont annoncés à VoiceOver ; les décorations portent `accessibilityHidden(true)`.

### Checklist §2

- [ ] Ajouter un 6e jeu ne demande de toucher à aucun écran existant.
- [ ] Le roster survit à la fermeture de l'app et au changement de jeu.
- [ ] Un test rejoue 200 tirages et vérifie qu'aucune carte ne ressort avant 70 % du paquet.
- [ ] Le retour arrière est impossible sur un écran secret (test UI).

---

## 3. Le plus susceptible de…

`3–12 joueurs` · `~10 min` · accent `Theme.amber` · prénoms **requis** · **200 cartes**

**Règle.** Une phrase s'affiche. Au décompte, tout le monde pointe du doigt la personne de la table qui correspond le mieux. Celui qui récolte le plus de doigts marque un point. Le plus gros total remporte le titre.

### 3.1 — Boucle

1. La carte s'affiche : « Le plus susceptible de… **se faire arrêter à la frontière** ». Le préfixe est dans l'interface, **jamais dans la donnée**.
2. Décompte **3 · 2 · 1 · Pointez**, ~2,4 s au total.
3. Tout le monde pointe simultanément. Le porteur tape le prénom le plus désigné dans une grille — un seul geste.
4. Résultat : le prénom en grand, le nombre de doigts, une barre de remplissage, +1 point.
5. Carte suivante. Après la dernière manche : classement, titre attribué au premier.

### 3.2 — Modes de comptage

| Mode | Fonctionnement | Quand |
|---|---|---|
| **Rapide** *(défaut)* | Un seul tap par manche, le rythme ne casse jamais. | Toujours. |
| Vote secret | Le téléphone circule, chacun désigne en secret, révélation simultanée. | Quand le groupe se connaît trop bien et s'aligne sur le premier doigt levé. |

### 3.3 — Écrans

1. **Carte + décompte** — la phrase dans un `Panel`, le chiffre du décompte en grand au centre.
2. **Désignation** — grille de prénoms 2 colonnes, un `GhostButton` « Ex æquo », `PrimaryButton` « Valider ».
3. **Résultat** — prénom gagnant, « 4 doigts sur 6 · +1 point », deux barres de répartition.
4. **Classement final** — tri décroissant, titre au premier.

### 3.4 — Animations

| Moment | Ce qui bouge | Réglage |
|---|---|---|
| Carte | Entrée `.forward` + inclinaison aléatoire −1,5° à +1,5°, **figée à la génération** | imite un paquet réel : deux cartes ne se posent jamais pareil |
| Décompte | Chaque chiffre `scale 1,35 → 1` puis fondu | `Theme.snap` · `impact(.light)` sur 3-2-1, `impact(.heavy)` sur « Pointez » |
| Sélection | Tuile en violet, `scale 1 → 1,04 → 1` | `Theme.snap` · `tap()` |
| Résultat | Barres remplies de 0 à leur valeur, décalées de 60 ms | 0,5 s `easeOut` ; prénom en `.reveal` |
| Fin | Confettis maison — 40 particules dans un `Canvas`, 1,6 s, **aucune bibliothèque** | `success()` |
| **Réduit** | Pas d'inclinaison, pas de confettis, barres déjà remplies, entrées en fondu 0,2 s | |

> La vibration lourde sur « Pointez » est ce qui synchronise la table, pas l'écran — personne ne regarde le téléphone à cet instant.

### 3.5 — Contenu

```swift
struct MostLikelyCard: Hashable, Sendable {
    let id: String     // "mst_014"
    let text: String   // "se faire arrêter à la frontière"
}

enum MostLikelyBank { /* même forme que WordBank */ }
```

La phrase se lit toujours après « Le plus susceptible de… » : elle commence par un **verbe à l'infinitif**, sans majuscule ni point final. Une carte qui ne passe pas ce test est mal écrite.

Packs : `soiree` (120, tout public) · `potes` (80) · `epice` (60, verrouillé).

### 3.6 — Réglages et cas limites

- Nombre de manches : 6 · 12 · 20 · sans fin. **Défaut 12.**
- Égalité : bouton « Ex æquo » qui permet de désigner deux prénoms ; les deux marquent.
- **3 joueurs minimum**, sinon le vote n'a pas de sens.
- Un joueur retiré en cours de partie garde ses points et sort de la grille.

### Checklist §3

- [ ] Le décompte est testé unitairement (durées, ordre des haptiques).
- [ ] L'égalité attribue bien un point à chacun.
- [ ] `screenshots.yml` couvre une manche complète de ce jeu.

---

## 4. Tu préfères ?

`2–12 joueurs` · `~10 min` · accent `Theme.brand` + `Theme.amber` · prénoms **requis en mode survie** · **200 dilemmes**

**Règle.** Deux options aussi désagréables l'une que l'autre. Chacun choisit, tout le monde s'explique.

C'est **l'écran le plus reconnaissable de l'app** : deux moitiés plein écran, violet contre ambre, et un « ou » au milieu.

### 4.1 — Trois modes, un seul moteur

| Mode | Ce qui se passe | Fin |
|---|---|---|
| **Débat** *(défaut)* | Tout le monde annonce son choix, le porteur compte en deux taps, l'app montre la répartition. | après N cartes |
| Vote secret | Le téléphone circule, chacun vote sans être vu, révélation simultanée du graphe. | après N cartes |
| **Survie** | Chacun vote, **la minorité est éliminée**. On recommence avec les survivants. | dernier debout |

> Le mode survie est le jeu « on choisit entre deux choses et la minorité saute ». Il ne mérite pas son propre moteur : même contenu, mêmes écrans, une règle en plus.
> **Égalité parfaite en mode survie : personne n'est éliminé**, on passe à la carte suivante — sinon la partie s'arrête sur un coup de dé.

### 4.2 — Écrans

1. **Le dilemme** — deux moitiés plein écran, un « ou » centré. Pas de `Panel`, pas de titre : les deux options occupent tout.
2. **Répartition** — deux barres horizontales épaisses, comptes en chiffres, mention des minoritaires en mode survie.
3. **Survivants** — grille de prénoms, éliminés grisés à 32 % d'opacité, jamais retirés.

### 4.3 — Animations

| Moment | Ce qui bouge | Réglage |
|---|---|---|
| Arrivée | Les deux moitiés entrent simultanément, l'une par le haut, l'autre par le bas, 60 ms d'écart | `Theme.spring` ; le « ou » en dernier, `.reveal` |
| Le « ou » | Pulsation `scale 1 → 1,04`, aller-retour 1,8 s | **seule boucle infinie de l'app** — coupée si animations réduites |
| Choix | La moitié retenue passe de 50/50 à 62/38, l'autre se désature | `Theme.spring` · `impact(.medium)` |
| Élimination | Les prénoms minoritaires tombent : `offset y +400`, opacité 0, décalés de 60 ms | 0,5 s · `warning()` |
| **Réduit** | Moitiés en fondu, « ou » figé, élimination en fondu sur place | |

### 4.4 — Contenu

```swift
struct Dilemma: Hashable, Sendable {
    let id: String   // "wyr_031"
    let a: String    // "Ne plus jamais manger de fromage"
    let b: String    // "Ne plus jamais revoir la mer"
}
```

**Critère de tri.** Les deux options doivent être **aussi mauvaises l'une que l'autre**. Si la réponse est évidente pour tout le monde, la carte est ratée : pas de débat, donc pas de jeu. Test : faire voter cinq personnes ; si les cinq choisissent pareil, la carte dégage.

### 4.5 — Réglages et cas limites

- Nombre de cartes : 8 · 15 · 25 · sans fin. Ignoré en mode survie.
- Mode survie, deux survivants et égalité : on passe la carte, indéfiniment s'il le faut.
- Le mode débat **fonctionne sans prénoms** — utile pour lancer une partie en dix secondes avec des inconnus.

### Checklist §4

- [ ] Les trois modes partagent le même moteur et le même paquet.
- [ ] L'égalité en mode survie n'élimine personne (test unitaire).
- [ ] Le « ou » ne pulse pas quand `accessibilityReduceMotion` est actif.

---

## 5. Je n'ai jamais

`3–12 joueurs` · `~15 min` · accent `Theme.mint` · prénoms **requis** · **250 cartes**

**Règle.** Une affirmation s'affiche : « Je n'ai jamais… menti sur mon âge ». Ceux qui l'ont déjà fait perdent une vie. Chacun démarre avec cinq vies ; le dernier debout gagne.

### 5.1 — Boucle

1. La carte s'affiche. Chacun annonce s'il l'a fait — l'app ne peut pas le savoir, c'est le groupe qui arbitre.
2. Le porteur tape les prénoms concernés. Chaque tap éteint une vie **immédiatement** sur la tuile.
3. *Valider*. Ceux qui tombent à zéro sont éliminés dans la foulée.
4. Carte suivante, jusqu'au dernier survivant.

### 5.2 — Modes d'aveu

| Mode | Fonctionnement |
|---|---|
| **À l'honneur** *(défaut)* | Chacun s'auto-dénonce, c'est immédiat. |
| Aveu secret | Le téléphone circule, chacun répond oui/non sans être vu. L'app affiche « **3 personnes sur 6** l'ont fait » **sans dire qui**, avec un bouton *Révéler* que le groupe active — ou pas. |

> L'aveu secret transforme un jeu d'ambiance en jeu de tension. C'est le meilleur candidat au déblocage payant de l'app.

### 5.3 — Écrans

1. **La carte** — préfixe « Je n'ai jamais… » en petit, l'affirmation en grand dans un `Panel`.
2. **Désignation** — grille de prénoms, **vies visibles en permanence** sous chaque prénom (5 points, éteints au fur et à mesure).
3. **Aveu secret** — le compte en très grand, deux boutons : *Révéler qui* / *Laisser le doute*.
4. **Podium** — dernier survivant.

### 5.4 — Animations

| Moment | Ce qui bouge | Réglage |
|---|---|---|
| Vie perdue | Le point passe `opacity 1 → 0,2` et `scale 1 → 0,7` | `Theme.snap` · `impact(.rigid)` — sec, un peu désagréable, c'est voulu |
| Élimination | La tuile se désature, tourne de −3°, descend en fin de grille | 0,45 s `Theme.spring` · `warning()` — le prénom reste lisible, on ne cache pas les morts |
| Aveu secret | Le compte entre en `.reveal` ; à la révélation, les prénoms apparaissent un par un, 120 ms d'écart | le silence entre deux noms **est** le jeu |
| Dernier debout | Sa tuile monte au centre et s'agrandit, confettis 1,6 s | `Theme.spring` · `success()` |
| **Réduit** | Points éteints sans redimensionnement, éliminés en fondu, pas de confettis | |

### 5.5 — Contenu

```swift
struct ConfessionCard: Hashable, Sendable {
    let id: String     // "nhie_042"
    let text: String   // "menti sur mon âge"
}
```

Préfixe « Je n'ai jamais… » dans l'interface. La donnée est un **participe passé**, sans majuscule ni point.

Packs : `soft` (100) · `potes` (90) · `epice` (60, verrouillé).

### 5.6 — Réglages et cas limites

- Vies de départ : 3 · 5 · 7. **Défaut 5.**
- **Mode sans élimination** : on compte les aveux, le plus gros total « gagne » — utile pour les grands groupes où sortir tôt est frustrant.
- Un joueur éliminé continue de voir les cartes et de commenter : il n'est **jamais** renvoyé hors de l'écran.
- Si tous les survivants tombent à zéro sur la même carte, tous sont vainqueurs ex æquo.

### Checklist §5

- [ ] L'élimination simultanée de tous les survivants est gérée (test unitaire).
- [ ] L'aveu secret n'expose jamais l'identité avant l'appui sur *Révéler*.
- [ ] Un joueur éliminé reste visible et annoncé comme éliminé par VoiceOver.

---

## 6. Longueur d'onde

`2–12 joueurs` · `~15 min` · accent `Theme.brand` · prénoms **requis** · **150 axes**

**Règle.** Un axe oppose deux notions — « Surcoté ↔ Sous-coté ». Une cible invisible est placée dessus. Un seul joueur, **le médium**, la voit ; il donne un indice à voix haute, et le groupe fait glisser un curseur pour la retrouver. Plus on tombe près, plus on marque.

> **Ce n'est pas un jeu d'élimination, et il n'y a rien à choisir entre deux options.** Le cœur du jeu est un curseur analogique et une cible cachée. Tout le reste est de l'habillage autour de ces deux objets.

### 6.1 — Boucle

1. Le téléphone passe au médium (`PassPhoneView`).
2. Révélation : l'axe et la cible — une position 0–100 avec une bande colorée autour.
3. Le médium annonce son indice à voix haute, puis tape *J'ai donné mon indice*. **La cible se referme instantanément.**
4. Il pose le téléphone au milieu de la table. Le groupe débat et fait glisser l'aiguille.
5. *Verrouiller*. Le volet se soulève, la cible apparaît sous l'aiguille.
6. Points selon la bande touchée. Manche suivante, médium suivant dans l'ordre du roster.

### 6.2 — Barème

| Écart à la cible | Points | Ressenti visé |
|---|---:|---|
| ≤ 3 % | **4** | Le cri de table. `success()`, la bande pulse deux fois. |
| ≤ 8 % | **3** | Satisfaction franche. |
| ≤ 16 % | **2** | « On n'était pas loin. » |
| > 16 % | **0** | `warning()`. Aucune moquerie de l'app — le groupe s'en charge. |

Objectif coopératif par défaut : **20 points en 7 manches**.
Mode deux équipes en option : alternance des médiums, et vol de manche — l'équipe adverse dit seulement si la cible est à gauche ou à droite de l'aiguille, pour 1 point.

### 6.3 — Écrans

1. **Vue médium** — cadran en demi-cercle, bandes colorées, aiguille de cible visible. `PhasePill` « Tu es le médium ».
2. **Vue groupe** — même cadran, **volet opaque** par-dessus, aiguille déplaçable au doigt, indice rappelé en haut.
3. **Révélation** — les deux aiguilles superposées, l'écart en pourcentage, le total.

### 6.4 — Animations — c'est ici que le jeu se gagne

| Moment | Ce qui bouge | Réglage |
|---|---|---|
| **Le volet** | `rotation3DEffect` autour de l'axe X, ancré en bas, 0° → 108° | 0,7 s `Theme.flip`. Métaphore : un couvercle qu'on soulève — **jamais un fondu**, qui ne raconte rien |
| **L'aiguille** | Suit le doigt via `DragGesture` converti en angle | `tap()` **à chaque tranche de 2 % franchie** — curseur cranté, comme une molette |
| Verrouillage | L'aiguille se fige avec un dépassement de 1,5° puis retour | `Theme.snap` — la demi-seconde de suspense avant l'ouverture est délibérée |
| Score | Le total s'incrémente chiffre par chiffre | `contentTransition(.numericText())` |
| **Réduit** | Volet en fondu 0,25 s, aiguille sans dépassement, bande sans pulsation. **Le crantage haptique reste.** | |

### 6.5 — Contenu

```swift
struct Axis: Hashable, Sendable {
    let id: String     // "wl_007"
    let left: String   // "Surcoté"
    let right: String  // "Sous-coté"
}
```

**Critère de tri.** Un bon axe est **subjectif et discutable** : « Surcoté ↔ Sous-coté », « Plaisir coupable ↔ Fierté », « Poli ↔ Malpoli ». Un axe factuel est un mauvais axe : sur « Petit ↔ Grand » il n'y a rien à débattre, donc pas de jeu.

> La moitié des axes mal écrits abîme l'impression générale plus vite que le double d'axes en moins.

### 6.6 — Réglages et cas limites

- **2 joueurs minimum** : un médium, un devineur. Le jeu reste bon à deux.
- Le médium ne participe pas au placement — règle sociale que l'app rappelle **une fois**, pas à chaque manche.
- **Retour arrière interdit** après *J'ai donné mon indice* : geste de retour désactivé, bouton retour absent.
- La cible n'est **jamais** tirée à moins de 8 % d'un bord — sinon « tout à droite » suffit et l'indice ne sert à rien.
- Bouton *Passer cet axe* pour le médium, avant d'avoir donné son indice, sans pénalité.

### Checklist §6

- [ ] La cible ne tombe jamais dans les 8 % de bord (test sur 1 000 tirages).
- [ ] Le calcul des bandes 4/3/2/0 est testé unitairement, bornes comprises.
- [ ] Le crantage haptique fonctionne encore en mode animations réduites.
- [ ] Impossible de revenir sur l'écran médium après l'indice (test UI).

---

## 7. Action ou vérité

`3–12 joueurs` · `~20 min` · accent `Theme.amber` / `Theme.brand` · prénoms **requis** · **2 × 120 cartes + 30 gages**

**Règle.** La bouteille désigne quelqu'un. Il choisit action ou vérité, l'app tire la carte, il s'exécute ou il passe — et passer se paie.

### 7.1 — Boucle

1. La bouteille tourne et s'arrête sur un joueur. Tour de rôle simple disponible en option.
2. Deux gros boutons : **Action** en ambre, **Vérité** en violet.
3. La carte se retourne et affiche le défi ou la question.
4. *Fait* → +1 point. *Je passe* → 0 point et un gage tiré au hasard.
5. La bouteille repart. Un joueur ne peut pas être désigné deux fois d'affilée.

### 7.2 — Intensités

| Niveau | Public | Statut |
|---|---|---|
| `soft` | Tout public, jouable en famille | actif |
| `chaud` | Entre amis, gênant sans être intime | actif |
| `brulant` | — | **verrouillé** : interrupteur des réglages + confirmation d'âge. Jamais actif par défaut, **invisible tant qu'il n'est pas activé**. |

### 7.3 — Animations

| Moment | Ce qui bouge | Réglage |
|---|---|---|
| **Bouteille** | 3 à 5 tours puis décélération | 2,4 s `easeOut`. **L'angle final est calculé avant de lancer** — on anime vers un résultat déjà tiré, on ne tire pas là où la physique s'arrête, sinon la répartition entre joueurs n'est pas garantie |
| Le tac-tac-tac | `tap()` à chaque passage devant un prénom, fréquence qui ralentit avec la rotation | c'est ce qui rend l'attente tenable |
| Arrêt | Rebond de 4° puis retour ; prénom en `.reveal` | `Theme.snap` · `impact(.heavy)` |
| Carte | `rotation3DEffect` axe Y, dos violet uni → face | 0,55 s `Theme.flip`. **Le texte n'apparaît qu'après 50 % de la rotation**, sinon on le lit à l'envers |
| Je passe | La carte part en biais : rotation −12°, `offset x −400` | 0,4 s ; le gage arrive derrière en `.forward` |
| **Réduit** | La bouteille ne tourne pas : le prénom est tiré et affiché directement, avec l'haptique lourde. La carte ne se retourne pas, elle apparaît en fondu. | |

### 7.4 — Contenu

```swift
enum Heat: String, Sendable { case soft, chaud, brulant }
enum DareNeeds: String, Sendable { case solo, table }  // "table" = implique un autre joueur

struct DareCard: Hashable, Sendable {
    let id: String        // "tod_a_058"
    let isAction: Bool    // false = vérité
    let text: String
    let heat: Heat
    let needs: DareNeeds
}
```

Les cartes `needs == .table` sont **exclues en dessous de 4 joueurs**.
Les gages sont un paquet séparé (~30 entrées), tirées avec le même `Deck`.

### 7.5 — Modération — le jeu le plus risqué de l'app

C'est celui qui peut faire refuser l'app, et **c'est le contenu qui décide, pas le code**. Quatre règles d'écriture, sans exception :

1. Aucun défi **physiquement dangereux** — rien qui implique de monter, courir, avaler, se brûler, sortir.
2. Aucune mention d'**alcool** ni de substance, dans aucun pack.
3. Aucun contenu **sexuellement explicite**, y compris dans le pack verrouillé — suggestif est la limite haute.
4. Aucun défi impliquant une **personne extérieure** à la partie : pas d'appel, pas de message, pas d'inconnu dans la rue.

**Ajouter un bouton *Signaler cette carte* sur chaque carte.** Il coûte une demi-journée, il désamorce la moitié des objections en revue App Store, et il fait remonter les cartes ratées.

### 7.6 — Réglages et cas limites

- Désignation : bouteille *(défaut)* ou tour de rôle.
- Proportion action / vérité : libre, ou forcée à 50/50.
- Un joueur ne peut pas être désigné deux fois de suite, **sauf s'ils ne sont que trois**.

### Checklist §7

- [ ] L'angle d'arrêt de la bouteille correspond exactement au joueur tiré (test unitaire sur 500 lancers, répartition uniforme).
- [ ] Les cartes `needs: .table` n'apparaissent pas à 3 joueurs.
- [ ] Le pack `brulant` est invisible tant qu'il n'est pas activé dans les réglages.
- [ ] Le bouton *Signaler* est présent sur toutes les cartes.

---

## 8. Contenu, packs et modération

> Le code de ces cinq jeux représente quelques semaines. Le contenu représente le reste — et c'est lui, pas le code, qui décidera si l'app est bonne.

| Jeu | Volume v1 | Format de la donnée | Soirées sans répétition |
|---|---:|---|---:|
| Le plus susceptible de | 200 | verbe à l'infinitif | 16 parties |
| Longueur d'onde | 150 | paire d'opposés | 21 parties |
| Je n'ai jamais | 250 | participe passé | 17 parties |
| Tu préfères | 200 | deux options | 13 parties |
| Action ou vérité | 240 + 30 gages | 2 paquets | 10 parties |

### Règles d'écriture communes

- **Une carte = une idée.** Si elle a besoin d'une virgule explicative, elle est trop longue.
- **Jamais de vouvoiement.** On tutoie ; l'app parle comme un ami.
- **Jamais de référence datée** — une actualité de 2026 sera illisible en 2028.
- **Jamais de personne réelle nommée**, célèbre ou non.
- **Rien qui vise une caractéristique protégée** : origine, religion, orientation, handicap, poids.
- Un **relecteur qui n'a pas écrit la carte** valide chaque pack avant intégration.

### Classification App Store

Avec les packs `soft` et `chaud` seuls, l'app vise **12+**. Le pack `brulant` d'Action ou vérité fait passer la fiche en **17+** dès qu'il est livré, **même verrouillé**.

**La décision se prend avant la première soumission, pas après** : changer de classification en cours de vie coûte une nouvelle revue complète.

---

## 9. Définition de fini

Un jeu n'est pas terminé quand il tourne. Il est terminé quand ces sept points sont vrais.

- [ ] **Le moteur est testé sans interface.** Composition, tirage, comptage et conditions de fin couverts par des tests unitaires purs, comme `GameEngineTests` l'est déjà.
- [ ] **Le tirage ne se répète pas.** Un test rejoue 200 manches et vérifie qu'aucune carte ne ressort avant 70 % du paquet.
- [ ] **Aucune valeur en dur.** Zéro couleur, taille, rayon ou durée hors de `Theme`.
- [ ] **Les animations réduites sont câblées.** L'app est jouable de bout en bout avec `accessibilityReduceMotion` actif, sans aucune boucle.
- [ ] **VoiceOver traverse une manche complète** sans impasse, et n'annonce **jamais** une information secrète.
- [ ] **`screenshots.yml` couvre le nouveau jeu** — c'est la seule preuve visuelle disponible depuis Windows.
- [ ] **Le contenu est relu** par quelqu'un qui ne l'a pas écrit, et le volume cible est atteint.

---

## Annexe — arbitrages déjà tranchés

Réversibles, mais cohérents entre eux : changer l'un demande de relire les autres.

| Décision | Retenu | Raison |
|---|---|---|
| « La minorité saute » | Un **mode** de Tu préfères, pas un jeu | Même contenu, mêmes écrans, une règle de plus. Un moteur économisé. |
| Longueur d'onde | **Coopératif** par défaut | Marche de 2 à 12 joueurs sans rééquilibrer. Deux équipes en option. |
| Comptage des votes | **Public** par défaut, secret en option | Le public est fluide, le secret est le vrai moment. L'un vend l'autre. |
| Prénoms | Saisis **une fois** pour la soirée | Un roster partagé par les cinq jeux. Re-saisir tue l'enchaînement. |
| Fin de partie | **Nombre de manches**, pas de score cible | Une partie doit durer un temps prévisible. 12 manches par défaut. |
| Alcool | **Jamais** dans le contenu | Classification App Store et refus de revue. Le groupe transforme les points en gorgées s'il veut. |
| Pack 18+ | **Verrouillé**, opt-in explicite | Un interrupteur dans les réglages, jamais actif par défaut, jamais visible sans être activé. |
| Contenu | **Swift**, pas JSON | Convention du repo (`WordBank.swift`) : vérifié à la compilation, relisible en diff de PR. |
