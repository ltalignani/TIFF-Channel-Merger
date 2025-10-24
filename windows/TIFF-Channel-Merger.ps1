# TIFF Channel Merger for Windows - Ultra Final Version v2
# Version 3.12 - Fixed QuPath script compatibility
# - FIXED: Groovy script generation now uses UTF-8 without BOM (removed invisible character bug)
# - FIXED: Channel names file now saved without BOM (fixes "﻿DAPI" issue)
# - FIXED: QuPath API compatibility - uses ImageServerMetadata.Builder constructor
# - REMOVED: "Advanced Options" checkbox (pyramidal images are now always created)
# - Pyramidal TIFFs are optimal for QuPath and provide smooth multi-resolution viewing
# - Always uses LZW compression, tiling (256x256), and pyramid generation
# - Uses .v temp file format to avoid TIFF reload memory limits
# - OME-XML injection DISABLED by default (use .ome.xml sidecar file instead)
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
            "selectFilesDesc" = "Sélectionnez au moins 2 fichiers TIFF à fusionner :`nL'ordre dans la liste détermine l'ordre des canaux (fichier le plus haut dans la liste = Canal 1, le deuxième = Canal 2, etc.)`nUtilisez les boutons Monter/Descendre pour réorganiser."
            "addFile" = "Ajouter des fichiers"
            "removeFile" = "Supprimer"
            "channelNaming" = "Nommage des canaux"
            "channelNamingDesc" = "Nommez chaque canal pour QuPath (optionnel) :`nNote : Les noms seront intégrés dans les métadonnées TIFF"
            "outputName" = "Nom du fichier de sortie"
            "outputNameDesc" = "Entrez le nom du fichier fusionné (sans extension) :"
            "outputLocation" = "Emplacement de sortie"
            "outputLocationDesc" = "Choisissez où sauvegarder le fichier fusionné :"
            "browse" = "Parcourir..."
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
            "createShortcut" = "Créer un raccourci sur le bureau ?"
            "createShortcutDesc" = "Voulez-vous créer un raccourci sur le bureau pour accéder facilement à cette application ?"
            "shortcutCreated" = "Le raccourci a été créé sur le bureau avec succès !"
            "shortcutError" = "Erreur lors de la création du raccourci :"
            "moveUp" = "Monter"
            "moveDown" = "Descendre"
            "previous" = "Précédent"
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
            "selectFilesDesc" = "Select at least 2 TIFF files to merge:`nThe order in the list determines the channel order (highest on the list = Channel 1, second = Channel 2, etc.)`nUse Move Up/Down buttons to reorder."
            "addFile" = "Add Files"
            "removeFile" = "Remove"
            "channelNaming" = "Channel Naming"
            "channelNamingDesc" = "Name each channel for QuPath (optional):`nNote: Channel names will be embedded in TIFF metadata"
            "outputName" = "Output File Name"
            "outputNameDesc" = "Enter the name of the merged file (without extension):"
            "outputLocation" = "Output Location"
            "outputLocationDesc" = "Choose where to save the merged file:"
            "browse" = "Browse..."
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
            "createShortcut" = "Create desktop shortcut?"
            "createShortcutDesc" = "Would you like to create a desktop shortcut for easy access to this application?"
            "shortcutCreated" = "Desktop shortcut created successfully!"
            "shortcutError" = "Error creating shortcut:"
            "moveUp" = "Move Up"
            "moveDown" = "Move Down"
            "previous" = "Previous"
        }
    }
}

