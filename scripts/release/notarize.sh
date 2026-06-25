#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_project_root
NOTARY_PROFILE="${GEUL_NOTARY_PROFILE:-geul-notary}"

if [[ ! -f "$DMG_PATH" ]]; then
    echo "error: package the DMG first with scripts/release/package-dmg.sh" >&2
    exit 1
fi

xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

cp "$DMG_PATH" "$STABLE_DMG_PATH"
shasum -a 256 "$DMG_PATH" | tee "$SHA_PATH"
shasum -a 256 "$STABLE_DMG_PATH" | tee "$STABLE_SHA_PATH"

echo "Notarized and stapled: $DMG_PATH"
