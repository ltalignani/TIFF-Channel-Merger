# Problème JPEG-XR et Solution

## 🔴 Le Problème

Lorsque vous fusionnez des fichiers TIFF qui utilisent la **compression JPEG-XR** (format propriétaire Microsoft), QuPath affiche cette erreur :

```
Error reading IFD type at: 12
Unable to open file: merged_channels.tif
java.io.IOException: Unable to open file
```

### Pourquoi ce problème ?

1. **JPEG-XR** (aussi appelé HD Photo ou TIFF code 22610) est une compression propriétaire Microsoft
2. Ce format est **mal supporté** par la plupart des outils scientifiques
3. VIPS peut lire les fichiers JPEG-XR, mais le TIFF fusionné résultant peut avoir des **métadonnées IFD corrompues**
4. QuPath et autres logiciels d'analyse ne peuvent pas lire ces TIFFs corrompus

### Comment vérifier si vos fichiers sont en JPEG-XR ?

Utilisez le script fourni :

```cmd
check_tiff_compression.bat "chemin\vers\votre\fichier.tif"
```

Si vous voyez `compression: jpegxr` ou `compression: 22610`, c'est du JPEG-XR.

## ✅ Solutions

### Solution 1 : Convertir AVANT la fusion (RECOMMANDÉ)

C'est la méthode la plus sûre pour éviter tout problème.

#### Étape 1 : Convertir tous vos fichiers

```cmd
cd windows
convert_jpegxr_to_standard_tiff.bat "C:\chemin\vers\dossier\images"
```

Ce script va :
- Lire tous les fichiers .tif du dossier
- Les décompresser complètement
- Les sauvegarder dans un sous-dossier `converted\`

#### Étape 2 : Utiliser les fichiers convertis pour la fusion

Dans TIFF Channel Merger, sélectionnez les fichiers du dossier `converted\` au lieu des fichiers originaux.

**Avantages :**
- ✅ Garantit un TIFF propre et compatible
- ✅ Pas de risque de corruption IFD
- ✅ Fonctionne avec tous les logiciels (QuPath, ImageJ, Fiji, etc.)
- ✅ Vous pouvez vérifier les fichiers convertis avant fusion

**Inconvénients :**
- ⏱️ Prend plus de temps (conversion + fusion)
- 💾 Double l'espace disque (originaux + convertis)

### Solution 2 : Fusion directe avec fallback (AUTOMATIQUE)

La version 3.10 inclut un **fallback automatique** :

1. Le programme essaie d'abord `tiffload --unlimited`
2. Si échec, il essaie `vips copy --sequential` (plus tolérant)
3. La fusion continue avec les fichiers décompressés en .v

**Avantages :**
- ✅ Automatique, pas d'étape supplémentaire
- ✅ Plus rapide

**Inconvénients :**
- ⚠️ Peut quand même produire un TIFF avec IFD corrompu
- ⚠️ L'injection OME-XML sera désactivée si le TIFF est invalide

### Solution 3 : Utiliser ImageJ/Fiji pour convertir

Si VIPS ne fonctionne pas bien :

1. Ouvrez Fiji : https://fiji.sc/
2. Ouvrez vos images JPEG-XR
3. Sauvegardez-les : `File` → `Save As` → `Tiff...`
4. Choisissez compression : `LZW` ou `None`
5. Utilisez ces fichiers pour la fusion

## 🔍 Diagnostic et Dépannage

### Vérifier l'intégrité d'un TIFF fusionné

```cmd
cd windows
%LOCALAPPDATA%\vips\bin\vipsheader.exe "chemin\vers\merged_channels.tif"
```

Si vous voyez un message d'erreur, le TIFF est corrompu.

### Logs à consulter

Après une fusion, consultez ces fichiers dans le dossier de sortie :

- `vips_diagnostic.log` - Informations sur le processus
- `vips_output.log` - Sortie standard de VIPS
- `vips_error.log` - Erreurs VIPS

Cherchez les lignes avec "WARNING" ou "ERROR".

### Le TIFF fusionné semble OK mais QuPath refuse de l'ouvrir ?

C'est probablement un problème d'IFD. Solutions :

1. **Reconvertir avec VIPS :**
   ```cmd
   vips copy merged_channels.tif merged_channels_fixed.tif
   ```

2. **Utiliser tiffcp (libtiff) :**
   ```cmd
   tiffcp -c lzw merged_channels.tif merged_channels_fixed.tif
   ```

3. **Ouvrir dans ImageJ et resauvegarder :**
   - Ouvrir dans Fiji
   - Save As → Tiff (compression LZW)

## 📋 Recommandations

### Pour éviter les problèmes à l'avenir :

1. **Demandez au scanner de sortir en TIFF standard** (LZW ou non compressé) au lieu de JPEG-XR

2. **Convertissez systématiquement** les exports scanner avant analyse :
   ```cmd
   convert_jpegxr_to_standard_tiff.bat "dossier_export_scanner"
   ```

3. **Gardez les originaux** mais travaillez toujours avec les convertis

4. **Testez un fichier** avant de tout convertir :
   - Convertissez 1 canal
   - Fusionnez avec un autre canal converti
   - Ouvrez dans QuPath
   - Si OK, convertissez tout le reste

### Pourquoi les scanners utilisent JPEG-XR ?

- Plus petite taille de fichier
- Compression avec perte minimale
- Rapide à encoder

**MAIS** : Très mauvaise compatibilité avec les outils scientifiques !

## 🆘 Besoin d'aide ?

Si aucune solution ne fonctionne :

1. Vérifiez la version de VIPS : `vips --version`
2. Essayez avec Fiji/ImageJ pour la conversion
3. Consultez les logs détaillés dans le dossier de sortie
4. Vérifiez que vous avez l'espace disque suffisant

## 📚 Ressources

- VIPS documentation : https://libvips.github.io/libvips/
- QuPath forum : https://forum.image.sc/tag/qupath
- ImageJ/Fiji : https://fiji.sc/
- TIFF specification : https://www.adobe.io/open/standards/TIFF.html
