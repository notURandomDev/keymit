#!/bin/bash

set -Eeuo pipefail

trap 'status=$?; echo "error: create-dmg.sh failed at line $LINENO (status $status)" >&2; exit $status' ERR

readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly APP_NAME="KeyCadence"
readonly VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Info.plist")}"
readonly BUILD_NUMBER="${BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$ROOT_DIR/Info.plist")}"
readonly OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/dist}"
readonly OUTPUT_DMG="${OUTPUT_DMG:-$OUTPUT_DIR/$APP_NAME-$VERSION.dmg}"

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/keycadence-dmg.XXXXXX")"
cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT INT TERM

cd "$ROOT_DIR"
env VERSION="$VERSION" BUILD_NUMBER="$BUILD_NUMBER" ./build.sh

mkdir -p "$OUTPUT_DIR"
ditto "$APP_NAME.app" "$STAGING_DIR/$APP_NAME.app"
cp INSTALL.md "$STAGING_DIR/Installation Guide.md"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$OUTPUT_DMG"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$OUTPUT_DMG"

hdiutil verify "$OUTPUT_DMG"
codesign --verify --deep --strict --verbose=2 "$APP_NAME.app"

shasum -a 256 "$OUTPUT_DMG" > "$OUTPUT_DMG.sha256"
echo "Created and verified: $OUTPUT_DMG"
echo "Checksum: $OUTPUT_DMG.sha256"
