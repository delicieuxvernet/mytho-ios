<#
    Taupe — dernier branchement de la CI
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
    directement dans les secrets GitHub du repo taupe-ios.
#>

param(
    [Parameter(Mandatory = $true)][string]$P8,
    [Parameter(Mandatory = $true)][string]$KeyId,
    [Parameter(Mandatory = $true)][string]$IssuerId,
    [string]$Repo = "delicieuxvernet/taupe-ios"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $P8)) { throw "Fichier introuvable : $P8" }
if ([System.IO.Path]::GetExtension($P8) -ne '.p8') { throw "Le fichier doit etre un .p8 : $P8" }

# La cle est encodee en base64 puis transmise a gh via stdin : elle ne transite
# ni par la ligne de commande (visible dans l'historique) ni par l'ecran.
$bytes = [System.IO.File]::ReadAllBytes($P8)
$b64 = [System.Convert]::ToBase64String($bytes)

$b64      | gh secret set ASC_API_KEY_BASE64 --repo $Repo
$KeyId    | gh secret set ASC_KEY_ID         --repo $Repo
$IssuerId | gh secret set ASC_ISSUER_ID      --repo $Repo

Write-Host ""
Write-Host "  Secrets App Store Connect poses sur $Repo" -ForegroundColor Green
gh secret list --repo $Repo

Write-Host ""
Write-Host "  Etape suivante : creer le certificat et le profil (une seule fois)" -ForegroundColor Yellow
Write-Host "    gh workflow run bootstrap.yml --repo $Repo"
Write-Host ""
Write-Host "  Prerequis Apple a faire AVANT ce workflow :" -ForegroundColor Yellow
Write-Host "    1. developer.apple.com  -> Identifiers -> (+) App IDs -> App"
Write-Host "       Bundle ID explicite : fr.taupe.app   (aucune capability requise)"
Write-Host "    2. appstoreconnect.apple.com -> Apps -> (+) Nouvelle app"
Write-Host "       iOS, bundle fr.taupe.app, langue Francais, SKU taupe-ios-001"
Write-Host ""
