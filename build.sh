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
ASSETS_DIR="Assets.xcassets/$ICON_NAME.appiconset"

if [ -f "Assets/$ICON_NAME.icns" ]; then
  cp "Assets/$ICON_NAME.icns" "$APP_NAME.app/Contents/Resources/$ICON_NAME.icns"
  echo "🎨 Using provided .icns icon"
elif [ -d "$ASSETS_DIR" ]; then
  TMP_DIR="$ICON_NAME.iconset"
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"
  if [ -f "$ASSETS_DIR/16.png" ]; then
    cp "$ASSETS_DIR/16.png" "$TMP_DIR/icon_16x16.png"
  fi
  if [ -f "$ASSETS_DIR/32.png" ]; then
    cp "$ASSETS_DIR/32.png" "$TMP_DIR/icon_16x16@2x.png"
    cp "$ASSETS_DIR/32.png" "$TMP_DIR/icon_32x32.png"
  fi
  if [ -f "$ASSETS_DIR/64.png" ]; then
    cp "$ASSETS_DIR/64.png" "$TMP_DIR/icon_32x32@2x.png"
  fi
  if [ -f "$ASSETS_DIR/128.png" ]; then
    cp "$ASSETS_DIR/128.png" "$TMP_DIR/icon_128x128.png"
  fi
  if [ -f "$ASSETS_DIR/256.png" ]; then
    cp "$ASSETS_DIR/256.png" "$TMP_DIR/icon_128x128@2x.png"
    cp "$ASSETS_DIR/256.png" "$TMP_DIR/icon_256x256.png"
  fi
  if [ -f "$ASSETS_DIR/512.png" ]; then
    cp "$ASSETS_DIR/512.png" "$TMP_DIR/icon_256x256@2x.png"
    cp "$ASSETS_DIR/512.png" "$TMP_DIR/icon_512x512.png"
  fi
  if [ -f "$ASSETS_DIR/1024.png" ]; then
    cp "$ASSETS_DIR/1024.png" "$TMP_DIR/icon_512x512@2x.png"
  fi
  iconutil -c icns "$TMP_DIR" -o "$ICON_NAME.icns" && \
  cp "$ICON_NAME.icns" "$APP_NAME.app/Contents/Resources/$ICON_NAME.icns" && \
  rm -rf "$TMP_DIR" "$ICON_NAME.icns" && \
  echo "🎨 Built .icns from Assets.xcassets"
elif [ -d "Assets/$ICON_NAME.iconset" ]; then
  iconutil -c icns "Assets/$ICON_NAME.iconset" -o "$ICON_NAME.icns" && \
  cp "$ICON_NAME.icns" "$APP_NAME.app/Contents/Resources/$ICON_NAME.icns" && \
  rm -f "$ICON_NAME.icns" && \
  echo "🎨 Built .icns from iconset"
elif [ -f "Assets/$ICON_NAME.png" ]; then
  TMP_DIR="$ICON_NAME.iconset"
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"
  sips -z 16 16 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "Assets/$ICON_NAME.png" --out "$TMP_DIR/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$TMP_DIR" -o "$ICON_NAME.icns" && \
  cp "$ICON_NAME.icns" "$APP_NAME.app/Contents/Resources/$ICON_NAME.icns" && \
  rm -rf "$TMP_DIR" "$ICON_NAME.icns" && \
  echo "🎨 Built .icns from PNG"
else
  echo "ℹ️ No app icon found."
fi

# Copy localization resources
if [ -d "Localization" ]; then
  cp -R Localization/* "$APP_NAME.app/Contents/Resources/"
  echo "🗣️ Copied localization resources"
fi

echo "🔨 Compiling Swift Sources..."
# -parse-as-library is needed because we use @main
swiftc $SOURCES \
    -o "$APP_NAME.app/Contents/MacOS/$APP_NAME" \
    -target arm64-apple-macosx26.0 \
    -parse-as-library \
    -O

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
