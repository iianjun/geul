#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_project_root

if [[ ! -f "$DMG_PATH" ]]; then
    echo "error: missing release artifact at $DMG_PATH" >&2
    exit 1
fi

if [[ ! -f "$SHA_PATH" ]]; then
    echo "error: missing checksum at $SHA_PATH" >&2
    exit 1
fi

if [[ ! -f "$STABLE_DMG_PATH" ]]; then
    echo "error: missing stable release artifact at $STABLE_DMG_PATH" >&2
    exit 1
fi

if [[ ! -f "$STABLE_SHA_PATH" ]]; then
    echo "error: missing stable checksum at $STABLE_SHA_PATH" >&2
    exit 1
fi

if [[ ! -f CHANGELOG.md ]]; then
    echo "error: missing CHANGELOG.md" >&2
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "error: authenticate GitHub CLI with gh auth login" >&2
    exit 1
fi

if [[ -n "$(git status --short)" ]]; then
    echo "error: commit release source changes before creating the GitHub Release" >&2
    git status --short >&2
    exit 1
fi

if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    git tag -a "$TAG" -m "geul $VERSION"
fi

git push origin "$TAG"

gh release create "$TAG" \
    "$DMG_PATH" \
    "$SHA_PATH" \
    "$STABLE_DMG_PATH" \
    "$STABLE_SHA_PATH" \
    --draft \
    --title "geul $VERSION" \
    --notes-file CHANGELOG.md

echo "Created draft GitHub Release: $TAG"
