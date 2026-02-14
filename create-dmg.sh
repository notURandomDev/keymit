#!/bin/bash

APP_NAME="KeyCadence"
DMG_NAME="KeyCadence"
VOLUME_NAME="KeyCadence"
DMG_SIZE="15m"

echo "🔨 Building app..."
./build.sh

if [ $? -ne 0 ]; then
    echo "❌ Build failed, cannot create DMG"
    exit 1
fi

echo "📦 Creating DMG..."

# Create a temporary directory for DMG contents
DMG_DIR="dmg_temp"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Copy the app
cp -R "$APP_NAME.app" "$DMG_DIR/"

# Create a symbolic link to Applications
ln -s /Applications "$DMG_DIR/Applications"

# Create temporary DMG
TEMP_DMG="temp.dmg"
hdiutil create -srcfolder "$DMG_DIR" -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size "$DMG_SIZE" "$TEMP_DMG"

# Mount the temporary DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')

# Set up the DMG appearance (optional - sets icon positions and window size)
sleep 2
echo '
   tell application "Finder"
     tell disk "'$VOLUME_NAME'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 920, 440}
           set viewOptions to the icon view options of container window
           set arrangement of viewOptions to not arranged
           set icon size of viewOptions to 128
           set position of item "'$APP_NAME'" of container window to {130, 150}
           set position of item "Applications" of container window to {390, 150}
           close
           open
           update without registering applications
           delay 2
     end tell
   end tell
' | osascript

# Unmount and convert to compressed DMG
hdiutil detach "$DEVICE"
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME.dmg"

# Cleanup
rm -rf "$DMG_DIR" "$TEMP_DMG"

echo "✅ DMG created successfully: $DMG_NAME.dmg"
echo "👉 Users can now drag the app to Applications folder to install"
