-- Fusion de canaux TIFF avec interface graphique multilingue
-- Version 3.0 - Interface utilisateur native avec support français/anglais

-- Variables globales pour les textes
global currentTexts

-- Sélectionner la langue
on selectLanguage()
	set dialogResult to display dialog "🌍 Language Selection / Sélection de langue

Choose your preferred language:
Choisissez votre langue préférée :" buttons {"Français", "English"} default button "English" with icon note

	return button returned of dialogResult
end selectLanguage

-- Initialiser les textes selon la langue
on initTexts(lang)
	if lang is "Français" then
		set currentTexts to {¬
			"vipsNotInstalled", "VIPS n'est pas installé sur votre système.

Ce logiciel est nécessaire pour fusionner les images.

Pour installer VIPS, ouvrez le Terminal et exécutez :
brew install vips

Si vous n'avez pas Homebrew, installez-le d'abord avec :
/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"", ¬
			"quit", "Quitter", ¬
			"welcome", "🔬 Fusion de canaux TIFF

Cette application permet de fusionner plusieurs fichiers TIFF (correspondant à différents canaux de fluorescence) en un seul fichier TIFF multi-canal.

Le fichier résultant pourra être ouvert dans QuPath pour l'analyse d'images de microscopie.", ¬
			"start", "Commencer", ¬
			"fileSelection", "Sélection des fichiers TIFF à fusionner

Vous allez pouvoir sélectionner plusieurs fichiers TIFF correspondant à vos différents canaux de fluorescence.

Cliquez sur 'Continuer' pour commencer la sélection.", ¬
			"continue", "Continuer", ¬
			"selectFile", "Sélectionnez un fichier TIFF (canal ", ¬
			"fileAdded", "Fichier ajouté : ", ¬
			"channelsSelected", "

Nombre de canaux sélectionnés : ", ¬
			"addMoreChannels", "

Voulez-vous ajouter un autre canal ?", ¬
			"finishSelection", "Terminer la sélection", ¬
			"addChannel", "Ajouter un canal", ¬
			"selectMoreFiles", "

Sélectionnez au moins un autre fichier pour continuer.", ¬
			"minTwoFiles", "Vous devez sélectionner au moins 2 fichiers pour la fusion.", ¬
			"retry", "Réessayer", ¬
			"outputFileName", "Nom du fichier de sortie

Entrez le nom du fichier fusionné (sans extension) :", ¬
			"cancel", "Annuler", ¬
			"outputLocation", "Emplacement du fichier de sortie

Où voulez-vous sauvegarder le fichier fusionné ?", ¬
			"sameFolder", "Même dossier", ¬
			"desktop", "Bureau", ¬
			"other", "Autre...", ¬
			"chooseLocation", "Choisissez l'emplacement :", ¬
			"downloads", "Téléchargements", ¬
			"browse", "Parcourir...", ¬
			"back", "Retour", ¬
			"chooseFolderPrompt", "Choisissez le dossier de destination", ¬
			"pyramidOptions", "Options avancées

Voulez-vous créer une image pyramidale ?

Une image pyramidale contient plusieurs niveaux de résolution, ce qui permet une visualisation plus fluide dans QuPath.

Recommandé : OUI pour les grandes images (>10,000×10,000 pixels)", ¬
			"no", "Non", ¬
			"yes", "Oui", ¬
			"filesSelected", "Fichiers sélectionnés :

", ¬
			"totalChannels", "
Nombre total de canaux : ", ¬
			"modify", "Modifier", ¬
			"summary", "Récapitulatif :

Nombre de canaux : ", ¬
			"outputFile", "
Fichier de sortie : ", ¬
			"folder", "
Dossier : ", ¬
			"pyramidal", "
Image pyramidale : ", ¬
			"launchFusion", "

Lancer la fusion ?", ¬
			"merge", "Fusionner", ¬
			"preparing", "Préparation de la fusion...", ¬
			"initializing", "Initialisation...", ¬
			"merging", "Fusion des canaux en cours...", ¬
			"processing", "Traitement de ", ¬
			"channels", " canaux...", ¬
			"creatingPyramid", "Création de la pyramide...", ¬
			"takesTime", "Cela peut prendre plusieurs minutes...", ¬
			"saving", "Enregistrement du fichier...", ¬
			"finalizing", "Finalisation...", ¬
			"cleaning", "Nettoyage...", ¬
			"removingTemp", "Suppression des fichiers temporaires...", ¬
			"completed", "Terminé !", ¬
			"success", "Fusion réussie", ¬
			"successMessage", "✅ Fusion terminée avec succès !

Fichier créé : ", ¬
			"location", "
Emplacement : ", ¬
			"quPathInstructions", "

Pour ouvrir dans QuPath :
1. Ouvrez le fichier
2. Allez dans Image → Image type → Fluorescence
3. Ouvrez View → Brightness/Contrast (Shift+C)
4. Ajustez la visibilité et les couleurs de chaque canal", ¬
			"openFolder", "Ouvrir le dossier", ¬
			"finish", "Terminer", ¬
			"errorPrefix", "❌ Erreur : "¬
		}
	else
		set currentTexts to {¬
			"vipsNotInstalled", "VIPS is not installed on your system.

This software is required to merge images.

To install VIPS, open Terminal and run:
brew install vips

If you don't have Homebrew, install it first with:
/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"", ¬
			"quit", "Quit", ¬
			"welcome", "🔬 TIFF Channel Merger

This application allows you to merge multiple TIFF files (corresponding to different fluorescence channels) into a single multi-channel TIFF file.

The resulting file can be opened in QuPath for microscopy image analysis.", ¬
			"start", "Start", ¬
			"fileSelection", "TIFF File Selection for Merging

You will be able to select multiple TIFF files corresponding to your different fluorescence channels.

Click 'Continue' to start the selection.", ¬
			"continue", "Continue", ¬
			"selectFile", "Select a TIFF file (channel ", ¬
			"fileAdded", "File added: ", ¬
			"channelsSelected", "

Number of channels selected: ", ¬
			"addMoreChannels", "

Would you like to add another channel?", ¬
			"finishSelection", "Finish selection", ¬
			"addChannel", "Add channel", ¬
			"selectMoreFiles", "

Select at least one more file to continue.", ¬
			"minTwoFiles", "You must select at least 2 files for merging.", ¬
			"retry", "Retry", ¬
			"outputFileName", "Output File Name

Enter the name of the merged file (without extension):", ¬
			"cancel", "Cancel", ¬
			"outputLocation", "Output File Location

Where would you like to save the merged file?", ¬
			"sameFolder", "Same folder", ¬
			"desktop", "Desktop", ¬
			"other", "Other...", ¬
			"chooseLocation", "Choose location:", ¬
			"downloads", "Downloads", ¬
			"browse", "Browse...", ¬
			"back", "Back", ¬
			"chooseFolderPrompt", "Choose destination folder", ¬
			"pyramidOptions", "Advanced Options

Would you like to create a pyramidal image?

A pyramidal image contains multiple resolution levels, which allows smoother visualization in QuPath.

Recommended: YES for large images (>10,000×10,000 pixels)", ¬
			"no", "No", ¬
			"yes", "Yes", ¬
			"filesSelected", "Selected files:

", ¬
			"totalChannels", "
Total number of channels: ", ¬
			"modify", "Modify", ¬
			"summary", "Summary:

Number of channels: ", ¬
			"outputFile", "
Output file: ", ¬
			"folder", "
Folder: ", ¬
			"pyramidal", "
Pyramidal image: ", ¬
			"launchFusion", "

Launch merge?", ¬
			"merge", "Merge", ¬
			"preparing", "Preparing merge...", ¬
			"initializing", "Initializing...", ¬
			"merging", "Merging channels...", ¬
			"processing", "Processing ", ¬
			"channels", " channels...", ¬
			"creatingPyramid", "Creating pyramid...", ¬
			"takesTime", "This may take several minutes...", ¬
			"saving", "Saving file...", ¬
			"finalizing", "Finalizing...", ¬
			"cleaning", "Cleaning up...", ¬
			"removingTemp", "Removing temporary files...", ¬
			"completed", "Completed!", ¬
			"success", "Merge successful", ¬
			"successMessage", "✅ Merge completed successfully!

File created: ", ¬
			"location", "
Location: ", ¬
			"quPathInstructions", "

To open in QuPath:
1. Open the file
2. Go to Image → Image type → Fluorescence
3. Open View → Brightness/Contrast (Shift+C)
4. Adjust visibility and colors for each channel", ¬
			"openFolder", "Open folder", ¬
			"finish", "Finish", ¬
			"errorPrefix", "❌ Error: "¬
		}
	end if
