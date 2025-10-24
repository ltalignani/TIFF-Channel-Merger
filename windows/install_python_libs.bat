@echo off
chcp 65001 >nul
echo.
echo ======================================================
echo  Installation des bibliothèques Python pour OME-TIFF
echo ======================================================
echo.

:: Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Python n'est pas installé ou pas dans le PATH
    echo.
    echo Téléchargez Python depuis: https://www.python.org/downloads/
    echo IMPORTANT: Cochez "Add Python to PATH" pendant l'installation
    echo.
    pause
    exit /b 1
)

echo Python détecté:
python --version
echo.

echo Installation de tifftools (recommandé)...
python -m pip install --upgrade tifftools
echo.

if errorlevel 0 (
    echo [OK] tifftools installé avec succès!
    echo.
    echo Vous pouvez maintenant utiliser TIFF Channel Merger
    echo avec support automatique des noms de canaux dans QuPath!
) else (
    echo [ATTENTION] L'installation a échoué
    echo.
    echo Essayons avec des alternatives...
    echo.

    echo Installation de tifffile...
    python -m pip install --upgrade tifffile
    echo.

    echo Installation de Pillow...
    python -m pip install --upgrade Pillow
)

echo.
echo ======================================================
echo  Installation terminée
echo ======================================================
echo.
echo Vérification des bibliothèques installées:
python -c "import sys; print('Python:', sys.version)"
echo.
python -c "try: import tifftools; print('[OK] tifftools est installé')\nexcept: print('[--] tifftools non disponible')"
python -c "try: import tifffile; print('[OK] tifffile est installé')\nexcept: print('[--] tifffile non disponible')"
python -c "try: from PIL import Image; print('[OK] Pillow est installé')\nexcept: print('[--] Pillow non disponible')"
echo.
pause