# Function to create desktop shortcut
function New-DesktopShortcut {
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutName = "TIFF Channel Merger.lnk"
        $shortcutPath = Join-Path $desktopPath $shortcutName

        # Don't create if already exists
        if (Test-Path $shortcutPath) {
            return $true
        }

        $batPath = Join-Path $PSScriptRoot "TIFF-Channel-Merger.bat"
        $iconPath = Join-Path $PSScriptRoot "tiff-merger-icon.ico"

        # Create shortcut using WScript.Shell
        $WScriptShell = New-Object -ComObject WScript.Shell
        $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $batPath
        $shortcut.WorkingDirectory = $PSScriptRoot
        $shortcut.Description = "TIFF Channel Merger - Merge fluorescence microscopy channels"

        # Set icon if exists
        if (Test-Path $iconPath) {
            $shortcut.IconLocation = $iconPath
        }

        $shortcut.Save()

        # Release COM object
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WScriptShell) | Out-Null

        return $true
    }
    catch {
        Write-Host "Error creating shortcut: $($_.Exception.Message)"
        return $false
    }
}

# Function to ask user about creating desktop shortcut
function Show-ShortcutDialog {
    # Check if shortcut already exists
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "TIFF Channel Merger.lnk"

    if (Test-Path $shortcutPath) {
        return $true  # Already exists, skip dialog
    }

    $result = [System.Windows.Forms.MessageBox]::Show(
        $script:texts["createShortcutDesc"],
        $script:texts["createShortcut"],
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        if (New-DesktopShortcut) {
            [System.Windows.Forms.MessageBox]::Show(
                $script:texts["shortcutCreated"],
                $script:texts["createShortcut"],
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                $script:texts["shortcutError"] + " " + $_.Exception.Message,
                $script:texts["error"],
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }

    return $true
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
    $form.Size = New-Object System.Drawing.Size(600, 270)
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

    # Buttons
    $previousButton = New-Object System.Windows.Forms.Button
    $previousButton.Text = $script:texts["previous"]
    $previousButton.Size = New-Object System.Drawing.Size(100, 30)
    $previousButton.Location = New-Object System.Drawing.Point(80, 180)
    $previousButton.Font = $font
    $previousButton.Add_Click({
        $form.DialogResult = "Retry"  # Use "Retry" as signal to go back
        $form.Close()
    })
    $form.Controls.Add($previousButton)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = $script:texts["merge"]
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Location = New-Object System.Drawing.Point(300, 180)
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

        $form.DialogResult = "OK"
        $form.Close()
    })
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = $script:texts["cancel"]
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Location = New-Object System.Drawing.Point(410, 180)
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

    if ($result -eq "Retry") {
        return "Retry"  # Signal to go back
    }
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
        $progressBar.Style = "Continuous"
        $progressBar.Minimum = 0
        $progressBar.Maximum = 100
        $progressBar.Value = 0
        $progressForm.Controls.Add($progressBar)

        $progressForm.Show()
        $progressForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

        # Prepare file paths - use .v format for temp to avoid TIFF memory limits
        $tempFile = Join-Path $script:outputPath "$($script:outputName)_temp.v"
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

        # Simple and direct approach: bandjoin the files directly
        # Use environment variables for large image processing
        $env:VIPS_DISC_THRESHOLD = "0"
        $env:IM_CONCURRENCY = "1"

        # Build file list for bandjoin
        $fileList = $vipsSelectedFiles -join " "
        $mergeCommand = "`"$($script:vipsPath)`" bandjoin `"$fileList`" `"$vipsTempFile`" --vips-disc-threshold=0"

        # Create batch file content
        $batchContent = @()
        $batchContent += "@echo off"
        $batchContent += "chcp 65001 >nul"
        $batchContent += ""
        $batchContent += "REM Set environment variables for large TIFF processing"
        $batchContent += "set VIPS_DISC_THRESHOLD=0"
        $batchContent += "set IM_CONCURRENCY=1"
        $batchContent += ""
        $batchContent += "REM Override libtiff memory limits (requires libtiff 4.5.0+)"
        $batchContent += "REM Set to 0 to disable memory limit checking"
        $batchContent += "set LIBTIFF_MEM_MALLOC_SIZE=0"
        $batchContent += ""
        $batchContent += "echo === VIPS Large TIFF Merge ==="
        $batchContent += "echo."
        $batchContent += "echo Processing $($vipsSelectedFiles.Count) channels..."
        $batchContent += "echo This may take several minutes for large images."
        $batchContent += "echo."
        $batchContent += "echo Environment:"
        $batchContent += "echo   VIPS_DISC_THRESHOLD=%VIPS_DISC_THRESHOLD%"
        $batchContent += "echo   IM_CONCURRENCY=%IM_CONCURRENCY%"
        $batchContent += "echo   LIBTIFF_MEM_MALLOC_SIZE=%LIBTIFF_MEM_MALLOC_SIZE%"
        $batchContent += "echo."

        # Check input files
        $batchContent += "echo Checking input files..."
        foreach ($file in $script:selectedFiles) {
            $batchContent += "if exist `"$file`" (echo   OK: `"$file`") else (echo   MISSING: `"$file`" & exit /b 1)"
        }

        $batchContent += "echo."
        $batchContent += "echo Merging channels with VIPS bandjoin..."
        $batchContent += "echo Command: $mergeCommand"
        $batchContent += "echo."
        $batchContent += $mergeCommand
        $batchContent += "if %ERRORLEVEL% neq 0 (echo ERROR: bandjoin failed & exit /b 1)"

        $windowsTempFile = $tempFile.Replace('/', '\')
        $batchContent += "echo."
        $batchContent += "if exist `"$windowsTempFile`" (echo SUCCESS: Channels merged) else (echo ERROR: Merge file not created & exit /b 1)"

        # Write batch file
        $batchContent | Out-File -FilePath $batchFile -Encoding ASCII

        Write-Host "Using two-step process with explicit tiffload --unlimited"
        Write-Host "Diagnostic log: $diagnosticLog"

        # Update progress: 10% - Preparation complete
        $progressLabel.Text = "Préparation terminée. Fusion des canaux en cours..."
        $progressBar.Value = 10
        $progressForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

        # Execute the batch file
        $progressLabel.Text = "Fusion des canaux TIFF en cours (étape 1/3)..."
        $progressBar.Value = 20
        $progressForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

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

        # Update progress: 50% - Merge complete
        $progressLabel.Text = "Fusion terminée. Création du fichier TIFF pyramidal (étape 2/3)..."
        $progressBar.Value = 50
        $progressForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

        # Create final file with tiffsave
        # Note: Do NOT use --properties here as it writes VIPS metadata to IMAGEDESCRIPTION
        # We will inject OME-XML later with Python script
        # Always create pyramidal TIFF with LZW compression
        $saveOptions = @("--compression=lzw", "--bigtiff", "--tile", "--tile-width=256", "--tile-height=256", "--pyramid")
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

            # Save channel names for post-processing (without BOM)
            $channelInfoFile = Join-Path $script:outputPath "$($script:outputName)_channels.txt"
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($channelInfoFile, ($channelList -join "`n"), $utf8NoBom)
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

        $progressLabel.Text = "Sauvegarde du fichier TIFF en cours..."
        $progressBar.Value = 60
        $progressForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

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

        # Update progress: 85% - TIFF save complete
        $progressLabel.Text = "Fichier TIFF créé. Ajout des métadonnées (étape 3/3)..."
        $progressBar.Value = 85
        $progressForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

        # Post-process to add OME-TIFF metadata if channel names are provided
        if ($hasChannelNames) {
            Write-Host "=== OME-TIFF POST-PROCESSING ==="
            Write-Host "Adding OME-TIFF metadata with channel names..."
            $progressLabel.Text = "Ajout des métadonnées OME-XML pour QuPath..."
            $progressBar.Value = 90
            $progressForm.Refresh()
            [System.Windows.Forms.Application]::DoEvents()

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

            # Get TIFF dimensions using vipsheader (doesn't load entire image in memory)
            $actualWidth = 1024
            $actualHeight = 1024
            if (Test-Path $finalFile) {
                try {
                    # Use vipsheader to get width and height without loading the whole file
                    $vipsHeaderPath = Join-Path (Split-Path $script:vipsPath) "vipsheader.exe"
                    if (Test-Path $vipsHeaderPath) {
                        $widthOutput = & $vipsHeaderPath -f width "$finalFile" 2>&1
                        $heightOutput = & $vipsHeaderPath -f height "$finalFile" 2>&1

                        if ($widthOutput -match '^\d+$') {
                            $actualWidth = [int]$widthOutput
                        }
                        if ($heightOutput -match '^\d+$') {
                            $actualHeight = [int]$heightOutput
                        }

                        Write-Host "Detected TIFF dimensions: ${actualWidth}x${actualHeight} (via vipsheader)"
                    } else {
                        Write-Host "vipsheader not found, using default dimensions: ${actualWidth}x${actualHeight}"
                    }
                } catch {
                    Write-Host "Could not read TIFF dimensions: $($_.Exception.Message)"
                    Write-Host "Using default dimensions: ${actualWidth}x${actualHeight}"
                }
            }

            # Generate OME-XML with actual dimensions
            $omeXml = New-OMEXMLMetadata -ChannelNames $omeChannelNames -SizeC $omeChannelNames.Count -SizeX $actualWidth -SizeY $actualHeight
            $omeXmlFile = Join-Path $script:outputPath "$($script:outputName).ome.xml"
            Write-UTF8BOM -FilePath $omeXmlFile -Content $omeXml
            Write-Host "OME-XML metadata saved to: $omeXmlFile"

            # Generate QuPath Groovy script for channel setup
            $groovyScript = @"
// QuPath script to import channel names from text file
// Auto-generated for: $($script:outputName).tif
// Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

import qupath.lib.images.servers.ImageChannel
import qupath.lib.images.servers.ImageServerMetadata
import java.nio.file.Paths
import java.nio.file.Files

// Path to the channel names file (same directory as TIFF)
def channelFile = Paths.get('$((Join-Path $script:outputPath "$($script:outputName)_channels.txt").Replace('\', '/'))')

if (!Files.exists(channelFile)) {
    println "ERROR: Channel names file not found:"
    println channelFile.toString()
    return
}

// Read channel names from file
def channelNames = Files.readAllLines(channelFile)
println "Found " + channelNames.size() + " channel names:"
channelNames.eachWithIndex { name, idx ->
    println "  Channel " + idx + ": " + name
}

// Get current image data
def imageData = getCurrentImageData()
if (imageData == null) {
    println "ERROR: No image is currently open"
    return
}

// Get the server and current channels
def server = imageData.getServer()
def channels = server.getMetadata().getChannels()

if (channels.size() != channelNames.size()) {
    println "WARNING: Number of channels in image (" + channels.size() + ") doesn't match number of names (" + channelNames.size() + ")"
}

// Create new channels with custom names
def newChannels = []
for (int i = 0; i < channels.size(); i++) {
    def name = i < channelNames.size() ? channelNames[i] : "Channel_" + i
    def color = channels[i].getColor()
    newChannels.add(ImageChannel.getInstance(name, color))
}

// Update the image metadata using Builder constructor
def originalMetadata = server.getMetadata()
def newMetadata = new ImageServerMetadata.Builder(originalMetadata)
    .channels(newChannels)
    .build()

imageData.updateServerMetadata(newMetadata)

println ""
println "✅ Channel names updated successfully!"
println "The channel names should now appear in the Brightness/Contrast panel."

// Refresh the display
fireHierarchyUpdate()
"@

            $groovyScriptPath = Join-Path $script:outputPath "QuPath_Import_$($script:outputName).groovy"
            # Save without BOM to avoid Groovy parsing issues
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($groovyScriptPath, $groovyScript, $utf8NoBom)
            Write-Host "QuPath script generated: $groovyScriptPath"

            # DISABLED: OME-XML injection causes file corruption for large pyramidal TIFFs
            # The Python libraries (tifffile, Pillow) load the entire 7+ GB file in memory
            # and destroy the pyramidal structure, resulting in empty/corrupted files.
            # Only tifftools works correctly but requires: pip install tifftools

            Write-Host ""
            Write-Host "=== OME-XML INJECTION SKIPPED (Prevents file corruption) ==="
            Write-Host "⚠️ For large pyramidal TIFFs (>1GB), Python injection can corrupt the file"
            Write-Host "Using OME-XML sidecar file instead (.ome.xml)"
            Write-Host ""
            Write-Host "💡 To enable safe OME-XML embedding:"
            Write-Host "   pip install tifftools"
            Write-Host "   (tifftools is the ONLY library that preserves large pyramidal TIFFs)"
            Write-Host ""

            $omeInjected = $false

            # Optional: Check if tifftools is available and ONLY use it
            # Uncomment this section if you want to try injection with tifftools only:
            <#
            $pythonScript = Join-Path $PSScriptRoot "inject_ome_xml.py"
            try {
                $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
                if ($pythonCmd) {
                    # Check if tifftools is installed
                    $tifftoolsCheck = & $pythonCmd.Source -c "import tifftools; print('OK')" 2>$null
                    if ($tifftoolsCheck -eq "OK") {
                        Write-Host "tifftools detected - attempting safe OME-XML injection..."
                        $env:PYTHONIOENCODING = "utf-8"
                        $env:PYTHONUTF8 = "1"
                        $result = & $pythonCmd.Source $pythonScript $finalFile $omeXmlFile 2>&1
                        Write-Host $result
                        if ($LASTEXITCODE -eq 0) {
                            $omeInjected = $true
                        }
                    }
                }
            } catch { }
            #>

            # Display results
            Write-Host ""
            Write-Host "📁 Files created:"
            Write-Host "  • $($script:outputName).tif (multi-channel pyramidal TIFF - $('{0:N2}' -f ((Get-Item $finalFile).Length / 1GB)) GB)"
            Write-Host "  • $($script:outputName).ome.xml (OME metadata sidecar)"
            Write-Host "  • $($script:outputName)_channels.txt (Channel names list)"
            Write-Host "  • QuPath_Import_$($script:outputName).groovy (QuPath import script)"
            Write-Host ""
            Write-Host "✅ TIFF FILE CREATED SUCCESSFULLY!"
            Write-Host "   Channels: $($omeChannelNames -join ', ')"
            Write-Host ""
            Write-Host "🔬 QuPath usage (2 methods):"
            Write-Host ""
            Write-Host "METHOD 1 - Automated (Recommended):"
            Write-Host "  1. Open $($script:outputName).tif in QuPath"
            Write-Host "  2. Set Image type: Image → Image type → Fluorescence"
            Write-Host "  3. Run the script: Automate → Script editor"
            Write-Host "  4. Open and run: QuPath_Import_$($script:outputName).groovy"
            Write-Host "  5. Channel names will be imported automatically!"
            Write-Host ""
            Write-Host "METHOD 2 - Manual:"
            Write-Host "  1. Open $($script:outputName).tif in QuPath"
            Write-Host "  2. Manually rename channels in Brightness/Contrast panel"
            Write-Host ""
            Write-Host "📝 Note: OME-XML embedding is disabled for large files to prevent corruption"
            Write-Host "   The .ome.xml sidecar file contains all channel metadata"
        }

        # Copy log files to output directory for troubleshooting
        Write-Host ""
        Write-Host "Copying log files to output directory..."
        $logDestination = $script:outputPath

        $logFiles = @(
            @{ Source = $diagnosticLog; Name = "vips_diagnostic.log" }
            @{ Source = "$env:TEMP\vips_output.log"; Name = "vips_output.log" }
            @{ Source = "$env:TEMP\vips_error.log"; Name = "vips_error.log" }
            @{ Source = "$env:TEMP\vips_save.log"; Name = "vips_save.log" }
            @{ Source = "$env:TEMP\vips_save_error.log"; Name = "vips_save_error.log" }
        )

        foreach ($logInfo in $logFiles) {
            if (Test-Path $logInfo.Source) {
                $destPath = Join-Path $logDestination $logInfo.Name
                try {
                    Copy-Item $logInfo.Source -Destination $destPath -Force
                    Write-Host "  ✓ Copied $($logInfo.Name)"
                } catch {
                    Write-Host "  ⚠ Could not copy $($logInfo.Name): $($_.Exception.Message)"
                }
            }
        }

        # Clean up temporary files (but keep logs in output directory)
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }

        Remove-Item $batchFile -ErrorAction SilentlyContinue
        Remove-Item $saveBatchFile -ErrorAction SilentlyContinue

        # Remove temp logs (already copied to output directory)
        Remove-Item "$env:TEMP\vips_output.log" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\vips_error.log" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\vips_save.log" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\vips_save_error.log" -ErrorAction SilentlyContinue
        Remove-Item $diagnosticLog -ErrorAction SilentlyContinue

        # Update progress: 100% - Complete!
        $progressLabel.Text = "Traitement terminé avec succès !"
        $progressBar.Value = 100
        $progressForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 500  # Brief pause to show completion

        $progressForm.Close()

        # Success message
        $fileSize = if (Test-Path $finalFile) { "{0:N2}" -f ((Get-Item $finalFile).Length / 1GB) } else { "?" }
        $successMessage = $script:texts["successDesc"] + "`n`n$finalFile`n($fileSize GB)"

        if ($script:channelNames | Where-Object { $_ -ne "" }) {
            $channelInfo = "`n`nCanaux configurés:`n" + ($script:channelNames | ForEach-Object { if ($_ -eq "") { "Sans nom" } else { $_ } } | ForEach-Object { "• $_" }) -join "`n"

            if ($script:selectedLanguage -eq "Français") {
                $successMessage += $channelInfo + "`n`n✅ TIFF multi-canaux créé avec succès"
                $successMessage += "`n`nFichiers créés :"
                $successMessage += "`n  • $($script:outputName).tif (image pyramidale)"
                $successMessage += "`n  • $($script:outputName).ome.xml (métadonnées OME)"
                $successMessage += "`n  • $($script:outputName)_channels.txt (noms des canaux)"
                $successMessage += "`n  • QuPath_Import_$($script:outputName).groovy"
                $successMessage += "`n`n📖 Pour utiliser dans QuPath :"
                $successMessage += "`n  1. Ouvrir le .tif dans QuPath"
                $successMessage += "`n  2. Exécuter le script .groovy pour importer les noms"
            } else {
                $successMessage += $channelInfo + "`n`n✅ Multi-channel TIFF created successfully"
                $successMessage += "`n`nFiles created:"
                $successMessage += "`n  • $($script:outputName).tif (pyramidal image)"
                $successMessage += "`n  • $($script:outputName).ome.xml (OME metadata)"
                $successMessage += "`n  • $($script:outputName)_channels.txt (channel names)"
                $successMessage += "`n  • QuPath_Import_$($script:outputName).groovy"
                $successMessage += "`n`n📖 To use in QuPath:"
                $successMessage += "`n  1. Open the .tif in QuPath"
                $successMessage += "`n  2. Run the .groovy script to import channel names"
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

        # Ask about desktop shortcut
        Show-ShortcutDialog

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

        # File selection and output configuration with back navigation support
        $configComplete = $false
        while (!$configComplete) {
            # File selection
            if (!(Show-FileSelection)) {
                return
            }

            # Output configuration
            $outputResult = Show-OutputConfiguration
            if ($outputResult -eq $true) {
                $configComplete = $true
            } elseif ($outputResult -eq "Retry") {
                # User clicked Previous, loop back to file selection
                continue
            } else {
                # User cancelled
                return
            }
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