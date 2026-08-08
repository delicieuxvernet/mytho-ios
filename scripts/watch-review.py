# Etat de la review App Store, en une ligne.
#   python scripts/watch-review.py
#
# Sert a la surveillance en boucle : la sortie est stable et comparable d'un
# appel a l'autre, donc un changement de ligne = un changement d'etat reel.
import json
import os
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

    print(f"{number} | version={state} | soumission={sub_state}{rejection}")


if __name__ == "__main__":
    main()
