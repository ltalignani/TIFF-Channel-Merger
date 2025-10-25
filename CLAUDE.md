# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**TIFF Channel Merger** is a cross-platform application for merging multiple TIFF files (fluorescence channels) into a single multi-channel TIFF file optimized for QuPath microscopy image analysis.

- **macOS version**: Python 3 + Tkinter GUI (`macOS/tiff_channel_merger_gui.py`)
- **Windows version**: PowerShell + WinForms GUI (`windows/TIFF-Channel-Merger.ps1`)
- **Image processing**: VIPS (libvips) library for efficient TIFF manipulation
- **Bilingual**: Complete French/English localization throughout

## Platform-Specific Development Commands

### macOS

**Testing the Python GUI:**
```bash
cd macOS/
python3 tiff_channel_merger_gui.py
```

**Building the application bundle:**
```bash
cd macOS/
./create_app_bundle.sh
# Creates "TIFF Channel Merger.app"
```

**Running from shell script:**
```bash
cd macOS/
./tiff-channel-merger.sh
```

**Prerequisites:**
```bash
# Install VIPS (required for image processing)
brew install vips

# Verify VIPS installation
vips --version
which vips
```

### Windows

**Testing the PowerShell GUI:**
```powershell
cd windows\
.\TIFF-Channel-Merger.ps1
```

**Using the launcher:**
```cmd
cd windows\
TIFF-Channel-Merger.bat
```

**Set execution policy (if needed):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**VIPS installation:**
- VIPS is automatically downloaded and installed to `%LOCALAPPDATA%\vips\` by the application
- Downloads latest `vips-dev-w64-all-*.zip` from GitHub releases
- No admin rights required

## Architecture and Key Concepts

### Platform Parity

Both macOS and Windows versions have identical features:
- Interactive channel ordering (▲/▼ buttons to reorder files in list)
- Custom channel naming (assign meaningful names to each channel)
- OME-XML metadata generation (sidecar `.ome.xml` files for QuPath)
- Pyramidal TIFF support (for large images >10,000×10,000 pixels)
- Bilingual interface (French/English)

**Important**: When adding features, maintain parity across both platforms.

### Channel Order System

The order of files in the list determines the channel assignment:
- **First file** in list = **Channel 1** (C=0 in OME-XML)
- **Second file** = **Channel 2** (C=1)
- **Third file** = **Channel 3** (C=2), etc.

Users can reorder files using ▲ (move up) / ▼ (move down) buttons before merging.

### VIPS Processing Workflow

**macOS** (`tiff_channel_merger_gui.py` lines 484-547):
1. Set environment variables for large image processing (`VIPS_DISC_THRESHOLD=2g`)
2. Direct merge with `vips bandjoin "file1.tif file2.tif ..." temp.tif`
3. Save with compression: `vips tiffsave temp.tif output.tif --compression=lzw --tile --pyramid --bigtiff`
4. Generate OME-XML sidecar if channel names provided
5. Clean up temporary files

**Windows** (PowerShell version uses similar approach):
- Uses `.v` intermediate format to avoid memory issues with 4+ channels
- `tiffload --unlimited` for large file support
- Sequential processing to prevent memory exhaustion

### OME-XML Metadata

When users provide custom channel names, the application creates an **OME-XML sidecar file** (`.ome.xml`) alongside the merged TIFF. QuPath automatically detects this file and uses the channel names.

**Key files:**
- macOS: `create_ome_xml()` method at line 601
- OME-XML namespace: `http://www.openmicroscopy.org/Schemas/OME/2016-06`
- Channel names must escape XML special characters (`&`, `<`, `>`)

### Bilingual Support

All user-facing text is stored in dictionaries:
- macOS: `init_texts()` method at line 75 (Python dictionaries)
- Windows: String variables throughout PowerShell script

**When adding new UI elements**: Add both French and English versions.

### VIPS Path Detection (macOS)

VIPS can be installed in multiple locations on macOS (lines 154-175):
```python
possible_paths = [
    "/opt/homebrew/bin/vips",  # Apple Silicon (M1/M2/M3)
    "/usr/local/bin/vips",      # Intel Macs
    "/opt/local/bin/vips"       # MacPorts
]
```

The application checks each path and falls back to `which vips` if not found.

## Common Development Tasks

### Adding a New Feature

1. **Design the feature** - Ensure it makes sense for both platforms
2. **Implement on macOS** - Modify `tiff_channel_merger_gui.py`
3. **Implement on Windows** - Modify `TIFF-Channel-Merger.ps1`
4. **Update READMEs** - Document in platform-specific README files
5. **Test on both platforms** - Verify identical behavior

### Modifying the VIPS Command Pipeline

When changing how VIPS processes images:
- **Test with small images first** (< 1GB)
- **Then test with large images** (> 4GB, multiple channels)
- **Monitor memory usage** - VIPS should use disk caching for large files
- **Verify output** - Check in QuPath that channels appear correctly

