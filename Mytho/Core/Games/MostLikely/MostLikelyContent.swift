import Foundation

// MARK: - Carte

/// Une carte du « plus susceptible de… ».
///
/// Le préfixe « Le plus susceptible de… » vit dans l'interface et **jamais dans
/// la donnée** (spec §3.5) : le texte commence par un verbe à l'infinitif, sans
/// majuscule ni point final. Une carte qui ne passe pas ce test est mal écrite —
/// et `MostLikelyTests` le vérifie.
///
/// `Identifiable` en plus de la forme donnée par la spec : c'est ce qui permet à
/// `Deck` de mémoriser les cartes vues sans qu'on ait à lui fournir une clé.
struct MostLikelyCard: Identifiable, Hashable, Sendable {
    let id: String
    let text: String
}

// MARK: - Packs

/// Les deux paquets du jeu. Le contenu se stocke en Swift et pas en JSON
/// (spec §1.2) : vérifié à la compilation, relisible en diff de PR.
enum MostLikelyPack: String, CaseIterable, Identifiable, Sendable {
    /// Tout public : jouable sans la confirmation d'âge, ni sexe ni alcool.
    case potes
    /// 18+ : la soirée qui dérape, assumée.
    case soiree

    var id: String { rawValue }

    var name: String {
        switch self {
        case .potes: return "Entre potes"
        case .soiree: return "Soirée"
        }
    }

    var subtitle: String {
        switch self {
        case .potes: return "Crush, ex, soirées qui partent en vrille et la table elle-même."
        case .soiree: return "Interdit aux mineurs. La soirée qui dérape, assumée."
        }
    }

    var symbol: String {
        switch self {
        case .potes: return "person.3.fill"
        case .soiree: return "flame.fill"
        }
    }

    /// Seul « Soirée » est verrouillé. Le déverrouillage passe par la
    /// confirmation d'âge des réglages — la fiche App Store est classée 17+.
    var isLocked: Bool { self == .soiree }

    var cards: [MostLikelyCard] {
        switch self {
        case .potes: return MostLikelyBank.potesCards
        case .soiree: return MostLikelyBank.soireeCards
        }
    }

    /// Le paquet ouvert est pré-coché ; « Soirée » se choisit par le bandeau.
    static let defaultSelection: Set<MostLikelyPack> = [.potes]

    /// Un paquet verrouillé n'est pas seulement grisé : il n'apparaît pas.
    /// Un paquet vidé de ses cartes non plus — proposer de cocher un paquet
    /// qui ne sortira jamais rien est une promesse qu'on ne tient pas.
    static func available(unlockedExtras: Bool) -> [MostLikelyPack] {
        allCases.filter { (unlockedExtras || !$0.isLocked) && !$0.cards.isEmpty }
    }
}

// MARK: - Banque

/// Même forme que `WordBank` : des tableaux statiques, aucun décodage à
/// l'exécution, aucune erreur de parsing possible.
enum MostLikelyBank {

    static var all: [MostLikelyCard] { MostLikelyPack.allCases.flatMap(\.cards) }

    /// Les cartes des paquets choisis. Un réglage sauvegardé qui ne pointe plus
    /// sur rien retombe sur le paquet de base plutôt que de rendre une partie
    /// injouable.
    ///
    /// Le verrou 18+ s'applique **ici** et pas seulement dans la vue : une table
    /// qui a coché « Soirée » puis refermé le contenu adulte dans les réglages
    /// ne doit plus en voir une seule carte. Le défaut est le verrou fermé —
    /// un appelant qui oublie l'argument obtient le paquet tout public.
    static func cards(for packs: Set<MostLikelyPack>, adultUnlocked: Bool = false) -> [MostLikelyCard] {
        let selected = MostLikelyPack.allCases
            .filter { packs.contains($0) && (!$0.isLocked || adultUnlocked) }
            .flatMap(\.cards)
        return selected.isEmpty ? potesCards : selected
    }

    // MARK: - Entre potes

