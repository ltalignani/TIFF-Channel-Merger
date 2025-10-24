# TIFF Channel Merger - Windows Version

## 📋 Overview

This is the Windows version of the TIFF Channel Merger application, equivalent to the macOS version. It provides a native Windows GUI for merging multiple TIFF files (fluorescence channels) into a single multi-channel TIFF file optimized for QuPath.

## 🚀 Quick Start

### Method 1: Fixed Version (Recommended)
1. Double-click `TIFF-Channel-Merger-Fixed.bat`
2. The corrected application will start automatically

### Method 2: Original Version
1. Double-click `TIFF-Channel-Merger.bat`
2. Use if you don't experience encoding issues

### Method 3: PowerShell Direct
1. Right-click `TIFF-Channel-Merger-Fixed.ps1`
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
- Output name and location configuration
- Pyramidal TIFF option for large images
- Progress indicators during processing
- Success confirmation with folder opening option

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

### Fixed Version Improvements
The `-Fixed` version addresses:
- **Character encoding**: Proper UTF-8 support for French accents
- **VIPS download**: Updated URLs from correct repository
- **Font rendering**: Uses Segoe UI for better Unicode support
- **Error handling**: Improved VIPS installation with fallback URLs

### Common Issues
- **"Cannot load assembly"**: Install .NET Framework 4.5+
- **"VIPS not found"**: Allow automatic installation or install manually
- **"Access denied"**: Ensure you have write permissions to `%LOCALAPPDATA%`

## 📝 Usage Instructions

1. **Launch** the application using the `.bat` file
2. **Select language** (English/French)
3. **Allow VIPS installation** if prompted
4. **Add TIFF files** using the file selection dialog
5. **Configure output** name and location
6. **Choose options** (pyramidal image recommended for large files)
7. **Start merge** and wait for completion
8. **Open result folder** when prompted

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