Key VIPS flags:
- `--compression=lzw` - Lossless compression
- `--tile --tile-width=256 --tile-height=256` - Tiled format for pyramids
- `--pyramid` - Create multi-resolution pyramid
- `--bigtiff` - Support files > 4GB
- `--vips-disc-threshold=0` - Force disk-based processing

### Debugging VIPS Issues

**macOS**: The application creates diagnostic logs in the output directory:
- `vips_output.log` - VIPS stdout
- `vips_error.log` - VIPS stderr
- `vips_diagnostic.log` - Complete processing information

See `copy_logs_to_output()` method at line 548.

**Windows**: Use the `vips_debug/` directory scripts:
```cmd
cd vips_debug
check_vips.bat          # Verify VIPS installation
vips_tiffload.bat       # Check tiffload options (--unlimited support)
test_tiffsave_options.bat  # Check tiffsave options
```

### QuPath Integration

Output files are optimized for QuPath:
- Multi-channel TIFF format with LZW compression
- Pyramidal structure for smooth zooming on large images
- OME-XML sidecar with channel names (when provided)
- BigTIFF format for files > 4GB

**Testing with QuPath:**
1. Open merged TIFF in QuPath
2. Check that channel names appear automatically (if OME-XML was generated)
3. Verify channels can be toggled and colored in View → Brightness/Contrast (Shift+C)

## Important Technical Notes

### Memory Management

**Problem**: Merging 4+ large TIFF files can exhaust memory
**Solution** (macOS):
- Set `VIPS_DISC_THRESHOLD=2g` environment variable
- Use `--vips-disc-threshold=0` flag to force disk processing
- Process sequentially, not in parallel

**Solution** (Windows):
- Convert to `.v` format with `tiffload --unlimited`
- Use sequential processing
- Clean up intermediate files

See macOS line 492-496 for environment setup.

### Large File Support

For files > 4GB:
- **Always use `--bigtiff` flag**
- VIPS handles BigTIFF automatically
- QuPath supports BigTIFF natively

### File Encoding

**macOS**: UTF-8 encoding throughout (Python 3 default)
**Windows**: UTF-8 BOM for proper French accent rendering in console (version 3.10+)

## Repository Structure

```
TIFF-Channel-Merger/
├── macOS/                           # macOS application
│   ├── tiff_channel_merger_gui.py   # Main Python/Tkinter GUI (667 lines)
│   ├── tiff-channel-merger.sh       # Terminal launcher
│   ├── create_app_bundle.sh         # Builds .app bundle
│   └── TIFF Channel Merger.app/     # Bundled macOS application
├── windows/                         # Windows application
│   ├── TIFF-Channel-Merger.ps1      # Main PowerShell/WinForms GUI (~2400 lines)
│   ├── TIFF-Channel-Merger.bat      # Windows launcher with proper encoding
│   ├── inject_ome_xml.py            # Python script for OME-XML injection (advanced)
│   └── QuPath_Import_Instructions.md # Guide for importing channel names into QuPath
├── vips_debug/                      # VIPS diagnostic scripts (Windows only)
│   ├── check_vips.bat
│   ├── test_vips.ps1
│   └── vips_tiffload.bat
└── README.md                        # Main documentation
```

## VIPS Command Reference

### Basic channel merge
```bash
vips bandjoin "ch1.tif ch2.tif ch3.tif" merged.tif
```

### Create pyramidal TIFF with compression
```bash
vips tiffsave input.tif output.tif \
  --compression=lzw \
  --tile --tile-width=256 --tile-height=256 \
  --pyramid \
  --bigtiff
```

### Load with unlimited memory (Windows)
```bash
vips tiffload input.tif temp.v --unlimited
```

### Check VIPS version
```bash
vips --version
vips list classes    # List all available operations
```

## Version History

- **v4.0** (macOS): Complete rewrite in Python/Tkinter with advanced features
- **v3.10** (Windows): Memory fix for 4+ channels, OME-XML support
- **v3.0** (macOS): Original AppleScript implementation (legacy, in OLD/ directory)

## Key Dependencies

- **VIPS/libvips**: Core image processing library
  - macOS: Installed via Homebrew (`brew install vips`)
  - Windows: Auto-downloaded from GitHub releases
- **Python 3.6+** (macOS): Pre-installed on macOS 10.15+
- **Tkinter** (macOS): Usually included with Python
- **PowerShell 5.1+** (Windows): Pre-installed on Windows 10/11
- **.NET Framework 4.5+** (Windows): For WinForms support

## Testing Checklist

When making changes, verify:
- [ ] File selection works (minimum 2 files required)
- [ ] Channel ordering buttons (▲/▼) function correctly
- [ ] Channel names are saved and appear in OME-XML
- [ ] Both standard and pyramidal TIFF creation work
- [ ] Large files (> 4GB) process without memory errors
- [ ] OME-XML sidecar is created when channel names provided
- [ ] QuPath can open and recognize channels
- [ ] Both French and English interfaces display correctly
- [ ] Error messages are clear and helpful
