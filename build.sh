#!/bin/bash

APP_NAME="KeyCadence"
SOURCES="Sources/App.swift Sources/KeyTracker.swift Sources/DashboardView.swift Sources/HeatmapView.swift Sources/SettingsView.swift Sources/SettingsWindowManager.swift Sources/AppPreferences.swift Sources/RestartHelper.swift Sources/LaunchManager.swift"

echo "🚧 Cleaning up..."
rm -rf "$APP_NAME.app"

echo "📂 Creating App Bundle Structure..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

echo "📝 Copying Info.plist..."
cp Info.plist "$APP_NAME.app/Contents/Info.plist"

ICON_NAME="AppIcon"

if [ -f "Assets/$ICON_NAME.icns" ]; then
  cp "Assets/$ICON_NAME.icns" "$APP_NAME.app/Contents/Resources/$ICON_NAME.icns"
  echo "🎨 Copied .icns icon"
else
  echo "ℹ️ No app icon found."
fi

# Copy localization resources
if [ -d "Localization" ]; then
  cp -R Localization/* "$APP_NAME.app/Contents/Resources/"
  echo "🗣️ Copied localization resources"
fi

echo "🔨 Compiling Swift Sources for Universal Binary..."

# Build for Apple Silicon (arm64)
echo "  📦 Building arm64..."
swiftc $SOURCES \
    -o "$APP_NAME.app/Contents/MacOS/$APP_NAME.arm64" \
    -target arm64-apple-macosx13.0 \
    -parse-as-library \
    -O

if [ $? -ne 0 ]; then
    echo "❌ arm64 build failed"
    exit 1
fi

# Build for Intel (x86_64)
echo "  📦 Building x86_64..."
swiftc $SOURCES \
    -o "$APP_NAME.app/Contents/MacOS/$APP_NAME.x86_64" \
    -target x86_64-apple-macosx13.0 \
    -parse-as-library \
    -O

if [ $? -ne 0 ]; then
    echo "❌ x86_64 build failed"
    exit 1
fi

# Merge into Universal Binary
echo "  🔗 Creating Universal Binary..."
lipo -create \
    "$APP_NAME.app/Contents/MacOS/$APP_NAME.arm64" \
    "$APP_NAME.app/Contents/MacOS/$APP_NAME.x86_64" \
    -output "$APP_NAME.app/Contents/MacOS/$APP_NAME"

# Clean up intermediate files
rm -f "$APP_NAME.app/Contents/MacOS/$APP_NAME.arm64"
rm -f "$APP_NAME.app/Contents/MacOS/$APP_NAME.x86_64"

echo "  ✅ Universal Binary created"

if [ $? -eq 0 ]; then
    echo "✅ Build Successful!"
    echo "👉 You can find the app at: $(pwd)/$APP_NAME.app"
    echo "🔏 Code signing (ad-hoc)..."
    codesign --force --deep --sign - "$APP_NAME.app" && echo "✅ Code signed"
    echo "⚠️  IMPORTANT: Upon first launch, you MUST grant Accessibility Permissions in System Settings -> Privacy & Security -> Accessibility."
else
    echo "❌ Build Failed"
    exit 1
fi
