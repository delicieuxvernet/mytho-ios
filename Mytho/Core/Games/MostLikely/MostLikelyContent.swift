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

/// Les trois paquets du jeu. Le contenu se stocke en Swift et pas en JSON
/// (spec §1.2) : vérifié à la compilation, relisible en diff de PR.
enum MostLikelyPack: String, CaseIterable, Identifiable, Sendable {
    /// 120 cartes, le grand public : ce qui arrive à tout le monde.
    case soiree
    /// 80 cartes, la mécanique du groupe : qui organise, qui annule, qui range.
    case potes
    /// 60 cartes, plus personnel : les petites manies qu'on n'avoue pas.
    case epice

    var id: String { rawValue }

    var name: String {
        switch self {
        case .soiree: return "Soirée"
        case .potes: return "Entre potes"
        case .epice: return "Épicé"
        }
    }

    var subtitle: String {
        switch self {
        case .soiree: return "Ce qui arrive à tout le monde, un jour ou l'autre."
        case .potes: return "La mécanique du groupe : qui organise, qui annule, qui range."
        case .epice: return "Les petites manies qu'on préfère garder pour soi."
        }
    }

    var symbol: String {
        switch self {
        case .soiree: return "sparkles"
        case .potes: return "person.3.fill"
        case .epice: return "flame.fill"
        }
    }

    /// Aucun paquet n'est verrouillé : les trois sont tout public, l'app étant
    /// classée 4+. Adosser « Épicé » au réglage de contenu adulte laissait
    /// 60 cartes mortes derrière un interrupteur qui ne les concernait pas.
    var isLocked: Bool { false }

    var cards: [MostLikelyCard] {
        switch self {
        case .soiree: return MostLikelyBank.soireeCards
        case .potes: return MostLikelyBank.potesCards
        case .epice: return MostLikelyBank.epiceCards
        }
    }

    /// Les deux paquets ouverts : 200 cartes, seize soirées de douze manches
    /// sans jamais revoir la même (spec §8).
    static let defaultSelection: Set<MostLikelyPack> = [.soiree, .potes]

    /// Les trois paquets sont proposés ; « Épicé » reste hors sélection par
    /// défaut, c'est un choix de ton, pas une restriction d'âge.

