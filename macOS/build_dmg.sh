#!/bin/bash
# Build a standalone "TIFF Channel Merger.app" (Python + Tk embedded with
# PyInstaller) and package it as a drag-to-Applications .dmg.
#
# Output:
#   dist/TIFF Channel Merger.app
#   dist/TIFF-Channel-Merger-<version>.dmg
#
# The app is self-contained: Python, Tk and libvips (through pyvips) are
# embedded, so users do not need Homebrew or VIPS.
#
# Build requirement: a Python 3.9+ whose tkinter uses Tk 8.6 or newer.
# Apple's /usr/bin/python3 ships Tk 8.5, which shows an empty window on
# recent macOS, so it is rejected. Override the choice with:
#   PYTHON=/path/to/python3 ./build_dmg.sh
#
# Copyright (c) 2024 Loïc Talignani & Céline Talignani
# Licensed under CC BY-NC-SA 4.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="TIFF Channel Merger"
VERSION="4.1"
BUNDLE_ID="org.tiffchannelmerger.app"
PYVIPS_VERSION="3.2.0"
PYVIPS_BINARY_VERSION="8.18.7"   # = the libvips version embedded in the app
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
ICON_PNG="$SCRIPT_DIR/../windows/tiff-merger-icon.png"
APP_PATH="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/TIFF-Channel-Merger-$VERSION.dmg"

# ---------------------------------------------------------------------------
# 1. Find a Python with Tk >= 8.6
# ---------------------------------------------------------------------------
has_modern_tk() {
    "$1" -c 'import sys, tkinter; sys.exit(0 if sys.version_info >= (3, 9) and tkinter.TkVersion >= 8.6 else 1)' 2>/dev/null
}

