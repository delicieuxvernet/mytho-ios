# Vérifie les invariants des banques de contenu avant tout commit.
#   python scripts/check-content.py nhie|ml|wyr|wordbank|all
#
# Miroir des assertions des tests unitaires : volumes, unicité, longueur,
# et balayage du lexique interdit par la classification (les packs de base
# restent tout public ; les packs adultes verrouillés ont leur propre règle).
import re
import sys
import unicodedata

REPO = r"C:\Users\stana\Desktop\Claude\Mytho-iOS"


def norm(text: str) -> str:
    return unicodedata.normalize("NFKD", text.lower()).encode("ascii", "ignore").decode()


# Tournures innocentes retirées AVANT le balayage : les mots seuls restent
# interdits, la locution entière ne l'est pas.
ALLOWED_PHRASES = [
    "coucher de soleil", "coucher du soleil", "se coucher", "me coucher",
    "pieds nus", "a l'oeil nu",
]


# Mots entiers uniquement : « Livre » ne doit pas déclencher « ivre ».
BANNED_BASE = [
    "alcool", "biere", "bieres", "vin", "vins", "vodka", "whisky", "rhum", "shot", "shots",
    "cocktail", "apero", "champagne", "bourre", "ivre", "cuite", "defonce",
    "drogue", "drogues", "joint", "clope", "clopes", "cigarette", "tabac", "vapoteuse",
    "sexe", "sexuel", "sexuelle", "nu", "nue", "nus", "nudes", "coucher", "sexto",
    "pari", "paris_argent", "casino", "poker",
    "arme", "armes", "pistolet", "tuer", "mort",
]


def banned_hits(entries):
    hits = []
    for ident, text in entries:
        cleaned = norm(text)
        for phrase in ALLOWED_PHRASES:
            cleaned = cleaned.replace(norm(phrase), " ")
        words = set(re.findall(r"[a-z]+", cleaned))
        bad = words & set(BANNED_BASE)
        if bad:
            hits.append((ident, text, sorted(bad)))
    return hits


# Ce qui reste interdit MEME dans les packs 18+ (regle 1.1.4 + lignes rouges) :
# le graphique, le non-consenti, les mineurs, les drogues dures, les marques.
BANNED_ADULT = [
    "viol", "violer", "mineur", "mineure", "mineurs", "inceste",
    "cocaine", "heroine", "crack", "seringue",
    "tiktok", "instagram", "netflix", "tinder", "snapchat", "uber",
]


def adult_hits(entries):
    hits = []
    for ident, text in entries:
        words = set(re.findall(r"[a-z]+", norm(text)))
        bad = words & set(BANNED_ADULT)
        if bad:
            hits.append((ident, text, sorted(bad)))
    return hits


def check(name, entries, expected_count, id_prefix=None, max_len=None, adult=False):
    ok = True
    print(f"--- {name} : {len(entries)} entrées")
    if len(entries) != expected_count:
        print(f"  ECHEC volume : {len(entries)} != {expected_count}")
        ok = False
    ids = [e[0] for e in entries]
    if len(set(ids)) != len(ids):
        print("  ECHEC ids dupliqués")
        ok = False
    if id_prefix:
        seq = [f"{id_prefix}{i:03d}" for i in range(1, expected_count + 1)]
        if ids != seq:
            print("  ECHEC séquence d'ids (ordre ou trous)")
            ok = False
    texts = [e[1] for e in entries]
    dups = sorted({t for t in texts if texts.count(t) > 1})
    if dups:
        print(f"  ECHEC textes dupliqués : {dups[:4]}")
        ok = False
    if max_len:
        too_long = [(i, len(t)) for i, t in entries if len(t) > max_len]
        if too_long:
            print(f"  ECHEC longueurs > {max_len} : {too_long[:4]}")
            ok = False
    hits = adult_hits(entries) if adult else banned_hits(entries)
    if hits:
        print("  ECHEC lexique 18+ :" if adult else "  ECHEC lexique 4+ :")
        for ident, text, bad in hits[:6]:
            print(f"    {ident} [{','.join(bad)}] {text}")
        ok = False
    print("  OK" if ok else "  A CORRIGER")
    return ok


def numeros_sains(prefixe, *lots):
    """Un identifiant n'est JAMAIS reattribue : une carte retiree emporte son
    numero. On verifie donc l'unicite globale et l'ordre croissant DANS chaque
    paquet — jamais la continuite de la suite, les trous sont la regle."""
    ok = True
    tous = []
    for lot in lots:
        suite = [int(i.split("_")[1]) for i, _ in lot]
        if suite != sorted(suite):
            print(f"  ECHEC {prefixe} : numeros dans le desordre")
            ok = False
        tous += suite
    if len(set(tous)) != len(tous):
        print(f"  ECHEC {prefixe} : un numero sert deux fois")
        ok = False
    return ok


def load(path, pattern):
    src = open(f"{REPO}/{path}", encoding="utf-8").read()
    return re.findall(pattern, src)


