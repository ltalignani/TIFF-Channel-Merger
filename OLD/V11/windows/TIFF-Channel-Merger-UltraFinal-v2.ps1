# TIFF Channel Merger for Windows - Ultra Final Version v2
# Version 3.4 - Fixed UTF-8 BOM encoding and added channel naming
# PowerShell script with WinForms interface

# Set console encoding to UTF-8 for proper character display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Force UTF-8 encoding for all string operations
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo("fr-FR")

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Ensure WinForms uses proper text rendering
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Global variables
$script:selectedLanguage = ""
$script:texts = @{}
$script:selectedFiles = @()
$script:channelNames = @()
$script:vipsPath = ""

# Language definitions with proper UTF-8 encoding
function Initialize-Texts {
    param([string]$language)

    if ($language -eq "Français") {
        $script:texts = @{
            "appTitle" = "Fusion de canaux TIFF"
            "languageSelection" = "Sélection de langue"
            "chooseLanguage" = "Choisissez votre langue préférée :"
            "french" = "Français"
            "english" = "English"
            "continue" = "Continuer"
            "cancel" = "Annuler"
            "quit" = "Quitter"
            "vipsNotFound" = "VIPS n'est pas installé sur votre système.`n`nCe logiciel est nécessaire pour fusionner les images.`n`nVoulez-vous télécharger et installer VIPS automatiquement ?"
            "downloadVips" = "Télécharger VIPS"
            "installVips" = "Installation de VIPS"
            "vipsInstalling" = "Téléchargement et installation de VIPS en cours...`nCela peut prendre quelques minutes."
            "vipsInstalled" = "VIPS a été installé avec succès !"
            "vipsError" = "Erreur lors de l'installation de VIPS :"
            "welcome" = "Bienvenue dans le Fusionneur de canaux TIFF`n`nCette application permet de fusionner plusieurs fichiers TIFF (correspondant à différents canaux de fluorescence) en un seul fichier TIFF multi-canal.`n`nLe fichier résultant pourra être ouvert dans QuPath pour l'analyse d'images de microscopie."
            "start" = "Commencer"
            "selectFiles" = "Sélectionner les fichiers TIFF"
            "selectFilesDesc" = "Sélectionnez au moins 2 fichiers TIFF à fusionner :"
            "addFile" = "Ajouter un fichier"
            "removeFile" = "Supprimer"
            "channelNaming" = "Nommage des canaux"
            "channelNamingDesc" = "Nommez chaque canal pour QuPath (optionnel) :"
            "outputName" = "Nom du fichier de sortie"
            "outputNameDesc" = "Entrez le nom du fichier fusionné (sans extension) :"
            "outputLocation" = "Emplacement de sortie"
            "outputLocationDesc" = "Choisissez où sauvegarder le fichier fusionné :"
            "browse" = "Parcourir..."
            "pyramidOption" = "Options avancées"
            "pyramidDesc" = "Créer une image pyramidale ?`n`nUne image pyramidale contient plusieurs niveaux de résolution, ce qui permet une visualisation plus fluide dans QuPath.`n`nRecommandé : OUI pour les grandes images (>10,000×10,000 pixels)"
            "yes" = "Oui"
            "no" = "Non"
            "summary" = "Récapitulatif"
            "merge" = "Fusionner"
            "merging" = "Fusion en cours..."
            "mergingDesc" = "Fusion des canaux TIFF en cours. Veuillez patienter..."
            "success" = "Succès !"
            "successDesc" = "La fusion a été terminée avec succès !`n`nFichier créé :"
            "openFolder" = "Ouvrir le dossier"
            "finish" = "Terminer"
            "error" = "Erreur"
            "minTwoFiles" = "Vous devez sélectionner au moins 2 fichiers TIFF."
            "invalidName" = "Veuillez entrer un nom de fichier valide."
            "selectOutput" = "Veuillez sélectionner un dossier de sortie."
            "tiffFilter" = "Fichiers TIFF (*.tif;*.tiff)|*.tif;*.tiff"
            "allFilter" = "Tous les fichiers (*.*)|*.*"
            "downloadProgress" = "Téléchargement en cours..."
            "extractProgress" = "Extraction en cours..."
        }
    } else {
        $script:texts = @{
            "appTitle" = "TIFF Channel Merger"
            "languageSelection" = "Language Selection"
            "chooseLanguage" = "Choose your preferred language:"
            "french" = "Français"
            "english" = "English"
            "continue" = "Continue"
            "cancel" = "Cancel"
            "quit" = "Quit"
            "vipsNotFound" = "VIPS is not installed on your system.`n`nThis software is required to merge images.`n`nWould you like to download and install VIPS automatically?"
            "downloadVips" = "Download VIPS"
            "installVips" = "Installing VIPS"
            "vipsInstalling" = "Downloading and installing VIPS...`nThis may take a few minutes."
            "vipsInstalled" = "VIPS has been installed successfully!"
            "vipsError" = "Error installing VIPS:"
            "welcome" = "Welcome to TIFF Channel Merger`n`nThis application allows you to merge multiple TIFF files (corresponding to different fluorescence channels) into a single multi-channel TIFF file.`n`nThe resulting file can be opened in QuPath for microscopy image analysis."
            "start" = "Start"
            "selectFiles" = "Select TIFF Files"
            "selectFilesDesc" = "Select at least 2 TIFF files to merge:"
            "addFile" = "Add File"
            "removeFile" = "Remove"
            "channelNaming" = "Channel Naming"
            "channelNamingDesc" = "Name each channel for QuPath (optional):"
            "outputName" = "Output File Name"
            "outputNameDesc" = "Enter the name of the merged file (without extension):"
            "outputLocation" = "Output Location"
            "outputLocationDesc" = "Choose where to save the merged file:"
            "browse" = "Browse..."
            "pyramidOption" = "Advanced Options"
            "pyramidDesc" = "Create pyramidal image?`n`nA pyramidal image contains multiple resolution levels, which allows smoother visualization in QuPath.`n`nRecommended: YES for large images (>10,000×10,000 pixels)"
            "yes" = "Yes"
            "no" = "No"
            "summary" = "Summary"
            "merge" = "Merge"
            "merging" = "Merging..."
            "mergingDesc" = "Merging TIFF channels in progress. Please wait..."
            "success" = "Success!"
            "successDesc" = "Merge completed successfully!`n`nFile created:"
            "openFolder" = "Open Folder"
            "finish" = "Finish"
            "error" = "Error"
            "minTwoFiles" = "You must select at least 2 TIFF files."
            "invalidName" = "Please enter a valid file name."
            "selectOutput" = "Please select an output folder."
            "tiffFilter" = "TIFF Files (*.tif;*.tiff)|*.tif;*.tiff"
            "allFilter" = "All Files (*.*)|*.*"
            "downloadProgress" = "Downloading..."
            "extractProgress" = "Extracting..."
        }
    }
}

