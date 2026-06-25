#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_env GEUL_DEVELOPMENT_TEAM
ensure_project_root
reset_release_dir
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"

xcodebuild archive \
    -project geul.xcodeproj \
    -scheme geul \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$GEUL_DEVELOPMENT_TEAM" \
    CODE_SIGN_STYLE=Automatic

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist ExportOptions.plist \
    DEVELOPMENT_TEAM="$GEUL_DEVELOPMENT_TEAM"

if [[ ! -d "$APP_PATH" ]]; then
    echo "error: expected exported app at $APP_PATH" >&2
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
echo "Built signed app: $APP_PATH"
