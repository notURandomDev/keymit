#!/bin/bash

set -Eeuo pipefail

trap 'status=$?; echo "error: build.sh failed at line $LINENO (status $status)" >&2; exit $status' ERR

readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly APP_NAME="KeyCadence"
readonly OUTPUT_APP="${OUTPUT_APP:-$ROOT_DIR/$APP_NAME.app}"
readonly BUILD_DIR="$ROOT_DIR/.build/app"
readonly BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"
readonly MODULE_CACHE="$ROOT_DIR/.build/module-cache"
readonly MINIMUM_MACOS_VERSION="${MINIMUM_MACOS_VERSION:-13.0}"
readonly ARCHS="${ARCHS:-arm64 x86_64}"

cd "$ROOT_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS" "$BUNDLE_DIR/Contents/Resources" "$MODULE_CACHE"

cp Info.plist "$BUNDLE_DIR/Contents/Info.plist"
plutil -lint Info.plist Localization/en.lproj/Localizable.strings Localization/zh-Hans.lproj/Localizable.strings >/dev/null
if [[ -n "${VERSION:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$BUNDLE_DIR/Contents/Info.plist"
fi
if [[ -n "${BUILD_NUMBER:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$BUNDLE_DIR/Contents/Info.plist"
fi

if [[ ! -f Assets/AppIcon.icns ]]; then
    echo "error: Assets/AppIcon.icns is required" >&2
    exit 1
fi
cp Assets/AppIcon.icns "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"
ditto Localization "$BUNDLE_DIR/Contents/Resources"

SOURCES=()
while IFS= read -r source; do
    SOURCES+=("$source")
done < <(find Sources -name '*.swift' -type f | sort)

if [[ ${#SOURCES[@]} -eq 0 ]]; then
    echo "error: no Swift source files found" >&2
    exit 1
fi

BINARIES=()
for arch in $ARCHS; do
    binary="$BUILD_DIR/$APP_NAME.$arch"
    echo "Building $APP_NAME for $arch..."
    xcrun --sdk macosx swiftc "${SOURCES[@]}" \
        -o "$binary" \
        -target "$arch-apple-macosx$MINIMUM_MACOS_VERSION" \
        -module-cache-path "$MODULE_CACHE" \
        -parse-as-library \
        -warnings-as-errors \
        -whole-module-optimization \
        -O
    BINARIES+=("$binary")
done

if [[ ${#BINARIES[@]} -eq 1 ]]; then
    cp "${BINARIES[0]}" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"
else
    lipo -create "${BINARIES[@]}" -output "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"
fi
chmod 755 "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

codesign --force --sign - --timestamp=none "$BUNDLE_DIR"

plutil -lint "$BUNDLE_DIR/Contents/Info.plist" >/dev/null
codesign --verify --deep --strict --verbose=2 "$BUNDLE_DIR"
lipo "$BUNDLE_DIR/Contents/MacOS/$APP_NAME" -verify_arch $ARCHS

rm -rf "$OUTPUT_APP"
ditto "$BUNDLE_DIR" "$OUTPUT_APP"
echo "Built and verified: $OUTPUT_APP"
