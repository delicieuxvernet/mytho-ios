# Fiche App Store — brouillon

> À copier-coller au moment de créer la fiche sur App Store Connect.
> Le nom « Taupe » est un nom de travail : si on le change, tout ce fichier
> se met à jour en même temps que project.yml / Info.plist / Fastfile.

## Création de la fiche (les 3 gestes)

| Champ | Valeur |
|---|---|
| Plateforme | iOS |
| Nom | Taupe — le jeu des infiltrés |
| Langue principale | Français (France) |
| Bundle ID | `fr.taupe.app` |
| SKU | `taupe-ios-001` |
| Accès | Accès complet |

## Métadonnées

**Sous-titre** (30 car. max)
`Qui n'a pas le même mot ?`

**Promotion (170 car. max)**
`Un mot secret pour tous, sauf pour les infiltrés. Décrivez, débattez, éliminez — sur un seul téléphone, de 3 à 20 joueurs.`

**Description**

```
Tout le monde reçoit le même mot secret. Tout le monde… sauf les infiltrés.

Taupe est un jeu de société de déduction qui se joue sur un seul iPhone,
autour d'une table, de 3 à 20 joueurs. Chacun pioche une carte, découvre
son mot en secret, puis le décrit en une phrase. Ni trop précis — les
infiltrés vous copieraient — ni trop vague — on vous accuserait.

LES RÔLES
• Les Civils partagent le même mot et cherchent les intrus.
• L'Undercover a un mot proche, mais différent. Il se fond dans la masse.
• Mr. White n'a aucun mot. Il improvise… et peut voler la victoire en
  devinant le mot des civils.

LES POUVOIRS
Déesse de la justice, Amoureux, Vengeuse, Duelistes, Mr. Meme, Fantôme :
six pouvoirs et variantes pour pimenter vos manches.

• 375 paires de mots en 8 thèmes, en français
• Points cumulés de manche en manche, classement intégré
• Aucun compte, aucune pub, aucune connexion requise : tout est sur le
  téléphone
• L'écran ne se verrouille jamais pendant une partie

Un mot pour tous. Sauf pour eux.
```

**Mots-clés (100 car. max)**
`jeu de société,soirée,amis,déduction,imposteur,mot,bluff,groupe,famille,fête,undercover`

**Catégorie** : Jeux > Jeux de mots (secondaire : Jeux > Party)

**Classification** : 4+ (aucun contenu sensible — la banque de mots est tout public)

## Confidentialité (App Privacy)

**« Aucune donnée collectée »** — c'est vrai au sens strict : pas de compte,
pas de réseau, pas d'analytics, pas de SDK tiers. Réglages et scores restent
dans UserDefaults sur l'appareil. Section la plus rapide du formulaire.

URL de politique de confidentialité : requise même sans collecte. Réutiliser
le pattern Kiwio (page statique sur le site web) ou une page GitHub Pages du
repo — à décider au moment de la soumission publique, pas nécessaire pour
TestFlight interne.

## Captures d'écran

Le workflow `screenshots.yml` produit des PNG 1206×2622 (iPhone 6,9" : format
accepté tel quel). Parcours couvert : accueil, règles, pioche, mot révélé,
ordre de parole, vote, élimination, fin de manche. Reprendre les meilleures
après chaque évolution visuelle.

## Modèle économique (décision produit, plus tard)

Position d'Arthur : les apps équivalentes sont sur abonnement mensuel, ce qui
est le problème à ne pas reproduire. Pistes compatibles App Store, du plus
simple au plus riche :
1. **Gratuit complet** pendant TestFlight (aucune friction pour les amis).
2. **Achat unique** (paywall léger : thèmes de mots premium, pas de gate sur
   le jeu de base) pour la sortie publique.
3. Jamais d'abonnement.
