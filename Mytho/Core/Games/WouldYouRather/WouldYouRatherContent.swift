import Foundation

// MARK: - La carte

/// Un dilemme : deux options, aucune bonne réponse (spec §4.4).
///
/// **Critère de tri d'une carte.** Les deux options doivent être aussi mauvaises
/// — ou aussi désirables — l'une que l'autre. Si la réponse est évidente pour
/// tout le monde, la carte est ratée : pas de débat, donc pas de jeu. Test :
/// faire voter cinq personnes ; si les cinq choisissent pareil, la carte dégage.
struct Dilemma: Identifiable, Hashable, Sendable {
    /// Stable et jamais réattribué : c'est lui que la mémoire du paquet retient
    /// pour ne pas ressortir la carte avant 70 % du tour (spec §2.4). Réordonner
    /// le contenu ne doit donc jamais décaler les identifiants.
    let id: String
    let a: String
    let b: String

    func text(_ side: DilemmaSide) -> String { side == .a ? a : b }
}

// MARK: - Le paquet

/// Les 185 dilemmes de « Tu préfères ? » (112 de base + 73 Extrême) : vérifié
/// à la compilation, relisible en diff de PR (spec §1.2).
///
/// Les identifiants ne sont **jamais réattribués** : une carte retirée emporte
/// son numéro dans la tombe, une carte qui arrive prend le numéro suivant. D'où
/// les trous dans la suite. C'est ce qui permet à la mémoire du paquet de rester
/// juste pour toutes les cartes conservées — renuméroter reviendrait à faire
/// ressortir aussitôt des cartes vues hier soir.
///
/// **Règles d'écriture appliquées** (spec §8) : une carte = une idée, tutoiement
/// systématique, aucune référence datée, aucune personne réelle, rien qui vise
/// une caractéristique protégée. L'app est classée 17+ : le paquet de base
/// assume le trash corporel mais reste jouable sans la confirmation d'âge —
/// ni sexe, ni alcool, ni drogue — et tout le cru vit dans l'Extrême.
///
/// Deux paquets, comme les deux autres jeux de cartes : le verrou d'âge se
/// vérifie dans `dilemmas(adultUnlocked:extremeEnabled:)`, jamais dans la vue.
enum WouldYouRatherBank {

    /// Le paquet de base, dans l'ordre des identifiants.
    static let all: [Dilemma] = base

    // MARK: Paquet de base