end initTexts

-- Fonction pour obtenir un texte
on getText(key)
	repeat with i from 1 to (count of currentTexts) by 2
		if item i of currentTexts is key then
			return item (i + 1) of currentTexts
		end if
	end repeat
	return key -- Retourne la clé si pas trouvée
end getText

-- Vérifier l'installation de VIPS
on checkVips()
	-- Essayer les chemins possibles pour VIPS
	set vipsPaths to {"/opt/homebrew/bin/vips", "/usr/local/bin/vips", "/opt/local/bin/vips"}

	repeat with vipsPath in vipsPaths
		try
			do shell script vipsPath & " --version"
			return vipsPath
		on error
			-- Continue to next path
		end try
	end repeat

	-- Si aucun chemin ne fonctionne
	display dialog getText("vipsNotInstalled") buttons {getText("quit")} default button getText("quit") with icon caution
	error "VIPS not installed"
end checkVips

-- Sélectionner les fichiers TIFF
on selectTiffFiles()
	set selectedFiles to {}
	set fileCount to 0

	display dialog getText("fileSelection") buttons {getText("quit"), getText("continue")} default button getText("continue") with icon note

	if button returned of result is getText("quit") then error "Cancelled by user"

	repeat
		try
			set selectedFile to choose file with prompt getText("selectFile") & (fileCount + 1) & ")" of type {"public.tiff", "com.adobe.tiff", "tif", "tiff"}
			set selectedFiles to selectedFiles & {selectedFile}
			set fileCount to fileCount + 1

			set fileName to name of (info for selectedFile)

			if fileCount ≥ 2 then
				set dialogResult to display dialog getText("fileAdded") & fileName & getText("channelsSelected") & fileCount & getText("addMoreChannels") buttons {getText("finishSelection"), getText("addChannel")} default button getText("addChannel") with icon note

				if button returned of dialogResult is getText("finishSelection") then
					exit repeat
				end if
			else
				display dialog getText("fileAdded") & fileName & getText("channelsSelected") & fileCount & getText("selectMoreFiles") buttons {getText("continue")} default button getText("continue") with icon note
			end if

		on error errorMessage
			if errorMessage contains "User canceled" then
				if fileCount ≥ 2 then
					exit repeat
				else
					display dialog getText("minTwoFiles") buttons {getText("retry"), getText("quit")} default button getText("retry") with icon caution
					if button returned of result is getText("quit") then error "Cancelled by user"
				end if
			else
				error errorMessage
			end if
		end try
	end repeat

	if fileCount < 2 then
		error "Not enough files selected"
	end if

	return selectedFiles
