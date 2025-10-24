@echo off
chcp 65001 >nul
echo.
echo === Vérification de la compression TIFF ===
echo.

if "%~1"=="" (
    echo Usage: check_tiff_compression.bat "chemin\vers\fichier.tif"
    echo.
    echo Exemple:
    echo   check_tiff_compression.bat "C:\Images\image.tif"
    echo.
    pause
    exit /b 1
)

set VIPSPATH=%LOCALAPPDATA%\vips\bin\vipsheader.exe

if not exist "%VIPSPATH%" (
    echo ERREUR: vipsheader non trouvé
    echo Installez VIPS d'abord
    pause
    exit /b 1
)

echo Fichier: %~1
echo.

echo Informations de base:
"%VIPSPATH%" --all "%~1" | findstr /i "width height bands format coding compression"
echo.

echo Compression détectée:
"%VIPSPATH%" -f compression "%~1"
echo.

pause
