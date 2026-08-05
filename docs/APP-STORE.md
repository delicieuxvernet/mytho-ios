# Fiche App Store — brouillon

> À copier-coller au moment de créer la fiche sur App Store Connect.
> Le nom « Mytho » est un nom de travail : si on le change, tout ce fichier
> se met à jour en même temps que project.yml / Info.plist / Fastfile.

## Création de la fiche (les 3 gestes)

| Champ | Valeur |
|---|---|
| Plateforme | iOS |
| Nom | Mytho — le jeu des infiltrés |
| Langue principale | Français (France) |
| Bundle ID | `fr.mytho.app` |
| SKU | `mytho-ios-001` |
| Accès | Accès complet |

## Métadonnées

**Sous-titre** (30 car. max)
`Qui n'a pas le même mot ?`

**Promotion (170 car. max)**
`Un mot secret pour tous, sauf pour les infiltrés. Décrivez, débattez, éliminez — sur un seul téléphone, de 3 à 20 joueurs.`

**Description**

```
Tout le monde reçoit le même mot secret. Tout le monde… sauf les infiltrés.

Mytho est un jeu de société de déduction qui se joue sur un seul iPhone,
autour d'une table, de 3 à 20 joueurs. Chacun pioche une carte, découvre
son mot en secret, puis le décrit en une phrase. Ni trop précis — les
infiltrés vous copieraient — ni trop vague — on vous accuserait.

LES RÔLES
• Les Civils partagent le même mot et cherchent les intrus.
• L'Undercover a un mot proche, mais différent. Il se fond dans la masse.
• Mr. White n'a aucun mot. Il improvise… et peut voler la victoire en
  devinant le mot des civils.

LES POUVOIRS
L'Arbitre, Amoureux, Vengeuse, Duellistes, Le Mime, Fantôme :
six pouvoirs et variantes pour pimenter vos manches.

• 375 paires de mots en 8 thèmes, en français
• Points cumulés de manche en manche, classement intégré
• Aucun compte, aucune pub, aucune connexion requise : tout est sur le
  téléphone
• L'écran ne se verrouille jamais pendant une partie

Un mot pour tous. Sauf pour eux.
```

**Mots-clés (100 car. max)**
`jeu de société,soirée,amis,déduction,imposteur,mot,bluff,groupe,famille,fête`

---

## Version 1.1 — prête à publier dès que la 1.0 est acceptée

La 1.0 en review ne contient qu'Undercover. La 1.1 ajoute trois jeux : il faut
donc reprendre le sous-titre, la promo et la description, qui ne parlent que
de mots secrets.

**Sous-titre** (30 car. max)
`4 jeux pour vos soirées`

**Promotion** (170 car. max)
`Quatre jeux de soirée sur un seul téléphone : infiltrés, dilemmes impossibles, votes à main levée et confessions. De 3 à 20 joueurs, sans compte ni connexion.`

**Description**

```
Quatre jeux de soirée, un seul téléphone qu'on se passe autour de la table.
De 3 à 20 joueurs, sans compte, sans publicité, sans connexion.

UNDERCOVER
Tout le monde reçoit le même mot secret. Tout le monde… sauf les infiltrés.
Décrivez votre mot en une phrase, débattez, éliminez. Six pouvoirs
optionnels — l'Arbitre, les Amoureux, la Vengeuse, les Duellistes, le Mime,
le Fantôme — pour pimenter vos manches. 375 paires de mots en français.

LE PLUS SUSCEPTIBLE DE…
« Qui est le plus susceptible de rire au mauvais moment ? » On compte
jusqu'à trois, tout le monde pointe. 260 cartes, en pointage rapide ou en
vote secret.

TU PRÉFÈRES ?
Deux options, aucune bonne réponse. 200 dilemmes, trois façons de jouer :
débat à main levée, vote secret, ou survie — les minoritaires sautent.

JE N'AI JAMAIS
Chacun ses vies. À chaque aveu, on en perd une. Le dernier debout gagne.
190 cartes, tout public.

• Les prénoms se saisissent une fois et servent aux quatre jeux
• Points cumulés de manche en manche, classement intégré
• Une carte ne revient jamais deux fois dans la même soirée
• L'écran ne se verrouille jamais pendant une partie

Un mot pour tous. Sauf pour eux.
```

**Mots-clés** (100 car. max)
`jeu de société,soirée,amis,déduction,imposteur,bluff,groupe,famille,fête,dilemme`

**Nouveautés de cette version** (champ « What's New »)

```
Trois jeux de plus, compris dans l'app :
• Le plus susceptible de… — 260 cartes, on pointe tous en même temps
• Tu préfères ? — 200 dilemmes, dont un mode survie
• Je n'ai jamais — 190 cartes, le dernier debout gagne

Les prénoms de la soirée se saisissent une fois et servent aux quatre jeux.
```

**Captures** : régénérer via `screenshots.yml` après la mise à jour du parcours
— la première doit montrer le catalogue des quatre jeux, pas l'écran d'Undercover.

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