end selectTiffFiles

-- Demander le nom du fichier de sortie
on getOutputFileName()
	set dialogResult to display dialog getText("outputFileName") default answer "merged_image" buttons {getText("cancel"), getText("continue")} default button getText("continue") with icon note

	if button returned of dialogResult is getText("cancel") then error "Cancelled by user"

	set outputName to text returned of dialogResult

	-- Nettoyer le nom de fichier
	set outputName to do shell script "echo " & quoted form of outputName & " | sed 's/[^a-zA-Z0-9._-]/_/g'"

	if outputName is "" then
		error "File name cannot be empty"
	end if

	return outputName
end getOutputFileName

-- Choisir le dossier de destination
on chooseOutputFolder(firstFilePath)
	set firstFileFolder to do shell script "dirname " & quoted form of (POSIX path of firstFilePath)

	set dialogResult to display dialog getText("outputLocation") buttons {getText("other"), getText("desktop"), getText("sameFolder")} default button getText("sameFolder") with icon note

	set chosenButton to button returned of dialogResult

	if chosenButton is getText("sameFolder") then
		return firstFileFolder
	else if chosenButton is getText("desktop") then
		return POSIX path of (path to desktop)
	else if chosenButton is getText("other") then
		-- Proposer d'abord les Téléchargements ou un dossier personnalisé
		set subDialogResult to display dialog getText("chooseLocation") buttons {getText("downloads"), getText("browse"), getText("back")} default button getText("downloads") with icon note

		set subChosenButton to button returned of subDialogResult

		if subChosenButton is getText("downloads") then
			return POSIX path of (path to downloads folder)
		else if subChosenButton is getText("browse") then
			set chosenFolder to choose folder with prompt getText("chooseFolderPrompt")
			return POSIX path of chosenFolder
		else if subChosenButton is getText("back") then
			-- Relancer le dialogue principal
			return chooseOutputFolder(firstFilePath)
		end if
	end if
end chooseOutputFolder

-- Demander les options de pyramide
on askPyramidOption()
	set dialogResult to display dialog getText("pyramidOptions") buttons {getText("no"), getText("yes")} default button getText("yes") with icon note

	return button returned of dialogResult is getText("yes")
end askPyramidOption

