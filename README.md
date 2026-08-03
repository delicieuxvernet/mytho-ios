# Mytho

Jeu de société de déduction pour 3 à 20 joueurs, sur un seul iPhone qu'on se
passe autour de la table. Tout le monde reçoit le même mot — sauf les infiltrés.

- **Civils** : reçoivent le mot majoritaire. Ils gagnent en démasquant tout le monde.
- **Undercover** : reçoit un mot proche mais différent. Il gagne en survivant.
- **Mr. White** : ne reçoit aucun mot. Il improvise, et s'il est démasqué il peut
  encore voler la manche en devinant le mot des civils.

Une manche enchaîne : distribution des cartes face cachée → description →
discussion → vote → élimination, jusqu'à ce qu'un camp l'emporte. Les points se
cumulent d'une manche à l'autre (civil +2, undercover survivant +10, Mr. White +6).

## Architecture

```
Mytho/
├── App/            MythoApp.swift, RootView (aiguillage par phase de jeu)
├── Core/           GameModels, GameEngine (logique pure), GameSession, WordBank
├── Design/         Theme (couleurs, typo, animations), Components
├── Views/          SetupView, DealView, PlayViews, ResultView
└── Resources/      Info.plist, Assets.xcassets
MythoTests/         Moteur, composition, banque de mots
```

Le moteur (`GameEngine`) est une **valeur pure** : aucun accès réseau, aucun
état global, un générateur aléatoire injecté. C'est ce qui rend chaque règle
testable et rejouable à l'identique. `GameSession` est le seul objet observable ;
`RootView` déduit l'écran à afficher de la phase du moteur, sans état de
navigation à maintenir en parallèle.

Aucune dépendance externe : le jeu tourne hors ligne et les builds restent rapides.

## Développement

Le projet Xcode n'est pas versionné — `project.yml` est la source de vérité.

```bash
xcodegen generate && open Mytho.xcodeproj
```

Régénérer l'icône (Windows, sans Xcode) :

```bash
powershell -ExecutionPolicy Bypass -File scripts/make-appicon.ps1
```

## Déploiement

Tout passe par GitHub Actions — aucun build local n'est nécessaire.

- Une **PR** déclenche la suite de tests sur simulateur.
- Un **push sur `main`** rejoue les tests puis, s'ils sont verts, archive, signe
  et envoie sur TestFlight.

Le premier run demande une mise en place unique : voir les commentaires en bas de
`.github/workflows/build-testflight.yml` pour la liste des secrets, et
`.github/workflows/bootstrap.yml` pour la création du certificat et du profil.