    /// Un paquet verrouillé n'est pas seulement grisé : il n'apparaît pas.
    static func available(unlockedExtras: Bool) -> [MostLikelyPack] {
        allCases.filter { unlockedExtras || !$0.isLocked }
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
    static func cards(for packs: Set<MostLikelyPack>) -> [MostLikelyCard] {
        let selected = MostLikelyPack.allCases
            .filter { packs.contains($0) }
            .flatMap(\.cards)
        return selected.isEmpty ? soireeCards : selected
    }

    // MARK: - Soirée

    static let soireeCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_001", text: "rire au mauvais moment"),
        MostLikelyCard(id: "mst_002", text: "pleurer devant une publicité"),
        MostLikelyCard(id: "mst_003", text: "parler tout seul dans la rue"),
        MostLikelyCard(id: "mst_004", text: "oublier son propre anniversaire"),
        MostLikelyCard(id: "mst_005", text: "arriver en retard à son mariage"),
        MostLikelyCard(id: "mst_006", text: "se perdre dans son propre quartier"),
        MostLikelyCard(id: "mst_007", text: "rater son train de deux minutes"),
        MostLikelyCard(id: "mst_008", text: "réserver un vol pour la mauvaise ville"),
        MostLikelyCard(id: "mst_009", text: "partir en vacances sans son chargeur"),
        MostLikelyCard(id: "mst_010", text: "oublier le nom de quelqu'un en pleine présentation"),
        MostLikelyCard(id: "mst_011", text: "saluer un inconnu en croyant le connaître"),
        MostLikelyCard(id: "mst_012", text: "répondre « toi aussi » au serveur"),
        MostLikelyCard(id: "mst_013", text: "tomber dans un escalator"),
        MostLikelyCard(id: "mst_014", text: "glisser sur un sol fraîchement lavé"),
        MostLikelyCard(id: "mst_015", text: "renverser son verre sur la nappe blanche"),
        MostLikelyCard(id: "mst_016", text: "casser un objet chez quelqu'un d'autre"),
        MostLikelyCard(id: "mst_017", text: "mettre le feu à une casserole d'eau"),
        MostLikelyCard(id: "mst_018", text: "faire fondre une spatule dans la poêle"),
        MostLikelyCard(id: "mst_019", text: "rater une recette à trois ingrédients"),
        MostLikelyCard(id: "mst_020", text: "manger le dernier morceau sans demander"),
        MostLikelyCard(id: "mst_021", text: "voler une frite dans l'assiette du voisin"),
        MostLikelyCard(id: "mst_022", text: "commander le même plat toute sa vie"),
        MostLikelyCard(id: "mst_023", text: "finir un paquet de gâteaux en une soirée"),
        MostLikelyCard(id: "mst_024", text: "cuisiner à deux heures du matin"),
        MostLikelyCard(id: "mst_025", text: "faire sonner le détecteur de fumée en cuisinant"),
        MostLikelyCard(id: "mst_026", text: "garder un yaourt périmé depuis six mois"),
        MostLikelyCard(id: "mst_027", text: "faire ses courses en ayant faim"),
        MostLikelyCard(id: "mst_028", text: "acheter quelque chose d'inutile en promotion"),
        MostLikelyCard(id: "mst_029", text: "dépenser tout son argent en un week-end"),
        MostLikelyCard(id: "mst_030", text: "retrouver un billet oublié dans une veste"),
        MostLikelyCard(id: "mst_031", text: "négocier le prix dans un magasin à prix fixe"),
        MostLikelyCard(id: "mst_032", text: "offrir un cadeau acheté le matin même"),
        MostLikelyCard(id: "mst_033", text: "réutiliser un cadeau reçu l'an dernier"),
        MostLikelyCard(id: "mst_034", text: "oublier de dire merci"),
        MostLikelyCard(id: "mst_035", text: "écrire une carte de vœux en retard"),
        MostLikelyCard(id: "mst_036", text: "chanter faux sans jamais s'en rendre compte"),
        MostLikelyCard(id: "mst_037", text: "connaître les paroles de toutes les chansons"),
        MostLikelyCard(id: "mst_038", text: "danser sans écouter la musique"),
        MostLikelyCard(id: "mst_039", text: "monter sur scène sans y être invité"),
        MostLikelyCard(id: "mst_040", text: "gagner un concours de grimaces"),
        MostLikelyCard(id: "mst_041", text: "faire rire toute une salle par accident"),
        MostLikelyCard(id: "mst_042", text: "raconter la même histoire trois fois"),
        MostLikelyCard(id: "mst_043", text: "couper la parole à tout le monde"),
        MostLikelyCard(id: "mst_044", text: "parler pendant tout un film"),
        MostLikelyCard(id: "mst_045", text: "s'endormir devant le générique de début"),
        MostLikelyCard(id: "mst_046", text: "pleurer devant un dessin animé"),
        MostLikelyCard(id: "mst_047", text: "connaître la fin d'une série avant les autres"),
        MostLikelyCard(id: "mst_048", text: "spoiler un film sans faire exprès"),
        MostLikelyCard(id: "mst_049", text: "relire le même livre dix fois"),
        MostLikelyCard(id: "mst_050", text: "commencer trente livres sans en finir un"),
        MostLikelyCard(id: "mst_051", text: "répondre à un message six jours plus tard"),
        MostLikelyCard(id: "mst_052", text: "envoyer un message à la mauvaise personne"),
        MostLikelyCard(id: "mst_053", text: "écrire un roman pour dire bonjour"),
        MostLikelyCard(id: "mst_054", text: "répondre uniquement par des émojis"),
        MostLikelyCard(id: "mst_055", text: "laisser cent onglets ouverts"),
        MostLikelyCard(id: "mst_056", text: "oublier son mot de passe toutes les semaines"),
        MostLikelyCard(id: "mst_057", text: "prendre deux cents photos du même coucher de soleil"),
        MostLikelyCard(id: "mst_058", text: "photographier son assiette avant d'y toucher"),
        MostLikelyCard(id: "mst_059", text: "faire tomber son téléphone dans le lavabo"),
        MostLikelyCard(id: "mst_060", text: "avoir toujours trois pour cent de batterie"),
        MostLikelyCard(id: "mst_061", text: "perdre ses clés dans sa propre maison"),
        MostLikelyCard(id: "mst_062", text: "chercher ses lunettes en les portant"),
        MostLikelyCard(id: "mst_063", text: "mettre un pull à l'envers toute la journée"),
        MostLikelyCard(id: "mst_064", text: "sortir avec deux chaussettes différentes"),
        MostLikelyCard(id: "mst_065", text: "garder un vêtement troué par sentimentalisme"),
        MostLikelyCard(id: "mst_066", text: "porter un manteau d'hiver au printemps"),
        MostLikelyCard(id: "mst_067", text: "avoir froid en toute saison"),
        MostLikelyCard(id: "mst_068", text: "dormir avec trois couvertures en été"),
        MostLikelyCard(id: "mst_069", text: "régler douze réveils et tous les ignorer"),
        MostLikelyCard(id: "mst_070", text: "se rendormir cinq minutes avant la sonnerie"),
        MostLikelyCard(id: "mst_071", text: "faire une sieste de trois heures"),
        MostLikelyCard(id: "mst_072", text: "rêver à voix haute"),
        MostLikelyCard(id: "mst_073", text: "ronfler en jurant ne jamais ronfler"),
        MostLikelyCard(id: "mst_074", text: "se lever avant le soleil pour aller courir"),
        MostLikelyCard(id: "mst_075", text: "abandonner un abonnement de sport en trois semaines"),
        MostLikelyCard(id: "mst_076", text: "courir un marathon sans entraînement"),
        MostLikelyCard(id: "mst_077", text: "se blesser en jouant à un jeu de société"),
        MostLikelyCard(id: "mst_078", text: "tomber du vélo devant témoins"),
        MostLikelyCard(id: "mst_079", text: "gagner à un jeu sans en connaître les règles"),
        MostLikelyCard(id: "mst_080", text: "renverser le plateau en perdant"),
        MostLikelyCard(id: "mst_081", text: "tricher aux cartes et se faire prendre"),
        MostLikelyCard(id: "mst_082", text: "relire la règle du jeu au milieu de la partie"),
        MostLikelyCard(id: "mst_083", text: "transformer une partie amicale en compétition"),
        MostLikelyCard(id: "mst_084", text: "bouder après une défaite"),
        MostLikelyCard(id: "mst_085", text: "réclamer une revanche jusqu'à minuit"),
        MostLikelyCard(id: "mst_086", text: "adopter un animal sur un coup de tête"),
        MostLikelyCard(id: "mst_087", text: "parler à son chat comme à un collègue"),
        MostLikelyCard(id: "mst_088", text: "nourrir tous les pigeons du parc"),
        MostLikelyCard(id: "mst_089", text: "avoir peur d'un insecte minuscule"),
        MostLikelyCard(id: "mst_090", text: "sauver une araignée au lieu de la chasser"),
        MostLikelyCard(id: "mst_091", text: "donner un prénom à sa plante"),
        MostLikelyCard(id: "mst_092", text: "faire mourir un cactus"),
        MostLikelyCard(id: "mst_093", text: "arroser des fleurs en plastique"),
        MostLikelyCard(id: "mst_094", text: "transformer son balcon en jungle"),
        MostLikelyCard(id: "mst_095", text: "déménager sur un coup de tête"),
        MostLikelyCard(id: "mst_096", text: "repeindre un mur à trois heures du matin"),
        MostLikelyCard(id: "mst_097", text: "monter un meuble sans lire la notice"),
        MostLikelyCard(id: "mst_098", text: "garder les vis en trop dans un tiroir"),
        MostLikelyCard(id: "mst_099", text: "réparer quelque chose avec du ruban adhésif"),
        MostLikelyCard(id: "mst_100", text: "appeler un proche pour changer une ampoule"),
        MostLikelyCard(id: "mst_101", text: "ranger sa chambre seulement quand on attend du monde"),
        MostLikelyCard(id: "mst_102", text: "cacher le désordre dans un placard"),
        MostLikelyCard(id: "mst_103", text: "garder un carton non déballé pendant deux ans"),
        MostLikelyCard(id: "mst_104", text: "collectionner les sacs en plastique"),
        MostLikelyCard(id: "mst_105", text: "jeter quelque chose et le regretter le lendemain"),
        MostLikelyCard(id: "mst_106", text: "retrouver un objet perdu dix ans plus tard"),
        MostLikelyCard(id: "mst_107", text: "partir camper sans savoir monter une tente"),
        MostLikelyCard(id: "mst_108", text: "se perdre en forêt en suivant un raccourci"),
        MostLikelyCard(id: "mst_109", text: "confondre le nord et le sud"),
        MostLikelyCard(id: "mst_110", text: "suivre un plan à l'envers pendant une heure"),
        MostLikelyCard(id: "mst_111", text: "escalader une montagne pour la vue"),
        MostLikelyCard(id: "mst_112", text: "plonger dans une eau glacée sans hésiter"),
        MostLikelyCard(id: "mst_113", text: "nager loin du bord sans savoir revenir"),
        MostLikelyCard(id: "mst_114", text: "avoir le mal de mer sur un pédalo"),
        MostLikelyCard(id: "mst_115", text: "bronzer en forme de tee-shirt"),
        MostLikelyCard(id: "mst_116", text: "oublier la crème solaire une seule fois"),
        MostLikelyCard(id: "mst_117", text: "rater un avion pour une sieste"),
        MostLikelyCard(id: "mst_118", text: "partir à l'aventure sans rien réserver"),
        MostLikelyCard(id: "mst_119", text: "revenir de voyage avec un objet impossible à transporter"),
        MostLikelyCard(id: "mst_120", text: "raconter ses vacances pendant six mois")
    ]

