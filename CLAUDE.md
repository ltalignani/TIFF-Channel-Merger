# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TIFF Channel Merger is a cross-platform application for merging multiple single-channel TIFF files (fluorescence microscopy channels) into a single multi-channel TIFF file optimized for QuPath image analysis software.

**Current Platform Support:**
- **Windows**: PowerShell GUI application (`windows/TIFF-Channel-Merger.ps1`)
- **macOS**: Python/Tkinter GUI (referenced in README but not present in current directory)

## Architecture

### Windows Application Structure

The Windows application is built using PowerShell with .NET WinForms:

1. **Main Application**: `windows/TIFF-Channel-Merger.ps1`
   - PowerShell script with WinForms-based GUI
   - Bilingual interface (French/English) with UTF-8 BOM encoding
   - Handles VIPS auto-installation from GitHub releases
   - Creates OME-XML metadata for QuPath integration
   - Uses Python/Pillow fallback for advanced metadata embedding

2. **Launcher**: `windows/TIFF-Channel-Merger.bat`
   - Sets UTF-8 console encoding (chcp 65001)
   - Launches PowerShell script with `-ExecutionPolicy Bypass`
   - Provides startup information and error handling

3. **QuPath Integration**:
   - `windows/QuPath_channel_setup.groovy`: Groovy script to import channel names into QuPath
   - `windows/QuPath_Import_Instructions.md`: User guide for QuPath integration

### Key Technical Components

**VIPS Integration:**
- Windows auto-installation: downloads from `https://github.com/libvips/libvips/releases/latest`
- Installs to: `%LOCALAPPDATA%\vips\`
- Uses `vips-dev-w64-all-*.zip` (full Windows build)
- Core commands:
  ```powershell
  vips.exe bandjoin "ch1.tif ch2.tif ch3.tif" "output.tif"
  vips.exe tiffsave "input.tif" "output.tif" --compression=lzw --tile --tile-width=256 --tile-height=256 --pyramid --bigtiff
  ```

**Metadata Generation:**
- Creates OME-XML sidecar files (`.ome.xml`) for channel metadata
- Attempts to embed metadata directly in TIFF using Python/Pillow if available
- Generates channel name text files for QuPath script compatibility
- Follows OME-XML 2016-06 schema specification

**GUI Architecture:**
- Language selection dialog on startup
- Multi-step wizard: file selection → channel ordering → channel naming → output config → processing
- Channel reordering with ▲/▼ buttons (affects channel assignment order)
- Real-time validation and error handling
- UTF-8 BOM encoding throughout for proper French accent display

## Development Commands

### Running the Application

**Windows:**
```cmd
cd windows
TIFF-Channel-Merger.bat
```

Or directly:
```powershell
cd windows
powershell.exe -ExecutionPolicy Bypass -File TIFF-Channel-Merger.ps1
```

### Testing VIPS Commands

```bash
# Check VIPS installation
vips --version

# Test basic merge (2 channels)
vips bandjoin "channel1.tif channel2.tif" merged.tif

# Create pyramidal TIFF
vips tiffsave merged.tif output.tif --compression=lzw --tile --tile-width=256 --tile-height=256 --pyramid --bigtiff
```

### Verifying Metadata

**Check OME-XML validity:**
```powershell
# Validate XML structure
[xml]$omeXml = Get-Content "output.ome.xml"
$omeXml.OME.Image.Pixels
```

**QuPath testing:**
1. Open `merged_channels.tif` in QuPath
2. Run `QuPath_channel_setup.groovy` script
3. Verify channel names appear in Brightness/Contrast panel

## Important Implementation Details

### Character Encoding (Critical for French UI)

The Windows application uses **UTF-8 BOM encoding** throughout:
- PowerShell file saved with UTF-8 BOM (signature: `0xEF 0xBB 0xBF`)
- Console encoding set to UTF-8: `chcp 65001`
- WinForms text rendering: `SetCompatibleTextRenderingDefault($false)`
- All string literals use proper UTF-8 encoding for accents (é, è, ê, à, etc.)

**When editing PowerShell files:** Always save with UTF-8 BOM to preserve French characters.

### VIPS Memory Management (Critical for 4+ Channels)

**Problem:** VIPS has a default 50MB cumulative memory limit for TIFF loading, causing errors like:
```
tiff2vips: Cumulated memory allocation of X + Y bytes is beyond the 52428800 cumulated byte limit
```

**Solution:** Use `tiffload --unlimited` and intermediate `.v` format:
```powershell
# Step 1: Pre-load each TIFF with unlimited memory to VIPS native format
vips.exe tiffload "input1.tif" "temp1.v" --unlimited --access sequential
vips.exe tiffload "input2.tif" "temp2.v" --unlimited --access sequential

# Step 2: Merge the .v files to a .v temp file (no memory limits)
vips.exe bandjoin "temp1.v temp2.v temp3.v" "merged_temp.v"

# Step 3: Convert .v to pyramidal TIFF (no reload issues)
vips.exe tiffsave "merged_temp.v" "output.tif" --compression=lzw --pyramid --tile --bigtiff
```

**Why this works:**
- `--unlimited` removes the 50MB denial-of-service limit when loading TIFF files
- `--access sequential` uses streaming I/O for memory efficiency
- `.v` format (VIPS native) has no memory constraints when reading/writing
- **Critical**: Using `.v` for the merged temp file prevents `tiffsave` from hitting the 50MB limit when creating the pyramid
- Only the final conversion from `.v` to `.tif` happens, avoiding TIFF reload issues

**Environment Variables for Large Images:**
```powershell
set VIPS_DISC_THRESHOLD=100m   # Use disk when image exceeds 100MB
set VIPS_CONCURRENCY=1         # Single thread to reduce memory pressure
set VIPS_NOVECTOR=1            # Disable vector operations for stability
```

### VIPS Command Syntax

**Critical:** VIPS `bandjoin` requires space-separated list in quotes:
```powershell
# CORRECT
vips.exe bandjoin "file1.tif file2.tif file3.tif" "output.tif"