    static let potesCards: [MostLikelyCard] = [
        // Version 2.0 (octobre 2026) : le registre des cartes Soirée
        // qu'Arthur a gardées — une mini-histoire précise, une heure, un
        // chiffre — sans sexe ni alcool : crush, ex, chaos ordinaire, et la
        // table elle-même prise à partie.
        MostLikelyCard(id: "mst_301", text: "stalker son crush jusqu'à ses photos de collège"),
        MostLikelyCard(id: "mst_302", text: "liker par erreur une photo de son crush vieille de six ans, à 3 h du matin"),
        MostLikelyCard(id: "mst_303", text: "répondre « mdr » à un message de rupture"),
        MostLikelyCard(id: "mst_304", text: "tomber amoureux en une soirée et se marier dans sa tête avant minuit"),
        MostLikelyCard(id: "mst_305", text: "avoir un crush différent à chaque soirée, « le bon » à chaque fois"),
        MostLikelyCard(id: "mst_306", text: "ghoster quelqu'un et lui reparler six mois plus tard comme si de rien n'était"),
        MostLikelyCard(id: "mst_307", text: "se cacher derrière un poteau pour éviter son ex dans la rue"),
        MostLikelyCard(id: "mst_308", text: "garder un sweat de chacun de ses ex"),
        MostLikelyCard(id: "mst_309", text: "se faire recaler par un videur devant son crush"),
        MostLikelyCard(id: "mst_310", text: "s'endormir pendant un date"),
        MostLikelyCard(id: "mst_311", text: "inviter son ex à son anniversaire « pour être mature »"),
        MostLikelyCard(id: "mst_312", text: "faire une crise de jalousie pour un simple like"),
        MostLikelyCard(id: "mst_313", text: "avoir un compte secret juste pour stalker ses ex"),
        MostLikelyCard(id: "mst_314", text: "connaître le prénom du nouveau crush de son ex avant son ex"),
        MostLikelyCard(id: "mst_315", text: "pleurer dans le bus en écoutant sa playlist de rupture"),
        MostLikelyCard(id: "mst_316", text: "poster une photo avec un nouveau crush dix minutes après s'être fait larguer"),
        MostLikelyCard(id: "mst_317", text: "connaître par cœur les horaires de boulot de son ex"),
        MostLikelyCard(id: "mst_318", text: "embrasser quelqu'un en soirée et jurer le lendemain que c'était un défi"),
        MostLikelyCard(id: "mst_319", text: "se faire recaler à un entretien pour avoir trop parlé de son ex"),
        MostLikelyCard(id: "mst_320", text: "envoyer « tu dors ? » à 3 h du matin"),
        MostLikelyCard(id: "mst_321", text: "commencer la soirée en couple et la finir célibataire"),
        MostLikelyCard(id: "mst_322", text: "commencer la soirée célibataire et la finir fiancé"),
        MostLikelyCard(id: "mst_323", text: "prendre un taxi à 200 € pour rejoindre quelqu'un qui ne répond plus"),
        MostLikelyCard(id: "mst_324", text: "embrasser quelqu'un et lui demander son prénom après"),
        MostLikelyCard(id: "mst_325", text: "rouler une pelle au DJ pour qu'il passe sa chanson"),
        MostLikelyCard(id: "mst_326", text: "choper quelqu'un rencontré dans la file des toilettes"),
        MostLikelyCard(id: "mst_327", text: "faire une déclaration d'amour au videur"),
        MostLikelyCard(id: "mst_328", text: "se mettre en couple sur un coup de tête et l'annoncer à ses parents le lendemain"),
        MostLikelyCard(id: "mst_329", text: "garder une appli de rencontre ouverte pendant un mariage"),
        MostLikelyCard(id: "mst_330", text: "faire semblant d'être malade pour annuler un date"),
        MostLikelyCard(id: "mst_331", text: "tomber amoureux de son coloc"),
        MostLikelyCard(id: "mst_332", text: "confondre les prénoms de ses deux crushs dans le même message"),
        MostLikelyCard(id: "mst_333", text: "dire « on reste potes » et ne plus jamais répondre"),
        MostLikelyCard(id: "mst_334", text: "rester ami avec tous ses ex et leurs nouveaux couples"),
        MostLikelyCard(id: "mst_335", text: "se faire passer pour quelqu'un d'autre sur une appli de rencontre"),
        MostLikelyCard(id: "mst_336", text: "raconter sa vie amoureuse à sa daronne dans les moindres détails"),
        MostLikelyCard(id: "mst_337", text: "demander à sa daronne comment répondre à un crush"),
        MostLikelyCard(id: "mst_338", text: "adopter un chat pour se remettre d'une rupture"),
        MostLikelyCard(id: "mst_339", text: "relancer quelqu'un avec un « coucou » trois mois après"),
        MostLikelyCard(id: "mst_340", text: "se faire piquer son crush par son meilleur pote"),
        MostLikelyCard(id: "mst_341", text: "sortir avec l'ex de son meilleur pote"),
        MostLikelyCard(id: "mst_342", text: "retourner chez son ex après une seule soirée de célibat"),
        MostLikelyCard(id: "mst_343", text: "passer une soirée entière à parler de son ex à son nouveau crush"),
        MostLikelyCard(id: "mst_344", text: "pleurer six mois pour quelqu'un avec qui il n'est jamais sorti"),
        MostLikelyCard(id: "mst_345", text: "se teindre les cheveux en bleu après une rupture"),
        MostLikelyCard(id: "mst_346", text: "se faire tatouer le prénom de quelqu'un après trois dates"),
        MostLikelyCard(id: "mst_347", text: "organiser une soirée uniquement pour inviter son crush"),
        MostLikelyCard(id: "mst_348", text: "avoir un crush secret sur quelqu'un de cette table"),
        MostLikelyCard(id: "mst_349", text: "lire les messages de quelqu'un d'ici pendant qu'il est aux toilettes"),
        MostLikelyCard(id: "mst_350", text: "être en train de stalker quelqu'un d'ici en ce moment même"),
        MostLikelyCard(id: "mst_351", text: "avoir déjà fait une capture de cette soirée pour la commenter ailleurs"),
        MostLikelyCard(id: "mst_352", text: "avoir un dossier sur chaque personne de cette table"),
        MostLikelyCard(id: "mst_353", text: "jouer les entremetteurs entre deux personnes de cette table"),
        MostLikelyCard(id: "mst_354", text: "avoir déjà craqué sur la moitié de la table"),
        MostLikelyCard(id: "mst_355", text: "créer un groupe de discussion juste pour parler de quelqu'un d'ici"),
        MostLikelyCard(id: "mst_356", text: "être le sujet d'un groupe de discussion dont il ne fait pas partie"),
        MostLikelyCard(id: "mst_357", text: "finir dans la friendzone de toute la table"),
        MostLikelyCard(id: "mst_358", text: "avoir ghosté tout le monde ici au moins une fois"),
        MostLikelyCard(id: "mst_359", text: "se brouiller avec toute la table à cause d'un jeu de société"),
        MostLikelyCard(id: "mst_360", text: "tricher à ce jeu en ce moment même"),
        MostLikelyCard(id: "mst_361", text: "pleurer devant un dessin animé et accuser une allergie"),
        MostLikelyCard(id: "mst_362", text: "dormir chez quelqu'un rencontré deux heures plus tôt"),
        MostLikelyCard(id: "mst_363", text: "draguer le serveur pour avoir un dessert gratuit"),
        MostLikelyCard(id: "mst_364", text: "dépenser tout son salaire le jour même où il tombe"),
        MostLikelyCard(id: "mst_365", text: "commander un kebab à 4 h du matin et s'endormir avant de le manger"),
        MostLikelyCard(id: "mst_366", text: "faire une sieste de quatre heures et appeler ça une sieste"),
        MostLikelyCard(id: "mst_367", text: "devenir viral pour la pire raison possible"),
        MostLikelyCard(id: "mst_368", text: "rejoindre une secte en croyant s'inscrire à un cours de yoga"),
        MostLikelyCard(id: "mst_369", text: "finir en couple avec quelqu'un rencontré dans une file d'attente"),
        MostLikelyCard(id: "mst_370", text: "se battre avec un pigeon pour un sandwich"),
        MostLikelyCard(id: "mst_371", text: "avaler un piment entier pour frimer et le regretter toute la nuit aux toilettes"),
        MostLikelyCard(id: "mst_372", text: "piquer le chargeur de tout le monde à chaque soirée"),
        MostLikelyCard(id: "mst_373", text: "devenir influenceur sur un sujet complètement inutile"),
        MostLikelyCard(id: "mst_374", text: "inventer une excuse si détaillée que tout le monde sait que c'est faux"),
        MostLikelyCard(id: "mst_375", text: "se faire virer d'un groupe de discussion"),
        MostLikelyCard(id: "mst_376", text: "s'incruster à une soirée où personne ne l'a invité"),
        MostLikelyCard(id: "mst_377", text: "pleurer dans un taxi en racontant toute sa vie au chauffeur"),
        MostLikelyCard(id: "mst_378", text: "se faire refouler d'une boîte en claquettes-chaussettes"),
        MostLikelyCard(id: "mst_379", text: "se faire griller par ses parents en rentrant par la fenêtre"),
        MostLikelyCard(id: "mst_380", text: "perdre son téléphone, ses clés et sa dignité dans la même soirée"),
        MostLikelyCard(id: "mst_381", text: "finir une soirée en caleçon chez des voisins inconnus"),
        MostLikelyCard(id: "mst_382", text: "se retrouver à une fête chez des gens qu'il n'a jamais vus"),
        MostLikelyCard(id: "mst_383", text: "inviter toute la boîte de nuit à finir chez lui"),
        MostLikelyCard(id: "mst_384", text: "finir la soirée dans une baignoire, tout habillé, au téléphone avec son ex"),
        MostLikelyCard(id: "mst_385", text: "finir en PLS dans la cuisine à chaque anniversaire"),
        MostLikelyCard(id: "mst_386", text: "rater son permis pour avoir fait un clin d'œil à l'inspecteur"),
        MostLikelyCard(id: "mst_387", text: "pleurer à chaque fin de soirée en hurlant « je vous aime trop »"),
        MostLikelyCard(id: "mst_388", text: "tomber dans une piscine tout habillé en voulant frimer"),
        MostLikelyCard(id: "mst_389", text: "faire un discours de mariage qui fait pleurer pour les mauvaises raisons"),
        MostLikelyCard(id: "mst_390", text: "se faire arrêter à la frontière")
    ]