find_python() {
    local candidates=()
    [ -n "${PYTHON:-}" ] && candidates+=("$PYTHON")
    if command -v uv >/dev/null 2>&1; then
        for v in 3.13 3.12 3.11; do
            local p
            p="$(uv python find --managed-python "$v" 2>/dev/null || true)"
            [ -n "$p" ] && candidates+=("$p")
        done
    fi
    candidates+=(
        /Library/Frameworks/Python.framework/Versions/3.13/bin/python3
        /Library/Frameworks/Python.framework/Versions/3.12/bin/python3
        /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3
        /usr/local/bin/python3.13 /usr/local/bin/python3.12 /usr/local/bin/python3
    )
    for p in "${candidates[@]}"; do
        if [ -x "$p" ] && has_modern_tk "$p"; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

echo "🔍 Looking for a Python with Tk 8.6+..."
if ! PY="$(find_python)"; then
    cat >&2 <<'EOF'
❌ No Python with Tk 8.6 or newer was found.

Install one of these, then run this script again:
  • uv python install 3.13                (https://docs.astral.sh/uv/)
  • the macOS installer from https://www.python.org/downloads/
  • brew install python-tk@3.13

Or point the script to a suitable interpreter:
  PYTHON=/path/to/python3 ./build_dmg.sh
EOF
    exit 1
fi
echo "   Using $PY ($("$PY" -c 'import sys, tkinter; print(sys.version.split()[0], "/ Tk", tkinter.Tcl().eval("info patchlevel"))'))"

# ---------------------------------------------------------------------------
# 2. Build environment with PyInstaller
# ---------------------------------------------------------------------------
echo "📦 Preparing build environment..."
rm -rf "$BUILD_DIR" "$APP_PATH" "$DMG_PATH"
mkdir -p "$BUILD_DIR" "$DIST_DIR"
"$PY" -m venv "$BUILD_DIR/venv"
"$BUILD_DIR/venv/bin/python" -m pip install --quiet --upgrade pip
"$BUILD_DIR/venv/bin/python" -m pip install --quiet "pyinstaller>=6.10"

# libvips is embedded through pyvips-binary (a self-contained libvips build).
# pyvips is only published as source: when it is installed, it compiles its
# own _libvips module against any libvips that pkg-config finds (e.g.
# Homebrew's), overwriting the self-contained one. pkg-config is disabled
# here so the app never depends on Homebrew.
echo "🧩 Installing embedded libvips (pyvips $PYVIPS_VERSION / libvips $PYVIPS_BINARY_VERSION)..."
PKG_CONFIG=/usr/bin/false PKG_CONFIG_PATH=/nonexistent \
    "$BUILD_DIR/venv/bin/python" -m pip install --quiet --no-cache-dir \
    "pyvips==$PYVIPS_VERSION" "pyvips-binary==$PYVIPS_BINARY_VERSION"

# Fail early if the libvips module links to anything outside the venv
if DYLD_PRINT_LIBRARIES=1 "$BUILD_DIR/venv/bin/python" -c "import pyvips" 2>&1 \
        | grep -E "/(opt/homebrew|usr/local|opt/local)/" ; then
    echo "❌ pyvips loads libraries from Homebrew/MacPorts (listed above): the app would not work on other Macs." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. App icon (.icns) from the shared PNG icon
# ---------------------------------------------------------------------------
echo "🎨 Creating app icon..."
ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$BUILD_DIR/AppIcon.icns"

# ---------------------------------------------------------------------------
# 4. Standalone .app
# ---------------------------------------------------------------------------
echo "🔨 Building $APP_NAME.app (this takes a minute)..."
"$BUILD_DIR/venv/bin/pyinstaller" \
    --noconfirm --clean --log-level WARN \
    --windowed \
    --name "$APP_NAME" \
    --icon "$BUILD_DIR/AppIcon.icns" \
    --osx-bundle-identifier "$BUNDLE_ID" \
    --hidden-import _libvips \
    --distpath "$DIST_DIR" \
    --workpath "$BUILD_DIR/pyinstaller" \
    --specpath "$BUILD_DIR" \
    "$SCRIPT_DIR/tiff_channel_merger_gui.py"

# Version shown in Finder > Get Info and About
PLIST="$APP_PATH/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$PLIST"
plutil -replace CFBundleVersion -string "$VERSION" "$PLIST"
plutil -replace NSHighResolutionCapable -bool true "$PLIST"

# Editing Info.plist invalidates PyInstaller's ad-hoc signature: sign again
# (ad-hoc only, the app is not notarized by Apple)
codesign --force --deep --sign - "$APP_PATH" >/dev/null 2>&1
codesign --verify --deep "$APP_PATH"

# The built app must merge with its own libvips, without Homebrew: run its
# headless self-test with a minimal PATH and check every loaded library
echo "🧪 Testing the embedded libvips..."
SELF_TEST_LOG="$BUILD_DIR/self_test.log"
env -i HOME="$HOME" PATH=/usr/bin:/bin DYLD_PRINT_LIBRARIES=1 \
    "$APP_PATH/Contents/MacOS/$APP_NAME" --self-test >"$SELF_TEST_LOG" 2>&1 || true
grep -v "^dyld" "$SELF_TEST_LOG" | sed 's/^/   /'
if ! grep -q "SELF-TEST OK" "$SELF_TEST_LOG"; then
    echo "❌ Self-test failed (full log: $SELF_TEST_LOG)" >&2
    exit 1
fi
if grep -E "^dyld.*/(opt/homebrew|usr/local|opt/local)/" "$SELF_TEST_LOG"; then
    echo "❌ The app loads libraries from Homebrew/MacPorts (listed above)." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 5. Drag-to-Applications disk image
# ---------------------------------------------------------------------------
echo "💿 Creating disk image..."
STAGING="$BUILD_DIR/dmg"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -quiet -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH"

echo ""
echo "✅ Done"
echo "   App: $APP_PATH"
echo "   DMG: $DMG_PATH ($(du -h "$DMG_PATH" | cut -f1))"
echo ""
echo "To install: open the .dmg and drag \"$APP_NAME\" onto Applications."
