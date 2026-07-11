#!/bin/bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"

if [[ $# -gt 1 ]]; then
    echo "usage: ./backup-data.sh [output.tar.gz]" >&2
    exit 2
fi

if pgrep -x KeyCadence >/dev/null 2>&1; then
    echo "error: quit KeyCadence before backing up so all pending statistics are saved" >&2
    exit 1
fi

if [[ $# -eq 1 ]]; then
    if [[ "$1" = /* ]]; then
        OUTPUT_FILE="$1"
    else
        OUTPUT_FILE="$PWD/$1"
    fi
else
    OUTPUT_FILE="$ROOT_DIR/backups/KeyCadence-data-$TIMESTAMP.tar.gz"
fi

if [[ "$OUTPUT_FILE" != *.tar.gz ]]; then
    echo "error: output file must end in .tar.gz" >&2
    exit 2
fi
if [[ -e "$OUTPUT_FILE" ]]; then
    echo "error: output already exists: $OUTPUT_FILE" >&2
    exit 1
fi

OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
mkdir -p "$OUTPUT_DIR"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/keycadence-backup.XXXXXX")"
TEMP_ARCHIVE="$(mktemp "$OUTPUT_DIR/.keycadence-backup.XXXXXX")"

cleanup() {
    rm -rf "$STAGING_DIR"
    if [[ -n "${TEMP_ARCHIVE:-}" && -e "$TEMP_ARCHIVE" ]]; then
        rm -f "$TEMP_ARCHIVE"
    fi
}
trap cleanup EXIT INT TERM

if [[ -n "${KEYCADENCE_BACKUP_DOMAIN:-}" ]]; then
    DOMAINS=("$KEYCADENCE_BACKUP_DOMAIN")
else
    DOMAINS=(
        "com.notURandomDev.KeyCadence"
        "com.user.KeyCadence"
        "com.user.keycount"
        "com.user.KeyLog"
    )
fi

FOUND_DOMAINS=()
for domain in "${DOMAINS[@]}"; do
    domain_file="$STAGING_DIR/$domain.plist"
    if defaults export "$domain" "$domain_file" >/dev/null 2>&1; then
        plutil -lint "$domain_file" >/dev/null
        chmod 600 "$domain_file"
        FOUND_DOMAINS+=("$domain")
    else
        rm -f "$domain_file"
    fi
done

if [[ ${#FOUND_DOMAINS[@]} -eq 0 ]]; then
    echo "error: no KeyCadence preferences were found for the current macOS user" >&2
    exit 1
fi

{
    echo "KeyCadence data backup"
    echo "Format version: 1"
    echo "Created: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "macOS user: $(id -un)"
    echo "Preference domains:"
    for domain in "${FOUND_DOMAINS[@]}"; do
        echo "- $domain"
    done
} > "$STAGING_DIR/MANIFEST.txt"
chmod 600 "$STAGING_DIR/MANIFEST.txt"

COPYFILE_DISABLE=1 tar -C "$STAGING_DIR" -czf "$TEMP_ARCHIVE" .
tar -tzf "$TEMP_ARCHIVE" >/dev/null
chmod 600 "$TEMP_ARCHIVE"
mv "$TEMP_ARCHIVE" "$OUTPUT_FILE"
TEMP_ARCHIVE=""

echo "Backup created: $OUTPUT_FILE"
echo "Included preference domains: ${FOUND_DOMAINS[*]}"
echo "Keep this file private; it contains your KeyCadence history and preferences."
