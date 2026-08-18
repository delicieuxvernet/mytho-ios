# Etat de la review App Store, en une ligne.
#   python scripts/watch-review.py        -> ligne stable, pour la surveillance
#   python scripts/watch-review.py --fr   -> une phrase, pour un humain
#
# Sert a la surveillance en boucle : la sortie par defaut est stable et
# comparable d'un appel a l'autre, donc un changement de ligne = un changement
# d'etat reel. Ne jamais la reformater.
import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt

KEY_ID = os.environ.get("ASC_KEY_ID", "HW9K8HFRVJ")
ISSUER = os.environ.get("ASC_ISSUER_ID", "3092a93a-568d-4af0-ab37-0724774622a7")
KEY_PATH = os.environ.get("ASC_KEY_PATH", r"C:\Users\stana\Downloads\AuthKey_HW9K8HFRVJ.p8")
APP_ID = "6797652496"
BASE = "https://api.appstoreconnect.apple.com"


def token() -> str:
    with open(KEY_PATH) as handle:
        key = handle.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def get(path: str, bearer: str):
    request = urllib.request.Request(BASE + path, headers={"Authorization": f"Bearer {bearer}"})
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        return json.loads(error.read().decode() or "{}")


def main() -> None:
    bearer = token()

    versions = get(f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1", bearer)
    version = versions.get("data", [{}])[0].get("attributes", {})
    state = version.get("appStoreState", "INCONNU")
    number = version.get("versionString", "?")

    submissions = get(f"/v1/reviewSubmissions?filter[app]={APP_ID}&limit=1", bearer)
    submission = submissions.get("data", [{}])
    sub_state = submission[0].get("attributes", {}).get("state", "AUCUNE") if submission else "AUCUNE"

    # Le motif de refus n'apparait que sur la resolution du centre de messages.
    rejection = ""
    if state in {"REJECTED", "DEVELOPER_REJECTED", "METADATA_REJECTED"}:
        rejection = " | REFUS : consulter App Store Connect > Centre de messages"

    if "--fr" not in sys.argv:
        # Sortie stable, comparable d'un appel a l'autre : c'est elle que la
        # surveillance automatique lit. Ne pas la reformater.
        print(f"{number} | version={state} | soumission={sub_state}{rejection}")
        return

    # Sortie pour un humain : « ou en est mon app, en une phrase ».
    build = get(f"/v1/appStoreVersions/{versions['data'][0]['id']}/build", bearer)
    numero = (build.get("data") or {}).get("attributes", {}).get("version", "?")
    phrases = {
        "PREPARE_FOR_SUBMISSION": "prete, mais PAS encore envoyee a Apple",
        "WAITING_FOR_REVIEW": "dans la file d'attente d'Apple (24-48 h en general)",
        "IN_REVIEW": "en cours d'examen par Apple, en ce moment meme",
        "PENDING_DEVELOPER_RELEASE": "ACCEPTEE — il ne reste qu'a appuyer sur publier",
        "READY_FOR_SALE": "EN LIGNE sur l'App Store",
        "PROCESSING_FOR_APP_STORE": "acceptee, Apple prepare la mise en ligne",
        "REJECTED": "REFUSEE par Apple — le motif est dans le centre de messages",
        "METADATA_REJECTED": "REFUSEE sur la fiche (textes ou captures)",
        "DEVELOPER_REJECTED": "retiree de la file par nous",
        "INVALID_BINARY": "build refuse techniquement par Apple",
    }
    print(f"Version {number} (build #{numero}) : {phrases.get(state, state)}.")
    if state in {"WAITING_FOR_REVIEW", "IN_REVIEW"}:
        print("Rien a faire : la publication se declenchera toute seule si Apple accepte.")


if __name__ == "__main__":
    main()
