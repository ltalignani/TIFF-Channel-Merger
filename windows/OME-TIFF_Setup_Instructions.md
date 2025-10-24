# OME-TIFF Setup Instructions

> **⚠️ OBSOLETE - VERSION 3.10 UPDATE**
>
> This document describes OME-XML injection features that are **disabled by default** in version 3.10 to prevent file corruption with large pyramidal TIFFs.
>
> **For current v3.10 usage**, see `QuPath_Import_Instructions.md` which explains the recommended sidecar file method.
>
> This document is kept for reference only. The sidecar file approach is more reliable and preserves file integrity.

---

## Overview (Historical - v3.7)

Version 3.7 of TIFF Channel Merger could create **true OME-TIFF files** where channel names are embedded directly in the TIFF file. This feature is now disabled in v3.10 due to corruption issues with large files.

## Requirements

To enable OME-TIFF creation, you need Python with one of these libraries:

1. **tifftools** (recommended - best for pyramidal TIFFs)
2. **tifffile** (good alternative)
3. **Pillow** (basic support, may not preserve all pyramid levels)

## Installation Steps

### Step 1: Check if Python is installed

Open PowerShell or Command Prompt and run:

```powershell
python --version
```

If you see a version number (e.g., `Python 3.12.0`), Python is installed. Skip to Step 2.

If not, download and install Python from: https://www.python.org/downloads/

**Important:** During installation, check the box "Add Python to PATH"

### Step 2: Install a TIFF library

Choose ONE of the following options (tifftools is recommended):

#### Option A: tifftools (Recommended)

```powershell
pip install tifftools
```

**Advantages:**
- ✅ Preserves all pyramid levels
- ✅ Direct tag manipulation (fastest)
- ✅ Works with complex multi-page TIFFs

#### Option B: tifffile

```powershell
pip install tifffile
```

**Advantages:**
- ✅ Good pyramidal TIFF support
- ✅ Fast and reliable
- ✅ Part of scientific Python ecosystem

#### Option C: Pillow

```powershell
pip install Pillow
```

**Advantages:**
- ✅ Most common library (often already installed)
- ⚠️ May not preserve all pyramid levels

### Step 3: Verify Installation

Run the TIFF Channel Merger and check the output after merging. You should see:

```
=== Attempting to create true OME-TIFF ===
Injecting OME-XML into TIFF IMAGEDESCRIPTION tag...
Python found: C:\...\python.exe
Running: python inject_ome_xml.py ...

Trying method: tifftools...
✓ SUCCESS: OME-XML injected with tifftools (preserves all pyramid levels)

OME-TIFF created successfully!
QuPath should now automatically recognize channel names.

🎉 OME-TIFF CREATED SUCCESSFULLY!
```

## Troubleshooting

### Python not found

**Error:** `⚠️ Python not found - cannot inject OME-XML into TIFF`

**Solution:**
1. Install Python from python.org
2. During installation, check "Add Python to PATH"
3. Restart Command Prompt/PowerShell after installation

### All libraries failed to install

**Error:** `pip : The term 'pip' is not recognized...`

**Solution:**
```powershell
python -m pip install --upgrade pip
python -m pip install tifftools
```

### Library installed but still fails

**Solution:** Try a different library:
```powershell
# If tifftools doesn't work:
pip uninstall tifftools
pip install tifffile

# If tifffile doesn't work:
pip uninstall tifffile
pip install Pillow
```

### Permission errors

**Error:** `Access is denied` or `Permission denied`

**Solution:** Install for current user only:
```powershell
pip install --user tifftools
```

## Without Python: Sidecar XML Method

If you cannot install Python, the application still creates:
- `merged_channels.ome.xml` - OME metadata sidecar file
- `merged_channels_channels.txt` - Plain text channel names
- `QuPath_channel_setup.groovy` - QuPath script for manual import

You can use the Groovy script in QuPath to import channel names manually.

## Testing

To test if OME-TIFF creation works:

1. Run the merger with at least 2 images
2. Provide custom channel names (e.g., "DAPI", "FITC", "CY3")
3. Complete the merge
4. Check for the success message: `🎉 OME-TIFF CREATED SUCCESSFULLY!`
5. Open the TIFF in QuPath - channel names should appear automatically!

## Benefits of OME-TIFF

✅ **Automatic channel recognition** - No manual setup in QuPath
✅ **Portable** - Metadata travels with the TIFF file
✅ **Standard format** - Compatible with ImageJ, Fiji, QuPath, and other tools
✅ **Professional** - Industry-standard format for microscopy
