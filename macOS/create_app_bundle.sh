#!/bin/bash
# Create macOS Application Bundle for TIFF Channel Merger
# Version 4.0 - Python/Tkinter implementation with direct launch

set -e

echo "Creating TIFF Channel Merger.app bundle..."

# Define paths
APP_NAME="TIFF Channel Merger"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_PATH="$SCRIPT_DIR/${APP_NAME}.app"
CONTENTS_PATH="$APP_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"

# Remove old app if exists
if [ -d "$APP_PATH" ]; then
    echo "Removing old application bundle..."
    rm -rf "$APP_PATH"
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$MACOS_PATH"
mkdir -p "$RESOURCES_PATH"

# Create main launcher script - direct Python execution
echo "Creating launcher script..."
cat > "$MACOS_PATH/TIFF Channel Merger" << 'LAUNCHER_EOF'
#!/bin/bash
# Main launcher for TIFF Channel Merger

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RESOURCES_DIR="$DIR/../Resources"

# Change to resources directory
cd "$RESOURCES_DIR" || exit 1

# Launch Python GUI directly
# Use exec to replace the shell with Python, making it the main process
exec /usr/bin/python3 tiff_channel_merger_gui.py
LAUNCHER_EOF

chmod +x "$MACOS_PATH/TIFF Channel Merger"

# Copy Python script to Resources
echo "Copying Python script..."
cp "$SCRIPT_DIR/tiff_channel_merger_gui.py" "$RESOURCES_PATH/"

# Create Info.plist with LSBackgroundOnly set to false to show in Dock
echo "Creating Info.plist..."
cat > "$CONTENTS_PATH/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>TIFF Channel Merger</string>
    <key>CFBundleIdentifier</key>
    <string>com.tiffchannelmerger.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>TIFF Channel Merger</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>4.0</string>
    <key>CFBundleVersion</key>
    <string>4.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.12</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSAppleEventsUsageDescription</key>
    <string>TIFF Channel Merger needs to access system resources to merge TIFF files.</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>tif</string>
                <string>tiff</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>TIFF Image</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
</dict>
</plist>
PLIST_EOF

# Create PkgInfo
echo "Creating PkgInfo..."
echo -n 'APPL????' > "$CONTENTS_PATH/PkgInfo"

# Create a nice README for users
cat > "$SCRIPT_DIR/LANCEMENT.txt" << 'README_EOF'
🔬 TIFF Channel Merger - Guide de lancement

Il existe 3 façons de lancer l'application :

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣  MÉTHODE RECOMMANDÉE - Script shell (Pas de permissions nécessaires)

   Double-cliquez sur : tiff-channel-merger.sh

   ✅ Simple et direct
   ✅ Pas de problème de permissions
   ✅ Interface graphique immédiate

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2️⃣  Application Bundle (Peut nécessiter des permissions)

   Double-cliquez sur : TIFF Channel Merger.app

   Si vous voyez un message de permissions :
   - Allez dans Préférences Système → Sécurité et confidentialité
   - Onglet "Confidentialité" → "Automatisation"
   - Cochez la case pour "TIFF Channel Merger"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3️⃣  Terminal (Pour utilisateurs avancés)

   Ouvrez Terminal et exécutez :
   cd "/chemin/vers/macOS"
   python3 tiff_channel_merger_gui.py

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  PRÉREQUIS : Assurez-vous que VIPS est installé
   brew install vips

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
README_EOF

echo ""
echo "✅ Application bundle created successfully!"
echo ""
echo "📁 Location: $APP_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 MÉTHODE RECOMMANDÉE POUR LANCER L'APPLICATION :"
echo ""
echo "   Double-cliquez sur : tiff-channel-merger.sh"
echo ""
echo "   ✅ Pas de problème de permissions"
echo "   ✅ Lancement immédiat"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Alternative : Double-cliquez sur TIFF Channel Merger.app"
echo "  (Peut demander des permissions la première fois)"
echo ""
echo "Un fichier LANCEMENT.txt a été créé avec toutes les instructions."
echo ""
