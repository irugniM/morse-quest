# Builds the Connect IQ Store cover (500x500) and hero (1440x720) images.
# Run from the project folder: powershell -File tools\make-store-art.ps1
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$shots = Join-Path $root 'store-screenshots'
$out = Join-Path $root 'store-art'
New-Item -ItemType Directory -Force $out | Out-Null

$white  = [System.Drawing.Color]::White
$orange = [System.Drawing.Color]::FromArgb(255, 255, 106, 19)
$grey   = [System.Drawing.Color]::FromArgb(255, 150, 150, 150)
$bg     = [System.Drawing.Color]::FromArgb(255, 12, 12, 12)

function New-Canvas($w, $h) {
    $b = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear($bg)
    return @($b, $g)
}

function Draw-RoundRect($g, $brush, $x, $y, $w, $h, $r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc($x, $y, 2*$r, 2*$r, 180, 90)
    $p.AddArc($x + $w - 2*$r, $y, 2*$r, 2*$r, 270, 90)
    $p.AddArc($x + $w - 2*$r, $y + $h - 2*$r, 2*$r, 2*$r, 0, 90)
    $p.AddArc($x, $y + $h - 2*$r, 2*$r, 2*$r, 90, 90)
    $p.CloseFigure()
    $g.FillPath($brush, $p)
}

# Dot-dash mark: "-- --.-" style row (M Q = -- --.-), drawn as discs and bars.
function Draw-Code($g, $code, $x, $y, $u, $color) {
    $br = New-Object System.Drawing.SolidBrush $color
    foreach ($c in $code.ToCharArray()) {
        if ($c -eq '.') { $g.FillEllipse($br, $x, $y - $u, 2*$u, 2*$u); $x += 3*$u }
        elseif ($c -eq '-') { Draw-RoundRect $g $br $x ($y - $u) (5*$u) (2*$u) $u; $x += 6*$u }
        elseif ($c -eq ' ') { $x += 3*$u }
    }
}
function Code-Width($code, $u) {
    $w = 0
    foreach ($c in $code.ToCharArray()) { if ($c -eq '.') { $w += 3*$u } elseif ($c -eq '-') { $w += 6*$u } elseif ($c -eq ' ') { $w += 3*$u } }
    return $w - $u
}

# Round watch screen showing a screenshot, with a bezel ring.
function Draw-Watch($g, $shotPath, $cx, $cy, $d) {
    $img = [System.Drawing.Image]::FromFile($shotPath)
    $ring = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 45, 45, 45))
    $g.FillEllipse($ring, $cx - $d/2 - 18, $cy - $d/2 - 18, $d + 36, $d + 36)
    $accent = New-Object System.Drawing.Pen $orange, 6
    $g.DrawEllipse($accent, $cx - $d/2 - 9, $cy - $d/2 - 9, $d + 18, $d + 18)
    $clip = New-Object System.Drawing.Drawing2D.GraphicsPath
    $clip.AddEllipse($cx - $d/2, $cy - $d/2, $d, $d)
    $state = $g.Save()
    $g.SetClip($clip)
    $g.FillEllipse([System.Drawing.Brushes]::Black, $cx - $d/2, $cy - $d/2, $d, $d)
    $g.InterpolationMode = 'NearestNeighbor'
    $g.PixelOffsetMode = 'Half'
    # Inset slightly so text near the screen edge isn't cut by the round mask.
    $s = $d * 0.92
    $g.DrawImage($img, [int]($cx - $s/2), [int]($cy - $s/2), [int]$s, [int]$s)
    $g.Restore($state)
    $img.Dispose()
}

$fTitle = New-Object System.Drawing.Font 'Segoe UI', 64, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fSub   = New-Object System.Drawing.Font 'Segoe UI', 28, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$wb = New-Object System.Drawing.SolidBrush $white
$ob = New-Object System.Drawing.SolidBrush $orange
$gb = New-Object System.Drawing.SolidBrush $grey
$center = New-Object System.Drawing.StringFormat; $center.Alignment = 'Center'; $center.LineAlignment = 'Center'
$left = New-Object System.Drawing.StringFormat; $left.Alignment = 'Near'; $left.LineAlignment = 'Center'

# ---------- cover 500x500 ----------
$b, $g = New-Canvas 500 500
Draw-Watch $g (Join-Path $shots '04-combo.png') 250 205 250
$g.DrawString('MORSE QUEST', (New-Object System.Drawing.Font 'Segoe UI', 54, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)), $wb, (New-Object System.Drawing.RectangleF 0, 375, 500, 64), $center)
$code = '-- --.-'
$u = 7
Draw-Code $g $code ((500 - (Code-Width $code $u)) / 2) 452 $u $orange
$g.Dispose()
$b.Save((Join-Path $out 'cover-500.png'), [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()

# ---------- hero 1440x720 ----------
$b, $g = New-Canvas 1440 720
Draw-Watch $g (Join-Path $shots '07-level-up.png') 1085 360 420
$g.DrawString('MORSE QUEST', $fTitle, $wb, (New-Object System.Drawing.RectangleF 110, 200, 800, 90), $left)
$fBig = New-Object System.Drawing.Font 'Segoe UI', 40, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString('Crack codes by feel.', $fBig, $ob, (New-Object System.Drawing.RectangleF 110, 290, 800, 60), $left)
$g.DrawString('Your watch buzzes a letter.', $fSub, $wb, (New-Object System.Drawing.RectangleF 110, 370, 800, 40), $left)
$g.DrawString('Tap it back without looking.', $fSub, $wb, (New-Object System.Drawing.RectangleF 110, 410, 800, 40), $left)
$g.DrawString('17 levels  -  combos  -  daily cipher', $fSub, $gb, (New-Object System.Drawing.RectangleF 110, 470, 800, 40), $left)
Draw-Code $g '-- --.-' 112 560 9 $orange
$g.Dispose()
$b.Save((Join-Path $out 'hero-1440x720.png'), [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()

Get-ChildItem $out | ForEach-Object { "{0} {1} KB" -f $_.Name, [math]::Round($_.Length / 1KB, 1) }