-- Fusionner les canaux
on mergeChannels(fileList, outputPath, createPyramid, vipsPath)
	set progress total steps to 4
	set progress completed steps to 0
	set progress description to getText("preparing")
	set progress additional description to getText("initializing")

	-- Construire la liste des fichiers pour VIPS (syntaxe avec guillemets autour de toute la liste)
	set vipsFileList to ""
	repeat with i from 1 to count of fileList
		set filePath to POSIX path of (item i of fileList)
		set vipsFileList to vipsFileList & filePath
		if i < count of fileList then set vipsFileList to vipsFileList & " "
	end repeat

	set tempFile to outputPath & "_temp.tif"
	set finalFile to outputPath & ".tif"

	-- Étape 1: Fusion des canaux
	set progress completed steps to 1
	set progress description to getText("merging")
	set progress additional description to getText("processing") & (count of fileList) & getText("channels")

	try
		set mergeCommand to vipsPath & " bandjoin \"" & vipsFileList & "\" " & quoted form of tempFile
		do shell script mergeCommand
	on error errorMessage
		do shell script "rm -f " & quoted form of tempFile
		error "Merge error: " & errorMessage
	end try

	-- Étape 2: Création du fichier final
	set progress completed steps to 2
	if createPyramid then
		set progress description to getText("creatingPyramid")
		set progress additional description to getText("takesTime")

		try
			set saveCommand to vipsPath & " tiffsave " & quoted form of tempFile & " " & quoted form of finalFile & " --compression=lzw --tile --tile-width=256 --tile-height=256 --pyramid --bigtiff"
			do shell script saveCommand
		on error errorMessage
			do shell script "rm -f " & quoted form of tempFile
			error "Pyramid creation error: " & errorMessage
		end try
	else
		set progress description to getText("saving")
		set progress additional description to getText("finalizing")

		try
			set saveCommand to vipsPath & " tiffsave " & quoted form of tempFile & " " & quoted form of finalFile & " --compression=lzw --bigtiff"
			do shell script saveCommand
		on error errorMessage
			do shell script "rm -f " & quoted form of tempFile
			error "Save error: " & errorMessage
		end try
	end if

	-- Étape 3: Nettoyage
	set progress completed steps to 3
	set progress description to getText("cleaning")
	set progress additional description to getText("removingTemp")

	do shell script "rm -f " & quoted form of tempFile

	-- Terminé
	set progress completed steps to 4
	set progress description to getText("completed")
	set progress additional description to getText("success")

	return finalFile
end mergeChannels

-- Programme principal
on run
	try
		-- Sélection de la langue
		set selectedLanguage to selectLanguage()
		initTexts(selectedLanguage)

		-- Vérifier VIPS et obtenir le chemin
		set vipsPath to checkVips()

		-- Interface de bienvenue
		display dialog getText("welcome") buttons {getText("quit"), getText("start")} default button getText("start") with icon note

		if button returned of result is getText("quit") then return

		-- Sélectionner les fichiers
		set selectedFiles to selectTiffFiles()

		-- Récapitulatif des fichiers
		set fileNames to ""
		repeat with i from 1 to count of selectedFiles
			set fileName to name of (info for (item i of selectedFiles))
			set fileNames to fileNames & "Canal " & i & ": " & fileName & return
		end repeat

		display dialog getText("filesSelected") & fileNames & getText("totalChannels") & (count of selectedFiles) buttons {getText("modify"), getText("continue")} default button getText("continue") with icon note

		if button returned of result is getText("modify") then
			set selectedFiles to selectTiffFiles()
		end if

		-- Nom du fichier de sortie
		set outputName to getOutputFileName()

		-- Dossier de destination
		set outputFolder to chooseOutputFolder(item 1 of selectedFiles)
		set outputPath to outputFolder & "/" & outputName

		-- Options de pyramide
		set createPyramid to askPyramidOption()

		-- Confirmation finale
		set pyramidText to ""
		if createPyramid then
			set pyramidText to getText("yes")
		else
			set pyramidText to getText("no")
		end if

		display dialog getText("summary") & (count of selectedFiles) & getText("outputFile") & outputName & ".tif" & getText("folder") & outputFolder & getText("pyramidal") & pyramidText & getText("launchFusion") buttons {getText("cancel"), getText("merge")} default button getText("merge") with icon note

		if button returned of result is getText("cancel") then return

		-- Lancer la fusion avec barre de progression
		set progress total steps to 4
		set finalPath to mergeChannels(selectedFiles, outputPath, createPyramid, vipsPath)

		-- Message de succès
		set successMsg to getText("successMessage") & outputName & ".tif" & getText("location") & outputFolder & getText("quPathInstructions")

		display dialog successMsg buttons {getText("openFolder"), getText("finish")} default button getText("openFolder") with icon note

		if button returned of result is getText("openFolder") then
			do shell script "open " & quoted form of outputFolder
		end if

	on error errorMessage
		if errorMessage is not "Cancelled by user" and errorMessage is not "User canceled." then
			try
				set errorText to getText("errorPrefix") & errorMessage
			on error
				set errorText to "❌ Error: " & errorMessage
			end try
			display dialog errorText buttons {"OK"} default button "OK" with icon stop
		end if
	end try
end run