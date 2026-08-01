#!/bin/bash

set -Eeuo pipefail

readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$ROOT_DIR/build.sh" "$@" --profile debug