# Function to convert Windows paths to Unix-style for VIPS
function Convert-PathForVips {
    param([string]$windowsPath)
    return $windowsPath.Replace('\', '/')
}

# Function to write UTF-8 BOM file
function Write-UTF8BOM {
    param([string]$FilePath, [string]$Content)
    $utf8BOM = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($FilePath, $Content, $utf8BOM)
}

# Function to check and install VIPS with improved error handling
function Test-VipsInstallation {
    # Check common VIPS installation paths
    $possiblePaths = @(
        "${env:ProgramFiles}\vips\bin\vips.exe",
        "${env:ProgramFiles(x86)}\vips\bin\vips.exe",
        "$env:LOCALAPPDATA\vips\bin\vips.exe",
        "vips.exe"  # Check if in PATH
    )

    foreach ($path in $possiblePaths) {
        if ($path -eq "vips.exe") {
            try {
                $null = Get-Command vips.exe -ErrorAction Stop
                $script:vipsPath = "vips.exe"
                return $true
            } catch {
                continue
            }
        } elseif (Test-Path $path) {
            $script:vipsPath = $path
            return $true
        }
    }

    return $false
}

function Install-Vips {
    try {
        # Create progress form
        $progressForm = New-Object System.Windows.Forms.Form
        $progressForm.Text = $script:texts["installVips"]
        $progressForm.Size = New-Object System.Drawing.Size(450, 200)
        $progressForm.StartPosition = "CenterScreen"
        $progressForm.FormBorderStyle = "FixedDialog"
        $progressForm.MaximizeBox = $false
        $progressForm.MinimizeBox = $false

        $progressLabel = New-Object System.Windows.Forms.Label
        $progressLabel.Text = $script:texts["vipsInstalling"]
        $progressLabel.Size = New-Object System.Drawing.Size(410, 60)
        $progressLabel.Location = New-Object System.Drawing.Point(20, 20)
        $progressForm.Controls.Add($progressLabel)

        $progressBar = New-Object System.Windows.Forms.ProgressBar
        $progressBar.Location = New-Object System.Drawing.Point(20, 90)
        $progressBar.Size = New-Object System.Drawing.Size(410, 23)
        $progressBar.Style = "Marquee"
        $progressForm.Controls.Add($progressBar)

        $statusLabel = New-Object System.Windows.Forms.Label
        $statusLabel.Text = $script:texts["downloadProgress"]
        $statusLabel.Size = New-Object System.Drawing.Size(410, 23)
        $statusLabel.Location = New-Object System.Drawing.Point(20, 120)
        $progressForm.Controls.Add($statusLabel)

        $progressForm.Show()
        $progressForm.Refresh()

        # Try multiple VIPS download sources
        $vipsUrls = @(
            "https://github.com/libvips/build-win64-mxe/releases/download/v8.17.2/vips-dev-w64-all-8.17.2.zip",
            "https://github.com/libvips/build-win64-mxe/releases/download/v8.15.1/vips-dev-w64-all-8.15.1.zip",
            "https://github.com/libvips/build-win64-mxe/releases/download/v8.14.5/vips-dev-w64-all-8.14.5.zip"
        )

        $downloadPath = "$env:TEMP\vips.zip"
        $installPath = "$env:LOCALAPPDATA\vips"
        $downloaded = $false

        # Try each URL until one works
        foreach ($url in $vipsUrls) {
            try {
                $statusLabel.Text = $script:texts["downloadProgress"] + " " + [System.IO.Path]::GetFileName($url)
                $progressForm.Refresh()

                # Download with progress
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($url, $downloadPath)
                $downloaded = $true
                break
            } catch {
                Write-Host "Failed to download from $url : $($_.Exception.Message)"
                continue
            }
        }

        if (-not $downloaded) {
            throw "Unable to download VIPS from any source. Please check your internet connection."
        }

        # Extract
        $statusLabel.Text = $script:texts["extractProgress"]
        $progressForm.Refresh()

        if (Test-Path $installPath) {
            Remove-Item $installPath -Recurse -Force
        }

        # Use .NET to extract ZIP
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $env:LOCALAPPDATA)

        # Find the extracted folder and rename it
        $extractedFolder = Get-ChildItem -Path $env:LOCALAPPDATA -Directory | Where-Object { $_.Name -like "vips-dev-*" } | Select-Object -First 1
        if ($extractedFolder) {
            if (Test-Path $installPath) {
                Remove-Item $installPath -Recurse -Force
            }
            Rename-Item $extractedFolder.FullName $installPath
        }

        # Clean up
        Remove-Item $downloadPath -Force

        # Set vips path
        $script:vipsPath = "$installPath\bin\vips.exe"

        $progressForm.Close()

        # Verify installation
        if (Test-Path $script:vipsPath) {
            [System.Windows.Forms.MessageBox]::Show($script:texts["vipsInstalled"], $script:texts["installVips"], "OK", "Information")
            return $true
        } else {
            throw "VIPS installation completed but executable not found"
        }

    } catch {
        if ($progressForm) { $progressForm.Close() }
        $errorMessage = $script:texts["vipsError"] + " " + $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($errorMessage, $script:texts["error"], "OK", "Error")
        return $false
    }
}

