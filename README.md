# TIFF Channel Merger

Cross-platform application for merging multiple TIFF files (fluorescence channels) into a single multi-channel TIFF file optimized for QuPath microscopy image analysis.

## Platform Support

| Platform | Application | Language Support | Advanced Features | VIPS Installation |
|----------|-------------|------------------|-------------------|-------------------|
| **macOS** | Python/Tkinter GUI + CLI | 🇫🇷 🇬🇧 | ✅ Channel ordering<br>✅ Channel naming<br>✅ OME-XML<br>✅ Batch mode (GUI + CLI) | Embedded in the `.dmg` app (CLI: Homebrew) |
| **Windows** | PowerShell GUI | 🇫🇷 🇬🇧 | ✅ Channel ordering<br>✅ Channel naming<br>✅ OME-XML | Automatic Download |

## Quick Start

### macOS

1. Open `TIFF-Channel-Merger-<version>.dmg` and drag **TIFF Channel Merger** onto **Applications**.
2. Start the app from Launchpad, Spotlight or the Applications folder. On first launch, right-click the app and choose **Open**, because it is not signed by Apple.
3. Nothing else to install: Python, the interface and VIPS are embedded in the app.

To build the `.dmg` from the source code:

```bash
cd macOS/
./build_dmg.sh     # creates dist/TIFF-Channel-Merger-<version>.dmg
```

See the [macOS installation guide](macOS/README-macOS.md#-installation) for running from source, the command line, and troubleshooting.

### Windows

```cmd
cd windows\
TIFF-Channel-Merger.bat
```

## Features

### Core Functionality

- **Multi-channel merging**: Combine 2+ TIFF files into single multi-channel image
- **Interactive channel ordering**: Reorder files with ▲/▼ buttons to control channel assignment
- **Channel naming**: Assign custom names to each channel for QuPath identification
- **OME-XML metadata**: Automatic generation of sidecar files for QuPath compatibility
- **Pyramidal TIFF support**: Optimized for large images (>10,000×10,000 pixels)
- **LZW compression**: Reduced file sizes with lossless compression
- **BigTIFF support**: Handle files larger than 4GB

### User Experience

- **Bilingual interface**: Complete French/English localization
- **Modern GUI**: Python/Tkinter (macOS) and WinForms (Windows)
- **Visual file ordering**: See and rearrange channel order before merging
- **Channel labeling**: Name each channel for easier QuPath workflow
- **Progress tracking**: Visual feedback during processing
- **Auto-installation**: VIPS dependency management (Windows: automatic download; macOS: embedded in the `.dmg` app, Homebrew for the CLI)

### Technical Features

- **Cross-platform parity**: Identical features on macOS and Windows
- **VIPS integration**: Professional image processing library
- **QuPath optimization**: OME-XML metadata for automatic channel recognition
- **Error handling**: Comprehensive validation and user feedback

## Project Structure

```
TIFF-Channel-Merger/
├── macOS/                              # macOS Application (v4.0)
│   ├── tiff_channel_merger_gui.py      # Main Python/Tkinter GUI
│   ├── tiff_channel_merger_cli.py      # Command-line interface (scripting/automation)
│   ├── tiff_merger_core.py             # Shared merge/OME logic used by the GUI and CLI
│   ├── LAUNCH-HERE.command             # Double-clickable launcher (runs from source)
│   ├── tiff-channel-merger.sh          # Shell launcher script
│   ├── LAUNCH.txt                      # Launch guide (all methods, incl. CLI)
│   ├── build_dmg.sh                    # Builds the standalone app + .dmg
│   ├── QuPath_Import_Instructions.md   # QuPath integration guide
│   └── README-macOS.md                 # macOS-specific docs
├── windows/                            # Windows Application
│   ├── TIFF-Channel-Merger.ps1         # PowerShell GUI app
│   ├── TIFF-Channel-Merger.bat         # Windows launcher
│   ├── QuPath_Import_Instructions.md   # QuPath integration guide
│   └── README-Windows.md               # Windows-specific docs
├── vips_debug/                         # VIPS diagnostic scripts (Windows)
├── CLAUDE.md                           # Development documentation
└── README.md                           # This file
```

## Installation & Setup

### macOS Prerequisites

The `.dmg` app needs nothing else. For the CLI or for running from source without `pyvips`:

```bash
# Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install VIPS
brew install vips

# To run the GUI or build the .dmg from source, you need Python 3.9+ with Tk 8.6+
# (Apple's /usr/bin/python3 has Tk 8.5 and shows an empty window).
```

Homebrew itself must be installed manually, but once it is, both the GUI and the CLI detect a missing VIPS and offer to run `brew install vips` for you (`-y`/`--yes` on the CLI to skip the confirmation prompt).

### Windows Prerequisites

- Windows 10/11 (PowerShell 5.1+ pre-installed)
- .NET Framework 4.5+ (usually pre-installed)
- VIPS will be automatically downloaded and installed

## Usage Workflow

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

## QuPath Integration

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

## Technical Specifications

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

## Troubleshooting

### Common Issues

**macOS:**

- **VIPS not found** (CLI or running from source): the CLI and GUI offer to install it via Homebrew; if Homebrew isn't installed, install it, then run `brew install vips`. The `.dmg` app embeds VIPS
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

## Updates & Development

### Building from Source

**macOS:**

```bash
cd macOS/
# Build the standalone app and the .dmg
./build_dmg.sh
# Creates dist/TIFF Channel Merger.app and dist/TIFF-Channel-Merger-<version>.dmg
```

**Windows:**

- Edit `TIFF-Channel-Merger.ps1` as needed
- No compilation required - PowerShell script runs directly

### Contributing

- Follow platform-specific development patterns
- Maintain bilingual support in all user-facing text
- Test on both platforms when making changes
- Preserve compatibility with VIPS library updates

## License & Credits

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

**Goal**: Simplify multi-channel TIFF preparation for microscopy image analysis across macOS and Windows platforms.
