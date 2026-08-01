#!/bin/bash

set -Eeuo pipefail

trap 'status=$?; echo "error: build.sh failed at line $LINENO (status $status)" >&2; exit $status' ERR

usage() {
    cat <<'EOF'
Usage: ./build.sh [--profile release|debug]

Build profiles:
  release  Build the signed arm64 + x86_64 release app (default)
  debug    Build the isolated, single-architecture debug app
EOF
}

PROFILE="release"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            if [[ $# -lt 2 ]]; then
                echo "error: --profile requires release or debug" >&2
                exit 2
            fi
            PROFILE="$2"
            shift 2
            ;;
        --profile=*)
            PROFILE="${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly MINIMUM_MACOS_VERSION="${MINIMUM_MACOS_VERSION:-13.0}"

APP_NAME=""
EXECUTABLE_NAME=""
INFO_PLIST=""
ICON_FILE=""
BUILD_DIR=""
MODULE_CACHE=""
ARCH_SPEC=""
CLEAN_BUILD=0
STRICT_VERIFY=0
SWIFT_FLAGS=()

case "$PROFILE" in
    release)
        APP_NAME="Keymit"
        EXECUTABLE_NAME="Keymit"
        INFO_PLIST="Info.plist"
        ICON_FILE="AppIcon.icns"
        BUILD_DIR="$ROOT_DIR/.build/app"
        MODULE_CACHE="$ROOT_DIR/.build/module-cache"
        ARCH_SPEC="${ARCHS:-arm64 x86_64}"
        CLEAN_BUILD=1
        STRICT_VERIFY=1
        SWIFT_FLAGS=(-warnings-as-errors -whole-module-optimization -O)
        ;;
    debug)
        APP_NAME="Keymit Debug"
        EXECUTABLE_NAME="KeymitDebug"
        INFO_PLIST="Info.Debug.plist"
        ICON_FILE="AppIcon.Debug.icns"
        BUILD_DIR="$ROOT_DIR/.build/debug-app"
        MODULE_CACHE="$ROOT_DIR/.build/debug-module-cache"
        ARCH_SPEC="${ARCHS:-${ARCH:-$(uname -m)}}"
        SWIFT_FLAGS=(-g -Onone)
        ;;
    *)
        echo "error: profile must be release or debug (got $PROFILE)" >&2
        exit 2
        ;;
esac

readonly OUTPUT_APP="${OUTPUT_APP:-$ROOT_DIR/$APP_NAME.app}"
readonly BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"

read -r -a ARCHES <<< "$ARCH_SPEC"
if [[ ${#ARCHES[@]} -eq 0 ]]; then
    echo "error: at least one architecture is required" >&2
    exit 2
fi
for arch in "${ARCHES[@]}"; do
    case "$arch" in
        arm64|x86_64) ;;
        *)
            echo "error: architecture must be arm64 or x86_64 (got $arch)" >&2
            exit 2
            ;;
    esac
done

cd "$ROOT_DIR"
if (( CLEAN_BUILD )); then
    rm -rf "$BUILD_DIR"
else
    rm -rf "$BUNDLE_DIR"
fi
mkdir -p "$BUNDLE_DIR/Contents/MacOS" "$BUNDLE_DIR/Contents/Resources" "$MODULE_CACHE"

cp "$INFO_PLIST" "$BUNDLE_DIR/Contents/Info.plist"
plutil -lint "$INFO_PLIST" Localization/en.lproj/Localizable.strings Localization/zh-Hans.lproj/Localizable.strings >/dev/null

if [[ "$PROFILE" == release ]]; then
    if [[ -n "${VERSION:-}" ]]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$BUNDLE_DIR/Contents/Info.plist"
    fi
    if [[ -n "${BUILD_NUMBER:-}" ]]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$BUNDLE_DIR/Contents/Info.plist"
    fi
fi

if [[ ! -f "Assets/$ICON_FILE" ]]; then
    echo "error: Assets/$ICON_FILE is required" >&2
    exit 1
fi
cp "Assets/$ICON_FILE" "$BUNDLE_DIR/Contents/Resources/$ICON_FILE"
ditto Localization "$BUNDLE_DIR/Contents/Resources"

bundle_executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$BUNDLE_DIR/Contents/Info.plist")"
if [[ "$bundle_executable" != "$EXECUTABLE_NAME" ]]; then
    echo "error: $INFO_PLIST declares executable $bundle_executable, expected $EXECUTABLE_NAME" >&2
    exit 1
fi
bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$BUNDLE_DIR/Contents/Info.plist")"

SOURCES=()
while IFS= read -r source; do
    SOURCES+=("$source")
done < <(find Sources -name '*.swift' -type f | sort)

if [[ ${#SOURCES[@]} -eq 0 ]]; then
    echo "error: no Swift source files found" >&2
    exit 1
fi

BINARIES=()
for arch in "${ARCHES[@]}"; do
    binary="$BUILD_DIR/$EXECUTABLE_NAME.$arch"
    echo "Building $APP_NAME for $arch ($PROFILE)..."
    xcrun --sdk macosx swiftc "${SOURCES[@]}" \
        -o "$binary" \
        -target "$arch-apple-macosx$MINIMUM_MACOS_VERSION" \
        -module-cache-path "$MODULE_CACHE" \
        -parse-as-library \
        "${SWIFT_FLAGS[@]}"
    BINARIES+=("$binary")
done

if [[ ${#BINARIES[@]} -eq 1 ]]; then
    cp "${BINARIES[0]}" "$BUNDLE_DIR/Contents/MacOS/$EXECUTABLE_NAME"
else
    lipo -create "${BINARIES[@]}" -output "$BUNDLE_DIR/Contents/MacOS/$EXECUTABLE_NAME"
fi
chmod 755 "$BUNDLE_DIR/Contents/MacOS/$EXECUTABLE_NAME"

SIGN_ARGS=(--force --sign - --timestamp=none)
if [[ "$PROFILE" == debug ]]; then
    designated_requirement="designated => identifier \"$bundle_identifier\""
    SIGN_ARGS+=("-r=$designated_requirement")
fi
codesign "${SIGN_ARGS[@]}" "$BUNDLE_DIR"

plutil -lint "$BUNDLE_DIR/Contents/Info.plist" >/dev/null
if (( STRICT_VERIFY )); then
    codesign --verify --deep --strict --verbose=2 "$BUNDLE_DIR"
    lipo "$BUNDLE_DIR/Contents/MacOS/$EXECUTABLE_NAME" -verify_arch "${ARCHES[@]}"
fi

rm -rf "$OUTPUT_APP"
ditto "$BUNDLE_DIR" "$OUTPUT_APP"
echo "Built $PROFILE app: $OUTPUT_APP"
