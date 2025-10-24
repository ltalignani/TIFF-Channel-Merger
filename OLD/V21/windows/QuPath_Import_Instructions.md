# 🔬 Comment importer les noms de canaux dans QuPath

## 📋 Contexte
QuPath ne lit pas automatiquement les fichiers OME-XML sidecar pour les noms de canaux. Voici plusieurs méthodes pour importer vos noms de canaux personnalisés.

## 🎯 Méthode 1 : Script QuPath automatique (Recommandée)

### Étapes :
1. **Ouvrez QuPath**
2. **Ouvrez votre fichier** : `merged_channels.tif`
3. **Allez dans** : `Automate` > `Show script editor`
4. **Copiez-collez le script** suivant :

```groovy
// QuPath script to set channel names for imported TIFF
import java.nio.file.Paths

// Get the current image
def imageData = getCurrentImageData()
if (imageData == null) {
    print("No image open!")
    return
}

// Get the image path and derive the channel names file path
def imagePath = imageData.getServer().getPath()
def parentDir = Paths.get(imagePath).getParent()
def channelNamesFile = parentDir.resolve("merged_channels_channels.txt").toFile()

if (!channelNamesFile.exists()) {
    print("Channel names file not found: " + channelNamesFile.getAbsolutePath())
    return
}

// Read channel names
def channelNames = channelNamesFile.readLines()
print("Found channel names: " + channelNames)

// Get the image server and update channel names
def server = imageData.getServer()
def channels = server.getMetadata().getChannels()

// Update channel names
for (int i = 0; i < Math.min(channels.size(), channelNames.size()); i++) {
    def channel = channels[i]
    def newName = channelNames[i].trim()
    if (!newName.isEmpty()) {
        def updatedChannel = ImageChannel.getInstance(newName, channel.getColor())
        channels[i] = updatedChannel
        print("Set channel " + i + " name to: " + newName)
    }
}

// Refresh the display
fireHierarchyUpdate()
print("Channel names updated successfully!")
```

5. **Cliquez sur** `Run`
6. **Vérifiez les logs** - vous devriez voir :
   ```
   Found channel names: [A546, CY7, CY5, DAPI, FITC]
   Set channel 0 name to: A546
   Set channel 1 name to: CY7
   Set channel 2 name to: CY5
   Set channel 3 name to: DAPI
   Set channel 4 name to: FITC
   Channel names updated successfully!
   ```

## 🎯 Méthode 2 : Modification manuelle

### Étapes :
1. **Ouvrez** `merged_channels.tif` dans QuPath
2. **Allez dans le panneau** `Brightness & contrast`
3. **Pour chaque canal** :
   - Clic droit sur `Channel 1` → `Rename` → `A546`
   - Clic droit sur `Channel 2` → `Rename` → `CY7`
   - Clic droit sur `Channel 3` → `Rename` → `CY5`
   - Clic droit sur `Channel 4` → `Rename` → `DAPI`
   - Clic droit sur `Channel 5` → `Rename` → `FITC`

## 🎯 Méthode 3 : Créer un vrai OME-TIFF

Si vous avez **Python + Pillow** installé :

### Installation :
```bash
pip install pillow
```

### Résultat :
- L'application tentera automatiquement d'intégrer les métadonnées OME directement dans le TIFF
- QuPath lira alors les noms de canaux automatiquement

## 📁 Fichiers disponibles
Après la fusion, vous disposez de :
- `merged_channels.tif` - Fichier TIFF multi-canal
- `merged_channels_channels.txt` - Liste des noms de canaux
- `merged_channels.ome.xml` - Métadonnées OME complètes
- `QuPath_channel_setup.groovy` - Script QuPath automatique

## 🔧 Dépannage

### Script ne fonctionne pas ?
- Vérifiez que `merged_channels_channels.txt` existe
- Vérifiez que le fichier TIFF est ouvert dans QuPath
- Regardez les messages dans la console QuPath

### Noms de canaux non sauvegardés ?
- Les noms de canaux dans QuPath ne sont pas sauvegardés automatiquement
- Sauvegardez votre projet QuPath : `File` > `Project` > `Create project`
- Ou réexécutez le script à chaque ouverture

## 💡 Conseils
- **Sauvegardez un projet QuPath** pour conserver les noms de canaux
- **Utilisez des noms courts** pour un affichage optimal
- **Évitez les caractères spéciaux** dans les noms de canaux

## 🆘 Support
Si aucune méthode ne fonctionne :
1. Vérifiez la version de QuPath (> 0.5.0 recommandée)
2. Essayez d'importer avec Bio-Formats dans ImageJ/Fiji
3. Contactez le support QuPath sur image.sc