    // MARK: - Soirée (18+)

    static let soireeCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_022", text: "avoir un historique porno à nettoyer en panique"),
        MostLikelyCard(id: "mst_026", text: "envoyer un nude à la mauvaise personne"),
        MostLikelyCard(id: "mst_027", text: "quitter quelqu'un par message"),
        MostLikelyCard(id: "mst_028", text: "bloquer son ex à 2h, le débloquer à 4h, le rebloquer à 6h"),
        MostLikelyCard(id: "mst_029", text: "jurer à toute la table que c'est fini avec son ex et repartir chez son ex le soir même"),
        MostLikelyCard(id: "mst_030", text: "proposer un plan à trois à 4h du matin"),
        MostLikelyCard(id: "mst_031", text: "jurer de tenir très bien l'alcool et finir à genoux devant les toilettes"),
        MostLikelyCard(id: "mst_038", text: "avoir déjà couché avec quelqu'un présent ce soir sans que la table le sache"),
        MostLikelyCard(id: "mst_040", text: "finir dans le lit de quelqu'un de cette pièce avant la fin de la soirée"),
        MostLikelyCard(id: "mst_041", text: "embrasser deux personnes de cette pièce dans la même soirée sans que ça se sache"),
        MostLikelyCard(id: "mst_042", text: "se réveiller à poil dans le couloir de l'immeuble, porte claquée"),
        MostLikelyCard(id: "mst_043", text: "se réveiller avec 47 messages envoyés à son ex et aucun souvenir"),
        MostLikelyCard(id: "mst_044", text: "tomber amoureux de la personne qui lui tient les cheveux au-dessus des toilettes"),
        MostLikelyCard(id: "mst_045", text: "promettre de ne rien dire et raconter sa nuit à toute la table au brunch"),

