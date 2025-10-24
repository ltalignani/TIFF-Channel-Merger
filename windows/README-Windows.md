# TIFF Channel Merger - Windows Version

## 📋 Overview

This is the Windows version of the TIFF Channel Merger application, equivalent to the macOS version. It provides a native Windows GUI for merging multiple TIFF files (fluorescence channels) into a single multi-channel TIFF file optimized for QuPath.

## 🚀 Quick Start

### Method 1: Batch Launcher (Recommended)
1. Double-click `TIFF-Channel-Merger.bat`
2. The application will start automatically with proper console encoding

### Method 2: PowerShell Direct
1. Right-click `TIFF-Channel-Merger.ps1`
2. Select "Run with PowerShell"

## 📋 System Requirements

- **Operating System**: Windows 10/11
- **PowerShell**: Version 5.1 or higher (pre-installed on Windows 10/11)
- **VIPS**: Automatically downloaded and installed by the application
- **.NET Framework**: 4.5 or higher (for WinForms support)

## 🌍 Features

### Multilingual Support
- **English** and **French** interface
- Language selection at startup
- Complete localization of all dialogs and messages

### VIPS Auto-Installation
- Automatic detection of VIPS installation
- One-click download and installation if not found
- Uses latest VIPS release from GitHub
- Installs to user directory (no admin rights required)

### GUI Features
- Native Windows dialogs using WinForms
- File selection with drag-and-drop support
- **Channel ordering controls**: Use ▲/▼ buttons to reorder files (determines channel assignment)
- **Channel naming**: Assign custom names to each channel for QuPath integration
- Output name and location configuration
- Pyramidal TIFF option for large images
- Progress indicators during processing
- Success confirmation with folder opening option
- OME-XML metadata support for QuPath

## 🔧 Technical Details

### Architecture
- **Language**: PowerShell with .NET WinForms
- **GUI Framework**: System.Windows.Forms
- **Image Processing**: VIPS (libvips)
- **Installation**: Portable, no registry modifications

### VIPS Integration
- Downloads from: `https://github.com/libvips/libvips/releases/latest`
- Installs to: `%LOCALAPPDATA%\vips\`
- Uses full version: `vips-dev-w64-all-*.zip`
- Supports all TIFF compression options

### File Processing
```powershell
# Basic merge command
vips.exe bandjoin "file1.tif file2.tif file3.tif" "output.tif"

# Pyramidal TIFF with compression
vips.exe tiffsave "input.tif" "output.tif" --compression=lzw --tile --tile-width=256 --tile-height=256 --pyramid --bigtiff
```

## 🛠️ Troubleshooting

### PowerShell Execution Policy
If you get an execution policy error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### VIPS Manual Installation
If automatic installation fails:
1. Download from: https://github.com/libvips/build-win64-mxe/releases
2. Get the latest `vips-dev-w64-all-*.zip` file
3. Extract to: `%LOCALAPPDATA%\vips\`
4. Ensure `vips.exe` is at: `%LOCALAPPDATA%\vips\bin\vips.exe`

### Current Version Features (v3.10)
The current version includes:
- **Memory fix**: No more crashes with 4+ large images (uses `--unlimited` + `.v` format)
- **OME-XML metadata**: Generates sidecar `.ome.xml` files with complete channel metadata
- **QuPath integration**: Auto-generated Groovy script for easy channel name import
- **Character encoding**: Proper UTF-8 BOM support for French accents
- **Channel ordering**: Interactive reordering with visual ▲/▼ buttons
- **Channel naming**: Custom names saved in multiple formats for QuPath compatibility
- **VIPS optimization**: Uses tiffload --unlimited with sequential access for large files
- **Font rendering**: Microsoft Sans Serif for better Unicode support
- **Error handling**: Improved VIPS installation with detailed diagnostics
- **File integrity**: OME-XML injection disabled by default to prevent corruption of large pyramidal TIFFs

### QuPath Integration Methods

The application creates several files to help import channel names into QuPath:

1. **`.ome.xml` sidecar file**: Contains complete OME-XML metadata
2. **`_channels.txt` file**: Simple list of channel names (one per line)
3. **`QuPath_Import_*.groovy` script**: Auto-generated script for automated import

See `QuPath_Import_Instructions.md` for step-by-step usage instructions.

**Note:** OME-XML embedding into TIFF files is disabled by default in v3.10 to prevent file corruption with large pyramidal TIFFs. The sidecar file approach is more reliable and preserves file integrity.

### Common Issues
- **"Cannot load assembly"**: Install .NET Framework 4.5+
- **"VIPS not found"**: Allow automatic installation or install manually
- **"Access denied"**: Ensure you have write permissions to `%LOCALAPPDATA%`
- **"Memory errors with 4+ channels"**: Update to version 3.10 which fixes this issue
- **"Channel names not appearing in QuPath"**: Use the auto-generated Groovy script to import them (see QuPath_Import_Instructions.md)

## 📝 Usage Instructions

1. **Launch** the application using the `.bat` file
2. **Select language** (English/French)
3. **Allow VIPS installation** if prompted
4. **Add TIFF files** using the file selection dialog
5. **Reorder channels** using ▲ Monter/▼ Descendre buttons (first file = Channel 1, second = Channel 2, etc.)
6. **Name channels** (optional) for easier identification in QuPath
7. **Configure output** name and location
8. **Choose options** (pyramidal image recommended for large files)
9. **Start merge** and wait for completion
10. **Open result folder** when prompted

## 🔗 Compatibility

### Supported File Formats
- Input: TIFF (.tif, .tiff)
- Output: Multi-channel TIFF with LZW compression
- Pyramidal: BigTIFF format for large images

### QuPath Integration
The output files are optimized for QuPath:
- Multi-channel TIFF format
- Pyramidal structure for smooth zooming
- LZW compression for smaller file sizes
- BigTIFF support for files >4GB

## 📊 Performance Notes

- **Small images** (<1GB): Standard TIFF recommended
- **Large images** (>1GB): Pyramidal TIFF recommended
- **Processing time**: Depends on file size and number of channels
- **Memory usage**: Optimized through VIPS streaming processing

## 🔄 Updates

To update VIPS:
1. Delete `%LOCALAPPDATA%\vips\` folder
2. Run the application
3. Allow automatic re-installation

## 📞 Support

For issues specific to the Windows version:
- Check Windows Event Viewer for detailed error logs
- Ensure PowerShell execution policy allows script execution
- Verify .NET Framework version compatibility