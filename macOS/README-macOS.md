# TIFF Channel Merger - macOS Version

## 📋 Overview

This is the macOS version of the TIFF Channel Merger application. It provides a native macOS GUI using Python/Tkinter for merging multiple TIFF files (fluorescence channels) into a single multi-channel TIFF file optimized for QuPath.

**Version 4.0** - Enhanced with advanced features matching the Windows version:
- Interactive channel ordering with ▲/▼ buttons
- Custom channel naming for QuPath integration
- OME-XML metadata support
- Modern Python/Tkinter interface

## 🚀 Quick Start

### Method 1: Easy Launch File (Recommended) ⭐
1. Double-click `LANCER-ICI.command`
2. A Terminal window opens with the GUI
3. No permissions issues!

### Method 2: Shell Script Launcher
1. Double-click `tiff-channel-merger.sh` in Finder
2. Or run from Terminal: `./tiff-channel-merger.sh`
3. The Python GUI will launch automatically

### Method 3: Application Bundle
1. Double-click `TIFF Channel Merger.app`
2. **Note**: May require granting permissions in System Preferences
3. If you see a permissions error, use Method 1 or 2 instead

### Method 4: Direct Python Execution
```bash
python3 tiff_channel_merger_gui.py
```

## 📋 System Requirements

- **Operating System**: macOS 10.12 Sierra or later
- **Python**: Python 3.6+ (pre-installed on macOS 10.15+)
- **Tkinter**: Usually included with Python (built-in)
- **VIPS**: Installed via Homebrew
- **Homebrew**: Package manager for macOS

## 🌍 Features

### Multilingual Support
- **English** and **French** interface
- Language selection at startup with modern dialog
- Complete localization of all UI elements and messages

### Advanced Channel Management
- **Interactive file ordering**: Use ▲/▼ buttons to reorder channels
- **Visual list**: See your files in the order they'll be merged
- **Channel naming**: Assign custom names to each channel
- **OME-XML metadata**: Channel names embedded in sidecar XML for QuPath

### VIPS Integration
- Automatic detection of VIPS installation paths:
  - `/opt/homebrew/bin/vips` (Apple Silicon)
  - `/usr/local/bin/vips` (Intel)
  - `/opt/local/bin/vips` (MacPorts)
- Helpful installation guidance if VIPS not found

### GUI Features
- **Modern Tkinter interface** with native macOS styling
- **Drag-and-drop file selection** with multi-select support
- **Live channel reordering**: Move files up/down in the list
- **Channel naming panel**: Name each channel individually
- **Output configuration**: Custom name and location
- **Pyramidal TIFF option**: For large images (>10,000×10,000 pixels)
- **Progress indicators**: Visual feedback during processing
- **Success confirmation**: With folder opening option

## 🔧 Technical Details

### Architecture
- **Language**: Python 3 with Tkinter
- **GUI Framework**: Tkinter (native Python GUI library)
- **Image Processing**: VIPS (libvips)
- **Packaging**: macOS Application Bundle (.app)
- **Metadata**: OME-XML sidecar files for QuPath

### VIPS Installation
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install VIPS
brew install vips
```

### File Processing
```bash
# Basic merge command
vips bandjoin "file1.tif file2.tif file3.tif" output.tif

# Pyramidal TIFF with compression
vips tiffsave input.tif output.tif --compression=lzw --tile --tile-width=256 --tile-height=256 --pyramid --bigtiff
```

### OME-XML Metadata & QuPath Integration
When channel names are provided, the application creates **4 files**:
1. **Multi-channel TIFF**: `merged_channels.tif` - Your final image
2. **OME-XML sidecar**: `merged_channels.ome.xml` - Complete metadata
3. **Channel names text file**: `merged_channels_channels.txt` - Simple list of names
4. **QuPath import script**: `QuPath_Import_merged_channels.groovy` - Automated import

See `QuPath_Import_Instructions.md` for detailed usage instructions.

## 🛠️ Troubleshooting

### VIPS Not Found
If the application reports VIPS is not installed:
1. Install Homebrew if not present
2. Run: `brew install vips`
3. Restart the application

### Python/Tkinter Issues
If you get Tkinter-related errors:
```bash
# For macOS with Homebrew Python
brew install python-tk

