# Test OME-TIFF - Guide rapide

> **⚠️ OBSOLETE - VERSION 3.10 UPDATE**
>
> Ce document décrit les tests pour l'injection OME-XML qui est **désactivée par défaut** dans la version 3.10 pour éviter la corruption des fichiers TIFF pyramidaux volumineux.
>
> **Pour l'utilisation actuelle v3.10**, voir `QuPath_Import_Instructions.md` qui explique la méthode recommandée avec fichiers sidecar.
>
> Ce document est conservé pour référence uniquement.

---

## Problèmes corrigés (v3.7.1) - Historique

### ✅ Problème 1 : Erreur d'encodage Unicode
**Erreur :** `UnicodeEncodeError: 'charmap' codec can't encode character '\u2717'`

**Correction :**
- Forcé l'encodage UTF-8 dans le script Python
- Remplacé les caractères Unicode (✓ ✗) par ASCII ([OK] [FAILED])
- Ajouté variables d'environnement `PYTHONIOENCODING=utf-8` et `PYTHONUTF8=1`

### ✅ Problème 2 : Mémoire insuffisante pour lire dimensions
**Erreur :** `System.Drawing: Mémoire insuffisante` (fichier 7.8 GB)

**Correction :**
- Utilise maintenant `vipsheader` au lieu de System.Drawing
- Lit width/height sans charger l'image complète en mémoire
- Fallback sur dimensions par défaut si vipsheader échoue

### ✅ Problème 3 : Option --properties interférait avec OME-XML
**Problème :** `--properties` écrivait métadonnées VIPS dans IMAGEDESCRIPTION

**Correction :**
- Retiré `--properties` de la commande tiffsave
- IMAGEDESCRIPTION reste vide pour injection OME-XML par Python

## Étape 1 : Vérifier Python et bibliothèques

Exécutez :
```cmd
install_python_libs.bat
```

Vous devriez voir :
```
[OK] tifftools est installé
```

Si tifftools n'est pas installé, le script l'installera automatiquement.

## Étape 2 : Tester la fusion

1. Lancez `TIFF-Channel-Merger.bat`
2. Fusionnez vos 5 images avec des noms de canaux
3. Attendez la fin

## Étape 3 : Vérifier les résultats

### Succès attendu :

Vous devriez voir dans les logs :
```
=== Attempting to create true OME-TIFF ===
Injecting OME-XML into TIFF IMAGEDESCRIPTION tag...
Python found: C:\...\python.exe
Running: python inject_ome_xml.py ...

TIFF file: C:\...\merged_channels.tif
OME-XML file: C:\...\merged_channels.ome.xml
OME-XML length: XXXX bytes

Backup created: C:\...\merged_channels.tif.backup_before_ome

Trying method: tifftools...
[OK] SUCCESS: OME-XML injected with tifftools (preserves all pyramid levels)

OME-TIFF created successfully!

🎉 OME-TIFF CREATED SUCCESSFULLY!
   Channel names embedded directly in TIFF file

🔬 QuPath usage:
  1. Open merged_channels.tif in QuPath
  2. Channel names automatically recognized: DAPI, FITC, Alexa 546, CY5, CY7
  3. Ready for analysis!
```

### Si échec :

Si vous voyez encore des erreurs, vérifiez :

1. **Python installé ?**
   ```cmd
   python --version
   ```

2. **Bibliothèque installée ?**
   ```cmd
   python -c "import tifftools; print('OK')"
   ```

3. **Permissions d'écriture ?**
   - Vérifiez que vous pouvez écrire dans le dossier de destination

## Étape 4 : Tester dans QuPath

1. Ouvrez QuPath
2. Drag & drop le fichier `merged_channels.tif`
3. Allez dans : `View` → `Brightness/Contrast` (Shift+C)
4. **Vérifiez que les noms de canaux apparaissent :**
   - Canal 1 : DAPI
   - Canal 2 : FITC
   - Canal 3 : Alexa 546
   - Canal 4 : CY5
   - Canal 5 : CY7

Si les noms apparaissent automatiquement → **SUCCÈS !** 🎉

Si les noms n'apparaissent pas :
- Vérifiez que l'injection OME-XML a réussi (logs)
- Utilisez le script Groovy de fallback

## Dépannage

### Erreur : tifftools not installed

```cmd
pip install tifftools
```

### Erreur : Permission denied

```cmd
pip install --user tifftools
```

### Python non trouvé

Installez Python depuis python.org et cochez "Add Python to PATH"

## Fichiers de sortie

Après fusion réussie, vous aurez :
- `merged_channels.tif` - TIFF pyramidal avec OME-XML intégré
- `merged_channels.tif.backup_before_ome` - Backup avant injection
- `merged_channels.ome.xml` - Sidecar XML (pour référence)
- `merged_channels_channels.txt` - Liste des noms de canaux
- Fichiers de logs (vips_*.log)
