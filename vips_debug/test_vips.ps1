# Test VIPS installation and options
$vipsPath = "$env:LOCALAPPDATA\vips\bin\vips.exe"

Write-Host "=== VIPS Installation Check ===" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $vipsPath) {
    Write-Host "✓ VIPS trouvé: $vipsPath" -ForegroundColor Green
    Write-Host ""

    # Version
    Write-Host "Version VIPS:" -ForegroundColor Yellow
    & $vipsPath --version
    Write-Host ""

    # Test if copy command exists
    Write-Host "=== Commande 'copy' ===" -ForegroundColor Yellow
    & $vipsPath copy 2>&1 | Select-Object -First 50
    Write-Host ""

    # List all available operations
    Write-Host "=== Opérations disponibles pour TIFF ===" -ForegroundColor Yellow
    & $vipsPath -l 2>&1 | Select-String "copy|tiff|sequential" | Select-Object -First 20

} else {
    Write-Host "✗ VIPS non trouvé à: $vipsPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Emplacements possibles:" -ForegroundColor Yellow
    @(
        "$env:ProgramFiles\vips\bin\vips.exe",
        "$env:ProgramFiles(x86)\vips\bin\vips.exe",
        "$env:LOCALAPPDATA\vips\bin\vips.exe"
    ) | ForEach-Object {
        if (Test-Path $_) {
            Write-Host "  TROUVÉ: $_" -ForegroundColor Green
        } else {
            Write-Host "  Non trouvé: $_" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "Appuyez sur Entree pour continuer..."
Read-Host