# Language selection dialog with proper font
function Show-LanguageSelection {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "TIFF Channel Merger"
    $form.Size = New-Object System.Drawing.Size(450, 220)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # Set font to support Unicode characters
    $font = New-Object System.Drawing.Font("Microsoft Sans Serif", 10)
    $form.Font = $font

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "🌍 Language Selection / Sélection de langue`n`nChoose your preferred language:`nChoisissez votre langue préférée :"
    $label.Size = New-Object System.Drawing.Size(410, 100)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Font = $font
    $form.Controls.Add($label)

    $frenchButton = New-Object System.Windows.Forms.Button
    $frenchButton.Text = "Français"
    $frenchButton.Size = New-Object System.Drawing.Size(120, 35)
    $frenchButton.Location = New-Object System.Drawing.Point(90, 140)
    $frenchButton.Font = $font
    $frenchButton.Add_Click({
        $script:selectedLanguage = "Français"
        $form.DialogResult = "OK"
        $form.Close()
    })
    $form.Controls.Add($frenchButton)

    $englishButton = New-Object System.Windows.Forms.Button
    $englishButton.Text = "English"
    $englishButton.Size = New-Object System.Drawing.Size(120, 35)
    $englishButton.Location = New-Object System.Drawing.Point(240, 140)
    $englishButton.Font = $font
    $englishButton.Add_Click({
        $script:selectedLanguage = "English"
        $form.DialogResult = "OK"
        $form.Close()
    })
    $form.Controls.Add($englishButton)

    $form.AcceptButton = $englishButton

    $result = $form.ShowDialog()
    $form.Dispose()

    return $result -eq "OK"
}

