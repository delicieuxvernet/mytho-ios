# Génère l'icône de l'app (1024x1024, sans canal alpha — exigence App Store).
# Chapeau de feutre blanc sur dégradé violet nuit.
#   powershell -ExecutionPolicy Bypass -File scripts\make-appicon.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$size = 1024
$out = Join-Path $PSScriptRoot '..\Taupe\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon.png'
$out = [System.IO.Path]::GetFullPath($out)

# 24 bits par pixel : pas de canal alpha, l'App Store refuse les icônes transparentes.
$bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# Fond : dégradé diagonal violet -> nuit
$rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
$c1 = [System.Drawing.Color]::FromArgb(255, 108, 92, 240)
$c2 = [System.Drawing.Color]::FromArgb(255, 14, 17, 45)
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 55.0)
$g.FillRectangle($brush, $rect)
$brush.Dispose()

# Halo doux derrière le chapeau
$halo = New-Object System.Drawing.Drawing2D.GraphicsPath
$halo.AddEllipse(160, 190, 704, 704)
$haloBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($halo)
$haloBrush.CenterColor = [System.Drawing.Color]::FromArgb(70, 255, 255, 255)
$haloBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
$g.FillPath($haloBrush, $halo)
$haloBrush.Dispose(); $halo.Dispose()

$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$band = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 24, 27, 58))

# Calotte : flancs droits et dessus pince, la silhouette d'un feutre.
$crown = New-Object System.Drawing.Drawing2D.GraphicsPath
$crown.AddBezier(320, 600, 318, 430, 336, 340, 372, 306)   # flanc gauche
$crown.AddBezier(372, 306, 404, 278, 440, 322, 512, 322)   # creux gauche du pincement
$crown.AddBezier(512, 322, 584, 322, 620, 278, 652, 306)   # creux droit
$crown.AddBezier(652, 306, 688, 340, 706, 430, 704, 600)   # flanc droit
$crown.AddLine(704, 600, 320, 600)
$crown.CloseFigure()
$g.FillPath($white, $crown)
$crown.Dispose()

# Bandeau sombre, posé juste au-dessus de l'aile.
$g.FillRectangle($band, 318, 512, 388, 96)

# Aile : large ellipse, releve legerement sur les cotes.
$g.FillEllipse($white, 148, 566, 728, 188)

$white.Dispose(); $band.Dispose(); $g.Dispose()

$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host ("Icone ecrite : {0}" -f $out)
