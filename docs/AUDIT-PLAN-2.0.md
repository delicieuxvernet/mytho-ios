# Mytho — audit complet et plan 2.0

> Rédigé le 19 octobre 2026, sur `main` à `bbed074` (version 1.2.0 en préparation).
> En ligne : **1.1.0, build #49**, en vente depuis le 20 août 2026.

## TL;DR

L'app est bien construite (moteurs testés, CI verte, DA cohérente), mais **elle n'est pas
vendable en l'état** :

- **Le contenu est famélique et pas assez drôle.** Il y a entre 14 et 41 cartes par jeu sur
  `main`, alors que la fiche App Store en promet 200 à 375.
- **Deux tuiles « Bientôt »** donnent l'image d'un produit inachevé.
- **Il n'y a aucun écran Réglages.** Une fois le 18+ ouvert, on ne peut plus le refermer, on
  ne peut pas couper les vibrations, et on ne peut pas remettre les paquets à zéro.
- **Les animations sont correctes mais génériques** : du rebond partout, un « Retour » qui
  glisse dans le mauvais sens, et une carte qui mélange ses deux faces en se retournant.

Le plan 2.0 traite tout cela en 7 lots, le contenu en premier.

---

## 1. État des lieux

| | |
|---|---|
| En ligne | 1.1.0 (build #49) · **18+** · gratuit · 0 note, 0 avis · 2,3 Mo · catégorie Mots |
| Fiche | nom « Mytho ! », sous-titre « Qui n'a pas le même mot ? » (ne parle que d'Undercover) |
| `main` | 1.2.0 · 4 jeux jouables (Undercover, Le plus susceptible, Tu préfères, Je n'ai jamais) + 2 tuiles « Bientôt » |
| Stack | SwiftUI iOS 17, zéro dépendance, XcodeGen ; CI GitHub Actions (tests → TestFlight) ; captures d'écran via `screenshots.yml` |
| Qualité du code | moteurs purs et testés (≈ 5 000 lignes de tests), verrou d'âge appliqué dans les banques et pas seulement dans les vues, mémoire de pioche persistée |

## 2. Constats

### 🔴 Bloquants pour vendre

**C1 — Le contenu ne tient pas une soirée.**

| Jeu | Promis sur la fiche | En ligne (#49) | `main` (1.2.0) | Tout public sur `main` |
|---|---:|---:|---:|---:|
| Undercover (paires) | 375 | 60 | 60 | 60 |
| Le plus susceptible | 300 | 45 | **14** | **0** |
| Tu préfères ? | 200 | 50 | 41 | 17 |
| Je n'ai jamais | 250 | 45 | 24 | **5** |

- *Le plus susceptible* **ne se lance plus** sans confirmation d'âge, faute de carte tout public.
- *Je n'ai jamais* en tout public, ce sont 5 cartes : la table a fait le tour du paquet en 3 minutes.
- Le ton est encore trop sage ou trop « dictionnaire » : les paires Undercover type *Chat / Chien*,
  *Règle / Équerre* ou *Perceuse / Scie* ne font rire personne. **Ni fun, ni jeune, ni stimulant.**

**C2 — La fiche App Store ment** (guideline 2.3.1). Les volumes affichés sont faux, le sous-titre
ne parle que d'un jeu sur quatre, et « les prénoms servent aux quatre jeux » est faux pour
Undercover, qui garde sa propre liste.

**C3 — Deux tuiles « Bientôt »** (Longueur d'onde, Action ou vérité) sur l'écran d'accueil. Une
app « finie » ne montre pas de jeux absents (guideline 2.1, contenu temporaire).

### 🟠 Importants

**I1 — Aucun écran Réglages.** Le modèle `AppSettings` existe, mais aucune vue ne l'expose.

- Le contenu 18+, une fois ouvert, ne se referme plus : il n'y a aucun moyen de rendre le
  téléphone à un mineur.
- `hapticsEnabled` n'est lu qu'à un seul endroit (le décompte de *Le plus susceptible*). Couper
  les vibrations est donc impossible.
- La mémoire des paquets ne se vide pas (« on a déjà tout vu »).
- Les animations réduites ne peuvent pas être forcées depuis l'app.

**I2 — Animations : correctes, mais génériques.** Relecture au format d'Emil Kowalski :

| Avant | Après | Pourquoi |
|---|---|---|
| `Theme.spring` (0,42 s / amorti 0,82) sur **tous** les changements d'écran | ressort critique (amorti ≈ 0,9–1) pour l'UI, rebond réservé aux moments physiques (lancer, pop, célébration) | Le rebond sur un écran qui arrive fait « jouet » ; il se gagne quand un geste a porté de l'élan |
| « Retour » rejoue la transition `.forward` (entrée par la droite) | transition **orientée** : avancer = entrée par la droite, reculer = entrée par la gauche | Cohérence spatiale : ce qui part d'un côté revient de ce côté |
| Retournement de la carte Undercover : les deux faces se fondent en opacité pendant toute la rotation | bascule nette de face **à 90°** (effet `Animatable`) | Au milieu du retournement, on voit aujourd'hui le dos et le mot superposés. C'est le moment signature du jeu |
| Bandeau de victoire qui part de `scale 0.5` | `scale 0.85 + opacité`, ressort | Rien n'apparaît à partir de presque rien |
| Tuiles de l'accueil posées d'un bloc | entrée en cascade (40 ms d'écart, 8 pt, ease-out) | L'accueil est vu une fois par soirée : il a droit à une entrée |
| Moitiés de *Tu préfères* : la moitié entière descend de 3 pt à l'appui | contenu qui se tasse (0,97) + voile, sans bouger le cadre ; « +1 » qui jaillit au comptage | Le cadre touche le séparateur : le déplacer casse le trait du milieu |
| Confettis uniquement dans *Le plus susceptible* | composant partagé, joué à **chaque** fin de partie gagnée | Une victoire est un moment rare : c'est là que la fête se mérite |
| Pas de `CADisableMinimumFrameDurationOnPhone` | clé ajoutée dans Info.plist | Les animations faites main (confettis `Canvas`, `TimelineView`) plafonnent à 60 Hz sur les iPhone ProMotion |
| Vibrations non coupables | `Haptics` respecte le réglage, partout | Une vibration qu'on ne peut pas couper finit par faire désinstaller l'app |

**I3 — Pas de boucle de croissance.** L'app n'a reçu aucune note en deux mois de vente, et il
n'existe ni demande de note au bon moment, ni bouton « Partager Mytho ». Pour une app de soirée,
c'est le bouche-à-oreille qui la fait vivre.

**I4 — Undercover vit hors des prénoms de la soirée.** Il faut saisir la table deux fois quand
on passe d'Undercover aux autres jeux.

**I5 — Le parcours de captures automatisé ne couvre qu'Undercover.** Les trois autres jeux
n'ont jamais été vus en capture, ce qui contredit la « définition de fini » de la spec.

### 🟡 Finitions

- **F1.** La bannière Extrême de *Tu préfères* affiche « 25 dilemmes » en dur, alors qu'il y en a 24.
- **F2.** Les tailles de police sont fixes, donc il n'y a pas de Dynamic Type (spec §2.8).
- **F3.** `PartyRoute` est déclaré mais jamais branché (code mort).
- **F4.** Le réglage `soundEnabled` existe alors qu'aucun son n'est joué : il ne faut pas l'exposer.

---

## 3. Recommandations

### R1 — Contenu 2.0 : drôle, jeune, trash, et en volume

Le contenu, c'est le produit. La charte qui suit part du goût d'Arthur, tel qu'il se lit dans ses
écrémages du 17 au 20 août, et ajoute ce qu'il demande désormais : l'esprit Limite Limite /
Blanc Manger Coco, et la langue des 18-25 ans.

**Ressorts qui marchent** (ceux de ses cartes gardées) :

1. **Le miroir** : les deux moitiés inversent les mêmes éléments (*Ton visage sur tes fesses / Tes fesses sur ton visage*).
2. **Le chiffre** : même coût, répartition différente (*Dix fois par jour, trente secondes / une fois par semaine, trois heures*).
3. **Le corps réel** : haleine, pets, odeurs, dents, poils, pipi, caca, vomi, transpiration.
4. **Le sexe réel** (18+) : fréquence, durée, ratages, bruits, simulation, les ex.
5. **Le tabou dit à voix haute** : le nombre de partenaires annoncé aux parents.
6. **Toi ou l'autre** : la même honte, subie ou infligée.
7. **L'absurde précis** : une image improbable, mais qui touche le corps, le sexe ou le regard des
   autres (*Que chaque pet te fasse jouir*). C'est l'absurde de Blanc Manger Coco, jamais du hasard.
8. **La langue des jeunes**, dosée pour rester lisible : crush, date, ghoster, vu, story, vocal,
   red flag, l'ick, le seum, en PLS, pécho, plan cul (18+), daron / daronne.

**Ce qu'Arthur a jeté**, donc à ne plus écrire :

- le corps imaginaire sans charge sociale (coude, nombril, orteil) ;
- la substitution alimentaire (*morve en fromage*) ;
- le numérique pur dans *Tu préfères* (historique, notes des ex) ;
- le tiers familial pris à témoin (mamie, maman) ;
- le « pire moment social » générique ;
- le dégoût posé sans torsion ;
- le dilemme où toute la table choisit pareil.

Dans *Je n'ai jamais* et *Le plus susceptible*, il veut l'aveu brut, sans pirouette en seconde moitié.

**Lignes rouges** (App Store 1.1.1 et 1.1.4, spec §8) : aucune caractéristique protégée (origine,
religion, orientation, handicap, poids), aucune personne réelle, aucune marque, rien de sexuel
impliquant des mineurs, rien de non consenti, pas d'inceste, pas de drogue dure, rien de
graphique. Les paquets de base restent sans sexe, sans alcool et sans drogue : tout le cru vit
derrière la porte d'âge.

**Volumes cibles 2.0** :

| Jeu | Base | 18+ | Total |
|---|---:|---:|---:|
| Tu préfères ? | 120 | 80 | **200** |
| Je n'ai jamais | 100 | 80 | **180** |
| Le plus susceptible | 100 | 80 | **180** |
| Undercover (paires) | 130 | 30 (« Hot », derrière la porte d'âge) | **160** |
| Action ou vérité | 2 × 80 | 2 × 40 + 30 gages | **270** |
| Longueur d'onde (axes) | 150 | — | **150** |

Les identifiants ne sont jamais réattribués. Le prochain numéro libre est `wyr_310`, `nhie_251`
et `mst_301`. Les mémoires de pioche passent en `.v4` : la soirée repart d'un paquet neuf.

**Une page de tri pour Arthur.** Toutes les nouvelles cartes seront publiées sur une page où
garder ou jeter se fait en un toucher, depuis le téléphone. Ses choix y restent enregistrés et
s'appliquent au tour suivant, comme pour l'écrémage d'août.

### R2 — Un vrai système de mouvement

On suit les principes d'Emil Kowalski et des WWDC « Fluid Interfaces » :

- des **jetons de mouvement** dans `Theme` : l'UI critique, le pop, le retournement, la sortie
  plus rapide que l'entrée ;
- des **transitions orientées** (avancer / reculer) ;
- un **retournement de carte exact** ;
- une **cascade** à l'accueil et sur les classements ;
- des **pops** sur les compteurs ;
- des **confettis** partagés, à 120 Hz ;
- une **retenue** : rien n'anime ce qu'on touche cent fois par soirée, et les animations réduites
  deviennent des fondus.

### R3 — Réglages et croissance

Un écran **Réglages**, depuis l'accueil :

- le contenu 18+, verrouillable à nouveau ;
- les vibrations ;
- les animations ;
- l'oubli des cartes déjà vues ;
- « Noter Mytho » et « Partager Mytho » ;
- la confidentialité et le support ;
- la version.

S'y ajoutent la **demande de note** après la 3ᵉ partie terminée (une fois par version), et les
prénoms de la soirée enfin partagés avec Undercover.

### R4 — Deux nouveaux jeux, et plus aucune tuile « Bientôt »

*Action ou vérité* (spec §7) et *Longueur d'onde* (spec §6) sont deux formats que les groupes
connaissent et réclament. Avec eux, l'app passe à **6 jeux**.

### R5 — Fiche et captures 2.0

- Le sous-titre devient « 6 jeux de soirée sans filtre ».
- La description affiche des volumes **exacts**.
- La première capture montre le catalogue.
- Le champ « Nouveautés » est rédigé pour la 2.0.

Version marketing : **2.0.0**. Six jeux, un contenu réécrit et un nouveau moteur de mouvement
justifient un numéro majeur.

### R6 — Modèle économique (décision d'Arthur, pas pour la 2.0)

La 2.0 reste **gratuite et complète**. On ne paywalle pas d'un coup un contenu qui était
gratuit : ce serait des avis 1 étoile assurés. Ensuite, en cohérence avec sa position
(« jamais d'abonnement ») :

- un **achat unique**, « Mytho+ », vers 4,99 € ;
- de nouveaux paquets thématiques à chaque saison ;
- le jeu de base reste toujours gratuit.

Un 7ᵉ format est un bon candidat : un **jeu de phrases à trous** façon Blanc Manger Coco, à mains
privées et en passant le téléphone. Il demande environ 400 cartes réponse : c'est un chantier 2.1.

---

## 4. Plan pas à pas

Méthode du repo : **un lot = une branche = une PR**. La CI est le seul compilateur, puisqu'il
n'y a pas de Mac. Chaque merge sur `main` part sur TestFlight. Les captures d'écran sont la seule
preuve visuelle.

### Lot 0 — Préparation ✅

1. Audit du code, de la fiche en ligne (API App Store Connect) et des captures de référence (run 38553135957).
2. Skills installés et relus : Emil Kowalski (15 skills), Impeccable, Taste. Playwright est
   écarté, car il teste du web et pas une app iOS native.
3. Ce document.

### Lot 1 — Contenu 2.0 (priorité absolue)

1. **Tu préfères ?** : 120 dilemmes de base et 80 Extrême, à partir de `wyr_310`. Le deck passe
   en `.v4`, et les tests de volume, de format et de lexique sont mis à jour.
2. **Je n'ai jamais** : 100 cartes « Entre potes » et 80 « Épicé », à partir de `nhie_251`. Deck `.v4`.
3. **Le plus susceptible** : 100 « Entre potes » et 80 « Soirée », à partir de `mst_301`. Le jeu
   redevient jouable sans 18+.
4. **Undercover** : les paires « dictionnaire » sont remplacées par des paires de soirée, de
   bouffe, de love, de vie de jeune et de style, plus une catégorie **Hot 18+** derrière la
   porte d'âge.
5. `scripts/check-content.py` est réaligné, avec les gardes anti-résurrection : aucune carte
   déjà jetée par Arthur ne revient.
6. Bannières 18+ : les compteurs sont calculés, plus jamais écrits en dur.
7. Page de tri publiée pour Arthur.

**Fini quand** : la CI est verte, les volumes cibles sont atteints, le lexique est propre, et la
page de tri est en ligne.

### Lot 2 — Mouvement et micro-interactions

1. Jetons `Theme.Motion` (ui, pop, flip, sortie) et retouche de `spring` / `snap`.
2. Transitions orientées avancer / reculer dans Undercover et les jeux de soirée.
3. Retournement de carte exact (`FlipModifier : Animatable`).
4. Cascade sur l'accueil, les classements et les grilles de prénoms.
5. Moitiés de *Tu préfères* : appui sans déplacement du cadre, et pop « +1 ».
6. Confettis partagés (`ConfettiView` sorti de *Le plus susceptible*) à chaque fin de partie gagnée.
7. 120 Hz (Info.plist) et `Haptics` branché sur le réglage.

**Fini quand** : la CI est verte, les captures sont relues, le mode réduit donne des fondus et
aucune boucle ne tourne.

### Lot 3 — Réglages et croissance

1. `SettingsView`, accessible depuis l'accueil.
2. Demande de note après la 3ᵉ partie terminée, une fois par version.
3. Liens « Noter » et « Partager ».
4. Undercover reprend les prénoms de la soirée.

**Fini quand** : on peut refermer le 18+, et c'est testé unitairement.

### Lot 4 — Action ou vérité

Moteur et tests (bouteille à angle précalculé, répartition uniforme sur 500 lancers), écran,
contenu modéré (aucun défi dangereux, aucune personne extérieure, pas d'alcool) et bouton
*Passer* avec gage.

### Lot 5 — Longueur d'onde

Moteur et tests (cible jamais à moins de 8 % d'un bord, barème 4 / 3 / 2 / 0), cadran, volet et
aiguille crantée (haptique tous les 2 %), et 150 axes.

### Lot 6 — Captures et fiche 2.0

1. Le parcours de captures couvre les 6 jeux.
2. Les captures App Store sont régénérées.
3. `MARKETING_VERSION` passe à 2.0.0.
4. La version 2.0 est préparée sur App Store Connect (textes, captures, build), prête à envoyer.

**Le dernier geste revient à Arthur** : « Soumettre pour vérification ». C'est une mise en ligne
publique avec du contenu 18+, donc elle passe par son OK.

---

## 5. Ce qui reste à Arthur

1. Trier les nouvelles cartes sur la page de tri, quand il veut. Ses choix s'appliqueront au
   tour suivant.
2. Tester la build TestFlight 2.0.
3. Appuyer sur **Soumettre** dans App Store Connect.
