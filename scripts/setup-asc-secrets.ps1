<#
    Mytho — dernier branchement de la CI
    ------------------------------------
    Quatre des sept secrets sont deja poses (match + team Apple). Il manque la
    cle API App Store Connect, qui ne peut pas etre recuperee : Apple ne laisse
    telecharger le fichier .p8 qu'une seule fois.

      powershell -ExecutionPolicy Bypass -File scripts\setup-asc-secrets.ps1 `
        -P8 "C:\chemin\vers\AuthKey_XXXXXXXXXX.p8" `
        -KeyId "XXXXXXXXXX" `
        -IssuerId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    Ou trouver ces trois valeurs :
      appstoreconnect.apple.com -> Utilisateurs et acces -> Integrations -> Cles
      - Si une cle EQUIPE avec role ADMIN existe deja et que tu as garde son .p8,
        reutilise-la : Key ID et Issuer ID sont affiches dans le tableau.
      - Sinon : (+) pour generer une cle, acces ADMIN, telecharge le .p8.
        /!\ Le telechargement n'est possible qu'une fois — range le fichier.

    Le script n'affiche jamais le contenu de la cle. Il l'encode et l'envoie
    directement dans les secrets GitHub du repo mytho-ios.
#>

param(
    [Parameter(Mandatory = $true)][string]$P8,
    [Parameter(Mandatory = $true)][string]$KeyId,
    [Parameter(Mandatory = $true)][string]$IssuerId,
    [string]$Repo = "delicieuxvernet/mytho-ios"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $P8)) { throw "Fichier introuvable : $P8" }
if ([System.IO.Path]::GetExtension($P8) -ne '.p8') { throw "Le fichier doit etre un .p8 : $P8" }

# La cle est encodee en base64 et transmise via --body : jamais affichee.
# /!\ Ne PAS piper les valeurs a gh via `|` : le pipeline PowerShell ajoute un
# retour a la ligne final, qui corrompt le Key ID dans le JWT -> l'API Apple
# repond « Authentication credentials are missing or invalid » (vecu 3 aout 2026,
# run 30854396897).
$bytes = [System.IO.File]::ReadAllBytes($P8)
$b64 = [System.Convert]::ToBase64String($bytes)

gh secret set ASC_API_KEY_BASE64 --repo $Repo --body $b64
gh secret set ASC_KEY_ID         --repo $Repo --body $KeyId
gh secret set ASC_ISSUER_ID      --repo $Repo --body $IssuerId

Write-Host ""
Write-Host "  Secrets App Store Connect poses sur $Repo" -ForegroundColor Green
gh secret list --repo $Repo

Write-Host ""
Write-Host "  Etape suivante : creer le certificat et le profil (une seule fois)" -ForegroundColor Yellow
Write-Host "    gh workflow run bootstrap.yml --repo $Repo"
Write-Host ""
Write-Host "  Prerequis Apple a faire AVANT ce workflow :" -ForegroundColor Yellow
Write-Host "    1. developer.apple.com  -> Identifiers -> (+) App IDs -> App"
Write-Host "       Bundle ID explicite : fr.mytho.app   (aucune capability requise)"
Write-Host "    2. appstoreconnect.apple.com -> Apps -> (+) Nouvelle app"
Write-Host "       iOS, bundle fr.mytho.app, langue Francais, SKU mytho-ios-001"
Write-Host ""
