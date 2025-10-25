#!/bin/bash
# Simple launcher for TIFF Channel Merger
# Can be run from Terminal

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🔬 TIFF Channel Merger - Launching..."
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed."
    echo "Please install Python 3 to run this application."
    exit 1
fi

# Check if VIPS is installed
if ! command -v vips &> /dev/null; then
    echo "⚠️  Warning: VIPS is not installed."
    echo "The application will prompt you to install it."
    echo ""
fi

# Launch the GUI
cd "$SCRIPT_DIR"
python3 tiff_channel_merger_gui.py
