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
    /// 40 cartes 18+, registre Picolo : la soirée qui dérape, assumée.
    case detraque

    var id: String { rawValue }

    var name: String {
        switch self {
        case .soiree: return "Soirée"
        case .potes: return "Entre potes"
        case .epice: return "Épicé"
        case .detraque: return "Détraqué"
        }
    }

    var subtitle: String {
        switch self {
        case .soiree: return "Ce qui arrive à tout le monde, un jour ou l'autre."
        case .potes: return "La mécanique du groupe : qui organise, qui annule, qui range."
        case .epice: return "Les petites manies qu'on préfère garder pour soi."
        case .detraque: return "Interdit aux mineurs. La soirée qui dérape, assumée."
        }
    }

    var symbol: String {
        switch self {
        case .soiree: return "sparkles"
        case .potes: return "person.3.fill"
        case .epice: return "flame.fill"
        case .detraque: return "moon.zzz.fill"
        }
    }

    /// Seul « Détraqué » est verrouillé : les trois autres sont tout public.
    /// Le déverrouillage passe par la confirmation d'âge des réglages — la
    /// fiche App Store est classée 17+ depuis la 1.1.
    var isLocked: Bool { self == .detraque }

    var cards: [MostLikelyCard] {
        switch self {
        case .soiree: return MostLikelyBank.soireeCards
        case .potes: return MostLikelyBank.potesCards
        case .epice: return MostLikelyBank.epiceCards
        case .detraque: return MostLikelyBank.detraqueCards
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
        MostLikelyCard(id: "mst_001", text: "rire à un enterrement en repensant à une vidéo"),
        MostLikelyCard(id: "mst_002", text: "pleurer devant une publicité avec un chien dedans"),
        MostLikelyCard(id: "mst_003", text: "se féliciter à voix haute pour un créneau réussi"),
        MostLikelyCard(id: "mst_004", text: "oublier son propre anniversaire"),
        MostLikelyCard(id: "mst_005", text: "arriver en retard à son mariage"),
        MostLikelyCard(id: "mst_006", text: "sortir du métro du mauvais côté à chaque fois"),
        MostLikelyCard(id: "mst_007", text: "louper son train en étant arrivé en avance"),
        MostLikelyCard(id: "mst_008", text: "réserver un vol pour la mauvaise ville"),
        MostLikelyCard(id: "mst_009", text: "réclamer son chargeur avant même de dire bonjour"),
        MostLikelyCard(id: "mst_010", text: "esquiver un prénom oublié à coups de « salut toi »"),
        MostLikelyCard(id: "mst_011", text: "faire un signe à quelqu'un qui saluait la personne derrière"),
        MostLikelyCard(id: "mst_012", text: "répondre « toi aussi » au serveur"),
        MostLikelyCard(id: "mst_013", text: "trébucher sur un trottoir et vérifier si quelqu'un a vu"),
        MostLikelyCard(id: "mst_014", text: "glisser juste devant le panneau « sol glissant »"),
        MostLikelyCard(id: "mst_015", text: "tacher son tee-shirt blanc dès la première bouchée"),
        MostLikelyCard(id: "mst_016", text: "reposer discrètement l'objet qu'il vient de casser"),
        MostLikelyCard(id: "mst_017", text: "mettre le feu à une casserole d'eau"),
        MostLikelyCard(id: "mst_018", text: "faire fondre une spatule dans la poêle"),
        MostLikelyCard(id: "mst_019", text: "rater un plat de pâtes au beurre"),
        MostLikelyCard(id: "mst_020", text: "engloutir le dernier morceau en demandant si quelqu'un le veut"),
        MostLikelyCard(id: "mst_021", text: "voler une frite dans l'assiette du voisin"),
        MostLikelyCard(id: "mst_022", text: "commander le même plat toute sa vie"),
        MostLikelyCard(id: "mst_023", text: "ouvrir un paquet de gâteaux « juste pour en prendre un »"),
        MostLikelyCard(id: "mst_024", text: "cuisiner à deux heures du matin"),
        MostLikelyCard(id: "mst_025", text: "faire sonner le détecteur de fumée en cuisinant"),
        MostLikelyCard(id: "mst_026", text: "garder un yaourt périmé depuis six mois"),
        MostLikelyCard(id: "mst_027", text: "faire ses courses en ayant faim"),
        MostLikelyCard(id: "mst_028", text: "justifier un achat inutile par « mais il était en promo »"),
        MostLikelyCard(id: "mst_029", text: "vérifier son compte en banque en fermant un œil"),
        MostLikelyCard(id: "mst_030", text: "retrouver un billet oublié dans une veste"),
        MostLikelyCard(id: "mst_031", text: "négocier le prix dans un magasin à prix fixe"),
        MostLikelyCard(id: "mst_032", text: "acheter le cadeau sur le trajet de l'anniversaire"),
        MostLikelyCard(id: "mst_033", text: "réutiliser un cadeau reçu l'an dernier"),
        MostLikelyCard(id: "mst_034", text: "envoyer « joyeux anniversaire » juste avant minuit"),
        MostLikelyCard(id: "mst_035", text: "souhaiter la bonne année jusqu'à fin mars"),
        MostLikelyCard(id: "mst_036", text: "chanter faux sans jamais s'en rendre compte"),
        MostLikelyCard(id: "mst_037", text: "vider la piste de danse avec sa chanson préférée"),
        MostLikelyCard(id: "mst_038", text: "chanter le refrain à fond et marmonner les couplets"),
        MostLikelyCard(id: "mst_039", text: "s'inscrire au karaoké pour les autres sans leur demander"),
        MostLikelyCard(id: "mst_040", text: "arriver à une soirée pizza en ayant déjà mangé"),
        MostLikelyCard(id: "mst_041", text: "faire rire toute une salle par accident"),
        MostLikelyCard(id: "mst_042", text: "raconter la même histoire deux fois à la même personne"),
        MostLikelyCard(id: "mst_043", text: "commencer toutes ses phrases par « non mais attends »"),
        MostLikelyCard(id: "mst_044", text: "demander « c'est qui lui ? » toutes les cinq minutes"),
        MostLikelyCard(id: "mst_045", text: "s'endormir devant le film qu'il a lui-même choisi"),
        MostLikelyCard(id: "mst_046", text: "pleurer devant un dessin animé"),
        MostLikelyCard(id: "mst_047", text: "regarder la suite de la série en douce sans l'avouer"),
        MostLikelyCard(id: "mst_048", text: "spoiler un film sans faire exprès"),
        MostLikelyCard(id: "mst_049", text: "relancer la même série pour la huitième fois"),
        MostLikelyCard(id: "mst_050", text: "commencer trente livres sans en finir un"),
        MostLikelyCard(id: "mst_051", text: "répondre à un message six jours plus tard"),
        MostLikelyCard(id: "mst_052", text: "envoyer « il est relou » à la personne concernée"),
        MostLikelyCard(id: "mst_053", text: "laisser un vocal de huit minutes sans aucune information"),
        MostLikelyCard(id: "mst_054", text: "réagir à une grande nouvelle par un simple pouce levé"),
        MostLikelyCard(id: "mst_055", text: "laisser cent onglets ouverts"),
        MostLikelyCard(id: "mst_056", text: "réinitialiser son mot de passe à chaque connexion"),
        MostLikelyCard(id: "mst_057", text: "prendre deux cents photos du même coucher de soleil"),
        MostLikelyCard(id: "mst_058", text: "photographier son assiette avant d'y toucher"),
        MostLikelyCard(id: "mst_059", text: "se prendre son téléphone dans la figure en le tenant au lit"),
        MostLikelyCard(id: "mst_060", text: "avoir toujours trois pour cent de batterie"),
        MostLikelyCard(id: "mst_061", text: "retourner vérifier trois fois si la porte est bien fermée"),
        MostLikelyCard(id: "mst_062", text: "chercher son téléphone avec la lampe torche du téléphone"),
        MostLikelyCard(id: "mst_063", text: "descendre la poubelle en pyjama et croiser tout l'immeuble"),
        MostLikelyCard(id: "mst_064", text: "surveiller ses baskets blanches comme un trésor national"),
        MostLikelyCard(id: "mst_065", text: "sauver un vieux pull troué de chaque grand tri"),
        MostLikelyCard(id: "mst_066", text: "considérer sa chaise comme une armoire officielle"),
        MostLikelyCard(id: "mst_067", text: "confisquer le seul plaid du canapé dès son arrivée"),
        MostLikelyCard(id: "mst_068", text: "vivre en décalage horaire sans avoir voyagé"),
        MostLikelyCard(id: "mst_069", text: "régler douze réveils et tous les ignorer"),
        MostLikelyCard(id: "mst_070", text: "se rendormir cinq minutes avant la sonnerie"),
        MostLikelyCard(id: "mst_071", text: "programmer vingt minutes de sieste et se réveiller de nuit"),
        MostLikelyCard(id: "mst_072", text: "détailler ses rêves comme si c'était passionnant"),
        MostLikelyCard(id: "mst_073", text: "ronfler en jurant ne jamais ronfler"),
        MostLikelyCard(id: "mst_074", text: "annoncer partout qu'il se met à la course à pied"),
        MostLikelyCard(id: "mst_075", text: "abandonner un abonnement de sport en trois semaines"),
        MostLikelyCard(id: "mst_076", text: "acheter la tenue complète avant la première séance"),
        MostLikelyCard(id: "mst_077", text: "se blesser en jouant à un jeu de société"),
        MostLikelyCard(id: "mst_078", text: "refuser de l'aide après une chute en répétant « ça va ça va »"),
        MostLikelyCard(id: "mst_079", text: "gagner à un jeu sans en connaître les règles"),
        MostLikelyCard(id: "mst_080", text: "renverser le plateau en perdant"),
        MostLikelyCard(id: "mst_081", text: "tricher aux cartes et se faire prendre"),
        MostLikelyCard(id: "mst_082", text: "relire la règle du jeu au milieu de la partie"),
        MostLikelyCard(id: "mst_083", text: "transformer une partie amicale en compétition"),
        MostLikelyCard(id: "mst_084", text: "bouder après une défaite à un jeu « juste pour rire »"),
        MostLikelyCard(id: "mst_085", text: "réclamer une revanche jusqu'à minuit"),
        MostLikelyCard(id: "mst_086", text: "adopter un animal sur un coup de tête"),
        MostLikelyCard(id: "mst_087", text: "parler à son chat comme à un collègue"),
        MostLikelyCard(id: "mst_088", text: "s'arrêter en pleine conversation pour un chien qui passe"),
        MostLikelyCard(id: "mst_089", text: "évacuer la pièce pour une guêpe en criant des ordres"),
        MostLikelyCard(id: "mst_090", text: "sauver une araignée au lieu de la chasser"),
        MostLikelyCard(id: "mst_091", text: "donner un prénom à sa plante"),
        MostLikelyCard(id: "mst_092", text: "faire mourir un cactus"),
        MostLikelyCard(id: "mst_093", text: "arroser des fleurs en plastique"),
        MostLikelyCard(id: "mst_094", text: "guetter le livreur à la fenêtre comme un chat"),
        MostLikelyCard(id: "mst_095", text: "planifier une nouvelle vie tous les dimanches soir"),
        MostLikelyCard(id: "mst_096", text: "repeindre un mur à trois heures du matin"),
        MostLikelyCard(id: "mst_097", text: "monter un meuble sans lire la notice"),
        MostLikelyCard(id: "mst_098", text: "garder les vis en trop dans un tiroir"),
        MostLikelyCard(id: "mst_099", text: "réparer quelque chose avec du ruban adhésif"),
        MostLikelyCard(id: "mst_100", text: "chercher un tuto vidéo pour ouvrir un bocal"),
        MostLikelyCard(id: "mst_101", text: "ranger sa chambre seulement quand on attend du monde"),
        MostLikelyCard(id: "mst_102", text: "entasser le bazar dans la baignoire avant les invités"),
        MostLikelyCard(id: "mst_103", text: "déménager trois fois le même carton jamais déballé"),
        MostLikelyCard(id: "mst_104", text: "posséder un sac rempli d'autres sacs"),
        MostLikelyCard(id: "mst_105", text: "conserver tous les câbles d'appareils disparus"),
        MostLikelyCard(id: "mst_106", text: "laver un mouchoir oublié avec tout le linge noir"),
        MostLikelyCard(id: "mst_107", text: "partir camper sans savoir monter une tente"),
        MostLikelyCard(id: "mst_108", text: "défendre son « raccourci » qui a doublé le trajet"),
        MostLikelyCard(id: "mst_109", text: "contredire le GPS et le regretter aussitôt"),
        MostLikelyCard(id: "mst_110", text: "courir après le bus sous le regard du chauffeur"),
        MostLikelyCard(id: "mst_111", text: "promettre un chemin « tout plat » avant la grande côte"),
        MostLikelyCard(id: "mst_112", text: "plonger dans une eau glacée sans hésiter"),
        MostLikelyCard(id: "mst_113", text: "entrer dans la mer centimètre par centimètre en hurlant"),
        MostLikelyCard(id: "mst_114", text: "avoir le mal de mer sur un pédalo"),
        MostLikelyCard(id: "mst_115", text: "bronzer en forme de tee-shirt"),
        MostLikelyCard(id: "mst_116", text: "ramener la moitié de la plage dans ses chaussures"),
        MostLikelyCard(id: "mst_117", text: "rater un avion pour une sieste"),
        MostLikelyCard(id: "mst_118", text: "partir à l'aventure sans rien réserver"),
        MostLikelyCard(id: "mst_119", text: "revenir de voyage avec un objet impossible à transporter"),
        MostLikelyCard(id: "mst_120", text: "raconter ses vacances pendant six mois")
    ]

    // MARK: - Entre potes

    static let potesCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_121", text: "arriver en retard au rendez-vous qu'il a lui-même fixé"),
        MostLikelyCard(id: "mst_122", text: "espérer secrètement que l'autre annule en premier"),
        MostLikelyCard(id: "mst_123", text: "dire « je pars dans cinq minutes » et rester deux heures"),
        MostLikelyCard(id: "mst_124", text: "promettre « on se capte » et réapparaître six mois plus tard"),
        MostLikelyCard(id: "mst_125", text: "répondre « on verra » à toutes les invitations"),
        MostLikelyCard(id: "mst_126", text: "arriver avec trois personnes non prévues"),
        MostLikelyCard(id: "mst_127", text: "s'endormir le premier à sa propre soirée"),
        MostLikelyCard(id: "mst_128", text: "réserver le canapé en y jetant une veste depuis l'entrée"),
        MostLikelyCard(id: "mst_129", text: "dire « c'est moi qui invite » et le regretter en silence"),
        MostLikelyCard(id: "mst_130", text: "filer aux toilettes pile au moment de l'addition"),
        MostLikelyCard(id: "mst_131", text: "compter les centimes en partageant l'addition"),
        MostLikelyCard(id: "mst_132", text: "hésiter vingt minutes puis commander comme d'habitude"),
        MostLikelyCard(id: "mst_133", text: "annoncer « je n'ai pas faim » puis finir les assiettes des autres"),
        MostLikelyCard(id: "mst_134", text: "vider le lave-vaisselle chez les autres"),
        MostLikelyCard(id: "mst_135", text: "disparaître au moment du rangement"),
        MostLikelyCard(id: "mst_136", text: "débarrasser les assiettes des gens qui mangent encore"),
        MostLikelyCard(id: "mst_137", text: "réveiller tout le groupe à l'aube pour les photos"),
        MostLikelyCard(id: "mst_138", text: "créer un groupe de discussion pour trois messages"),
        MostLikelyCard(id: "mst_139", text: "quitter le groupe puis demander qu'on le réintègre"),
        MostLikelyCard(id: "mst_140", text: "espionner le groupe sans jamais y écrire un mot"),
        MostLikelyCard(id: "mst_141", text: "envoyer trente photos floues après une sortie"),
        MostLikelyCard(id: "mst_142", text: "archiver une photo gênante pour la ressortir plus tard"),
        MostLikelyCard(id: "mst_143", text: "ressortir un dossier de collège en plein dîner"),
        MostLikelyCard(id: "mst_144", text: "se souvenir de tous les anniversaires"),
        MostLikelyCard(id: "mst_145", text: "signer la carte commune sans avoir mis un centime"),
        MostLikelyCard(id: "mst_146", text: "pleurer pendant un discours de mariage"),
        MostLikelyCard(id: "mst_147", text: "monopoliser le micro toute la soirée"),
        MostLikelyCard(id: "mst_148", text: "improviser un discours et le réussir"),
        MostLikelyCard(id: "mst_149", text: "tenir un secret jusqu'au bout"),
        MostLikelyCard(id: "mst_150", text: "révéler la fête surprise à l'intéressé lui-même"),
        MostLikelyCard(id: "mst_151", text: "complimenter un plat raté avec un aplomb parfait"),
        MostLikelyCard(id: "mst_152", text: "dire tout haut ce que les autres pensent tout bas"),
        MostLikelyCard(id: "mst_153", text: "lancer le débat pain au chocolat ou chocolatine"),
        MostLikelyCard(id: "mst_154", text: "avoir raison et le rappeler pendant des années"),
        MostLikelyCard(id: "mst_155", text: "reconnaître ses torts en premier"),
        MostLikelyCard(id: "mst_156", text: "s'excuser trois jours plus tard"),
        MostLikelyCard(id: "mst_157", text: "bouder puis revenir comme si de rien n'était"),
        MostLikelyCard(id: "mst_158", text: "rédiger un pavé de trois écrans pour un simple malentendu"),
        MostLikelyCard(id: "mst_159", text: "régler tous les conflits du groupe"),
        MostLikelyCard(id: "mst_160", text: "revenir des toilettes avec un nouveau meilleur ami"),
        MostLikelyCard(id: "mst_161", text: "connaître quelqu'un dans chaque ville"),
        MostLikelyCard(id: "mst_162", text: "présenter deux amis et regretter qu'ils s'entendent trop bien"),
        MostLikelyCard(id: "mst_163", text: "adopter le chien de la soirée et ignorer les humains"),
        MostLikelyCard(id: "mst_164", text: "capter tous les potins sans bouger du canapé"),
        MostLikelyCard(id: "mst_165", text: "partir d'une fête sans dire au revoir"),
        MostLikelyCard(id: "mst_166", text: "rester si tard qu'on lui propose le petit-déjeuner"),
        MostLikelyCard(id: "mst_167", text: "proposer un jeu à minuit passé"),
        MostLikelyCard(id: "mst_168", text: "relancer la musique quand tout le monde veut dormir"),
        MostLikelyCard(id: "mst_169", text: "lancer une chorégraphie devant tout le monde"),
        MostLikelyCard(id: "mst_170", text: "imiter parfaitement quelqu'un du groupe"),
        MostLikelyCard(id: "mst_171", text: "prendre l'accent d'une région après deux jours sur place"),
        MostLikelyCard(id: "mst_172", text: "rire à ses propres blagues avant la chute"),
        MostLikelyCard(id: "mst_173", text: "répéter la même blague toute l'année"),
        MostLikelyCard(id: "mst_174", text: "réagir à une blague avec dix secondes de retard"),
        MostLikelyCard(id: "mst_175", text: "photographier l'écran au lieu de faire une capture"),
        MostLikelyCard(id: "mst_176", text: "passer ses appels en haut-parleur au milieu du salon"),
        MostLikelyCard(id: "mst_177", text: "imposer une vidéo « attends elle est courte » de neuf minutes"),
        MostLikelyCard(id: "mst_178", text: "lire les messages par-dessus l'épaule"),
        MostLikelyCard(id: "mst_179", text: "connaître le code du téléphone de chacun"),
        MostLikelyCard(id: "mst_180", text: "retourner son téléphone face cachée dès qu'on approche"),
        MostLikelyCard(id: "mst_181", text: "filmer tout le monde et ne jamais rien envoyer"),
        MostLikelyCard(id: "mst_182", text: "se voir sur une photo et exiger qu'on la supprime"),
        MostLikelyCard(id: "mst_183", text: "supprimer sa story au bout de quarante secondes"),
        MostLikelyCard(id: "mst_184", text: "garder la même photo de profil depuis toujours"),
        MostLikelyCard(id: "mst_185", text: "créer un sondage pour choisir entre deux dates"),
        MostLikelyCard(id: "mst_186", text: "couvrir quelqu'un sans poser de questions"),
        MostLikelyCard(id: "mst_187", text: "venir chercher quelqu'un à n'importe quelle heure"),
        MostLikelyCard(id: "mst_188", text: "prêter un jeu et le racheter plutôt que de le redemander"),
        MostLikelyCard(id: "mst_189", text: "rendre un livre emprunté six ans plus tard"),
        MostLikelyCard(id: "mst_190", text: "emprunter un pull et l'adopter définitivement"),
        MostLikelyCard(id: "mst_191", text: "offrir son manteau à quelqu'un qui a froid"),
        MostLikelyCard(id: "mst_192", text: "partager sa dernière part sans hésiter"),
        MostLikelyCard(id: "mst_193", text: "cacher la dernière part derrière les légumes du frigo"),
        MostLikelyCard(id: "mst_194", text: "apporter un dessert « fait maison » encore dans son emballage"),
        MostLikelyCard(id: "mst_195", text: "apporter des chips et repartir avec le plat"),
        MostLikelyCard(id: "mst_196", text: "cuisiner pour vingt personnes quand il y en a six"),
        MostLikelyCard(id: "mst_197", text: "faire visiter sa ville comme un guide professionnel"),
        MostLikelyCard(id: "mst_198", text: "monter un tableur de voyage dix minutes après l'idée"),
        MostLikelyCard(id: "mst_199", text: "proposer un départ à l'autre bout du monde demain matin"),
        MostLikelyCard(id: "mst_200", text: "garder tous ses amis d'enfance")
    ]

    // MARK: - Épicé

    static let epiceCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_201", text: "rire de ses propres messages en les relisant"),
        MostLikelyCard(id: "mst_202", text: "réécouter ses propres vocaux et regretter sa voix"),
        MostLikelyCard(id: "mst_203", text: "rejouer une conversation dans sa tête pendant des jours"),
        MostLikelyCard(id: "mst_204", text: "préparer une réponse cinglante trois jours trop tard"),
        MostLikelyCard(id: "mst_205", text: "répéter « salut ça va » avant de sonner à la porte"),
        MostLikelyCard(id: "mst_206", text: "se recoiffer devant chaque vitrine"),
        MostLikelyCard(id: "mst_207", text: "prendre quarante selfies pour en garder un"),
        MostLikelyCard(id: "mst_208", text: "chercher son propre nom sur internet"),
        MostLikelyCard(id: "mst_209", text: "relire une conversation vieille de cinq ans"),
        MostLikelyCard(id: "mst_210", text: "liker par accident une photo vieille de sept ans"),
        MostLikelyCard(id: "mst_211", text: "vérifier ce que devient son crush du collège"),
        MostLikelyCard(id: "mst_212", text: "reconnaître un lieu à partir d'une seule photo"),
        MostLikelyCard(id: "mst_213", text: "identifier n'importe qui en ligne en trois clics"),
        MostLikelyCard(id: "mst_214", text: "inventer un métier passionnant en soirée"),
        MostLikelyCard(id: "mst_215", text: "exagérer une histoire un peu plus à chaque fois"),
        MostLikelyCard(id: "mst_216", text: "prétendre connaître un film jamais vu"),
        MostLikelyCard(id: "mst_217", text: "hocher la tête sans rien comprendre"),
        MostLikelyCard(id: "mst_218", text: "surjouer la joie devant un cadeau déjà possédé"),
        MostLikelyCard(id: "mst_219", text: "prétendre adorer la randonnée sur une appli de rencontre"),
        MostLikelyCard(id: "mst_220", text: "imposer son bon profil sur toutes les photos de groupe"),
        MostLikelyCard(id: "mst_221", text: "arrondir son âge dans le bon sens"),
        MostLikelyCard(id: "mst_222", text: "dire « j'arrive » en étant encore au lit"),
        MostLikelyCard(id: "mst_223", text: "poser un lapin tout en restant actif en ligne"),
        MostLikelyCard(id: "mst_224", text: "inventer une urgence pour quitter une soirée"),
        MostLikelyCard(id: "mst_225", text: "simuler une panne de réseau"),
        MostLikelyCard(id: "mst_226", text: "passer en mode avion au milieu d'une dispute par messages"),
        MostLikelyCard(id: "mst_227", text: "écrire puis effacer le même message pendant dix minutes"),
        MostLikelyCard(id: "mst_228", text: "envoyer « désolé du roman » après un message de trois lignes"),
        MostLikelyCard(id: "mst_229", text: "ghoster quelqu'un puis regarder toutes ses stories"),
        MostLikelyCard(id: "mst_230", text: "bloquer quelqu'un puis le débloquer le lendemain"),
        MostLikelyCard(id: "mst_231", text: "lâcher un secret après trois heures de jeu"),
        MostLikelyCard(id: "mst_232", text: "entretenir une rancune pour une histoire de chaussettes"),
        MostLikelyCard(id: "mst_233", text: "tenir un carnet des services rendus"),
        MostLikelyCard(id: "mst_234", text: "calculer précisément qui doit quoi à qui"),
        MostLikelyCard(id: "mst_235", text: "accepter un défi ridicule pour ne pas perdre la face"),
        MostLikelyCard(id: "mst_236", text: "refuser d'admettre une erreur évidente"),
        MostLikelyCard(id: "mst_237", text: "tricher à un test de personnalité"),
        MostLikelyCard(id: "mst_238", text: "se vexer d'un quiz « quel légume es-tu ? »"),
        MostLikelyCard(id: "mst_239", text: "prendre ce jeu beaucoup trop au sérieux"),
        MostLikelyCard(id: "mst_240", text: "poser la question que personne n'ose poser"),
        MostLikelyCard(id: "mst_241", text: "mettre tous ses défauts sur le dos de son signe astro"),
        MostLikelyCard(id: "mst_242", text: "croire à une superstition sans l'avouer"),
        MostLikelyCard(id: "mst_243", text: "toucher du bois discrètement"),
        MostLikelyCard(id: "mst_244", text: "faire un vœu à onze heures onze précises"),
        MostLikelyCard(id: "mst_245", text: "trimballer un porte-bonheur depuis l'enfance"),
        MostLikelyCard(id: "mst_246", text: "défendre son tiroir du bazar comme un coffre-fort"),
        MostLikelyCard(id: "mst_247", text: "compter les marches d'un escalier"),
        MostLikelyCard(id: "mst_248", text: "éviter les fissures du trottoir"),
        MostLikelyCard(id: "mst_249", text: "renifler un vêtement avant de le remettre"),
        MostLikelyCard(id: "mst_250", text: "porter le même pull trois jours de suite"),
        MostLikelyCard(id: "mst_251", text: "repousser une douche pour finir un épisode"),
        MostLikelyCard(id: "mst_252", text: "cocher la case sport après dix minutes de marche"),
        MostLikelyCard(id: "mst_253", text: "laisser la vaisselle jusqu'au dernier bol propre"),
        MostLikelyCard(id: "mst_254", text: "manger debout devant le réfrigérateur"),
        MostLikelyCard(id: "mst_255", text: "commander à manger alors que le frigo est plein"),
        MostLikelyCard(id: "mst_256", text: "cacher du chocolat même en vivant seul"),
        MostLikelyCard(id: "mst_257", text: "déterrer un souvenir gênant devant toute la table"),
        MostLikelyCard(id: "mst_258", text: "avouer une bêtise dix ans après"),
        MostLikelyCard(id: "mst_259", text: "s'excuser auprès d'un meuble après l'avoir percuté"),
        MostLikelyCard(id: "mst_260", text: "parler à la télévision comme si elle répondait")
    ]

    /// 18+, verrouillé derrière la confirmation d'âge. Cru mais jamais
    /// graphique : la règle 1.1.4 s'applique même en 17+.
    static let detraqueCards: [MostLikelyCard] = [
        MostLikelyCard(id: "mst_261", text: "finir en garde à vue pour un pari perdu"),
        MostLikelyCard(id: "mst_262", text: "coucher avec l'ex de quelqu'un de cette table"),
        MostLikelyCard(id: "mst_263", text: "faire ça dans les toilettes du bar avant la fin de la soirée"),
        MostLikelyCard(id: "mst_264", text: "avoir un contact enregistré sous un faux nom pour cacher un plan"),
        MostLikelyCard(id: "mst_265", text: "se réveiller dans une autre ville, sans téléphone et sans le haut"),
        MostLikelyCard(id: "mst_266", text: "tenir un classement chiffré et argumenté de ses ex"),
        MostLikelyCard(id: "mst_267", text: "répondre à un sexto à table au repas de Noël"),
        MostLikelyCard(id: "mst_268", text: "se faire tatouer le prénom d'un plan d'un soir"),
        MostLikelyCard(id: "mst_269", text: "vendre les secrets de ce groupe pour 50 balles"),
        MostLikelyCard(id: "mst_270", text: "simuler depuis des années avec la même personne"),
        MostLikelyCard(id: "mst_271", text: "envoyer un vocal de 4 minutes en pleurant à son ex à 4h du matin"),
        MostLikelyCard(id: "mst_272", text: "se faire éliminer d'une téléréalité de dating dès l'épisode 1"),
        MostLikelyCard(id: "mst_273", text: "draguer le médecin en pleine consultation gênante"),
        MostLikelyCard(id: "mst_274", text: "se marier à l'étranger sur un coup de tête et l'annoncer par story"),
        MostLikelyCard(id: "mst_275", text: "avoir un dossier photo qui nécessiterait un avocat"),
        MostLikelyCard(id: "mst_276", text: "appeler son boss « mon cœur » et poser un congé pour s'en remettre"),
        MostLikelyCard(id: "mst_277", text: "finir la soirée en couple avec la personne détestée au début"),
        MostLikelyCard(id: "mst_278", text: "réciter le prénom des ex de tout le monde ici, dans l'ordre"),
        MostLikelyCard(id: "mst_279", text: "connaître par cœur l'emploi du temps de son crush"),
        MostLikelyCard(id: "mst_280", text: "recontacter un plan bloqué « juste pour savoir »"),
        MostLikelyCard(id: "mst_281", text: "tenir un tableur de ses rencards avec des notes sur 10"),
        MostLikelyCard(id: "mst_282", text: "recevoir un mot des voisins — pas pour le bruit des fêtes"),
        MostLikelyCard(id: "mst_283", text: "finir torse nu dans une fontaine publique un soir de match"),
        MostLikelyCard(id: "mst_284", text: "envoyer « je suis devant chez toi » sans prévenir personne"),
        MostLikelyCard(id: "mst_285", text: "draguer par vengeance le meilleur pote de son ex"),
        MostLikelyCard(id: "mst_286", text: "accepter un rencard pour le resto et partir avant le dessert"),
        MostLikelyCard(id: "mst_287", text: "tomber amoureux en une soirée et déménager en un mois"),
        MostLikelyCard(id: "mst_288", text: "finir aux urgences pour une démonstration de souplesse"),
        MostLikelyCard(id: "mst_289", text: "se faire bannir d'un karaoké pour excès de sincérité"),
        MostLikelyCard(id: "mst_290", text: "raconter sa nuit au chauffeur, prénoms et détails compris"),
        MostLikelyCard(id: "mst_291", text: "payer pour faire disparaître une photo de soirée"),
        MostLikelyCard(id: "mst_292", text: "faire semblant de partir puis dormir sur le paillasson"),
        MostLikelyCard(id: "mst_293", text: "embrasser quelqu'un ici ce soir si le jeu le demandait"),
        MostLikelyCard(id: "mst_294", text: "garder un vêtement « oublié » comme trophée"),
        MostLikelyCard(id: "mst_295", text: "connaître le code du téléphone de tous ses ex"),
        MostLikelyCard(id: "mst_296", text: "répondre au téléphone pendant — et finir la conversation"),
        MostLikelyCard(id: "mst_297", text: "avoir une alerte sur le prénom de son ex"),
        MostLikelyCard(id: "mst_298", text: "divorcer avant la fin du vin d'honneur"),
        MostLikelyCard(id: "mst_299", text: "déclencher l'alarme incendie pour éviter une conversation"),
        MostLikelyCard(id: "mst_300", text: "se découvrir un ex en commun avec quelqu'un de cette table")
    ]
}
