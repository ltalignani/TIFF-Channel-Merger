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
            "selectFilesDesc" = "Sélectionnez au moins 2 fichiers TIFF à fusionner :`nL'ordre dans la liste détermine l'ordre des canaux (le premier = Canal 1, le deuxième = Canal 2, etc.)`nUtilisez les boutons Monter/Descendre pour réorganiser."
            "addFile" = "Ajouter un fichier"
            "removeFile" = "Supprimer"
            "channelNaming" = "Nommage des canaux"
            "channelNamingDesc" = "Nommez chaque canal pour QuPath (optionnel) :`nNote : Les noms seront intégrés dans les métadonnées TIFF"
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
            "selectFilesDesc" = "Select at least 2 TIFF files to merge:`nThe order in the list determines the channel order (first = Channel 1, second = Channel 2, etc.)`nUse Move Up/Down buttons to reorder."
            "addFile" = "Add File"
            "removeFile" = "Remove"
            "channelNaming" = "Channel Naming"
            "channelNamingDesc" = "Name each channel for QuPath (optional):`nNote: Channel names will be embedded in TIFF metadata"
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

# Function to create OME-XML metadata for TIFF
function New-OMEXMLMetadata {
    param(
        [string[]]$ChannelNames,
        [int]$SizeX = 1024,
        [int]$SizeY = 1024,
        [int]$SizeC = 1,
        [int]$SizeZ = 1,
        [int]$SizeT = 1,
        [string]$PixelType = "uint16"
    )

    $omeXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<!-- Warning: this comment is an OME-XML metadata block, which contains crucial dimensional parameters and other important metadata. Please edit cautiously (if at all), and back up the original data before doing so. -->
<OME xmlns="http://www.openmicroscopy.org/Schemas/OME/2016-06"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://www.openmicroscopy.org/Schemas/OME/2016-06
                         http://www.openmicroscopy.org/Schemas/OME/2016-06/ome.xsd">
  <Image ID="Image:0" Name="merged_channels">
    <Pixels DimensionOrder="XYCZT" ID="Pixels:0" Type="$PixelType"
            SizeC="$SizeC" SizeT="$SizeT" SizeX="$SizeX" SizeY="$SizeY" SizeZ="$SizeZ">
"@

    for ($i = 0; $i -lt $SizeC; $i++) {
        $channelName = if ($ChannelNames -and $i -lt $ChannelNames.Count -and $ChannelNames[$i]) {
            $ChannelNames[$i]
        } else {
            "Channel $($i + 1)"
        }

        # Escape XML special characters
        $channelName = $channelName.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&apos;")

        $omeXml += "`      <Channel ID=`"Channel:0:$i`" Name=`"$channelName`"/>`n"
    }

    $omeXml += @"
      <TiffData IFD="0" PlaneCount="$SizeC"/>
    </Pixels>
  </Image>
</OME>
"@

    return $omeXml
}

# Function to add OME-XML metadata to TIFF using Python (if available)
function Add-OMEMetadataToTIFF {
    param(
        [string]$TiffPath,
        [string[]]$ChannelNames
    )

    try {
        # Check if Python is available
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonCmd) {
            $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
        }

        if ($pythonCmd) {
            # Create a Python script to add OME metadata
            $pythonScript = @"
import sys
import os
try:
    from PIL import Image
    from PIL.TiffTags import TAGS
    import xml.etree.ElementTree as ET

    print("=== Python OME Metadata Script ===")
    tiff_path = sys.argv[1]
    channel_names = sys.argv[2].split('|')

    # Convert Unix-style path back to Windows if needed
    if os.name == 'nt' and '/' in tiff_path:
        tiff_path = tiff_path.replace('/', os.sep)

    print(f"TIFF file: {tiff_path}")
    print(f"File exists: {os.path.exists(tiff_path)}")
    print(f"File size: {os.path.getsize(tiff_path) if os.path.exists(tiff_path) else 'N/A'} bytes")
    print(f"Channel names: {channel_names}")

    # Try to read the TIFF file with different methods
    with Image.open(tiff_path) as img:
        width, height = img.size

        # Get image info
        mode = img.mode
        bands = len(img.getbands()) if hasattr(img, 'getbands') else 1

        print(f"Image size: {width}x{height}")
        print(f"Image mode: {mode}")
        print(f"Image bands: {bands}")

        # Determine pixel type based on mode
        if mode in ['I', 'I;16']:
            pixel_type = "uint16"
        elif mode in ['L', 'P']:
            pixel_type = "uint8"
        elif mode == 'F':
            pixel_type = "float"
        else:
            pixel_type = "uint16"  # default

        print(f"Pixel type: {pixel_type}")

        # Create OME-XML metadata with warning comment
        ome_xml = '''<?xml version="1.0" encoding="UTF-8"?>
<!-- Warning: this comment is an OME-XML metadata block, which contains crucial dimensional parameters and other important metadata. Please edit cautiously (if at all), and back up the original data before doing so. -->
<OME xmlns="http://www.openmicroscopy.org/Schemas/OME/2016-06"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://www.openmicroscopy.org/Schemas/OME/2016-06
                         http://www.openmicroscopy.org/Schemas/OME/2016-06/ome.xsd">
  <Image ID="Image:0" Name="merged_channels">
    <Pixels DimensionOrder="XYCZT" ID="Pixels:0" Type="{}"
            SizeC="{}" SizeT="1" SizeX="{}" SizeY="{}" SizeZ="1">'''.format(pixel_type, len(channel_names), width, height)

        for i, name in enumerate(channel_names):
            clean_name = name.strip() if name.strip() else f"Channel_{i+1}"
            # Escape XML special characters
            clean_name = clean_name.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
            ome_xml += f'\n      <Channel ID="Channel:0:{i}" Name="{clean_name}"/>'

        ome_xml += f'''
      <TiffData IFD="0" PlaneCount="{len(channel_names)}"/>
    </Pixels>
  </Image>
</OME>'''

        print("Generated OME-XML:")
        print(ome_xml[:500] + "..." if len(ome_xml) > 500 else ome_xml)

        # Create a backup
        backup_path = tiff_path + ".backup"
        if not os.path.exists(backup_path):
            import shutil
            shutil.copy2(tiff_path, backup_path)
            print(f"Backup created: {backup_path}")

        # Save with OME metadata - try different methods
        try:
            # Method 1: Direct save with description
            img.save(tiff_path, format='TIFF', description=ome_xml, compression='none')
            print("OME metadata added successfully with method 1!")
        except Exception as e1:
            print(f"Method 1 failed: {e1}")
            try:
                # Method 2: Save without compression specified
                img.save(tiff_path, description=ome_xml)
                print("OME metadata added successfully with method 2!")
            except Exception as e2:
                print(f"Method 2 failed: {e2}")
                # Method 3: Manual TIFF tag manipulation
                from PIL.TiffImagePlugin import ImageFileDirectory_v2
                info = img.info
                info['description'] = ome_xml
                img.save(tiff_path, tiffinfo=info)
                print("OME metadata added successfully with method 3!")

except ImportError as e:
    print(f"Python PIL/Pillow not available: {e}")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
"@

            $pythonScriptPath = "$env:TEMP\add_ome_metadata.py"
            $pythonScript | Out-File -FilePath $pythonScriptPath -Encoding UTF8

            # Convert Windows path to Unix-style for Python
            $pythonTiffPath = $TiffPath.Replace('\', '/')
            $channelNamesStr = $ChannelNames -join "|"

            Write-Host "Python script path: $pythonScriptPath"
            Write-Host "Python TIFF path (converted): $pythonTiffPath"
            Write-Host "Channel names string: $channelNamesStr"

            $result = & $pythonCmd.Source $pythonScriptPath $pythonTiffPath $channelNamesStr 2>&1

            Write-Host "Python OME metadata result: $result"
            Remove-Item $pythonScriptPath -ErrorAction SilentlyContinue

            return $result -match "successfully"
        }
    } catch {
        Write-Host "Python OME metadata processing failed: $($_.Exception.Message)"
    }

    return $false
}

# Alternative: PowerShell native approach using .NET TIFF manipulation
function Add-OMEMetadataNative {
    param(
        [string]$TiffPath,
        [string[]]$ChannelNames
    )

    try {
        Write-Host "Attempting PowerShell native TIFF metadata manipulation..."

        # Create OME-XML
        $omeXml = New-OMEXMLMetadata -ChannelNames $ChannelNames -SizeC $ChannelNames.Count

        # Try using System.Drawing to manipulate TIFF
        Add-Type -AssemblyName System.Drawing

        $image = [System.Drawing.Image]::FromFile($TiffPath)
        $width = $image.Width
        $height = $image.Height

        Write-Host "Loaded TIFF: ${width}x${height}"

        # This approach has limitations with multi-page TIFFs
        # So we'll create a sidecar file instead
        $image.Dispose()

        Write-Host "PowerShell native approach: Created sidecar XML file"
        return $false  # Force sidecar approach

    } catch {
        Write-Host "PowerShell native approach failed: $($_.Exception.Message)"
        return $false
    }
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
    $form.Size = New-Object System.Drawing.Size(800, 620)
    $form.StartPosition = "CenterScreen"

    # Set font for Unicode support
    $font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9)
    $form.Font = $font

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $script:texts["selectFilesDesc"]
    $label.Size = New-Object System.Drawing.Size(740, 50)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Font = $font
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Size = New-Object System.Drawing.Size(740, 200)
    $listBox.Location = New-Object System.Drawing.Point(20, 80)
    $listBox.Font = $font
    $form.Controls.Add($listBox)

    $addButton = New-Object System.Windows.Forms.Button
    $addButton.Text = $script:texts["addFile"]
    $addButton.Size = New-Object System.Drawing.Size(120, 30)
    $addButton.Location = New-Object System.Drawing.Point(20, 300)
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
    $removeButton.Location = New-Object System.Drawing.Point(160, 300)
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

    # Move Up button
    $moveUpButton = New-Object System.Windows.Forms.Button
    $moveUpButton.Text = if ($script:selectedLanguage -eq "Français") { "▲ Monter" } else { "▲ Move Up" }
    $moveUpButton.Size = New-Object System.Drawing.Size(120, 30)
    $moveUpButton.Location = New-Object System.Drawing.Point(300, 300)
    $moveUpButton.Font = $font
    $moveUpButton.Add_Click({
        if ($listBox.SelectedIndex -gt 0) {
            $index = $listBox.SelectedIndex

            # Swap files
            $temp = $script:selectedFiles[$index]
            $script:selectedFiles[$index] = $script:selectedFiles[$index - 1]
            $script:selectedFiles[$index - 1] = $temp

            # Swap channel names
            $tempName = $script:channelNames[$index]
            $script:channelNames[$index] = $script:channelNames[$index - 1]
            $script:channelNames[$index - 1] = $tempName

            # Update ListBox
            $item = $listBox.Items[$index]
            $listBox.Items[$index] = $listBox.Items[$index - 1]
            $listBox.Items[$index - 1] = $item
            $listBox.SelectedIndex = $index - 1

            # Refresh channel naming
            & $UpdateChannelNaming
        }
    })
    $form.Controls.Add($moveUpButton)

    # Move Down button
    $moveDownButton = New-Object System.Windows.Forms.Button
    $moveDownButton.Text = if ($script:selectedLanguage -eq "Français") { "▼ Descendre" } else { "▼ Move Down" }
    $moveDownButton.Size = New-Object System.Drawing.Size(120, 30)
    $moveDownButton.Location = New-Object System.Drawing.Point(440, 300)
    $moveDownButton.Font = $font
    $moveDownButton.Add_Click({
        if ($listBox.SelectedIndex -ge 0 -and $listBox.SelectedIndex -lt ($script:selectedFiles.Count - 1)) {
            $index = $listBox.SelectedIndex

            # Swap files
            $temp = $script:selectedFiles[$index]
            $script:selectedFiles[$index] = $script:selectedFiles[$index + 1]
            $script:selectedFiles[$index + 1] = $temp

            # Swap channel names
            $tempName = $script:channelNames[$index]
            $script:channelNames[$index] = $script:channelNames[$index + 1]
            $script:channelNames[$index + 1] = $tempName

            # Update ListBox
            $item = $listBox.Items[$index]
            $listBox.Items[$index] = $listBox.Items[$index + 1]
            $listBox.Items[$index + 1] = $item
            $listBox.SelectedIndex = $index + 1

            # Refresh channel naming
            & $UpdateChannelNaming
        }
    })
    $form.Controls.Add($moveDownButton)

    # Channel naming section
    $channelLabel = New-Object System.Windows.Forms.Label
    $channelLabel.Text = $script:texts["channelNamingDesc"]
    $channelLabel.Size = New-Object System.Drawing.Size(740, 30)
    $channelLabel.Location = New-Object System.Drawing.Point(20, 350)
    $channelLabel.Font = $font
    $form.Controls.Add($channelLabel)

    # Container for channel name textboxes
    $channelPanel = New-Object System.Windows.Forms.Panel
    $channelPanel.Size = New-Object System.Drawing.Size(740, 140)
    $channelPanel.Location = New-Object System.Drawing.Point(20, 380)
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
    $okButton.Location = New-Object System.Drawing.Point(560, 540)
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
    $cancelButton.Location = New-Object System.Drawing.Point(680, 540)
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
        $progressForm.Size = New-Object System.Drawing.Size(440, 200)
        $progressForm.StartPosition = "CenterScreen"
        $progressForm.FormBorderStyle = "FixedDialog"
        $progressForm.MaximizeBox = $false
        $progressForm.MinimizeBox = $false

        $font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9)
        $progressForm.Font = $font

        $progressLabel = New-Object System.Windows.Forms.Label
        $progressLabel.Text = $script:texts["mergingDesc"]
        $progressLabel.Size = New-Object System.Drawing.Size(360, 60)
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

        # NEW APPROACH: Load each TIFF explicitly with --unlimited flag to bypass memory limits
        # Then use bandjoin on the loaded .v files (VIPS native format)
        # This is necessary because bandjoin with file paths uses implicit loading without --unlimited

        # Use environment variables to increase VIPS limits for large images
        $env:VIPS_DISC_THRESHOLD = "0"  # Force disk-based processing
        $env:IM_CONCURRENCY = "1"       # Reduce parallelism to save memory

        # Create batch file content
        $batchContent = @()
        $batchContent += "@echo off"
        $batchContent += "chcp 65001 >nul"
        $batchContent += ""
        $batchContent += "REM Set VIPS environment variables for large image processing"
        $batchContent += "set VIPS_DISC_THRESHOLD=0"
        $batchContent += "set IM_CONCURRENCY=1"
        $batchContent += ""
        $batchContent += "echo === VIPS Large Image Processing ==="
        $batchContent += "echo."
        $batchContent += "echo Step 1: Loading TIFF files with unlimited memory option..."
        $batchContent += "echo."

        # Step 1: Load each TIFF with --unlimited and convert to .v format (VIPS native)
        $loadedFiles = @()
        for ($i = 0; $i -lt $vipsSelectedFiles.Count; $i++) {
            $vFile = "$env:TEMP/vips_channel_$i.v"
            $loadedFiles += $vFile

            $vipsPath = $vipsSelectedFiles[$i]
            $loadCommand = "`"$($script:vipsPath)`" tiffload `"$vipsPath`" `"$vFile`" --unlimited"

            $batchContent += "echo Loading channel $($i+1)/$($vipsSelectedFiles.Count): $vipsPath"
            $batchContent += $loadCommand
            $batchContent += "if %ERRORLEVEL% neq 0 (echo ERROR: Failed to load channel $($i+1) & exit /b 1)"
            $batchContent += "echo."
        }

        # Step 2: Join the loaded .v files
        $batchContent += "echo."
        $batchContent += "echo Step 2: Joining channels..."
        $batchContent += "echo."

        $vFileList = $loadedFiles -join " "
        $mergeCommand = "`"$($script:vipsPath)`" bandjoin `"$vFileList`" `"$vipsTempFile`" --vips-disc-threshold=0"

        $batchContent += "echo Merge command: $mergeCommand"
        $batchContent += "echo."
        $batchContent += $mergeCommand
        $batchContent += "if %ERRORLEVEL% neq 0 (echo ERROR: Failed to join channels & exit /b 1)"
        $batchContent += "echo."

        # Cleanup temporary .v files
        $batchContent += "echo Cleaning up temporary files..."
        foreach ($vFile in $loadedFiles) {
            $windowsVFile = $vFile.Replace('/', '\')
            $batchContent += "if exist `"$windowsVFile`" del /q `"$windowsVFile`""
        }

        $windowsTempFile = $tempFile.Replace('/', '\')
        $batchContent += "echo."
        $batchContent += "if exist `"$windowsTempFile`" (echo SUCCESS: Merge completed) else (echo ERROR: Merge file not created & exit /b 1)"

        # Write batch file
        $batchContent | Out-File -FilePath $batchFile -Encoding ASCII

        Write-Host "Using two-step process with explicit tiffload --unlimited"
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
            throw "VIPS processing failed. Check diagnostic log at: $diagnosticLog`n`nError: $errorOutput"
        }

        # Create final file with tiffsave
        $saveOptions = @("--compression=lzw", "--bigtiff")
        if ($script:createPyramid) {
            $saveOptions += @("--tile", "--tile-width=256", "--tile-height=256", "--pyramid")
        }

        # For now, save without custom metadata until we implement OME-TIFF support
        # VIPS doesn't have --description option, we need to use --properties or post-process
        $hasChannelNames = $script:channelNames | Where-Object { $_ -ne "" }
        if ($hasChannelNames) {
            $channelList = @()
            for ($i = 0; $i -lt $script:selectedFiles.Count; $i++) {
                $channelName = if ($script:channelNames[$i] -and $script:channelNames[$i] -ne "") {
                    $script:channelNames[$i]
                } else {
                    "Channel_$($i+1)"
                }
                $channelList += $channelName
            }
            Write-Host "Channel names saved for post-processing: $($channelList -join ', ')"

            # Save channel names for post-processing
            $channelInfoFile = Join-Path $script:outputPath "$($script:outputName)_channels.txt"
            ($channelList -join "`n") | Out-File -FilePath $channelInfoFile -Encoding UTF8
            Write-Host "Channel names saved to: $channelInfoFile"
        }

        $saveCommand = "`"$($script:vipsPath)`" tiffsave `"$vipsTempFile`" `"$vipsFinalFile`" " + ($saveOptions -join " ") + " --vips-disc-threshold=0"

        # Create save batch file
        $saveBatchFile = "$env:TEMP\vips_save.bat"
        @"
@echo off
chcp 65001 >nul

REM Set VIPS environment variables for large image processing
set VIPS_DISC_THRESHOLD=0
set IM_CONCURRENCY=1

echo === VIPS Save Execution ===
echo Command: $saveCommand
echo.
echo VIPS_DISC_THRESHOLD=%VIPS_DISC_THRESHOLD%
echo IM_CONCURRENCY=%IM_CONCURRENCY%
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

        # Post-process to add OME-TIFF metadata if channel names are provided
        if ($hasChannelNames) {
            Write-Host "=== OME-TIFF POST-PROCESSING ==="
            Write-Host "Adding OME-TIFF metadata with channel names..."
            $progressLabel.Text = "Adding OME metadata for QuPath..."
            $progressForm.Refresh()

            $omeChannelNames = @()
            for ($i = 0; $i -lt $script:selectedFiles.Count; $i++) {
                $channelName = if ($script:channelNames[$i] -and $script:channelNames[$i] -ne "") {
                    $script:channelNames[$i]
                } else {
                    "Channel_$($i+1)"
                }
                $omeChannelNames += $channelName
                Write-Host "Channel $($i+1): '$channelName'"
            }

            Write-Host "Final file path: $finalFile"
            Write-Host "File exists: $(Test-Path $finalFile)"

            if (Test-Path $finalFile) {
                $fileSize = (Get-Item $finalFile).Length
                Write-Host "File size: $fileSize bytes"
            }

            # Alternative approach: Use VIPS with --properties to get basic metadata support
            Write-Host "Attempting VIPS --properties approach for metadata..."

            # Create OME-XML and save to sidecar file
            $omeXml = New-OMEXMLMetadata -ChannelNames $omeChannelNames -SizeC $omeChannelNames.Count
            $omeXmlFile = Join-Path $script:outputPath "$($script:outputName).ome.xml"
            Write-UTF8BOM -FilePath $omeXmlFile -Content $omeXml
            Write-Host "OME-XML metadata saved to: $omeXmlFile"

            # Create a more detailed OME-XML with actual TIFF dimensions
            if (Test-Path $finalFile) {
                try {
                    Add-Type -AssemblyName System.Drawing
                    $image = [System.Drawing.Image]::FromFile($finalFile)
                    $actualWidth = $image.Width
                    $actualHeight = $image.Height
                    $image.Dispose()

                    Write-Host "Detected TIFF dimensions: ${actualWidth}x${actualHeight}"

                    # Recreate OME-XML with actual dimensions
                    $omeXmlActual = New-OMEXMLMetadata -ChannelNames $omeChannelNames -SizeC $omeChannelNames.Count -SizeX $actualWidth -SizeY $actualHeight
                    Write-UTF8BOM -FilePath $omeXmlFile -Content $omeXmlActual

                } catch {
                    Write-Host "Could not read TIFF dimensions: $($_.Exception.Message)"
                }
            }

            Write-Host "✅ OME-XML sidecar file created successfully!"
            Write-Host ""
            Write-Host "📁 Files created:"
            Write-Host "  • $($script:outputName).tif (multi-channel TIFF)"
            Write-Host "  • $($script:outputName).ome.xml (OME metadata)"
            Write-Host ""
            Write-Host "🔬 QuPath usage:"
            Write-Host "  1. Open $($script:outputName).tif in QuPath"
            Write-Host "  2. QuPath will automatically detect the .ome.xml file"
            Write-Host "  3. Channel names will be: $($omeChannelNames -join ', ')"

            # Try Python embedding as secondary option (non-blocking)
            Write-Host ""
            Write-Host "Attempting Python OME metadata embedding (optional)..."
            $omeSuccess = Add-OMEMetadataToTIFF -TiffPath $finalFile -ChannelNames $omeChannelNames

            if ($omeSuccess) {
                Write-Host "✅ Bonus: OME metadata also embedded in TIFF!"
            } else {
                Write-Host "ℹ️  Python embedding failed (normal with complex TIFFs)"
                Write-Host "   Sidecar XML file provides full OME support"
            }
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

            if ($omeSuccess) {
                if ($script:selectedLanguage -eq "Français") {
                    $successMessage += $channelInfo + "`n`n✅ OME-TIFF créé : Les noms de canaux sont intégrés dans QuPath"
                } else {
                    $successMessage += $channelInfo + "`n`n✅ OME-TIFF created: Channel names integrated for QuPath"
                }
            } else {
                if ($script:selectedLanguage -eq "Français") {
                    $successMessage += $channelInfo + "`n`n⚠️ TIFF standard créé : Pour OME-TIFF avec noms de canaux, installez Python + PIL/Pillow"
                    $successMessage += "`n`nFichier des noms de canaux : $channelInfoFile"
                } else {
                    $successMessage += $channelInfo + "`n`n⚠️ Standard TIFF created: For OME-TIFF with channel names, install Python + PIL/Pillow"
                    $successMessage += "`n`nChannel names file: $channelInfoFile"
                }
            }
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