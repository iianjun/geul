#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
hook_path="$repo_root/.githooks/pre-commit"
check_script="$repo_root/scripts/check-no-docs-staged"

if [ ! -x "$hook_path" ]; then
  echo "Missing executable pre-commit hook: $hook_path" >&2
  exit 1
fi

if [ ! -x "$check_script" ]; then
  echo "Missing executable docs check script: $check_script" >&2
  exit 1
fi

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/geul-no-docs-pre-commit.XXXXXX")
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

cd "$tmp_dir"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git config core.hooksPath "$repo_root/.githooks"

printf 'docs/\n' > .gitignore
mkdir -p Sources
printf 'let allowed = true\n' > Sources/main.swift
git add .gitignore Sources/main.swift
git commit -m "allowed commit" >/dev/null 2>allowed-stderr.txt

mkdir -p docs
printf '# Local notes\n' > docs/notes.md
git add -f docs/notes.md

if git commit -m "blocked docs commit" >blocked-stdout.txt 2>blocked-stderr.txt; then
  echo "Expected pre-commit hook to block staged docs/ files" >&2
  exit 1
fi

if ! grep -q "docs/notes.md" blocked-stderr.txt; then
  echo "Expected hook output to mention the staged docs path" >&2
  cat blocked-stderr.txt >&2
  exit 1
fi
