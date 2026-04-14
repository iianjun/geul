# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

geul is a macOS-only app for viewing markdown files. Run `geul file.md` from the CLI to open the app and render the given markdown file. Each file opens in a new window.

## Build

```bash
# Xcode (primary — produces app bundle for distribution)
xcodebuild -project geul.xcodeproj -scheme geul -configuration Debug build

# SPM (CLI build)
swift build
```

## Architecture

- **macOS 14+**, SwiftUI-based, trunk-based development
- Xcode project (`geul.xcodeproj`) is the primary build system; `Package.swift` is maintained for SPM build verification only
- Source directory: `geul/`

### CLI Flow

```
geul file.md → /usr/local/bin/geul (shell wrapper)
  → open -a "geul" file.md
  → macOS LaunchServices → Apple Events
  → AppDelegate.application(_:open:) → new NSWindow per file
```

- **Shell wrapper** (`geul/Resources/geul`): `open -a` 호출. 심링크가 아님 — `Bundle.main`이 항상 `.app` 번들을 가리키도록 보장
- **Document Types** (`geul/Info.plist`): `.md` UTI 등록 → Apple Events로 파일 수신
- **Multi-window**: 파일마다 독립 NSWindow. `WindowGroup` 미사용 — AppDelegate가 직접 관리

## Verification

Always run these checks after code changes.

### 1. SwiftLint

```bash
make lint        # strict lint check
make lint-fix    # auto-fix correctable violations
```

### 2. Process Management

```bash
make kill        # kill all running geul processes
make install     # Xcode build + install CLI wrapper to /usr/local/bin/geul
```

### 3. Build & Test (XcodeBuildMCP)

Use the XcodeBuildMCP MCP server for build and test verification.

1. `session_show_defaults` — confirm project/scheme/simulator settings
2. `build_sim` — verify the build succeeds
3. `test_sim` — run tests if a test target exists
4. UI changes: `build_run_sim` to launch on simulator, then `screenshot` to verify the result

## Documentation

- PM documents (PRD, discovery plan, feature spec, etc.) are stored in `docs/pm/`
- The `docs/` directory is gitignored and managed locally only

## Progress Tracking

Track phase-level progress in `docs/pm/PROGRESS.md`.

- **Phase start:** Update status to "in progress" and record the plan file path
- **Plan complete:** Add the finalized task list to the phase's `### Tasks` section as `- [ ]` checkboxes
- **Task complete:** Check off the corresponding checkbox (`- [x]`)
- **Phase complete:** Update status to "done", record completion date, commits, and known issues
- **Known issue found:** Record under the relevant phase or the carry-over target phase

## Conventions

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat:`, `fix:`, `chore:`, `refactor:`)
- **CLAUDE.md must always be written in English.** Other docs (PRD, plans, PROGRESS.md) may use Korean.
