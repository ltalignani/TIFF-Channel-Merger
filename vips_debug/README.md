# VIPS Debug Tools

Ce répertoire contient des scripts de test et de diagnostic pour VIPS (libvips).

## Utilité

Ces outils sont destinés au débogage lors de l'installation de l'application sur un nouveau PC. Ils permettent de vérifier rapidement que VIPS est correctement installé et fonctionnel.

## Fichiers disponibles

### Scripts de vérification générale

- **check_vips.bat** - Vérification complète de l'installation VIPS
  - Vérifie la présence de vips.exe
  - Affiche la version installée
  - Teste la commande 'copy'
  - Liste les opérations disponibles

- **test_vips.ps1** - Version PowerShell améliorée de la vérification
  - Recherche VIPS dans plusieurs emplacements possibles
  - Affichage coloré des résultats
  - Plus de détails sur les opérations disponibles

- **vips_info.bat** - Génère un rapport d'installation dans %TEMP%

### Scripts de test des commandes spécifiques

- **vips_tiffload.bat** - Affiche toutes les options de la commande `tiffload`
  - Utile pour vérifier le support de `--unlimited`

- **test_tiffsave_options.bat** - Affiche toutes les options de `tiffsave`
  - Recherche les options de métadonnées (description, properties)

- **list_vips_commands.bat** - Liste toutes les opérations VIPS
  - Filtre les commandes 'set', 'copy', 'header', 'meta'

- **test_vipsedit.bat** - Affiche l'aide de vipsedit.exe

- **test_vipsheader.bat** - Affiche l'aide de vipsheader.exe

## Utilisation typique lors du débogage

### 1. Vérifier que VIPS est installé

```cmd
cd vips_debug
check_vips.bat
```

ou

```powershell
cd vips_debug
.\test_vips.ps1
```

### 2. Vérifier le support des options critiques

```cmd
vips_tiffload.bat
```

Cherchez `--unlimited` dans la sortie pour confirmer le support des grandes images.

### 3. Lister toutes les opérations disponibles

```cmd
list_vips_commands.bat
```

## Notes techniques

- Tous les scripts utilisent `%LOCALAPPDATA%\vips\bin\vips.exe` comme chemin d'installation par défaut
- Les scripts génèrent des fichiers temporaires dans `%TEMP%`
- Aucune modification de fichiers n'est effectuée, ce sont des outils de lecture seule

## Dépannage

Si VIPS n'est pas trouvé :
1. Vérifiez que l'application principale a bien installé VIPS
2. Cherchez manuellement vips.exe dans :
   - `%LOCALAPPDATA%\vips\bin\`
   - `C:\Program Files\vips\bin\`
   - `C:\Program Files (x86)\vips\bin\`

## Mise à jour

Ces scripts correspondent à la version de l'application qui utilise :
- VIPS avec support de `tiffload --unlimited`
- Format intermédiaire `.v` pour contourner les limites mémoire
- Compression LZW et pyramides pour les TIFFs
