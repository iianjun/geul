#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
RELEASE_DIR="$BUILD_DIR/release"
ARCHIVE_PATH="$BUILD_DIR/geul.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP_PATH="$EXPORT_DIR/geul.app"
VERSION="1.0.0"
BUILD_NUMBER="1"
TAG="v$VERSION"
DMG_PATH="$RELEASE_DIR/geul-$VERSION.dmg"
SHA_PATH="$RELEASE_DIR/geul-$VERSION.sha256"
STABLE_DMG_PATH="$RELEASE_DIR/geul.dmg"
STABLE_SHA_PATH="$RELEASE_DIR/geul.sha256"

require_env() {
    local name="$1"
    if [[ -z "${!name:-}" ]]; then
        echo "error: set $name before running this script" >&2
        exit 1
    fi
}

ensure_project_root() {
    cd "$PROJECT_ROOT"
}

reset_release_dir() {
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
}
