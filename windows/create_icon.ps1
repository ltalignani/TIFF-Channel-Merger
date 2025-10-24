# Script to create icon with 3 stacked TIFF files
# This creates a simple icon using .NET Drawing classes

Add-Type -AssemblyName System.Drawing

$iconSize = 256
$bitmap = New-Object System.Drawing.Bitmap($iconSize, $iconSize)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Background (transparent)
$graphics.Clear([System.Drawing.Color]::Transparent)

# Define colors
$fileColor1 = [System.Drawing.Color]::FromArgb(255, 70, 130, 180)  # Steel blue
$fileColor2 = [System.Drawing.Color]::FromArgb(255, 100, 160, 210) # Lighter blue
$fileColor3 = [System.Drawing.Color]::FromArgb(255, 130, 190, 240) # Lightest blue
$borderColor = [System.Drawing.Color]::FromArgb(255, 40, 80, 120)  # Dark blue

# Function to draw a file/document icon
function Draw-FileIcon($g, $x, $y, $width, $height, $fillColor, $borderColor) {
    $cornerSize = [int]($width * 0.2)

    # Create path for document shape with folded corner
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath

    # Main rectangle
    $path.AddLine($x, $y, $x + $width - $cornerSize, $y)
    $path.AddLine($x + $width - $cornerSize, $y, $x + $width, $y + $cornerSize)
    $path.AddLine($x + $width, $y + $cornerSize, $x + $width, $y + $height)
    $path.AddLine($x + $width, $y + $height, $x, $y + $height)
    $path.AddLine($x, $y + $height, $x, $y)
    $path.CloseFigure()

    # Fill
    $brush = New-Object System.Drawing.SolidBrush($fillColor)
    $g.FillPath($brush, $path)

    # Border
    $pen = New-Object System.Drawing.Pen($borderColor, 3)
    $g.DrawPath($pen, $path)

    # Folded corner
    $cornerPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $cornerPath.AddLine($x + $width - $cornerSize, $y, $x + $width - $cornerSize, $y + $cornerSize)
    $cornerPath.AddLine($x + $width - $cornerSize, $y + $cornerSize, $x + $width, $y + $cornerSize)
    $cornerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 200, 200, 200))
    $g.FillPath($cornerBrush, $cornerPath)
    $g.DrawPath($pen, $cornerPath)

    # Draw TIFF text on the file
    $font = New-Object System.Drawing.Font("Arial", [int]($height * 0.15), [System.Drawing.FontStyle]::Bold)
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

    $textRect = New-Object System.Drawing.RectangleF($x, $y + $height * 0.4, $width - $cornerSize, $height * 0.3)
    $g.DrawString("TIFF", $font, $textBrush, $textRect, $stringFormat)

    $brush.Dispose()
    $pen.Dispose()
    $cornerBrush.Dispose()
    $font.Dispose()
    $textBrush.Dispose()
    $path.Dispose()
    $cornerPath.Dispose()
}

# Draw 3 stacked files with 3D effect (perspective)
$fileWidth = 160
$fileHeight = 200
$offsetX = 20
$offsetY = 15

# Back file (darkest)
Draw-FileIcon $graphics (30 + $offsetX * 2) (20 + $offsetY * 2) $fileWidth $fileHeight $fileColor1 $borderColor

# Middle file
Draw-FileIcon $graphics (30 + $offsetX) (20 + $offsetY) $fileWidth $fileHeight $fileColor2 $borderColor

# Front file (lightest)
Draw-FileIcon $graphics 30 20 $fileWidth $fileHeight $fileColor3 $borderColor

# Save as PNG first (for preview)
$pngPath = Join-Path $PSScriptRoot "tiff-merger-icon.png"
$bitmap.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "PNG icon saved: $pngPath"

# Convert to ICO format (multiple sizes)
# For .ico, we need to create multiple resolutions
$iconPath = Join-Path $PSScriptRoot "tiff-merger-icon.ico"

# Create icon with multiple sizes: 16x16, 32x32, 48x48, 256x256
$sizes = @(16, 32, 48, 256)
$bitmaps = @()

foreach ($size in $sizes) {
    $smallBitmap = New-Object System.Drawing.Bitmap($size, $size)
    $smallGraphics = [System.Drawing.Graphics]::FromImage($smallBitmap)
    $smallGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $smallGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $smallGraphics.DrawImage($bitmap, 0, 0, $size, $size)
    $bitmaps += $smallBitmap
}

# Save as ICO using Icon.FromHandle (simple approach)
try {
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    $stream = [System.IO.File]::Create($iconPath)
    $icon.Save($stream)
    $stream.Close()
    Write-Host "ICO icon saved: $iconPath"
} catch {
    Write-Host "Could not create ICO file directly. Using PNG fallback."
    Write-Host "To create a proper .ico file, use an online converter or ImageMagick:"
    Write-Host "  magick convert tiff-merger-icon.png -define icon:auto-resize=256,48,32,16 tiff-merger-icon.ico"
}

# Cleanup
$graphics.Dispose()
$bitmap.Dispose()
foreach ($bmp in $bitmaps) {
    $bmp.Dispose()
}

Write-Host ""
Write-Host "Icon created successfully!"
Write-Host "PNG: $pngPath (use this for preview)"
Write-Host "ICO: $iconPath (use this for Windows shortcuts)"
