# Génère l'icône de l'app : l'œil reptilien à plat, signature de Mytho.
# 1024x1024, SANS canal alpha — l'App Store refuse les icônes transparentes.
#   powershell -ExecutionPolicy Bypass -File scripts\make-appicon.ps1
#
# DA v2 « jeu de société dessiné » : aplats francs, gros contours encrés, aucun
# dégradé, aucun flou. Les formes reprennent celles de ReptileEyeView pour que
# l'icône et l'app racontent la même chose.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$size = 1024
$out = Join-Path $PSScriptRoot '..\Mytho\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon.png'
$out = [System.IO.Path]::GetFullPath($out)

# 24 bits par pixel : pas de canal alpha.
$bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Palette alignée sur Theme.swift.
$violet   = [System.Drawing.Color]::FromArgb(255, 108, 92, 240)   # Theme.brand
$encre    = [System.Drawing.Color]::FromArgb(255, 34, 30, 51)     # Skin.day.outline
$vertNuit = [System.Drawing.Color]::FromArgb(255, 18, 59, 42)
$menthe   = [System.Drawing.Color]::FromArgb(255, 52, 211, 153)   # Theme.mint
$iris     = [System.Drawing.Color]::FromArgb(255, 124, 232, 184)
$pupille  = [System.Drawing.Color]::FromArgb(255, 4, 21, 13)
$reflet   = [System.Drawing.Color]::FromArgb(235, 255, 255, 255)

$g.Clear($violet)

function New-CircleRect([double]$cx, [double]$cy, [double]$r) {
    New-Object System.Drawing.RectangleF(
        [float]($cx - $r), [float]($cy - $r), [float]($r * 2), [float]($r * 2))
}

# Marge volontairement large : l'icône survit au masque arrondi d'iOS comme au
# recadrage circulaire de la Watch sans que l'œil soit rogné.
$cx = $size / 2.0
$cy = $size / 2.0
$rExt = $size * 0.34

$brushGlobe = New-Object System.Drawing.SolidBrush($vertNuit)
$g.FillEllipse($brushGlobe, (New-CircleRect $cx $cy $rExt))
$penEncre = New-Object System.Drawing.Pen($encre, [float]($size * 0.042))
$g.DrawEllipse($penEncre, (New-CircleRect $cx $cy $rExt))

$penMenthe = New-Object System.Drawing.Pen($menthe, [float]($size * 0.030))
$g.DrawEllipse($penMenthe, (New-CircleRect $cx $cy ($rExt * 0.86)))

$rIris = $rExt * 0.56
$brushIris = New-Object System.Drawing.SolidBrush($iris)
$g.FillEllipse($brushIris, (New-CircleRect $cx $cy $rIris))
$penIris = New-Object System.Drawing.Pen($encre, [float]($size * 0.030))
$g.DrawEllipse($penIris, (New-CircleRect $cx $cy $rIris))

# Pupille fendue verticale : c'est elle qui rend l'œil reptilien.
$pw = $rIris * 0.30
$ph = $rIris * 1.62
$brushPupille = New-Object System.Drawing.SolidBrush($pupille)
$g.FillEllipse($brushPupille, (New-Object System.Drawing.RectangleF(
    [float]($cx - $pw / 2), [float]($cy - $ph / 2), [float]$pw, [float]$ph)))

# Reflet : un aplat franc, jamais un dégradé.
$brushReflet = New-Object System.Drawing.SolidBrush($reflet)
$g.FillEllipse($brushReflet, (New-Object System.Drawing.RectangleF(
    [float]($cx - $rIris * 0.46), [float]($cy - $rIris * 0.52),
    [float]($rIris * 0.34), [float]($rIris * 0.21))))

$brushGlobe.Dispose(); $penEncre.Dispose(); $penMenthe.Dispose()
$brushIris.Dispose(); $penIris.Dispose(); $brushPupille.Dispose()
$brushReflet.Dispose(); $g.Dispose()

$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host ("Icone ecrite : {0}" -f $out)
