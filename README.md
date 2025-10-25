# 🔬 TIFF Channel Merger

Cross-platform application for merging multiple TIFF files (fluorescence channels) into a single multi-channel TIFF file optimized for QuPath microscopy image analysis.

## 🌍 Platform Support

| Platform | Application | Language Support | Advanced Features | VIPS Installation |
|----------|-------------|------------------|-------------------|-------------------|
| **macOS** | Python/Tkinter GUI | 🇫🇷 🇬🇧 | ✅ Channel ordering<br>✅ Channel naming<br>✅ OME-XML | Manual (Homebrew) |
| **Windows** | PowerShell GUI | 🇫🇷 🇬🇧 | ✅ Channel ordering<br>✅ Channel naming<br>✅ OME-XML | Automatic Download |

## 🚀 Quick Start

### macOS

```bash
cd macOS/
open "TIFF Channel Merger.app"
# Or run directly:
./tiff-channel-merger.sh
```

### Windows

```cmd
cd windows\
TIFF-Channel-Merger.bat
```

## 📋 Features

### ✨ Core Functionality

- **Multi-channel merging**: Combine 2+ TIFF files into single multi-channel image
- **Interactive channel ordering**: Reorder files with ▲/▼ buttons to control channel assignment
- **Channel naming**: Assign custom names to each channel for QuPath identification
- **OME-XML metadata**: Automatic generation of sidecar files for QuPath compatibility
- **Pyramidal TIFF support**: Optimized for large images (>10,000×10,000 pixels)
- **LZW compression**: Reduced file sizes with lossless compression
- **BigTIFF support**: Handle files larger than 4GB

### 🌍 User Experience

- **Bilingual interface**: Complete French/English localization
- **Modern GUI**: Python/Tkinter (macOS) and WinForms (Windows)
- **Visual file ordering**: See and rearrange channel order before merging
- **Channel labeling**: Name each channel for easier QuPath workflow
- **Progress tracking**: Visual feedback during processing
- **Auto-installation**: VIPS dependency management (Windows)

### 🔧 Technical Features

- **Cross-platform parity**: Identical features on macOS and Windows
- **VIPS integration**: Professional image processing library
- **QuPath optimization**: OME-XML metadata for automatic channel recognition
- **Error handling**: Comprehensive validation and user feedback

## 📁 Project Structure

```
TIFF-Channel-Merger/
├── macOS/                              # macOS Application (v4.0)
│   ├── TIFF Channel Merger.app/        # Ready-to-use macOS app bundle
│   ├── tiff_channel_merger_gui.py      # Main Python/Tkinter GUI
│   ├── tiff-channel-merger.sh          # Terminal launcher
│   ├── create_app_bundle.sh            # App bundle builder
│   ├── fusion_canaux_gui_*.applescript # Legacy AppleScript (v3.0)
│   └── README-macOS.md                 # macOS-specific docs
├── windows/                            # Windows Application
│   ├── TIFF-Channel-Merger.ps1         # PowerShell GUI app
│   ├── TIFF-Channel-Merger.bat         # Windows launcher
│   ├── QuPath_Import_Instructions.md   # QuPath integration guide
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

# Python 3 is pre-installed on macOS 10.15+
# Tkinter is usually included with Python
```

### Windows Prerequisites

- Windows 10/11 (PowerShell 5.1+ pre-installed)
- .NET Framework 4.5+ (usually pre-installed)
- VIPS will be automatically downloaded and installed

## 💡 Usage Workflow

1. **🌍 Language Selection**: Choose French or English interface
2. **📁 File Selection**: Add 2+ TIFF files representing different channels
3. **🔀 Channel Ordering**: Use ▲/▼ buttons to arrange files (first = Channel 1, second = Channel 2, etc.)
4. **🏷️ Channel Naming** (optional): Assign meaningful names to each channel
5. **📝 Output Configuration**:
   - Set output filename
   - Choose destination folder
   - Enable pyramidal option for large images
6. **⚙️ Processing**: Automatic channel merging with OME-XML metadata generation
7. **✅ Completion**: Open result folder - files ready for QuPath with channel names!

## 🔗 QuPath Integration

The merged TIFF files are optimized for QuPath with **automatic channel recognition**:

**With OME-XML metadata** (when channel names are provided):

1. **Open** the merged TIFF file in QuPath
2. QuPath automatically detects the `.ome.xml` sidecar file
3. **Channel names appear as specified** in the merger
4. **Adjust**: View → Brightness/Contrast (Shift+C) to customize colors

**Without metadata** (channel names not provided):

1. **Open** the merged file in QuPath
2. **Set image type**: Image → Image type → Fluorescence
3. **Adjust channels**: View → Brightness/Contrast (Shift+C)
4. **Customize**: Manually set names, colors and visibility

## 🎯 Technical Specifications

### Supported Formats

- **Input**: TIFF (.tif, .tiff) - single channel files
- **Output**: Multi-channel TIFF with metadata preservation
- **Metadata**: OME-XML sidecar files (.ome.xml) for QuPath
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
# Build application bundle
./create_app_bundle.sh
# Application will be created as "TIFF Channel Merger.app"
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

### License

This project is licensed under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)**.

- ✅ Free for academic and research use
- ✅ Free for educational purposes
- ❌ Commercial use prohibited
- 📝 Attribution required
- 🔄 Derivative works must use the same license

See the [LICENSE](LICENSE) file for details.

### Authors

**Developed by:**

- **Céline Talignani** - Co-Developer
- **Loïc Talignani** - Co-Developer

### Third-Party Software

- **VIPS Library**: <https://libvips.github.io/libvips/> (LGPL 2.1+)
- **QuPath**: <https://qupath.github.io/> (GPL-3.0)

---

**🎯 Goal**: Simplify multi-channel TIFF preparation for microscopy image analysis across macOS and Windows platforms.
