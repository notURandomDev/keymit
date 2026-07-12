#!/bin/bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly TARGET_DOMAIN="com.notURandomDev.KeyCadence"
readonly TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
readonly ALLOWED_DOMAINS=(
    "com.notURandomDev.KeyCadence"
    "com.user.KeyCadence"
    "com.user.keycount"
    "com.user.KeyLog"
)

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "usage: ./restore-data.sh <backup.tar.gz> [source-domain]" >&2
    exit 2
fi

BACKUP_FILE="$1"
SOURCE_DOMAIN="${2:-$TARGET_DOMAIN}"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "error: backup file does not exist: $BACKUP_FILE" >&2
    exit 1
fi
if [[ "$BACKUP_FILE" != *.tar.gz ]]; then
    echo "error: backup file must end in .tar.gz" >&2
    exit 2
fi
if pgrep -x KeyCadence >/dev/null 2>&1; then
    echo "error: quit KeyCadence before restoring data" >&2
    exit 1
fi

domain_allowed=false
for domain in "${ALLOWED_DOMAINS[@]}"; do
    if [[ "$SOURCE_DOMAIN" == "$domain" ]]; then
        domain_allowed=true
        break
    fi
done
if [[ "$domain_allowed" != true ]]; then
    echo "error: unsupported source domain: $SOURCE_DOMAIN" >&2
    exit 2
fi

EXPECTED_MEMBER="./$SOURCE_DOMAIN.plist"
if ! tar -tzf "$BACKUP_FILE" >/dev/null; then
    echo "error: backup archive is corrupt or unreadable" >&2
    exit 1
fi
if ! tar -tzf "$BACKUP_FILE" | grep -Fx "$EXPECTED_MEMBER" >/dev/null; then
    echo "error: source domain is not present in the backup: $SOURCE_DOMAIN" >&2
    exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/keycadence-restore.XXXXXX")"
cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

SOURCE_PLIST="$WORK_DIR/source.plist"
BEFORE_PLIST="$WORK_DIR/before.plist"
VERIFIED_PLIST="$WORK_DIR/verified.plist"
SOURCE_NORMALIZED="$WORK_DIR/source.txt"
VERIFIED_NORMALIZED="$WORK_DIR/verified.txt"

tar -xOzf "$BACKUP_FILE" "$EXPECTED_MEMBER" > "$SOURCE_PLIST"
plutil -lint "$SOURCE_PLIST" >/dev/null

if defaults read "$TARGET_DOMAIN" >/dev/null 2>&1; then
    HAD_CURRENT_DATA=true
    defaults export "$TARGET_DOMAIN" "$BEFORE_PLIST" >/dev/null
    mkdir -p "$ROOT_DIR/backups"
    SAFETY_BACKUP="$ROOT_DIR/backups/KeyCadence-pre-restore-$TIMESTAMP.tar.gz"
    "$ROOT_DIR/backup-data.sh" "$SAFETY_BACKUP" >/dev/null
    echo "Safety backup created: $SAFETY_BACKUP"
else
    HAD_CURRENT_DATA=false
fi

rollback() {
    if [[ "$HAD_CURRENT_DATA" == true ]]; then
        defaults import "$TARGET_DOMAIN" "$BEFORE_PLIST" >/dev/null
    else
        defaults delete "$TARGET_DOMAIN" >/dev/null 2>&1 || true
    fi
}

if ! defaults import "$TARGET_DOMAIN" "$SOURCE_PLIST" >/dev/null; then
    rollback
    echo "error: import failed; previous data was restored" >&2
    exit 1
fi

if ! defaults export "$TARGET_DOMAIN" "$VERIFIED_PLIST" >/dev/null 2>&1; then
    rollback
    echo "error: restored preferences could not be read; previous data was restored" >&2
    exit 1
fi

plutil -lint "$VERIFIED_PLIST" >/dev/null
plutil -p "$SOURCE_PLIST" > "$SOURCE_NORMALIZED"
plutil -p "$VERIFIED_PLIST" > "$VERIFIED_NORMALIZED"
if ! cmp -s "$SOURCE_NORMALIZED" "$VERIFIED_NORMALIZED"; then
    rollback
    echo "error: restored data did not match the backup; previous data was restored" >&2
    exit 1
fi

echo "Restore completed and verified."
echo "Source domain: $SOURCE_DOMAIN"
echo "Target domain: $TARGET_DOMAIN"
echo "You can now launch KeyCadence."
