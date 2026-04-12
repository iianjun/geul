# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

geul is a macOS-only app for viewing markdown files. Run `geul README.md` from the CLI to open the app and render the given markdown file.

## Build

```bash
# Xcode (primary — produces app bundle for distribution)
xcodebuild -project geul.xcodeproj -scheme geul -configuration Debug build

# SPM (CLI build)
swift build
```

## Architecture

- **macOS 14+**, SwiftUI-based, trunk-based development
- Xcode project (`geul.xcodeproj`) is the primary build system; `Package.swift` is maintained for SPM compatibility
- Source directory: `geul/`

## Verification

Always run these checks after code changes.

### 1. SwiftLint

```bash
make lint        # strict lint check
make lint-fix    # auto-fix correctable violations
```

### 2. Build & Test (XcodeBuildMCP)

Use the XcodeBuildMCP MCP server for build and test verification.

1. `session_show_defaults` — confirm project/scheme/simulator settings
2. `build_sim` — verify the build succeeds
3. `test_sim` — run tests if a test target exists
4. UI changes: `build_run_sim` to launch on simulator, then `screenshot` to verify the result

## Documentation

- PM documents (PRD, discovery plan, feature spec, etc.) are stored in `docs/pm/`
- The `docs/` directory is gitignored and managed locally only

## Conventions

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat:`, `fix:`, `chore:`, `refactor:`)
