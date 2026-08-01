#!/bin/bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
readonly DEBUG_APP="$ROOT_DIR/Keymit Debug.app"
readonly DEBUG_INFO="$DEBUG_APP/Contents/Info.plist"
readonly RELEASE_INFO="$ROOT_DIR/Info.plist"

rm -rf "$DEBUG_APP"
"$ROOT_DIR/build.sh" --profile debug

test -x "$DEBUG_APP/Contents/MacOS/KeymitDebug"
test -f "$DEBUG_APP/Contents/Resources/AppIcon.Debug.icns"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEBUG_INFO")" = "com.notURandomDev.Keymit.debug"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$DEBUG_INFO")" = "Keymit Debug"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$DEBUG_INFO")" = "KeymitDebug"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$DEBUG_INFO")" = "AppIcon.Debug.icns"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$RELEASE_INFO")" = "com.notURandomDev.Keymit"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$RELEASE_INFO")" = "AppIcon.icns"
codesign -d -r- "$DEBUG_APP" 2>&1 | grep -Fq 'designated => identifier "com.notURandomDev.Keymit.debug"'

echo "Debug bundle identity is isolated from the release bundle."
