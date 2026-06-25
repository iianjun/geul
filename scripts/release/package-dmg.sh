#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_project_root

if [[ ! -d "$APP_PATH" ]]; then
    echo "error: build the exported app first with scripts/release/build.sh" >&2
    exit 1
fi

DMG_ROOT="$RELEASE_DIR/dmg-root"
rm -rf "$DMG_ROOT" "$DMG_PATH" "$STABLE_DMG_PATH"
mkdir -p "$DMG_ROOT"

cp -R "$APP_PATH" "$DMG_ROOT/geul.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
    -volname "geul $VERSION" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

cp "$DMG_PATH" "$STABLE_DMG_PATH"
shasum -a 256 "$DMG_PATH" | tee "$SHA_PATH"
shasum -a 256 "$STABLE_DMG_PATH" | tee "$STABLE_SHA_PATH"

echo "Packaged DMG: $DMG_PATH"