def run(which: str) -> bool:
    ok = True
    if which in ("nhie", "all"):
        src = open(
            f"{REPO}/Mytho/Core/Games/NeverHaveIEver/NeverHaveIEverContent.swift",
            encoding="utf-8",
        ).read()
        tete, queue = src.split("// MARK: - Pack verrouillé", 1)
        motif = r'card\((\d+),\s*"((?:[^"\\]|\\.)*)"\)'
        base = [(f"nhie_{int(n):03d}", t) for n, t in re.findall(motif, tete)]
        adult = [(f"nhie_{int(n):03d}", t) for n, t in re.findall(motif, queue)]
        ok &= check("Je n'ai jamais (base)", base, 5, max_len=70)
        ok &= check("Je n'ai jamais (18+)", adult, 19, max_len=70, adult=True)
        ok &= numeros_sains("nhie", base, adult)
    if which in ("ml", "all"):
        src = open(
            f"{REPO}/Mytho/Core/Games/MostLikely/MostLikelyContent.swift",
            encoding="utf-8",
        ).read()
        tete, queue = src.split("// MARK: - Soirée (18+)", 1)
        motif = r'MostLikelyCard\(id:\s*"(mst_\d+)",\s*text:\s*"((?:[^"\\]|\\.)*)"\)'
        base = re.findall(motif, tete)
        adult = re.findall(motif, queue)
        ok &= check("Le plus susceptible (base)", base, 0, max_len=90)
        ok &= check("Le plus susceptible (18+)", adult, 14, max_len=90, adult=True)
        ok &= numeros_sains("mst", base, adult)
    if which in ("wyr", "all"):
        src = open(
            f"{REPO}/Mytho/Core/Games/WouldYouRather/WouldYouRatherContent.swift",
            encoding="utf-8",
        ).read()
        motif = (
            r'Dilemma\(id:\s*"(wyr_\d+)",\s*a:\s*"((?:[^"\\]|\\.)*)",\s*b:\s*"((?:[^"\\]|\\.)*)"\)'
        )
        # Le partage base / Extreme se lit sur les deux tableaux du code, et
        # NON sur le numero d'identifiant : un numero n'est jamais reattribue,
        # une carte retiree laisse donc un trou definitif dans la suite.
        tete, queue = src.split("// MARK: Pack Extrême (18+)", 1)
        raw_base = re.findall(motif, tete)
        raw_adult = re.findall(motif, queue)
        raw = raw_base + raw_adult
        base = [(i, f"{a} / {b}") for i, a, b in raw_base]
        adult = [(i, f"{a} / {b}") for i, a, b in raw_adult]
        options = [(i, a) for i, a, _ in raw] + [(i, b) for i, _, b in raw]
        ok &= check("Tu préfères (base)", base, 17)
        ok &= check("Tu préfères (Extrême 18+)", adult, 24, adult=True)
        numeros = [int(i[4:]) for i, _, _ in raw]
        if len(set(numeros)) != len(numeros):
            print("  ECHEC identifiant reattribue : un numero sert deux fois")
            ok = False
        # Croissant a l'interieur de chaque paquet ; entre les deux, non : le
        # paquet de base a recu les numeros les plus recents.
        for nom, lot in (("base", raw_base), ("Extreme", raw_adult)):
            suite = [int(i[4:]) for i, _, _ in lot]
            if sorted(suite) != suite:
                print(f"  ECHEC identifiants dans le desordre ({nom})")
                ok = False
        too_long = [(i, len(t)) for i, t in options if len(t) > 60]
        if too_long:
            print(f"  ECHEC options > 60 : {too_long[:4]}")
            ok = False
    if which in ("wordbank", "all"):
        src = open(f"{REPO}/Mytho/Core/WordBank.swift", encoding="utf-8").read()
        body = src.split("// MARK: - Tout public", 1)[1]
        raw = re.findall(r'WordPair\(a:\s*"((?:[^"\\]|\\.)*)",\s*b:\s*"((?:[^"\\]|\\.)*)"\)', body)
        pairs = [(f"p{n:03d}", f"{a} / {b}") for n, (a, b) in enumerate(raw, 1)]
        # L'app est classee 17+ et la categorie « Soiree » assume l'alcool
        # (choix produit du 17 aout) : seules les lignes rouges 18+ s'appliquent.
        ok &= check("WordBank (paires)", pairs, 60, adult=True)
        words = {}
        for a, b in raw:
            for w in (a, b):
                words[w.lower()] = words.get(w.lower(), 0) + 1
        reused = [w for w, c in words.items() if c > 1]
        if reused:
            print(f"  ECHEC mots réutilisés entre paires : {reused[:6]}")
            ok = False
        long_words = sorted({w for a, b in raw for w in (a, b) if len(w) > 24})
        if long_words:
            print(f"  ECHEC mots > 24 car. : {long_words[:4]}")
            ok = False
    return ok


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    sys.exit(0 if run(target) else 1)
