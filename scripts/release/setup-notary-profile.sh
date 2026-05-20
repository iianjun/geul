#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_env GEUL_APPLE_ID
require_env GEUL_DEVELOPMENT_TEAM
require_env GEUL_APP_SPECIFIC_PASSWORD

xcrun notarytool store-credentials geul-notary \
    --apple-id "$GEUL_APPLE_ID" \
    --team-id "$GEUL_DEVELOPMENT_TEAM" \
    --password "$GEUL_APP_SPECIFIC_PASSWORD"

echo "Stored notary credentials in keychain profile: geul-notary"
