#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_project_root

if [[ ! -d "$APP_PATH" ]]; then
    echo "error: missing exported app at $APP_PATH" >&2
    exit 1
fi

if [[ ! -f "$DMG_PATH" ]]; then
    echo "error: missing DMG at $DMG_PATH" >&2
    exit 1
fi

if [[ ! -f "$SHA_PATH" ]]; then
    echo "error: missing checksum at $SHA_PATH" >&2
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose "$DMG_PATH"
shasum -a 256 --check "$SHA_PATH"

tmp_dir="$(mktemp -d)"
mount_dir="$tmp_dir/mount"
attached=0

cleanup() {
    if [[ "$attached" -eq 1 ]]; then
        hdiutil detach "$mount_dir" -quiet || true
    fi
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$mount_dir"
hdiutil attach "$DMG_PATH" -mountpoint "$mount_dir" -nobrowse -quiet
attached=1

test -d "$mount_dir/geul.app"
test -L "$mount_dir/Applications"

hdiutil detach "$mount_dir" -quiet
attached=0

echo "Release verification passed for geul $VERSION"
