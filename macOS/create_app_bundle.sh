#!/bin/bash
# Kept for backward compatibility: the app is now built as a standalone
# PyInstaller bundle (Python + Tk embedded) by build_dmg.sh.
#
# The previous version of this script made an app that ran Apple's
# /usr/bin/python3, whose Tk 8.5 shows an empty window on recent macOS.
#
# Output: dist/TIFF Channel Merger.app and dist/TIFF-Channel-Merger-<version>.dmg

exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build_dmg.sh" "$@"
