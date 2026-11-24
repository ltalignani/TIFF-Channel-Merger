# TIFF Channel Merger - macOS Version

## 📋 Overview

This is the macOS version of the TIFF Channel Merger application. It provides a native macOS GUI using Python/Tkinter for merging multiple TIFF files (fluorescence channels) into a single multi-channel TIFF file optimized for QuPath.

**Version 4.0** - Enhanced with advanced features matching the Windows version:
- Interactive channel ordering with ▲/▼ buttons
- Custom channel naming for QuPath integration
- OME-XML metadata support
- Modern Python/Tkinter interface

## 🚀 Installation

### Install the app (users)

1. Open `TIFF-Channel-Merger-4.1.dmg`.
2. Drag **TIFF Channel Merger** onto the **Applications** folder.
3. Start it from Launchpad, Spotlight or the Applications folder. To keep it in the Dock, right-click its Dock icon while it runs and choose **Options → Keep in Dock**.

**First launch:** the app is not signed by Apple, so macOS may say it cannot verify the developer. Right-click the app in Applications, choose **Open**, then confirm. On recent macOS versions, you may instead have to go to **System Settings → Privacy & Security** and click **Open Anyway**. You only need to do this once.

**VIPS:** the app includes Python and its interface, but not VIPS, the image library that does the merging. If VIPS is missing, the app offers to install it with Homebrew. If Homebrew is not installed either, install it from [brew.sh](https://brew.sh), run `brew install vips` in the Terminal, then restart the app.

### Build the .dmg (developers)

```bash
cd macOS/
./build_dmg.sh
```

This creates `dist/TIFF Channel Merger.app` and `dist/TIFF-Channel-Merger-<version>.dmg` (about 12 MB). The script:

- picks a Python whose Tkinter uses Tk 8.6 or newer (Apple's `/usr/bin/python3` has Tk 8.5, which shows an empty window on recent macOS). It looks for a Python installed with [uv](https://docs.astral.sh/uv/) (`uv python install 3.13`), from python.org, or with Homebrew (`brew install python-tk@3.13`). Force a choice with `PYTHON=/path/to/python3 ./build_dmg.sh`;
- installs PyInstaller in `build/venv` (nothing is installed system-wide);
- builds the app icon from `windows/tiff-merger-icon.png`;
- builds the app, signs it ad hoc (no Apple notarization), and packages the `.dmg`.

The app is built for the processor of the Mac that builds it: a build made on Apple Silicon does not run on Intel Macs. To change the version number, edit `VERSION` in `build_dmg.sh`. `create_app_bundle.sh` now just calls `build_dmg.sh`.

### Run from the source code

The GUI needs a Python whose Tkinter uses Tk 8.6 or newer. Apple's `/usr/bin/python3` shows an empty window.

```bash
cd macOS/
python3 -c "import tkinter; print(tkinter.TkVersion)"   # must print 8.6 or higher
python3 tiff_channel_merger_gui.py
```

`LAUNCH-HERE.command` and `tiff-channel-merger.sh` run the same command using the `python3` found in your PATH.

### Command line (scripting/automation)

The CLI has no interface, so it works with any Python 3.9+, including `/usr/bin/python3`:

```bash
python3 tiff_channel_merger_cli.py merge --files ch1.tif ch2.tif --output-name merged --output-dir ~/Desktop
python3 tiff_channel_merger_cli.py batch --config batch_jobs.json
```

See [CLI Usage](#️-cli-usage) below for the full option list.

### Troubleshooting

- **Empty window**: the app is running with a Tk that is too old. Use the app from the `.dmg`, or run the source code with a Python that has Tk 8.6+ (see above).
- **`No module named '_tkinter'`** or **`Library not loaded: ...libtk8.6.dylib`**: this Python has no working Tkinter. Use the `.dmg` app, or install a Python as listed in "Build the .dmg".
- **"VIPS is not installed"** even though `vips` works in the Terminal: VIPS must be in `/opt/homebrew/bin`, `/usr/local/bin` or `/opt/local/bin`. An app opened from the Finder does not see the Terminal's PATH.

## 📋 System Requirements

- **Operating System**: a recent macOS on the same processor type (Apple Silicon or Intel) as the Mac that built the `.dmg`
- **VIPS**: installed with Homebrew (the app offers to install it)
- **Building or running from source**: Python 3.9+ with Tk 8.6+

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
- If VIPS isn't found and Homebrew is installed, both the GUI and the CLI offer to run `brew install vips` for you automatically
- Falls back to manual installation guidance if Homebrew itself isn't installed

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

### Batch Mode (GUI)
Click **Batch Mode** on the welcome screen to queue several merges (e.g. one per slide):
1. **Add Job** opens the usual file selection / naming / output screens, then **Add to Batch** returns to the job list (double-click a job or use **Edit** to change it).
2. **💾 Save List** / **📂 Load List** store the jobs as `batch_jobs.json`, the same format as the Windows GUI and the CLI.
3. **▶ Run Batch** merges the jobs one after the other. A failed job is marked *Error* and the batch continues.
4. A `batch_report.txt` is written to the first job's output folder.

Each job produces the same files as a single merge. The `vips_*.log` files are overwritten when several jobs share an output folder.

## ⌨️ CLI Usage

For scripting and automation, `tiff_channel_merger_cli.py` provides the same merge and batch functionality as the GUI, without any dialogs.

```bash
# Single merge (channel order = --files order)
python3 tiff_channel_merger_cli.py merge \
    --files ch1_dapi.tif ch2_gfp.tif ch3_rfp.tif \
    --names DAPI GFP RFP \
    --output-name merged_channels \
    --output-dir ~/Desktop

# Batch mode: process every job in a batch_jobs.json file
# (same JSON schema as the Windows GUI's Save/Load batch list, so files are interchangeable)
python3 tiff_channel_merger_cli.py batch --config batch_jobs.json
```

Run `python3 tiff_channel_merger_cli.py --help`, `merge --help`, or `batch --help` for the full option list (pyramidal TIFF is on by default, use `--no-pyramid` to disable it; `--lang fr` switches console messages to French). If VIPS is missing and Homebrew is installed, the CLI prompts to run `brew install vips` for you; pass `-y`/`--yes` to confirm automatically without a prompt (useful in non-interactive scripts, where the prompt is skipped anyway if stdin isn't a TTY). Shared logic lives in `tiff_merger_core.py`; the GUI uses it for batch job lists and reports, but keeps its own merge pipeline.

## 🛠️ Troubleshooting

### VIPS Not Found
If the application reports VIPS is not installed:
1. If Homebrew is already installed, accept the "Install VIPS now?" prompt (GUI dialog or CLI `[y/N]`) and it will run `brew install vips` for you
2. Otherwise, install Homebrew first, then run: `brew install vips`
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
chmod +x tiff-channel-merger.sh build_dmg.sh
```

### Rebuilding the Application
```bash
./build_dmg.sh
```

## 📝 Usage Instructions

1. **Launch** the application (from Applications after installing the `.dmg`, or from source)
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
├── tiff_channel_merger_cli.py          # Command-line interface (scripting/automation)
├── tiff_merger_core.py                 # Shared merge/OME logic used by the GUI and CLI
├── LAUNCH-HERE.command                 # Double-clickable launcher (source, needs Python with Tk 8.6+)
├── tiff-channel-merger.sh              # Shell launcher script
├── LAUNCH.txt                          # Launch guide (all methods, incl. CLI)
├── build_dmg.sh                        # Builds the standalone app + .dmg (PyInstaller)
├── create_app_bundle.sh                # Old name, now calls build_dmg.sh
├── QuPath_Import_Instructions.md       # QuPath channel-name import guide
├── build/                              # Build files (git-ignored)
├── dist/                               # Built app and .dmg (git-ignored)
├── OLD/                                 # Legacy v3.0 AppleScript implementation
└── README-macOS.md                     # This file
```

### Building the Application
```bash
# Build the standalone app and the .dmg
./build_dmg.sh

# Results:
# dist/TIFF Channel Merger.app
# dist/TIFF-Channel-Merger-<version>.dmg
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
- `tkinter`: GUI framework (needs Tk 8.6+; embedded in the `.dmg` app)
- `subprocess`: VIPS command execution
- `pathlib`: Cross-platform path handling
- `os`, `sys`: System operations

## 📞 Support

For issues specific to the macOS version:
- **Python errors**: Check Python version with `python3 --version`
- **Tkinter errors**: Verify with `python3 -m tkinter`
- **VIPS errors**: Verify installation with `which vips` and `vips --version`
- **Application blocked at first launch**: System Settings → Privacy & Security → Open Anyway
- **Rebuild app**: Run `./build_dmg.sh`

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