        // Version 2.0 (octobre 2026) : le thread de 3 h du matin, encore.
        MostLikelyCard(id: "mst_391", text: "envoyer « tu dors ? » à trois personnes différentes la même nuit"),
        MostLikelyCard(id: "mst_392", text: "embrasser quelqu'un au before et quelqu'un d'autre à l'after"),
        MostLikelyCard(id: "mst_393", text: "se réveiller dans le lit de quelqu'un dont il ne connaît pas le prénom"),
        MostLikelyCard(id: "mst_394", text: "coucher avec son ex « une dernière fois » pour la cinquième fois"),
        MostLikelyCard(id: "mst_395", text: "faire un strip-tease sur une table qui finit par casser"),
        MostLikelyCard(id: "mst_396", text: "proposer un shot à 7 h du matin pour « finir proprement »"),
        MostLikelyCard(id: "mst_397", text: "se faire surprendre en plein acte par ses colocs deux fois la même semaine"),
        MostLikelyCard(id: "mst_398", text: "avoir un plan cul dans chaque ville où il a vécu"),
        MostLikelyCard(id: "mst_399", text: "tomber amoureux pendant un plan à trois"),
        MostLikelyCard(id: "mst_400", text: "appeler sa daronne bourré pour lui dire qu'il l'aime"),
        MostLikelyCard(id: "mst_401", text: "vomir aux toilettes pendant un date et revenir comme si de rien n'était"),
        MostLikelyCard(id: "mst_402", text: "avoir un body count plus élevé que toute la table réunie"),
        MostLikelyCard(id: "mst_403", text: "noter ses plans sur dix dans les notes de son téléphone"),
        MostLikelyCard(id: "mst_404", text: "finir un enterrement de vie de jeune fille avec le strip-teaseur"),
        MostLikelyCard(id: "mst_405", text: "gémir assez fort pour que les voisins applaudissent"),
        MostLikelyCard(id: "mst_406", text: "partir acheter des clopes et revenir en couple"),
        MostLikelyCard(id: "mst_407", text: "boire un shot dans le nombril de quelqu'un de cette table"),
        MostLikelyCard(id: "mst_408", text: "se réveiller avec un suçon sans savoir de qui"),
        MostLikelyCard(id: "mst_409", text: "faire l'amour dans la chambre des parents d'un pote pendant une soirée"),
        MostLikelyCard(id: "mst_410", text: "perdre son slip en soirée et ne jamais le retrouver"),
        MostLikelyCard(id: "mst_411", text: "jurer qu'il ne boira plus jamais, un dimanche à 14 h, sous la couette"),
        MostLikelyCard(id: "mst_412", text: "danser sur le bar et finir dans les bras du barman"),
        MostLikelyCard(id: "mst_413", text: "se mettre en couple bourré et l'annoncer à toute la famille au réveil"),
        MostLikelyCard(id: "mst_414", text: "avoir couché avec l'ex de chaque personne de cette table"),
        MostLikelyCard(id: "mst_415", text: "simuler si bien qu'on lui demande un rappel"),
        MostLikelyCard(id: "mst_416", text: "rentrer à 6 h avec un kebab dans une main et un inconnu dans l'autre"),
        MostLikelyCard(id: "mst_417", text: "accuser l'alcool pour un bisou qu'il assume totalement"),
        MostLikelyCard(id: "mst_418", text: "faire semblant d'être sobre devant ses parents en parlant beaucoup trop lentement"),
        MostLikelyCard(id: "mst_419", text: "coucher avec quelqu'un juste pour son lit king size"),
        MostLikelyCard(id: "mst_420", text: "envoyer à son ex un pavé de quarante lignes à 4 h et « mauvais numéro » à midi"),
        MostLikelyCard(id: "mst_421", text: "avoir déjà fantasmé sur la moitié de la table"),
        MostLikelyCard(id: "mst_422", text: "s'endormir en plein acte"),
        MostLikelyCard(id: "mst_423", text: "tester une position vue sur internet et finir chez l'ostéo"),
        MostLikelyCard(id: "mst_424", text: "vomir sur ses propres chaussures en criant « ça va, ça va »"),
        MostLikelyCard(id: "mst_425", text: "faire l'amour sur une machine à laver en marche"),
        MostLikelyCard(id: "mst_426", text: "avoir un plan cul qui ignore son vrai prénom"),
        MostLikelyCard(id: "mst_427", text: "donner un faux numéro après une nuit"),
        MostLikelyCard(id: "mst_428", text: "avoir des menottes dans sa table de nuit"),
        MostLikelyCard(id: "mst_429", text: "donner un prénom à son sextoy"),
        MostLikelyCard(id: "mst_430", text: "faire un plan à trois et se sentir de trop"),
        MostLikelyCard(id: "mst_431", text: "être le plus bruyant de l'immeuble"),
        MostLikelyCard(id: "mst_432", text: "confondre son plan cul et son ex dans un message"),
        MostLikelyCard(id: "mst_433", text: "draguer le serveur pour une tournée gratuite"),
        MostLikelyCard(id: "mst_434", text: "jouer à action ou vérité juste pour embrasser quelqu'un"),
        MostLikelyCard(id: "mst_435", text: "porter les fringues de son plan d'un soir au brunch du lendemain"),
        MostLikelyCard(id: "mst_436", text: "rentrer à 8 h en tenue de soirée devant toute la boulangerie"),
        MostLikelyCard(id: "mst_437", text: "coucher avec son voisin de palier et déménager pour l'éviter"),
        MostLikelyCard(id: "mst_438", text: "appeler son ex par erreur en plein acte"),
        MostLikelyCard(id: "mst_439", text: "se faire réveiller par ses parents avec quelqu'un dans son lit"),
        MostLikelyCard(id: "mst_440", text: "payer la tournée à toute la boîte pour quelqu'un qui repart avec un autre"),
        MostLikelyCard(id: "mst_441", text: "finir la soirée en slip dans la fontaine de la ville"),
        MostLikelyCard(id: "mst_442", text: "ramener quelqu'un à la maison et réveiller ses colocs à chaque étape"),
        MostLikelyCard(id: "mst_443", text: "se réveiller à l'autre bout du pays sans savoir comment")
    ]
}
