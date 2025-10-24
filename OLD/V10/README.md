# 🔬 TIFF Channel Merger

Cross-platform application for merging multiple TIFF files (fluorescence channels) into a single multi-channel TIFF file optimized for QuPath microscopy image analysis.

## 🌍 Platform Support

| Platform | Application | Language Support | VIPS Installation |
|----------|-------------|------------------|-------------------|
| **macOS** | Native AppleScript App | 🇫🇷 🇬🇧 | Manual (Homebrew) |
| **Windows** | PowerShell GUI | 🇫🇷 🇬🇧 | Automatic Download |

## 🚀 Quick Start

### macOS
```bash
cd macOS/
open "TIFF Channel Merger.app"
```

### Windows
```cmd
cd windows\
TIFF-Channel-Merger.bat
```

## 📋 Features

### ✨ Core Functionality
- **Multi-channel merging**: Combine 2+ TIFF files into single multi-channel image
- **Pyramidal TIFF support**: Optimized for large images (>10,000×10,000 pixels)
- **LZW compression**: Reduced file sizes with lossless compression
- **BigTIFF support**: Handle files larger than 4GB

### 🌍 User Experience
- **Bilingual interface**: Complete French/English localization
- **Native GUI**: Platform-specific dialogs and file browsers
- **Drag-and-drop**: Easy file selection and path handling
- **Progress tracking**: Visual feedback during processing
- **Auto-installation**: VIPS dependency management (Windows)

### 🔧 Technical Features
- **Cross-platform**: Identical functionality on macOS and Windows
- **VIPS integration**: Professional image processing library
- **QuPath optimization**: Output format optimized for microscopy analysis
- **Error handling**: Comprehensive validation and user feedback

## 📁 Project Structure

```
TIFF-Channel-Merger/
├── macOS/                              # macOS Application
│   ├── TIFF Channel Merger.app/        # Ready-to-use macOS app
│   ├── fusion_canaux_gui_multilingual_fixed.applescript
│   ├── create_multilingual_app.sh      # App builder script
│   └── README-macOS.md                 # macOS-specific docs
├── windows/                            # Windows Application
│   ├── TIFF-Channel-Merger.ps1         # PowerShell GUI app
│   ├── TIFF-Channel-Merger.bat         # Windows launcher
│   └── README-Windows.md               # Windows-specific docs
├── fusion_canaux_simple_script.sh      # VIPS usage examples (reference)
├── CLAUDE.md                          # Development documentation
├── README.md                          # This file
└── OLD/                               # Development archives
```

## 🛠️ Installation & Setup

### macOS Prerequisites
```bash
# Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install VIPS
brew install vips
```

### Windows Prerequisites
- Windows 10/11 (PowerShell 5.1+ pre-installed)
- .NET Framework 4.5+ (usually pre-installed)
- VIPS will be automatically downloaded and installed

## 💡 Usage Workflow

1. **🌍 Language Selection**: Choose French or English interface
2. **📁 File Selection**: Add 2+ TIFF files representing different channels
3. **📝 Output Configuration**:
   - Set output filename
   - Choose destination folder
   - Enable pyramidal option for large images
4. **⚙️ Processing**: Automatic channel merging with progress feedback
5. **✅ Completion**: Open result folder or continue with analysis

## 🔗 QuPath Integration

The merged TIFF files are optimized for QuPath:

1. **Open** the merged file in QuPath
2. **Set image type**: Image → Image type → Fluorescence
3. **Adjust channels**: View → Brightness/Contrast (Shift+C)
4. **Customize**: Set colors and visibility for each channel

## 🎯 Technical Specifications

### Supported Formats
- **Input**: TIFF (.tif, .tiff) - single channel files
- **Output**: Multi-channel TIFF with metadata preservation
- **Compression**: LZW (lossless) for optimal file sizes
- **Large files**: BigTIFF format for >4GB images

### VIPS Commands Used
```bash
# Basic channel merging
vips bandjoin "ch1.tif ch2.tif ch3.tif" merged.tif

# Pyramidal TIFF creation
vips tiffsave merged.tif output.tif \
  --compression=lzw \
  --tile --tile-width=256 --tile-height=256 \
  --pyramid --bigtiff
```

### Performance Guidelines
- **Memory efficient**: Streaming processing via VIPS
- **Small images** (<1GB): Standard TIFF recommended
- **Large images** (>1GB): Pyramidal TIFF recommended
- **Processing time**: Scales with file size and channel count

## 🆘 Troubleshooting

### Common Issues

**macOS:**
- **VIPS not found**: Install via `brew install vips`
- **App won't open**: Right-click → Open to bypass security
- **Permission errors**: Check file/folder permissions

**Windows:**
- **PowerShell blocked**: Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **VIPS download fails**: Check internet connection and firewall
- **GUI not loading**: Ensure .NET Framework 4.5+ is installed

### Getting Help
- Check platform-specific README files in `macOS/` and `windows/` directories
- Review `CLAUDE.md` for development documentation
- Verify VIPS installation: `vips --version`

## 🔄 Updates & Development

### Building from Source

**macOS:**
```bash
cd macOS/
./create_multilingual_app.sh
```

**Windows:**
- Edit `TIFF-Channel-Merger.ps1` as needed
- No compilation required - PowerShell script runs directly

### Contributing
- Follow platform-specific development patterns
- Maintain bilingual support in all user-facing text
- Test on both platforms when making changes
- Preserve compatibility with VIPS library updates

## 📄 License & Credits

- **VIPS Library**: https://libvips.github.io/libvips/
- **QuPath**: https://qupath.github.io/
- **Development**: Cross-platform microscopy image processing tool

---

**🎯 Goal**: Simplify multi-channel TIFF preparation for microscopy image analysis across macOS and Windows platforms.