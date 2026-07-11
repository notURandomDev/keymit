#!/bin/bash

set -Eeuo pipefail
trap 'status=$?; echo "error: release.sh failed at line $LINENO (status $status)" >&2; exit $status' ERR

readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly VERSION="${1:-}"
readonly BUILD_NUMBER="${2:-}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "usage: ./release.sh <version> <build-number>" >&2
    exit 2
fi
if [[ ! "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
    echo "error: build-number must be a positive integer" >&2
    exit 2
fi
cd "$ROOT_DIR"
plist_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
plist_build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Info.plist)"
if [[ "$VERSION" != "$plist_version" || "$BUILD_NUMBER" != "$plist_build" ]]; then
    echo "error: release version/build must match committed Info.plist ($plist_version/$plist_build)" >&2
    exit 2
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "error: commit or stash tracked changes before creating a release" >&2
    exit 2
fi

CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/test-module-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/test-module-cache" \
swift test --disable-sandbox

env \
    VERSION="$VERSION" \
    BUILD_NUMBER="$BUILD_NUMBER" \
    ./create-dmg.sh

echo "Ad-hoc release package is ready in dist/."
echo "Users must approve the app in System Settings > Privacy & Security on first launch."
echo "Package version matches v$VERSION; review the checksum before publishing."
