@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
echo.
echo ================================================================
echo  Conversion JPEG-XR vers TIFF standard (pour fusion)
echo ================================================================
echo.
echo Ce script convertit les TIFFs avec compression JPEG-XR
echo en TIFFs standard avec compression LZW pour éviter les
echo problèmes lors de la fusion et de l'ouverture dans QuPath.
echo.

if "%~1"=="" (
    echo Usage: convert_jpegxr_to_standard_tiff.bat "dossier_source"
    echo.
    echo Exemple:
    echo   convert_jpegxr_to_standard_tiff.bat "C:\Images\JPEG-XR"
    echo.
    echo Tous les fichiers .tif du dossier seront convertis
    echo et sauvegardés dans un sous-dossier "converted\"
    echo.
    pause
    exit /b 1
)

set SOURCE_DIR=%~1
set OUTPUT_DIR=%SOURCE_DIR%\converted
set VIPSPATH=%LOCALAPPDATA%\vips\bin\vips.exe

if not exist "%VIPSPATH%" (
    echo ERREUR: VIPS non trouvé
    echo Installez VIPS via le TIFF Channel Merger
    pause
    exit /b 1
)

if not exist "%SOURCE_DIR%" (
    echo ERREUR: Dossier source non trouvé: %SOURCE_DIR%
    pause
    exit /b 1
)

echo Dossier source: %SOURCE_DIR%
echo Dossier sortie: %OUTPUT_DIR%
echo.

:: Create output directory
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
    echo Dossier créé: %OUTPUT_DIR%
)

echo.
echo Conversion en cours...
echo.

set COUNT=0
set SUCCESS=0
set FAILED=0

for %%F in ("%SOURCE_DIR%\*.tif" "%SOURCE_DIR%\*.tiff") do (
    if exist "%%F" (
        set /a COUNT+=1
        echo [!COUNT!] Conversion: %%~nxF

        :: Convert with VIPS: decompress completely and save with LZW
        "%VIPSPATH%" copy "%%F" "%OUTPUT_DIR%\%%~nxF" --sequential

        if !ERRORLEVEL! equ 0 (
            set /a SUCCESS+=1
            echo     [OK] Converti avec succès
        ) else (
            set /a FAILED+=1
            echo     [ERREUR] Échec de conversion
        )
        echo.
    )
)

echo ================================================================
echo  Résumé de conversion
echo ================================================================
echo Total fichiers traités: %COUNT%
echo Succès: %SUCCESS%
echo Échecs: %FAILED%
echo.
echo Fichiers convertis disponibles dans:
echo %OUTPUT_DIR%
echo.
echo IMPORTANT: Utilisez les fichiers du dossier "converted"
echo pour la fusion avec TIFF Channel Merger!
echo.
pause