    // MARK: - Entre potes

    static let potesCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_121", text: "organiser toute la soirée et arriver en dernier"),
        MostLikelyCard(id: "mst_122", text: "annuler un plan une heure avant"),
        MostLikelyCard(id: "mst_123", text: "dire « je pars dans cinq minutes » et rester deux heures"),
        MostLikelyCard(id: "mst_124", text: "proposer un plan et ne jamais rien organiser"),
        MostLikelyCard(id: "mst_125", text: "répondre « on verra » à toutes les invitations"),
        MostLikelyCard(id: "mst_126", text: "arriver avec trois personnes non prévues"),
        MostLikelyCard(id: "mst_127", text: "dormir sur le canapé des autres"),
        MostLikelyCard(id: "mst_128", text: "squatter la meilleure place du salon"),
        MostLikelyCard(id: "mst_129", text: "régler l'addition pour toute la table"),
        MostLikelyCard(id: "mst_130", text: "oublier son portefeuille au restaurant"),
        MostLikelyCard(id: "mst_131", text: "compter les centimes en partageant l'addition"),
        MostLikelyCard(id: "mst_132", text: "commander pour les autres sans leur demander"),
        MostLikelyCard(id: "mst_133", text: "goûter dans l'assiette de chacun"),
        MostLikelyCard(id: "mst_134", text: "vider le lave-vaisselle chez les autres"),
        MostLikelyCard(id: "mst_135", text: "disparaître au moment du rangement"),
        MostLikelyCard(id: "mst_136", text: "ranger la cuisine avant de partir"),
        MostLikelyCard(id: "mst_137", text: "envoyer un message de remerciement le lendemain"),
        MostLikelyCard(id: "mst_138", text: "créer un groupe de discussion pour trois messages"),
        MostLikelyCard(id: "mst_139", text: "quitter un groupe de discussion sans prévenir"),
        MostLikelyCard(id: "mst_140", text: "répondre à tous les messages sauf ceux du groupe"),
        MostLikelyCard(id: "mst_141", text: "envoyer trente photos floues après une sortie"),
        MostLikelyCard(id: "mst_142", text: "archiver une photo gênante pour la ressortir plus tard"),
        MostLikelyCard(id: "mst_143", text: "ressortir une histoire vieille de dix ans"),
        MostLikelyCard(id: "mst_144", text: "se souvenir de tous les anniversaires"),
        MostLikelyCard(id: "mst_145", text: "offrir le cadeau le plus surprenant"),
        MostLikelyCard(id: "mst_146", text: "pleurer pendant un discours de mariage"),
        MostLikelyCard(id: "mst_147", text: "monopoliser le micro toute la soirée"),
        MostLikelyCard(id: "mst_148", text: "improviser un discours et le réussir"),
        MostLikelyCard(id: "mst_149", text: "tenir un secret jusqu'au bout"),
        MostLikelyCard(id: "mst_150", text: "vendre la mèche sans le vouloir"),
        MostLikelyCard(id: "mst_151", text: "inventer une histoire pour ne vexer personne"),
        MostLikelyCard(id: "mst_152", text: "dire tout haut ce que les autres pensent tout bas"),
        MostLikelyCard(id: "mst_153", text: "lancer un débat sur un sujet minuscule"),
        MostLikelyCard(id: "mst_154", text: "avoir raison et le rappeler pendant des années"),
        MostLikelyCard(id: "mst_155", text: "reconnaître ses torts en premier"),
        MostLikelyCard(id: "mst_156", text: "s'excuser trois jours plus tard"),
        MostLikelyCard(id: "mst_157", text: "bouder puis revenir comme si de rien n'était"),
        MostLikelyCard(id: "mst_158", text: "écrire un long message pour dissiper un malentendu"),
        MostLikelyCard(id: "mst_159", text: "régler tous les conflits du groupe"),
        MostLikelyCard(id: "mst_160", text: "se lier d'amitié avec un inconnu en dix minutes"),
        MostLikelyCard(id: "mst_161", text: "connaître quelqu'un dans chaque ville"),
        MostLikelyCard(id: "mst_162", text: "oublier de présenter les gens entre eux"),
        MostLikelyCard(id: "mst_163", text: "passer la soirée avec les inconnus plutôt qu'avec ses amis"),
        MostLikelyCard(id: "mst_164", text: "rester dans un coin toute la soirée puis tout raconter"),
        MostLikelyCard(id: "mst_165", text: "partir d'une fête sans dire au revoir"),
        MostLikelyCard(id: "mst_166", text: "rester jusqu'au petit matin"),
        MostLikelyCard(id: "mst_167", text: "proposer un jeu à minuit passé"),
        MostLikelyCard(id: "mst_168", text: "relancer la musique quand tout le monde veut dormir"),
        MostLikelyCard(id: "mst_169", text: "lancer une chorégraphie devant tout le monde"),
        MostLikelyCard(id: "mst_170", text: "imiter parfaitement quelqu'un du groupe"),
        MostLikelyCard(id: "mst_171", text: "prendre l'accent d'une région après deux jours sur place"),
        MostLikelyCard(id: "mst_172", text: "rire à ses propres blagues avant la chute"),
        MostLikelyCard(id: "mst_173", text: "répéter la même blague toute l'année"),
        MostLikelyCard(id: "mst_174", text: "réagir à une blague avec dix secondes de retard"),
        MostLikelyCard(id: "mst_175", text: "rire nerveusement dans un moment sérieux"),
        MostLikelyCard(id: "mst_176", text: "répondre au téléphone en pleine conversation"),
        MostLikelyCard(id: "mst_177", text: "montrer une vidéo à toute la table de force"),
        MostLikelyCard(id: "mst_178", text: "lire les messages par-dessus l'épaule"),
        MostLikelyCard(id: "mst_179", text: "connaître le code du téléphone de chacun"),
        MostLikelyCard(id: "mst_180", text: "laisser son téléphone déverrouillé sur la table"),
        MostLikelyCard(id: "mst_181", text: "filmer au lieu de participer"),
        MostLikelyCard(id: "mst_182", text: "se voir sur une photo et exiger qu'on la supprime"),
        MostLikelyCard(id: "mst_183", text: "changer de photo de profil chaque semaine"),
        MostLikelyCard(id: "mst_184", text: "garder la même photo de profil depuis toujours"),
        MostLikelyCard(id: "mst_185", text: "écrire un mot d'excuse pour un ami en retard"),
        MostLikelyCard(id: "mst_186", text: "couvrir quelqu'un sans poser de questions"),
        MostLikelyCard(id: "mst_187", text: "venir chercher quelqu'un à n'importe quelle heure"),
        MostLikelyCard(id: "mst_188", text: "prêter un objet et ne jamais le revoir"),
        MostLikelyCard(id: "mst_189", text: "rendre un livre emprunté six ans plus tard"),
        MostLikelyCard(id: "mst_190", text: "emprunter un pull et l'adopter définitivement"),
        MostLikelyCard(id: "mst_191", text: "offrir son manteau à quelqu'un qui a froid"),
        MostLikelyCard(id: "mst_192", text: "partager sa dernière part sans hésiter"),
        MostLikelyCard(id: "mst_193", text: "garder la dernière part pour plus tard"),
        MostLikelyCard(id: "mst_194", text: "arriver avec un dessert fait maison"),
        MostLikelyCard(id: "mst_195", text: "apporter des chips et repartir avec le plat"),
        MostLikelyCard(id: "mst_196", text: "cuisiner pour vingt personnes quand il y en a six"),
        MostLikelyCard(id: "mst_197", text: "faire visiter sa ville comme un guide professionnel"),
        MostLikelyCard(id: "mst_198", text: "organiser un voyage entier en une soirée"),
        MostLikelyCard(id: "mst_199", text: "proposer un départ à l'autre bout du monde demain matin"),
        MostLikelyCard(id: "mst_200", text: "garder tous ses amis d'enfance")
    ]

    // MARK: - Épicé

    static let epiceCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_201", text: "rire de ses propres messages en les relisant"),
        MostLikelyCard(id: "mst_202", text: "se filmer pour vérifier sa voix"),
        MostLikelyCard(id: "mst_203", text: "rejouer une conversation dans sa tête pendant des jours"),
        MostLikelyCard(id: "mst_204", text: "préparer une réponse cinglante trois jours trop tard"),
        MostLikelyCard(id: "mst_205", text: "s'entraîner à sourire devant le miroir"),
        MostLikelyCard(id: "mst_206", text: "se recoiffer devant chaque vitrine"),
        MostLikelyCard(id: "mst_207", text: "prendre quarante selfies pour en garder un"),
        MostLikelyCard(id: "mst_208", text: "chercher son propre nom sur internet"),
        MostLikelyCard(id: "mst_209", text: "relire une conversation vieille de cinq ans"),
        MostLikelyCard(id: "mst_210", text: "connaître par cœur le parcours de ses connaissances"),
        MostLikelyCard(id: "mst_211", text: "suivre l'actualité d'une personne perdue de vue"),
        MostLikelyCard(id: "mst_212", text: "reconnaître un lieu à partir d'une seule photo"),
        MostLikelyCard(id: "mst_213", text: "deviner un mot de passe du premier coup"),
        MostLikelyCard(id: "mst_214", text: "inventer un métier passionnant en soirée"),
        MostLikelyCard(id: "mst_215", text: "exagérer une histoire un peu plus à chaque fois"),
        MostLikelyCard(id: "mst_216", text: "prétendre connaître un film jamais vu"),
        MostLikelyCard(id: "mst_217", text: "hocher la tête sans rien comprendre"),
        MostLikelyCard(id: "mst_218", text: "faire semblant d'aimer un cadeau"),
        MostLikelyCard(id: "mst_219", text: "mentir sur son âge pour rire"),
        MostLikelyCard(id: "mst_220", text: "prendre la pose dès qu'un appareil photo apparaît"),
        MostLikelyCard(id: "mst_221", text: "arrondir son âge dans le bon sens"),
        MostLikelyCard(id: "mst_222", text: "dire « j'arrive » en étant encore au lit"),
        MostLikelyCard(id: "mst_223", text: "jurer être déjà en route"),
        MostLikelyCard(id: "mst_224", text: "inventer une urgence pour quitter une soirée"),
        MostLikelyCard(id: "mst_225", text: "simuler une panne de réseau"),
        MostLikelyCard(id: "mst_226", text: "laisser un message vocal et le regretter aussitôt"),
        MostLikelyCard(id: "mst_227", text: "écrire un message puis le supprimer"),
        MostLikelyCard(id: "mst_228", text: "rédiger un message et l'envoyer à minuit"),
        MostLikelyCard(id: "mst_229", text: "relancer trois fois sans réponse"),
        MostLikelyCard(id: "mst_230", text: "bloquer quelqu'un puis le débloquer le lendemain"),
        MostLikelyCard(id: "mst_231", text: "lâcher un secret après trois heures de jeu"),
        MostLikelyCard(id: "mst_232", text: "entretenir une rancune pour une histoire de chaussettes"),
        MostLikelyCard(id: "mst_233", text: "tenir un carnet des services rendus"),
        MostLikelyCard(id: "mst_234", text: "calculer précisément qui doit quoi à qui"),
        MostLikelyCard(id: "mst_235", text: "accepter un défi ridicule pour ne pas perdre la face"),
        MostLikelyCard(id: "mst_236", text: "refuser d'admettre une erreur évidente"),
        MostLikelyCard(id: "mst_237", text: "tricher à un test de personnalité"),
        MostLikelyCard(id: "mst_238", text: "remplir un questionnaire en se donnant le beau rôle"),
        MostLikelyCard(id: "mst_239", text: "répondre honnêtement à une question gênante"),
        MostLikelyCard(id: "mst_240", text: "poser la question que personne n'ose poser"),
        MostLikelyCard(id: "mst_241", text: "lire son horoscope tous les matins"),
        MostLikelyCard(id: "mst_242", text: "croire à une superstition sans l'avouer"),
        MostLikelyCard(id: "mst_243", text: "toucher du bois discrètement"),
        MostLikelyCard(id: "mst_244", text: "faire un vœu à chaque étoile filante"),
        MostLikelyCard(id: "mst_245", text: "trimballer un porte-bonheur depuis l'enfance"),
        MostLikelyCard(id: "mst_246", text: "ranger ses affaires dans un ordre incompréhensible"),
        MostLikelyCard(id: "mst_247", text: "compter les marches d'un escalier"),
        MostLikelyCard(id: "mst_248", text: "éviter les fissures du trottoir"),
        MostLikelyCard(id: "mst_249", text: "renifler un vêtement avant de le remettre"),
        MostLikelyCard(id: "mst_250", text: "porter le même pull trois jours de suite"),
        MostLikelyCard(id: "mst_251", text: "repousser une douche pour finir un épisode"),
        MostLikelyCard(id: "mst_252", text: "se coucher sans se laver les dents"),
        MostLikelyCard(id: "mst_253", text: "laisser la vaisselle jusqu'au dernier bol propre"),
        MostLikelyCard(id: "mst_254", text: "manger debout devant le réfrigérateur"),
        MostLikelyCard(id: "mst_255", text: "finir un plat directement dans sa boîte"),
        MostLikelyCard(id: "mst_256", text: "cacher une réserve de chocolat"),
        MostLikelyCard(id: "mst_257", text: "déterrer un souvenir gênant devant toute la table"),
        MostLikelyCard(id: "mst_258", text: "avouer une bêtise dix ans après"),
        MostLikelyCard(id: "mst_259", text: "présenter ses excuses à un objet"),
        MostLikelyCard(id: "mst_260", text: "parler à la télévision comme si elle répondait")
    ]
}