    private static let base: [Dilemma] = [
        Dilemma(id: "wyr_004", a: "Plus jamais de papier toilette", b: "Plus jamais te brosser les dents"),
        Dilemma(id: "wyr_007", a: "Chier de la confiture", b: "Pisser de la mayonnaise"),
        Dilemma(id: "wyr_009", a: "Ton prochain pet est un vrai caca", b: "Ton prochain rot est du vomi"),
        Dilemma(id: "wyr_011", a: "Péter par la bouche", b: "Roter par les fesses"),
        Dilemma(id: "wyr_012", a: "Des ongles à la place des dents", b: "Des dents à la place des ongles"),
        Dilemma(id: "wyr_013", a: "Ton visage sur tes fesses", b: "Tes fesses sur ton visage"),

        // Vague du 20 août 2026. Douze cartes sont parties : du dégoût posé
        // côte à côte sans torsion (piscine de caca, haleine de vomi), et des
        // dilemmes où toute la table choisissait pareil — un choix évident
        // n'est pas un choix. Ce qui arrive vise le miroir, la figure du pack
        // Extrême validée par Arthur : les deux moitiés inversent les mêmes
        // éléments et coûtent exactement le même prix.
        Dilemma(id: "wyr_065", a: "Chier dix fois par jour, trente secondes", b: "Chier une fois par semaine, mais trois heures"),
        // Vague du 20 août 2026, ecrite au registre des cartes qu'Arthur a
        // gardees : permutation corporelle, substitution de matiere, chiffre.
        // Le registre « pire moment social » en est absent, il l'a balaye.
        Dilemma(id: "wyr_264", a: "Haleine de poubelle, dents parfaites", b: "Dents pourries, haleine de menthe"),
        Dilemma(id: "wyr_265", a: "Des pets muets qui sentent les enfers", b: "Des pets bruyants qui ne sentent rien"),
        Dilemma(id: "wyr_268", a: "Tes doigts sentent le poisson à vie", b: "Ton haleine sent l'ail à vie"),
        // Vague 2 du 20 août 2026 : le corps REEL, celui que tout le monde a
        // deja subi. Le corps imaginaire (nombril, coude, aisselle) et la
        // substitution alimentaire ont ete jetes en bloc au tri precedent.
        Dilemma(id: "wyr_293", a: "Ne plus jamais fermer la porte des toilettes", b: "Ne plus jamais pouvoir tirer la chasse"),
        Dilemma(id: "wyr_294", a: "Puer sans jamais t'en rendre compte", b: "Le savoir et ne rien pouvoir y faire"),
        Dilemma(id: "wyr_295", a: "N'aller qu'aux toilettes publiques, toute ta vie", b: "N'y aller que chez les autres, jamais chez toi"),
        Dilemma(id: "wyr_296", a: "Que tes pets sortent avec le son de ta voix", b: "Que ta voix sorte avec le bruit d'un pet"),
        Dilemma(id: "wyr_297", a: "Faire pipi au lit une fois par mois", b: "Une petite fuite en public une fois par an"),
        Dilemma(id: "wyr_298", a: "Perdre une dent par an, elle repousse en un mois", b: "Garder toutes tes dents, mais bien jaunes à vie"),
        Dilemma(id: "wyr_299", a: "Un monosourcil bien épais, à vie", b: "Plus aucun sourcil, ni cils, à vie"),

        // Version 2.0 (octobre 2026) : « plus drôle, plus jeune, plus
        // stimulant ». Le corps réel reste le socle, et trois veines s'y
        // ajoutent : la vie amoureuse des 18-25 ans (crush, date, ex, vu,
        // vocal), la table elle-même (« ton voisin de gauche ») et l'absurde
        // précis à la Blanc Manger Coco. Aucune option ne ressuscite une
        // carte retirée : chacune a été comparée à tout l'historique git.
        Dilemma(id: "wyr_310", a: "Une goutte de pipi à chaque éternuement", b: "Un petit pet à chaque fou rire"),
        Dilemma(id: "wyr_311", a: "Ronfler comme un tracteur, toutes les nuits", b: "Parler de ton crush dans ton sommeil"),
        Dilemma(id: "wyr_312", a: "Une crotte de nez visible sur chaque photo", b: "De la salade entre les dents à chaque date"),
        Dilemma(id: "wyr_313", a: "Un bouton de fièvre avant chaque date", b: "Un orgelet avant chaque soirée"),
        Dilemma(id: "wyr_314", a: "Des aisselles qui coulent comme des robinets", b: "Des mains si moites que personne ne te les serre"),
        Dilemma(id: "wyr_315", a: "Une diarrhée surprise à chaque premier date", b: "Deux semaines sans caca à chaque vacances"),
        Dilemma(id: "wyr_316", a: "Toujours du PQ collé sous ta chaussure", b: "Toujours ta braguette ouverte, sans le savoir"),
        Dilemma(id: "wyr_317", a: "Sentir le chien mouillé dès qu'il pleut", b: "Sentir l'oignon dès que tu stresses"),
        Dilemma(id: "wyr_318", a: "Être allergique au papier toilette", b: "Être allergique au savon"),
        Dilemma(id: "wyr_319", a: "Que toute la soirée entende quand tu fais caca", b: "Que toute la soirée sente quand tu fais caca"),
        Dilemma(id: "wyr_320", a: "Ne plus jamais laver tes cheveux", b: "Ne plus jamais couper tes ongles"),
        Dilemma(id: "wyr_321", a: "Des auréoles sous les bras sur chaque t-shirt", b: "Une petite tache de pipi sur chaque pantalon"),
        Dilemma(id: "wyr_322", a: "Embrasser ton crush avec une haleine de kebab", b: "Que ton crush t'embrasse avec une haleine de kebab"),
        Dilemma(id: "wyr_323", a: "Te gratter les fesses sans t'en rendre compte", b: "Renifler tes doigts sans t'en rendre compte"),
        Dilemma(id: "wyr_324", a: "Être surpris en train de renifler ton slip", b: "Surprendre ton crush en train de renifler le sien"),
        Dilemma(id: "wyr_325", a: "Un pet bruyant à chaque fois que tu t'assois", b: "Un rot sonore à chaque fois que tu te lèves"),
        Dilemma(id: "wyr_326", a: "Porter le même slip pendant une semaine", b: "Porter les mêmes chaussettes pendant un mois"),
        Dilemma(id: "wyr_327", a: "Annoncer « j'ai fini » en sortant des toilettes", b: "Être applaudi à chaque sortie des toilettes"),
        Dilemma(id: "wyr_328", a: "Que ton ventre gargouille le prénom de ton crush", b: "Éternuer le prénom de ton ex"),
        Dilemma(id: "wyr_329", a: "Un bouton qui pousse à chaque mensonge", b: "Une ride qui apparaît à chaque vérité"),
        Dilemma(id: "wyr_330", a: "Faire caca en forêt, sans papier", b: "Faire caca dans un avion, en pleines turbulences"),
        Dilemma(id: "wyr_331", a: "Faire pipi dans une bouteille devant toute ta bande", b: "Te retenir quatre heures de route, sans pause"),
        Dilemma(id: "wyr_332", a: "Des pieds qui puent uniquement pendant tes dates", b: "Une haleine qui pue uniquement en entretien"),
        Dilemma(id: "wyr_333", a: "Boire un verre de ta propre sueur", b: "Lécher le front d'un inconnu en sueur"),
        Dilemma(id: "wyr_334", a: "Que la table note chacun de tes pets sur dix", b: "Que la table note chacun de tes bisous sur dix"),
        Dilemma(id: "wyr_335", a: "Péter à chaque fois que tu dis « je t'aime »", b: "Dire « je t'aime » à chaque fois que tu pètes"),
        Dilemma(id: "wyr_336", a: "Te faire ghoster par ton crush, sans explication", b: "Te faire friendzoner par ton crush, avec un câlin"),
        Dilemma(id: "wyr_337", a: "Te faire larguer par un vocal de douze minutes", b: "Recevoir « ok » en réponse à ton « je t'aime »"),
        Dilemma(id: "wyr_338", a: "Un date parfait qui mâche la bouche ouverte", b: "Un date nul à pleurer qui embrasse divinement"),
        Dilemma(id: "wyr_339", a: "Que ton ex sorte avec ton meilleur pote", b: "Que ton meilleur pote sorte avec ta daronne"),
        Dilemma(id: "wyr_340", a: "Avouer tes sentiments à ton crush devant tout le monde", b: "Ne jamais rien dire, et le voir finir avec ton pote"),
        Dilemma(id: "wyr_341", a: "Tomber amoureux de ton voisin de droite", b: "Que ton voisin de gauche tombe amoureux de toi"),
        Dilemma(id: "wyr_342", a: "Le prénom de ton ex tatoué sur ton front", b: "Ton prénom tatoué sur le front de ton ex"),
        Dilemma(id: "wyr_343", a: "Que ton ex soit DJ à chaque soirée où tu vas", b: "Que tes parents soient videurs à chaque soirée"),
        Dilemma(id: "wyr_344", a: "Raconter ta vie amoureuse à tes parents chaque dimanche", b: "Que tes parents te racontent la leur chaque dimanche"),
        Dilemma(id: "wyr_345", a: "Que ton crush ait l'ick de ton rire", b: "Que ton crush ait l'ick de ta démarche"),
        Dilemma(id: "wyr_346", a: "Un crush qui t'envoie des vocaux de dix minutes", b: "Un crush qui répond avec trois jours de retard"),
        Dilemma(id: "wyr_347", a: "Un crush qui a exactement le rire de ton père", b: "Un crush qui a exactement la voix de ta mère"),
        Dilemma(id: "wyr_348", a: "Que ton date t'appelle par le mauvais prénom", b: "Appeler ton date par le prénom de ton ex"),
        Dilemma(id: "wyr_349", a: "Que ton ex te remercie dans son discours de mariage", b: "Que ton ex te demande d'être son témoin"),
        Dilemma(id: "wyr_350", a: "Un date avec trois cents peluches sur son lit", b: "Un date avec la photo de son ex au-dessus du lit"),
        Dilemma(id: "wyr_351", a: "Rouler une pelle à ton ex devant ton crush", b: "Rouler une pelle à ton crush devant ton ex"),
        Dilemma(id: "wyr_352", a: "Un premier bisou avec ton appareil dentaire coincé", b: "Un premier bisou avec le nez qui coule"),
        Dilemma(id: "wyr_353", a: "Que ta daronne t'appelle « mon bébé » devant ton crush", b: "Que ton daron drague ton crush devant toi"),
        Dilemma(id: "wyr_354", a: "Liker par erreur une photo de ton ex vieille de cinq ans", b: "Appeler ton crush par erreur à trois heures du matin"),
        Dilemma(id: "wyr_355", a: "Draguer ton ex en soirée sans le reconnaître", b: "Que ton ex te drague sans te reconnaître"),
        Dilemma(id: "wyr_356", a: "Que tous tes dates finissent par « on reste potes »", b: "Que tous tes potes finissent par devenir tes ex"),
        Dilemma(id: "wyr_357", a: "Être le crush secret de tout le monde ici", b: "Que tout le monde ici soit ton crush secret"),
        Dilemma(id: "wyr_358", a: "Un vu à chacun de tes messages à ton crush", b: "Un « mdr » en réponse à chacun de tes messages"),
        Dilemma(id: "wyr_359", a: "Que ton ex devienne une star qui parle de toi en interview", b: "Que ton ex devienne ton beau-frère"),
        Dilemma(id: "wyr_360", a: "T'endormir le premier à chaque soirée, photos à l'appui", b: "Être toujours le dernier à partir, à sept heures du mat"),
        Dilemma(id: "wyr_361", a: "Le hoquet à chaque mensonge", b: "Un éternuement à chaque tentative de drague"),
        Dilemma(id: "wyr_362", a: "Trois heures de karaoké devant tous tes profs", b: "Trois heures d'exposé devant tous tes ex"),
        Dilemma(id: "wyr_363", a: "Devenir célèbre grâce à une vidéo de toi aux toilettes", b: "Rester un parfait inconnu toute ta vie"),
        Dilemma(id: "wyr_364", a: "Un million d'abonnés qui te détestent", b: "Dix abonnés qui t'adorent vraiment"),
        Dilemma(id: "wyr_365", a: "Ton téléphone bloqué à 1 % toute ta vie", b: "Une connexion qui rame toute ta vie"),
        Dilemma(id: "wyr_366", a: "Envoyer la capture à la personne dont tu te moques", b: "Recevoir la capture où on se moque de toi"),
        Dilemma(id: "wyr_367", a: "Un commentateur de foot qui décrit tout ce que tu fais", b: "Une musique de film d'horreur partout où tu vas"),
        Dilemma(id: "wyr_368", a: "Un rire enregistré après chacune de tes blagues", b: "Des bruits de grillons après chacune de tes blagues"),
        Dilemma(id: "wyr_369", a: "Que ta daronne devienne influenceuse", b: "Que ton daron se lance dans le rap"),
        Dilemma(id: "wyr_370", a: "Que ta daronne commente chacune de tes photos", b: "Que ton ex like chacune de tes photos, à trois heures"),
        Dilemma(id: "wyr_371", a: "Vivre en coloc avec ton ex et son nouveau crush", b: "Vivre chez tes parents jusqu'à quarante ans"),
        Dilemma(id: "wyr_372", a: "Que tes parents gèrent tes réseaux pendant un an", b: "Que tes potes gèrent ton compte en banque pendant un an"),
        Dilemma(id: "wyr_373", a: "Garder à vie ta coupe de cheveux de tes douze ans", b: "T'habiller à vie comme tes parents"),
        Dilemma(id: "wyr_374", a: "Ne plus jamais pouvoir mettre un émoji", b: "Ne plus pouvoir parler qu'en émojis"),
        Dilemma(id: "wyr_375", a: "Que ton GPS parle avec la voix de ton ex", b: "Que ton réveil sonne avec la voix de ta daronne"),
        Dilemma(id: "wyr_376", a: "Que ton chien parle et balance tous tes secrets", b: "Que ton chat juge tous tes dates à voix haute"),
        Dilemma(id: "wyr_377", a: "Faire la bise à chacun, même dans une soirée de cinquante", b: "Ne plus faire la bise à personne, jamais"),
        Dilemma(id: "wyr_378", a: "Ne plus pouvoir mentir pendant une semaine", b: "Que tout le monde te mente pendant une semaine"),
        Dilemma(id: "wyr_379", a: "Dire oui à tout ce qu'on te propose pendant une semaine", b: "Dire non à tout ce qu'on te propose pendant un mois"),
        Dilemma(id: "wyr_380", a: "Une semaine sans téléphone", b: "Une semaine sans douche"),
        Dilemma(id: "wyr_381", a: "Un an sans réseaux sociaux", b: "Un an sans sortir le soir"),
        Dilemma(id: "wyr_382", a: "Que ton prénom devienne un synonyme de « gênant »", b: "Que ton nom de famille devienne une insulte"),
        Dilemma(id: "wyr_383", a: "Des kebabs toujours sans sauce, à vie", b: "Des pizzas toujours à l'ananas, à vie"),
        Dilemma(id: "wyr_384", a: "Avoir le rire d'une hyène", b: "Avoir le rire d'un phoque"),
        Dilemma(id: "wyr_385", a: "Que la table choisisse ta prochaine coupe de cheveux", b: "Que la table choisisse ton prochain tatouage"),
        Dilemma(id: "wyr_386", a: "Échanger ton téléphone avec ton voisin de gauche, 24 h", b: "Échanger tes fringues avec ton voisin de droite, une semaine"),
        Dilemma(id: "wyr_387", a: "Un mois de vacances avec ton voisin de droite", b: "Un an de coloc avec ton voisin de gauche"),
        Dilemma(id: "wyr_388", a: "Renifler le pied de ton voisin de gauche", b: "Lécher le coude de ton voisin de droite"),
        Dilemma(id: "wyr_389", a: "Savoir ce que chaque personne ici pense vraiment de toi", b: "Que chacun ici sache ce que tu penses de lui"),
        Dilemma(id: "wyr_390", a: "Être le plus beau de la table, mais le plus chiant", b: "Le plus drôle de la table, mais le plus moche"),
        Dilemma(id: "wyr_391", a: "Six heures coincé dans un ascenseur avec ton ex", b: "Six heures coincé avec ton voisin de gauche, sans toilettes"),
        Dilemma(id: "wyr_392", a: "Une soirée pyjama avec tous tes profs", b: "Des vacances en camping avec tous tes ex"),
        Dilemma(id: "wyr_393", a: "Un surnom choisi par ton voisin de droite, à vie", b: "Une sonnerie choisie par ton voisin de gauche, à vie"),
        Dilemma(id: "wyr_394", a: "Changer de corps avec ton voisin de gauche, une journée", b: "Changer de vie avec ton voisin de droite, une semaine"),
        Dilemma(id: "wyr_395", a: "Un million, mais un pet à chaque phrase", b: "Rester fauché à vie, mais toujours classe"),
        Dilemma(id: "wyr_396", a: "Gagner mille euros à chaque crise de larmes en public", b: "Perdre cent euros à chaque fou rire"),
        Dilemma(id: "wyr_397", a: "Lécher la barre du métro pour dix mille euros", b: "Lécher le sol d'un festival pour cent mille euros"),
        Dilemma(id: "wyr_398", a: "Lire dans les pensées, mais seulement celles de tes parents", b: "Voir l'avenir, mais seulement celui de ton ex"),
        Dilemma(id: "wyr_399", a: "Arrêter le temps, mais uniquement aux toilettes", b: "Remonter le temps, mais seulement de dix secondes"),
        Dilemma(id: "wyr_400", a: "Te téléporter n'importe où, mais sans tes fringues", b: "Voler comme un oiseau, mais en hurlant tout le long"),
        Dilemma(id: "wyr_401", a: "Une queue qui remue dès que ton crush arrive", b: "Des oreilles qui sifflent dès que tu mens"),
        Dilemma(id: "wyr_402", a: "Parler aux animaux, mais ils te trouvent tous relou", b: "Comprendre les bébés, mais ils ne disent que des horreurs"),
        Dilemma(id: "wyr_403", a: "Affronter un canard de la taille d'un cheval", b: "Affronter cent chevaux de la taille d'un canard"),
        Dilemma(id: "wyr_404", a: "Un reflet qui bouge avec trois secondes de retard", b: "Une ombre qui fait ce qu'elle veut")
    ]