# Welcome dialog with proper encoding
function Show-Welcome {
    $result = [System.Windows.Forms.MessageBox]::Show($script:texts["welcome"], $script:texts["appTitle"], "OKCancel", "Information")
    return $result -eq "OK"
}

# File selection dialog with Unicode support and channel naming
function Show-FileSelection {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $script:texts["selectFiles"]
    $form.Size = New-Object System.Drawing.Size(740, 600)
    $form.StartPosition = "CenterScreen"

    # Set font for Unicode support
    $font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9)
    $form.Font = $font

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $script:texts["selectFilesDesc"]
    $label.Size = New-Object System.Drawing.Size(660, 30)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Font = $font
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Size = New-Object System.Drawing.Size(660, 200)
    $listBox.Location = New-Object System.Drawing.Point(20, 60)
    $listBox.Font = $font
    $form.Controls.Add($listBox)

    $addButton = New-Object System.Windows.Forms.Button
    $addButton.Text = $script:texts["addFile"]
    $addButton.Size = New-Object System.Drawing.Size(120, 30)
    $addButton.Location = New-Object System.Drawing.Point(20, 280)
    $addButton.Font = $font
    $addButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = $script:texts["tiffFilter"] + "|" + $script:texts["allFilter"]
        $openFileDialog.Multiselect = $true

        if ($openFileDialog.ShowDialog() -eq "OK") {
            foreach ($file in $openFileDialog.FileNames) {
                if ($script:selectedFiles -notcontains $file) {
                    $script:selectedFiles += $file
                    $script:channelNames += ""  # Add empty channel name
                    $listBox.Items.Add([System.IO.Path]::GetFileName($file))
                }
            }
            # Refresh channel naming section
            & $UpdateChannelNaming
        }
    })
    $form.Controls.Add($addButton)

    $removeButton = New-Object System.Windows.Forms.Button
    $removeButton.Text = $script:texts["removeFile"]
    $removeButton.Size = New-Object System.Drawing.Size(120, 30)
    $removeButton.Location = New-Object System.Drawing.Point(160, 280)
    $removeButton.Font = $font
    $removeButton.Add_Click({
        if ($listBox.SelectedIndex -ge 0) {
            $index = $listBox.SelectedIndex
            $script:selectedFiles = $script:selectedFiles | Where-Object { $_ -ne $script:selectedFiles[$index] }
            $script:channelNames = $script:channelNames[0..($index-1)] + $script:channelNames[($index+1)..($script:channelNames.Length-1)]
            $listBox.Items.RemoveAt($index)
            & $UpdateChannelNaming
        }
    })
    $form.Controls.Add($removeButton)

    # Channel naming section
    $channelLabel = New-Object System.Windows.Forms.Label
    $channelLabel.Text = $script:texts["channelNamingDesc"]
    $channelLabel.Size = New-Object System.Drawing.Size(660, 30)
    $channelLabel.Location = New-Object System.Drawing.Point(20, 330)
    $channelLabel.Font = $font
    $form.Controls.Add($channelLabel)

    # Container for channel name textboxes
    $channelPanel = New-Object System.Windows.Forms.Panel
    $channelPanel.Size = New-Object System.Drawing.Size(660, 150)
    $channelPanel.Location = New-Object System.Drawing.Point(20, 360)
    $channelPanel.AutoScroll = $true
    $form.Controls.Add($channelPanel)

    # Function to update channel naming UI
    $script:channelTextBoxes = @()
    $UpdateChannelNaming = {
        $channelPanel.Controls.Clear()
        $script:channelTextBoxes = @()

        for ($i = 0; $i -lt $script:selectedFiles.Count; $i++) {
            $fileName = [System.IO.Path]::GetFileName($script:selectedFiles[$i])
            $yPos = ($i * 30) + 5

            # Label for file
            $fileLabel = New-Object System.Windows.Forms.Label
            $fileLabel.Text = "$($i+1). $fileName"
            $fileLabel.Size = New-Object System.Drawing.Size(300, 20)
            $labelX = 5
            $labelY = $yPos
            $fileLabel.Location = New-Object System.Drawing.Point($labelX, $labelY)
            $fileLabel.Font = $font
            $channelPanel.Controls.Add($fileLabel)

            # TextBox for channel name
            $channelTextBox = New-Object System.Windows.Forms.TextBox
            $channelTextBox.Size = New-Object System.Drawing.Size(200, 20)
            $textBoxX = 320
            $textBoxY = $yPos
            $channelTextBox.Location = New-Object System.Drawing.Point($textBoxX, $textBoxY)
            $channelTextBox.Font = $font
            if ($i -lt $script:channelNames.Count) {
                $channelTextBox.Text = $script:channelNames[$i]
            }
            $channelTextBox.Tag = $i
            $channelTextBox.Add_TextChanged({
                # Ensure the channelNames array is large enough
                while ($script:channelNames.Count -le $this.Tag) {
                    $script:channelNames += ""
                }
                $script:channelNames[$this.Tag] = $this.Text
            })
            $channelPanel.Controls.Add($channelTextBox)
            $script:channelTextBoxes += $channelTextBox
        }
        $form.Refresh()
    }

    # Initialize channel naming display if files are already selected
    if ($script:selectedFiles.Count -gt 0) {
        & $UpdateChannelNaming
    }

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = $script:texts["continue"]
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Location = New-Object System.Drawing.Point(480, 520)
    $okButton.Font = $font
    $okButton.Add_Click({
        if ($script:selectedFiles.Count -ge 2) {
            $form.DialogResult = "OK"
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show($script:texts["minTwoFiles"], $script:texts["error"], "OK", "Warning")
        }
    })
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = $script:texts["cancel"]
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Location = New-Object System.Drawing.Point(600, 520)
    $cancelButton.Font = $font
    $cancelButton.Add_Click({
        $form.DialogResult = "Cancel"
        $form.Close()
    })
    $form.Controls.Add($cancelButton)

    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton

    $result = $form.ShowDialog()
    $form.Dispose()

    return $result -eq "OK"
}

