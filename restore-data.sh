#!/bin/bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly TARGET_DOMAIN="com.notURandomDev.Keymit"
readonly TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
if [[ $# -ne 1 ]]; then
    echo "usage: ./restore-data.sh <backup.tar.gz>" >&2
    exit 2
fi

BACKUP_FILE="$1"
SOURCE_DOMAIN="$TARGET_DOMAIN"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "error: backup file does not exist: $BACKUP_FILE" >&2
    exit 1
fi
if [[ "$BACKUP_FILE" != *.tar.gz ]]; then
    echo "error: backup file must end in .tar.gz" >&2
    exit 2
fi
if pgrep -x Keymit >/dev/null 2>&1; then
    echo "error: quit Keymit before restoring data" >&2
    exit 1
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

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/keymit-restore.XXXXXX")"
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
    SAFETY_BACKUP="$ROOT_DIR/backups/Keymit-pre-restore-$TIMESTAMP.tar.gz"
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
echo "You can now launch Keymit."