# WRONG - will fail
vips.exe bandjoin file1.tif file2.tif file3.tif output.tif
```

### Channel Order Management

Channel order is determined by file list position:
- First file in list = Channel 0
- Second file = Channel 1, etc.
- GUI provides ▲/▼ buttons to reorder files before merging
- Channel names array must match file order

### OME-XML Metadata Structure

```xml
<OME xmlns="http://www.openmicroscopy.org/Schemas/OME/2016-06">
  <Image ID="Image:0" Name="merged_channels">
    <Pixels DimensionOrder="XYCZT" SizeC="N" SizeT="1" SizeX="W" SizeY="H" SizeZ="1" Type="uint16">
      <Channel ID="Channel:0:0" Name="CustomName1"/>
      <Channel ID="Channel:0:1" Name="CustomName2"/>
      <TiffData IFD="0" PlaneCount="N"/>
    </Pixels>
  </Image>
</OME>
```

### QuPath Integration Workflow

**Version 3.7+ with Python (Recommended):**

1. Application creates true OME-TIFF file with embedded metadata:
   - Uses `inject_ome_xml.py` script to inject OME-XML into TIFF IMAGEDESCRIPTION tag
   - Tries tifftools → tifffile → Pillow (in order of preference)
   - Preserves pyramidal structure and all metadata

2. QuPath **automatically recognizes** channel names when opening the TIFF
   - No manual setup required!
   - Channel names appear immediately in Brightness/Contrast panel

**Without Python (Fallback):**

1. Application generates metadata files:
   - `output.ome.xml`: Full OME-XML sidecar metadata
   - `output_channels.txt`: Line-separated channel names
   - `QuPath_channel_setup.groovy`: Auto-generated script with correct paths

2. User must manually import channel names:
   - Run the Groovy script in QuPath to import names, OR
   - Manually rename channels in Brightness/Contrast panel

**To enable OME-TIFF auto-recognition:**
```powershell
pip install tifftools  # Recommended
# OR: pip install tifffile
# OR: pip install Pillow
```

### Version History Context

The `OLD/` directory contains development versions V10-V25, showing iterative improvements:
- Early versions: Basic shell scripts
- V10-V14: Initial GUI development
- V16-V21: Channel ordering features added
- V22-V25: OME-XML integration and QuPath optimization

Current production version represents the consolidated Windows implementation.

## Common Development Patterns

### Adding New Language Strings

When adding UI elements, update the `Initialize-Texts` function with both French and English:

```powershell
if ($language -eq "Français") {
    $script:texts = @{
        "newFeature" = "Nouvelle fonctionnalité"
    }
} else {
    $script:texts = @{
        "newFeature" = "New Feature"
    }
}
```

### Handling VIPS Errors

VIPS errors should be caught and presented bilingually:
```powershell
try {
    & $vipsExe bandjoin $inputList $outputPath
    if ($LASTEXITCODE -ne 0) {
        throw "VIPS returned error code $LASTEXITCODE"
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        $script:texts["vipsError"] + "`n`n$_",
        $script:texts["error"],
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}
```

### Python/Pillow Fallback Pattern

The application attempts to use Python for advanced OME-TIFF embedding:
1. Check for `python` or `python3` command
2. Generate inline Python script with metadata
3. Execute and capture output for diagnostics
4. Fall back to sidecar XML if Python unavailable

## File Output Specifications

**Generated files for each merge operation:**
- `[name].tif`: Multi-channel TIFF with LZW compression
- `[name].ome.xml`: OME-XML sidecar metadata
- `[name]_channels.txt`: Plain text channel names (one per line)
- `QuPath_channel_setup.groovy`: Auto-generated QuPath script

**TIFF Properties:**
- Compression: LZW (lossless)
- Format: BigTIFF (for >4GB files)
- Pyramidal: Optional, recommended for images >10,000×10,000 pixels
- Tile size: 256×256 (for pyramidal TIFFs)

## Troubleshooting Reference

**PowerShell execution policy errors:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**VIPS auto-install failure:**
Check internet connection, firewall settings, and GitHub accessibility.
Manual install location: `%LOCALAPPDATA%\vips\bin\vips.exe`

**French characters display as ���:**
File encoding issue - resave PowerShell script with UTF-8 BOM encoding.

**QuPath doesn't show channel names:**
QuPath cannot auto-read OME sidecar files. User must run the provided Groovy script or manually rename channels.

**Memory errors with 4+ channels:**
Error: "Cumulated memory allocation... is beyond the 52428800 cumulated byte limit"
Solution: Version 3.6+ uses `tiffload --unlimited` + `.v` intermediate format to completely bypass the 50MB limit at all stages. Upgrade if using older version.

**tiffsave fails with Exit code: 1:**
This happens when the temp merged file is in `.tif` format and tiffsave tries to reload it (hits 50MB limit again).
Solution: Version 3.6+ uses `.v` format for temp merged file, eliminating this issue.

**Out of memory with very large TIFFs:**
Reduce `VIPS_DISC_THRESHOLD` to force earlier disk usage (e.g., "50m" instead of "100m").
Close other applications to free RAM during processing.