# Output configuration dialog with Unicode support
function Show-OutputConfiguration {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $script:texts["outputName"]
    $form.Size = New-Object System.Drawing.Size(520, 320)
    $form.StartPosition = "CenterScreen"

    # Set font for Unicode support
    $font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9)
    $form.Font = $font

    # Output name
    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = $script:texts["outputNameDesc"]
    $nameLabel.Size = New-Object System.Drawing.Size(480, 30)
    $nameLabel.Location = New-Object System.Drawing.Point(20, 20)
    $nameLabel.Font = $font
    $form.Controls.Add($nameLabel)

    $nameTextBox = New-Object System.Windows.Forms.TextBox
    $nameTextBox.Text = "merged_channels"
    $nameTextBox.Size = New-Object System.Drawing.Size(480, 23)
    $nameTextBox.Location = New-Object System.Drawing.Point(20, 50)
    $nameTextBox.Font = $font
    $form.Controls.Add($nameTextBox)

    # Output location
    $locationLabel = New-Object System.Windows.Forms.Label
    $locationLabel.Text = $script:texts["outputLocationDesc"]
    $locationLabel.Size = New-Object System.Drawing.Size(480, 30)
    $locationLabel.Location = New-Object System.Drawing.Point(20, 90)
    $locationLabel.Font = $font
    $form.Controls.Add($locationLabel)

    $locationTextBox = New-Object System.Windows.Forms.TextBox
    $locationTextBox.Text = [Environment]::GetFolderPath("Desktop")
    $locationTextBox.Size = New-Object System.Drawing.Size(380, 23)
    $locationTextBox.Location = New-Object System.Drawing.Point(20, 120)
    $locationTextBox.Font = $font
    $form.Controls.Add($locationTextBox)

    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = $script:texts["browse"]
    $browseButton.Size = New-Object System.Drawing.Size(80, 23)
    $browseButton.Location = New-Object System.Drawing.Point(410, 120)
    $browseButton.Font = $font
    $browseButton.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.SelectedPath = $locationTextBox.Text
        if ($folderDialog.ShowDialog() -eq "OK") {
            $locationTextBox.Text = $folderDialog.SelectedPath
        }
    })
    $form.Controls.Add($browseButton)

    # Pyramid option
    $pyramidLabel = New-Object System.Windows.Forms.Label
    $pyramidLabel.Text = $script:texts["pyramidDesc"]
    $pyramidLabel.Size = New-Object System.Drawing.Size(480, 80)
    $pyramidLabel.Location = New-Object System.Drawing.Point(20, 160)
    $pyramidLabel.Font = $font
    $form.Controls.Add($pyramidLabel)

    $pyramidCheckBox = New-Object System.Windows.Forms.CheckBox
    $pyramidCheckBox.Text = $script:texts["pyramidOption"]
    $pyramidCheckBox.Checked = $true
    $pyramidCheckBox.Size = New-Object System.Drawing.Size(200, 23)
    $pyramidCheckBox.Location = New-Object System.Drawing.Point(20, 245)
    $pyramidCheckBox.Font = $font
    $form.Controls.Add($pyramidCheckBox)

    # Buttons
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = $script:texts["merge"]
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Location = New-Object System.Drawing.Point(300, 245)
    $okButton.Font = $font
    $okButton.Add_Click({
        if ([string]::IsNullOrWhiteSpace($nameTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show($script:texts["invalidName"], $script:texts["error"], "OK", "Warning")
            return
        }
        if ([string]::IsNullOrWhiteSpace($locationTextBox.Text) -or !(Test-Path $locationTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show($script:texts["selectOutput"], $script:texts["error"], "OK", "Warning")
            return
        }

        $script:outputName = $nameTextBox.Text -replace '[^\w\-_.]', '_'
        $script:outputPath = $locationTextBox.Text
        $script:createPyramid = $pyramidCheckBox.Checked

        $form.DialogResult = "OK"
        $form.Close()
    })
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = $script:texts["cancel"]
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Location = New-Object System.Drawing.Point(410, 245)
    $cancelButton.Font = $font
    $cancelButton.Add_Click({
        $form.DialogResult = "Cancel"
        $form.Close()
    })
    $form.Controls.Add($cancelButton)

    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton

    $result = $form.ShowDialog()
    $form.Dispose()

    return $result -eq "OK"
}

# Ultra-final merge channels function with channel naming support
function Invoke-ChannelMerge {
    try {
        # Create progress form
        $progressForm = New-Object System.Windows.Forms.Form
        $progressForm.Text = $script:texts["merging"]
        $progressForm.Size = New-Object System.Drawing.Si(440, 200)
        $progressForm.StartPosition = "CenterScreen"
        $progressForm.FormBorderStyle = "FixedDialog"
        $progressForm.MaximizeBox = $false
        $progressForm.MinimizeBox = $false

        $font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9)
        $progressForm.Font = $font

        $progressLabel = New-Object System.Windows.Forms.Label
        $progressLabel.Text = $script:texts["mergingDesc"]
        $progressLabel.Size = New-Object System.Drawing.Size(360, 80)
        $progressLabel.Location = New-Object System.Drawing.Point(20, 20)
        $progressLabel.Font = $font
        $progressForm.Controls.Add($progressLabel)

        $progressBar = New-Object System.Windows.Forms.ProgressBar
        $progressBar.Location = New-Object System.Drawing.Point(20, 90)
        $progressBar.Size = New-Object System.Drawing.Size(360, 23)
        $progressBar.Style = "Marquee"
        $progressForm.Controls.Add($progressBar)

        $progressForm.Show()
        $progressForm.Refresh()

        # Prepare file paths
        $tempFile = Join-Path $script:outputPath "$($script:outputName)_temp.tif"
        $finalFile = Join-Path $script:outputPath "$($script:outputName).tif"

        # Convert all paths to Unix-style for VIPS compatibility
        $vipsSelectedFiles = $script:selectedFiles | ForEach-Object { Convert-PathForVips $_ }
        $vipsTempFile = Convert-PathForVips $tempFile
        $vipsFinalFile = Convert-PathForVips $finalFile

        # Create diagnostic log
        $diagnosticLog = "$env:TEMP\vips_diagnostic.log"
        $channelInfo = ""
        for ($i = 0; $i -lt $script:selectedFiles.Count; $i++) {
            $channelName = if ($script:channelNames[$i]) { $script:channelNames[$i] } else { "Channel $($i+1)" }
            $channelInfo += "  Channel $($i+1): $channelName -> $($script:selectedFiles[$i])`n"
        }

        $diagnosticContent = @"
=== VIPS Diagnostic Log ===
VIPS Path: $($script:vipsPath)
Output Path: $($script:outputPath)
Temp File (Windows): $tempFile
Temp File (Unix): $vipsTempFile
Final File (Windows): $finalFile
Final File (Unix): $vipsFinalFile

Channel Configuration:
$channelInfo

Selected Files (Windows):
$($script:selectedFiles | ForEach-Object { "  $_" } | Out-String)

Selected Files (Unix):
$($vipsSelectedFiles | ForEach-Object { "  $_" } | Out-String)

File existence check:
$($script:selectedFiles | ForEach-Object { "  $_ : $(Test-Path $_)" } | Out-String)
"@
        Write-UTF8BOM -FilePath $diagnosticLog -Content $diagnosticContent

        # Create a temporary batch file for VIPS execution
        $batchFile = "$env:TEMP\vips_merge.bat"
        $logFile = "$env:TEMP\vips_output.log"

        # Build the VIPS bandjoin command with Unix-style paths
        # VIPS syntax: vips bandjoin "file1 file2 file3" output
        $fileList = $vipsSelectedFiles -join " "
        $mergeCommand = "`"$($script:vipsPath)`" bandjoin `"$fileList`" `"$vipsTempFile`""

        # Create batch file content step by step to avoid escaping issues
        $batchContent = @()
        $batchContent += "@echo off"
        $batchContent += "chcp 65001 >nul"
        $batchContent += "echo === VIPS Merge Execution ==="
        $batchContent += "echo Command: $mergeCommand"
        $batchContent += "echo."
        $batchContent += "echo Checking input files..."

        # Add file checks one by one
        foreach ($file in $script:selectedFiles) {
            $batchContent += "if exist `"$file`" (echo FOUND: `"$file`") else (echo MISSING: `"$file`")"
        }

        $batchContent += "echo."
        $batchContent += "echo Executing VIPS merge command..."
        $batchContent += $mergeCommand
        $batchContent += "echo Exit code: %ERRORLEVEL%"
        $batchContent += "echo."
        $windowsTempFile = $tempFile.Replace('/', '\')
        $batchContent += "if exist `"$windowsTempFile`" (echo SUCCESS: Temp file created) else (echo ERROR: Temp file not created)"

        # Write batch file
        $batchContent | Out-File -FilePath $batchFile -Encoding ASCII

        Write-Host "VIPS merge command: $mergeCommand"
        Write-Host "Diagnostic log: $diagnosticLog"

        # Execute the batch file
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$batchFile`"" -Wait -PassThru -RedirectStandardOutput $logFile -RedirectStandardError "$env:TEMP\vips_error.log"

        if ($process.ExitCode -ne 0 -or !(Test-Path $tempFile)) {
            $errorOutput = ""
            if (Test-Path "$env:TEMP\vips_error.log") {
                $errorOutput = Get-Content "$env:TEMP\vips_error.log" -Raw
            }
            if (Test-Path $logFile) {
                $commandOutput = Get-Content $logFile -Raw
                $errorOutput += "`n`nCommand Output:`n$commandOutput"
            }
            throw "VIPS bandjoin failed. Check diagnostic log at: $diagnosticLog`n`nError: $errorOutput"
        }

        # Create final file with tiffsave
        $saveOptions = @("--compression=lzw", "--bigtiff")
        if ($script:createPyramid) {
            $saveOptions += @("--tile", "--tile-width=256", "--tile-height=256", "--pyramid")
        }

        # Add channel names as TIFF tags if provided
        if ($script:channelNames | Where-Object { $_ -ne "" }) {
            $channelDescription = ($script:channelNames | ForEach-Object { if ($_ -eq "") { "Unnamed" } else { $_ } }) -join ";"
            $saveOptions += @("--description=`"Channels: $channelDescription`"")
        }

        $saveCommand = "`"$($script:vipsPath)`" tiffsave `"$vipsTempFile`" `"$vipsFinalFile`" " + ($saveOptions -join " ")

        # Create save batch file
        $saveBatchFile = "$env:TEMP\vips_save.bat"
        @"
@echo off
chcp 65001 >nul
echo === VIPS Save Execution ===
echo Command: $saveCommand
echo.
if exist "$tempFile" (echo FOUND: Temp file) else (echo MISSING: Temp file)
echo.
echo Executing VIPS save command...
$saveCommand
echo Exit code: %ERRORLEVEL%
echo.
if exist "$finalFile" (echo SUCCESS: Final file created) else (echo ERROR: Final file not created)
"@ | Out-File -FilePath $saveBatchFile -Encoding ASCII

        Write-Host "VIPS save command: $saveCommand"

        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$saveBatchFile`"" -Wait -PassThru -RedirectStandardOutput "$env:TEMP\vips_save.log" -RedirectStandardError "$env:TEMP\vips_save_error.log"

        if ($process.ExitCode -ne 0 -or !(Test-Path $finalFile)) {
            $errorOutput = ""
            if (Test-Path "$env:TEMP\vips_save_error.log") {
                $errorOutput = Get-Content "$env:TEMP\vips_save_error.log" -Raw
            }
            if (Test-Path "$env:TEMP\vips_save.log") {
                $commandOutput = Get-Content "$env:TEMP\vips_save.log" -Raw
                $errorOutput += "`n`nCommand Output:`n$commandOutput"
            }
            throw "VIPS tiffsave failed. Check diagnostic log at: $diagnosticLog`n`nError: $errorOutput"
        }

        # Clean up
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
        Remove-Item $batchFile -ErrorAction SilentlyContinue
        Remove-Item $saveBatchFile -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\vips_*.log" -ErrorAction SilentlyContinue

        $progressForm.Close()

        # Success message
        $successMessage = $script:texts["successDesc"] + "`n`n$finalFile"
        if ($script:channelNames | Where-Object { $_ -ne "" }) {
            $channelInfo = "`n`nCanaux configurés:`n" + ($script:channelNames | ForEach-Object { if ($_ -eq "") { "Sans nom" } else { $_ } } | ForEach-Object { "• $_" }) -join "`n"
            $successMessage += $channelInfo
        }
        $result = [System.Windows.Forms.MessageBox]::Show($successMessage, $script:texts["success"], "OKCancel", "Information")

        if ($result -eq "OK") {
            Start-Process "explorer.exe" -ArgumentList "/select,`"$finalFile`""
        }

        return $true

    } catch {
        if ($progressForm) { $progressForm.Close() }
        $errorMessage = "Merge failed: " + $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($errorMessage, $script:texts["error"], "OK", "Error")
        return $false
    }
}

# Main application function
function Start-TiffChannelMerger {
    try {
        # Language selection
        if (!(Show-LanguageSelection)) {
            return
        }

        Initialize-Texts $script:selectedLanguage

        # Check VIPS installation
        if (!(Test-VipsInstallation)) {
            $result = [System.Windows.Forms.MessageBox]::Show($script:texts["vipsNotFound"], $script:texts["appTitle"], "YesNo", "Question")
            if ($result -eq "Yes") {
                if (!(Install-Vips)) {
                    return
                }
            } else {
                return
            }
        }

        # Welcome
        if (!(Show-Welcome)) {
            return
        }

        # File selection
        if (!(Show-FileSelection)) {
            return
        }

        # Output configuration
        if (!(Show-OutputConfiguration)) {
            return
        }

        # Merge channels
        Invoke-ChannelMerge

    } catch {
        $errorMessage = "Application error: " + $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Error", "OK", "Error")
    }
}

# Start the application
Start-TiffChannelMerger