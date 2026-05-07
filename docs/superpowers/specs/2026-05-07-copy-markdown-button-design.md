# Copy Markdown Button Design

**Status**: Approved design, ready for user spec review  
**Date**: 2026-05-07  
**Scope**: Reader window only

## 1. Goal

Add a native reader control that copies the complete original markdown file content to the macOS clipboard.

The copied value is the source markdown, not rendered text from the WebView. It should include whatever the file currently contains, such as frontmatter, code fences, comments, and trailing newlines.

## 2. Non-Goals

- Copying rendered HTML
- Copying rendered plain text from the WebView
- Adding a floating in-document button
- Adding a context-menu-only workflow
- Changing CLI, TUI, indexing, or markdown rendering behavior

## 3. Chosen UX

Use a native toolbar/titlebar button in the reader window.

The button appears as a macOS window action rather than content inside the markdown document. Its label and tooltip are `Copy Markdown`; the visible control can be icon-forward if SwiftUI toolbar rendering supports it cleanly.

After a successful copy, the UI shows a short `Copied` confirmation. The feedback must be subtle and temporary so the reader stays quiet.

The button is disabled while there is no successfully loaded markdown source, such as during initial loading, missing-file usage state, or failed file read state. A successfully loaded empty file is valid and can be copied as an empty string.

## 4. Approach Considered

### A. SwiftUI Toolbar + Swift Clipboard

`ContentView` owns the current source markdown string. A toolbar button writes that string to `NSPasteboard.general`.

This is the selected approach because it keeps clipboard work in native Swift, avoids WebView clipboard permissions, and stays outside the rendered document surface.

### B. Floating Button Inside WebView

Inject a visible copy button into the HTML and use browser clipboard APIs from JavaScript.

This is not selected because it adds chrome inside the reading surface, can cover document content, and depends on WebView clipboard behavior.

### C. AppKit `NSToolbar` Owned By `NSWindow`

Build the button directly from `AppDelegate`/`NSWindow`.

This is not selected because the button needs access to `ContentView`'s current markdown state. Wiring AppKit toolbar actions back into SwiftUI state would add unnecessary complexity for this small feature.

## 5. Architecture

### `ContentView`

`ContentView` becomes the source of truth for the current original markdown source:

```swift
@State private var markdown: String?
```

On initial file load:

1. Read the source markdown from `fileURL`
2. Store it in `markdown`
3. Render it to HTML as today
4. Pass rendered HTML to `MarkdownWebView`

On read failure, `markdown` is set to `nil` so the toolbar action cannot copy stale content. An empty string still means the file was loaded successfully.

### `MarkdownWebView.Coordinator`

Live reload currently rereads the file and patches the WebView directly from the coordinator. To keep `ContentView.markdown` current, reload events should notify `ContentView` with the freshly read source markdown.

The coordinator can expose a callback:

```swift
let onMarkdownReload: (String) -> Void
```

When `handleFileChange()` successfully reads the file, it calls the callback on the main thread before or alongside `updateContent(...)`.

This preserves the current seamless DOM patch behavior while keeping native toolbar state synchronized with file changes.

### Clipboard Action

`ContentView` owns a small helper:

```swift
private func copyMarkdown()
```

The helper:

1. Verifies `markdown` is not `nil`
2. Clears `NSPasteboard.general`
3. Writes `markdown` as `.string`
4. Updates short-lived copy feedback state

Empty files are valid markdown files. Copying a successfully loaded empty file writes an empty string to the pasteboard.

## 6. Data Flow

```text
Initial reader open
  ContentView.loadFile()
    -> read original markdown
    -> markdown state updated
    -> MarkdownRenderer.render(markdown)
    -> HTMLTemplate.compose(...)
    -> MarkdownWebView(html:)

File save while reader is open
  FileWatcher
    -> MarkdownWebView.Coordinator.handleFileChange()
    -> read original markdown
    -> onMarkdownReload(markdown)
    -> MarkdownRenderer.render(markdown)
    -> evaluateJavaScript("updateContent(...)")

User taps Copy Markdown
  Toolbar button
    -> ContentView.copyMarkdown()
    -> NSPasteboard.general receives original markdown
    -> brief Copied feedback
```

## 7. Error Handling

- Missing file or initial read failure: show the existing error message and keep copy disabled.
- Live reload read failure: keep the last rendered document as today, and do not overwrite `ContentView.markdown`.
- Pasteboard write failure is unlikely with `NSPasteboard`; if writing returns false, do not show `Copied`.
- File deletion: keep the current title behavior. Copy may continue to use the last successfully loaded markdown while the last render remains visible.

## 8. Testing

### Unit-Level Verification

Add a focused helper if needed so pasteboard writing can be tested without launching the full reader. The test should verify that markdown text including code fences and trailing newline is written exactly as provided, and that a successfully loaded empty string is preserved.

### Build Verification

Run the repository-required checks after implementation:

```bash
make lint
swift test
xcodebuild -project geul.xcodeproj -scheme geul -configuration Debug build
```

If XcodeBuildMCP defaults are configured, use `session_show_defaults` and `build_sim` as the primary Xcode verification path.

### Manual Verification

1. Open a markdown file in the reader
2. Click `Copy Markdown`
3. Paste into a plain text field
4. Confirm the pasted content matches the source file, not the rendered text
5. Edit and save the source file while the reader is open
6. Click `Copy Markdown` again and confirm the clipboard receives the updated source

## 9. Implementation Boundaries

Expected files:

- `geul/ContentView.swift`
- `geul/MarkdownWebView.swift`
- Optional focused test file under `Tests/geulTests/`

No changes are expected in `MarkdownRenderer`, `HTMLTemplate`, CLI/TUI files, or theme resources.