# Verify Tkinter is available
python3 -m tkinter
```

### Application Won't Open
If macOS blocks the application:
1. Right-click the application
2. Select "Open"
3. Click "Open" in the security dialog

### Permission Issues
If you get permission errors:
```bash
chmod +x tiff-channel-merger.sh
chmod +x create_app_bundle.sh
```

### Rebuilding the Application
```bash
./create_app_bundle.sh
```

## 📝 Usage Instructions

1. **Launch** the application (double-click `.app` or run shell script)
2. **Select language** (English/Français) in the initial dialog
3. **File Selection**:
   - Click "Add Files" to select TIFF files
   - Files appear in a list showing the channel order
   - Select a file and use ▲/▼ buttons to reorder
   - Top file = Channel 1, second = Channel 2, etc.
   - Use "Remove" to delete unwanted files
4. **Channel Naming** (optional):
   - Enter custom names for each channel
   - Names will appear in QuPath for easier identification
   - Leave blank to use default names (Channel_1, Channel_2, etc.)
5. **Configure Output**:
   - Enter output filename (without extension)
   - Choose destination folder (or use Desktop)
   - Check "Create pyramidal image" for large images
6. **Merge**:
   - Click "Merge" to start processing
   - Monitor progress with visual indicator
   - Open result folder when complete

## 🔗 Compatibility

### Supported File Formats
- Input: TIFF (.tif, .tiff, .TIF, .TIFF)
- Output: Multi-channel TIFF with LZW compression
- Metadata: OME-XML (.ome.xml sidecar)
- Pyramidal: BigTIFF format for files >4GB

### QuPath Integration
The output files are optimized for QuPath with OME-XML metadata:

**Automatic channel detection**:
1. Open the merged TIFF file in QuPath
2. QuPath automatically detects the `.ome.xml` file
3. Channel names appear as specified in the merger

**Manual setup** (if needed):
1. Go to Image → Image type → Fluorescence
2. Open View → Brightness/Contrast (Shift+C)
3. Adjust visibility and colors for each channel

## 📊 Performance Notes

- **Small images** (<10,000×10,000 pixels): Standard TIFF
- **Large images** (>10,000×10,000 pixels): Pyramidal TIFF recommended
- **Processing time**: Varies with file size and channel count
- **Memory usage**: Efficient through VIPS streaming processing
- **Python overhead**: Minimal, GUI is lightweight

## 🔄 Development

### Project Structure
```
macOS/
├── tiff_channel_merger_gui.py          # Main Python/Tkinter application
├── tiff-channel-merger.sh              # Shell launcher script
├── create_app_bundle.sh                # App bundle builder
├── TIFF Channel Merger.app/            # macOS application bundle
│   ├── Contents/
│   │   ├── Info.plist                  # Bundle metadata
│   │   ├── MacOS/launch.sh            # Launch script
│   │   └── Resources/                  # Application resources
│   │       └── tiff_channel_merger_gui.py
└── README-macOS.md                     # This file
```

### Building the Application
```bash
# Create/update the application bundle
./create_app_bundle.sh

# The resulting application will be:
# "TIFF Channel Merger.app"
```

### Architecture Changes from v3.0
- **v3.0**: AppleScript with basic dialogs
- **v4.0**: Python/Tkinter with advanced GUI
  - More flexible UI with better UX
  - Interactive channel ordering
  - Channel naming support
  - OME-XML metadata generation
  - Match Windows version features

### Key Python Modules
- `tkinter`: GUI framework (built-in)
- `subprocess`: VIPS command execution
- `pathlib`: Cross-platform path handling
- `os`, `sys`: System operations

## 📞 Support

For issues specific to the macOS version:
- **Python errors**: Check Python version with `python3 --version`
- **Tkinter errors**: Verify with `python3 -m tkinter`
- **VIPS errors**: Verify installation with `which vips` and `vips --version`
- **Application permissions**: Check System Preferences → Security & Privacy
- **Rebuild app**: Run `./create_app_bundle.sh` to recreate the bundle

## 🆕 Changelog

### Version 4.0
- Completely rewritten in Python/Tkinter
- Added interactive channel ordering with ▲/▼ buttons
- Added channel naming feature
- Added OME-XML metadata support
- Modern GUI matching Windows version
- Improved error handling and user feedback

### Version 3.0
- AppleScript-based implementation
- Basic multilingual support
- File selection dialogs
- Pyramidal TIFF option