    // MARK: Pack Extrême (18+)

    /// 73 dilemmes 18+, hors du paquet de base : dégoût assumé, honte
    /// sociale, intime cru, absurde corporel. Verrouillé derrière la
    /// confirmation d'âge — et jamais graphique (règle 1.1.4).
    static let extreme: [Dilemma] = [
        Dilemma(id: "wyr_026", a: "Boire un litre de règles", b: "Boire un litre de sperme"),
        Dilemma(id: "wyr_030", a: "Un pénis de la taille d'un téton", b: "Des tétons de la taille d'un pénis"),
        Dilemma(id: "wyr_036", a: "Revivre ta pire cuite chaque samedi", b: "Ne plus jamais boire une goutte"),
        Dilemma(id: "wyr_037", a: "Dire ton nombre exact à tes parents", b: "Que tes parents te disent le leur"),
        Dilemma(id: "wyr_038", a: "Que ta peuff ait un goût de paff", b: "Que ta paff ait un goût de peuff"),
        Dilemma(id: "wyr_039", a: "Pleurer bruyamment à chaque orgasme", b: "Rire aux éclats à chaque enterrement"),
        Dilemma(id: "wyr_041", a: "Que ça dure 30 secondes à vie", b: "Que ça dure 3 heures obligatoires"),
        Dilemma(id: "wyr_050", a: "Zéro préliminaires pour toujours", b: "Rien que ça, jamais la suite"),

        // Vague du 20 août 2026. Une seule carte est partie (« fonds de verre /
        // comptoir du bar » : du dégoût posé, sans inversion) — ce pack est la
        // référence de goût validée par Arthur, on y ajoute plus qu'on n'y
        // coupe. Les neuf qui arrivent sont toutes bâties sur le miroir ou sur
        // le chiffre, les deux ressorts de ses cartes préférées.
        Dilemma(id: "wyr_067", a: "Crier le prénom de ton ex pendant l'amour", b: "Que l'autre crie celui de son ex"),
        // Vague du 20 août 2026 : les cinq ressorts, en version 18+.
        Dilemma(id: "wyr_273", a: "Ton nez à la place de ton sexe", b: "Ton sexe à la place de ton nez"),
        Dilemma(id: "wyr_277", a: "Des poils de cul à la place des cheveux", b: "Des cheveux à la place des poils de cul"),
        Dilemma(id: "wyr_278", a: "Que chaque orgasme te fasse péter", b: "Que chaque pet te fasse jouir"),
        Dilemma(id: "wyr_286", a: "Coucher une fois tous les dix ans", b: "Six fois par jour, sans jamais finir"),
        Dilemma(id: "wyr_288", a: "Une gueule de bois de trois jours chaque mois", b: "Une petite gueule de bois tous les matins"),
        // Vague 2 du 20 août 2026 : la vie sexuelle reelle — frequence, duree,
        // ratages, bruits, lendemains. Rien d'invente.
        Dilemma(id: "wyr_300", a: "Une panne à chaque première fois", b: "Finir en dix secondes à chaque première fois"),
        Dilemma(id: "wyr_301", a: "Simuler à chaque fois, toute ta vie", b: "Savoir que l'autre a toujours simulé"),
        Dilemma(id: "wyr_302", a: "Que tout l'immeuble t'entende jouir", b: "Ne plus jamais pouvoir faire le moindre bruit"),
        Dilemma(id: "wyr_303", a: "Te réveiller chaque dimanche sans savoir où", b: "Te souvenir de tout ce que tu fais bourré"),
        Dilemma(id: "wyr_304", a: "Un bruit de pet à chaque coup de reins", b: "Un rot sonore à chaque baiser"),
        Dilemma(id: "wyr_305", a: "Ne plus jamais changer de position", b: "Ne jamais pouvoir refaire la même deux fois"),
        Dilemma(id: "wyr_306", a: "Être celui qui pleure à chaque soirée", b: "Être celui qui gerbe à chaque soirée"),
        Dilemma(id: "wyr_307", a: "Que ce soit toujours trop sec", b: "Que ce soit toujours trop mouillé"),
        Dilemma(id: "wyr_308", a: "Perdre un cheveu à chaque orgasme", b: "Perdre un cheveu à chaque verre d'alcool"),
        Dilemma(id: "wyr_309", a: "Que ton haleine sente toujours le sexe", b: "Que ton sexe sente l'haleine du matin"),

        // Version 2.0 (octobre 2026) : le sexe réel, les soirées qui
        // dérapent, la table prise à partie — avec le miroir et le chiffre
        // comme ressorts, et l'absurde en plus. Jamais graphique (1.1.4).
        Dilemma(id: "wyr_405", a: "Un partenaire canon qui embrasse comme une machine à laver", b: "Un partenaire moche qui fait des miracles avec sa langue"),
        Dilemma(id: "wyr_406", a: "Un plan à trois avec tes deux pires ex", b: "Un plan à trois avec deux sosies de toi"),
        Dilemma(id: "wyr_407", a: "Le faire uniquement dans le noir total", b: "Le faire uniquement en pleine lumière, miroir au plafond"),
        Dilemma(id: "wyr_408", a: "Une voix de GPS qui annonce chaque position", b: "Une musique de victoire à chaque orgasme"),
        Dilemma(id: "wyr_409", a: "Le faire dans une voiture minuscule en plein hiver", b: "Le faire sur une plage brûlante en plein été"),
        Dilemma(id: "wyr_410", a: "Embrasser ton voisin de gauche avec la langue", b: "Lécher l'oreille de ton voisin de droite"),
        Dilemma(id: "wyr_411", a: "Le faire en chaussettes, à vie", b: "Le faire avec ton bonnet, à vie"),
        Dilemma(id: "wyr_412", a: "Être le meilleur coup de la ville, sans jamais jouir", b: "Le pire coup de la ville, mais jouir à chaque fois"),
        Dilemma(id: "wyr_413", a: "Un plan cul génial qui tombe amoureux de toi", b: "Un couple génial où le sexe est à chier"),
        Dilemma(id: "wyr_414", a: "Que tes tétons clignotent quand tu es excité", b: "Que tes oreilles sifflent quand tu es excité"),
        Dilemma(id: "wyr_415", a: "Un partenaire qui crie « olé » à chaque orgasme", b: "Un partenaire qui dit « merci » à la fin"),
        Dilemma(id: "wyr_416", a: "Le faire avec un chat qui te fixe sans cligner", b: "Le faire avec un chien qui aboie à chaque changement"),
        Dilemma(id: "wyr_417", a: "Que tous tes ex deviennent meilleurs potes", b: "Que tous tes ex se marient entre eux"),
        Dilemma(id: "wyr_418", a: "Que ton ex te raconte en détail sa meilleure nuit", b: "Raconter en détail à ton ex ta meilleure nuit"),
        Dilemma(id: "wyr_419", a: "Ne pouvoir jouir que le lundi matin", b: "Ne pouvoir jouir qu'en écoutant l'hymne national"),
        Dilemma(id: "wyr_420", a: "Faire des bruits de dauphin pendant l'amour", b: "Que l'autre fasse des bruits de dauphin"),
        Dilemma(id: "wyr_421", a: "Faire un strip-tease devant toute la table", b: "Assister à celui de ton voisin de gauche"),
        Dilemma(id: "wyr_422", a: "Des capotes au goût kebab, à vie", b: "Des capotes qui jouent de la musique, à vie"),
        Dilemma(id: "wyr_423", a: "Un sexe énorme, mais toujours mou", b: "Un tout petit sexe, mais toujours prêt"),
        Dilemma(id: "wyr_424", a: "Une nuit avec ton crush, puis ne plus jamais le revoir", b: "Être son meilleur pote à vie, sans jamais rien tenter"),
        Dilemma(id: "wyr_425", a: "Un lit qui grince à chaque mouvement, à vie", b: "Une tête de lit qui cogne chez le voisin, à vie"),
        Dilemma(id: "wyr_426", a: "Que ton gémissement devienne ta sonnerie", b: "Que ta sonnerie devienne ton gémissement"),
        Dilemma(id: "wyr_427", a: "Le faire avec la musique d'un dessin animé en boucle", b: "Le faire pendant que ta daronne t'appelle en boucle"),
        Dilemma(id: "wyr_428", a: "Une nuit avec un mime qui ne fait aucun bruit", b: "Une nuit avec un clown qui klaxonne"),
        Dilemma(id: "wyr_429", a: "Que chaque baiser ait le goût de ton dernier repas", b: "Le goût du dernier repas de l'autre"),
        Dilemma(id: "wyr_430", a: "Ton coup d'un soir s'installe sur ton palier", b: "Ton coup d'un soir sort avec ta sœur le lendemain"),
        Dilemma(id: "wyr_431", a: "Le faire toujours les yeux dans les yeux", b: "Le faire toujours de dos, à vie"),
        Dilemma(id: "wyr_432", a: "Dire « je t'aime » à chaque orgasme, même aux inconnus", b: "Ne jamais pouvoir dire « je t'aime », même en couple"),
        Dilemma(id: "wyr_433", a: "Le faire une fois dans une cabine d'essayage", b: "Le faire une fois dans les toilettes d'un avion"),
        Dilemma(id: "wyr_434", a: "Un partenaire qui fait un discours avant de commencer", b: "Un partenaire qui chante pendant tout l'acte"),
        Dilemma(id: "wyr_435", a: "Que ton voisin de gauche choisisse ton prochain plan", b: "Que ton voisin de droite choisisse ton prochain couple"),
        Dilemma(id: "wyr_436", a: "Te faire larguer pendant l'amour", b: "Larguer quelqu'un pendant l'amour"),
        Dilemma(id: "wyr_437", a: "Le faire dans un hamac, à vie", b: "Le faire sur un matelas gonflable qui se dégonfle"),
        Dilemma(id: "wyr_438", a: "Que tous tes sextos partent bourrés de fautes", b: "Que ton correcteur change chaque mot coquin"),
        Dilemma(id: "wyr_439", a: "Un orgasme d'une heure, une seule fois dans ta vie", b: "Dix secondes d'orgasme, mais quand tu veux"),
        Dilemma(id: "wyr_440", a: "Te faire surprendre en plein acte par ton coloc", b: "Surprendre ton coloc en plein acte"),
        Dilemma(id: "wyr_441", a: "Une nuit torride, puis une diarrhée chez l'autre", b: "Une nuit ratée, puis le meilleur petit-déj de ta vie"),
        Dilemma(id: "wyr_442", a: "Que la table connaisse ta position préférée", b: "Que la table connaisse ton pire coup d'un soir"),
        Dilemma(id: "wyr_443", a: "Annoncer ton body count à toute la table", b: "Que ton ex l'annonce à ta place, en arrondissant"),
        Dilemma(id: "wyr_444", a: "Pécho à chaque soirée, sans retenir un seul prénom", b: "Pécho une fois par an, mais toujours la bonne"),
        Dilemma(id: "wyr_445", a: "Trouver un sextoy géant chez ton crush", b: "Que ton crush trouve ton tiroir à sextoys"),
        Dilemma(id: "wyr_446", a: "Être excité dès que tu stresses", b: "Être excité dès que tu as faim"),
        Dilemma(id: "wyr_447", a: "Être bourré au bout d'un verre", b: "Ne jamais être bourré, même après vingt"),
        Dilemma(id: "wyr_448", a: "Te réveiller à côté de ton ex après chaque cuite", b: "Te réveiller dans la baignoire après chaque cuite"),
        Dilemma(id: "wyr_449", a: "Te réveiller avec un tatouage mystère après chaque cuite", b: "Te réveiller avec une alliance inconnue après chaque cuite"),
        Dilemma(id: "wyr_450", a: "Être drôle bourré mais insupportable sobre", b: "Drôle sobre mais insupportable bourré"),
        Dilemma(id: "wyr_451", a: "Que chaque verre te fasse balancer un secret", b: "Que chaque verre te fasse écrire à ton ex"),
        Dilemma(id: "wyr_452", a: "Une gueule de bois qui dure jusqu'au mercredi", b: "Un after qui dure jusqu'au mercredi"),
        Dilemma(id: "wyr_453", a: "Plus une goutte d'alcool de ta vie", b: "Plus une seule nuit d'amour de ta vie")
    ]

    /// Le paquet effectivement joué : la base, plus l'Extrême si l'âge est
    /// confirmé ET que la table l'a activé. Le verrou se vérifie ici, pas dans
    /// la vue — un réglage sauvegardé ne rouvre pas un pack refermé.
    static func dilemmas(adultUnlocked: Bool, extremeEnabled: Bool) -> [Dilemma] {
        guard adultUnlocked, extremeEnabled else { return all }
        return all + extreme
    }
}
