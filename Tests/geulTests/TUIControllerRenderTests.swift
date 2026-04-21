import XCTest
@testable import geul

final class TUIControllerRenderTests: XCTestCase {
    private func matched(_ path: String, indices: [Int] = []) -> MatchedEntry {
        MatchedEntry(
            entry: FileEntry(
                url: URL(fileURLWithPath: "/tmp/\(path)"),
                relativePath: path, depth: 0, mtime: Date()
            ),
            score: 0,
            matchIndices: indices
        )
    }

    // MARK: - composeRow

    func testComposeRowUnselectedIsPrefixedPath() {
        let row = TUIController.composeRow(
            entry: matched("abc.md"),
            width: 10,
            selected: false
        )
        // "  abc.md" + 2 spaces of padding up to width 10
        XCTAssertEqual(row, "  abc.md  ")
        XCTAssertFalse(row.contains("\u{1B}["))
    }

    func testComposeRowSelectedWrapsInInverse() {
        let row = TUIController.composeRow(
            entry: matched("abc.md"),
            width: 10,
            selected: true
        )
        XCTAssertTrue(row.hasPrefix(Terminal.ansi.inverseOn))
        XCTAssertTrue(row.hasSuffix(Terminal.ansi.reset))
        XCTAssertTrue(row.contains("❯ abc.md"))
    }

    func testComposeRowWithMatchesUsesUnderlineOff() {
        // 'b' at index 1 is a match; no [0m inside the match close.
        let row = TUIController.composeRow(
            entry: matched("abc.md", indices: [1]),
            width: 10,
            selected: false
        )
        XCTAssertTrue(row.contains(Terminal.ansi.underlineOn + "b" + Terminal.ansi.underlineOff))
        // The [0m seen in selected rows is absent here because we're unselected.
        XCTAssertFalse(row.contains(Terminal.ansi.reset))
    }

    func testComposeRowSelectedWithMatchesPreservesInverse() {
        // Known bug case from Phase 6: inverse must not be cleared by match close.
        let row = TUIController.composeRow(
            entry: matched("abc.md", indices: [1]),
            width: 10,
            selected: true
        )
        // Exactly one [0m at the very end (row wrapper close).
        let resetCount = row.components(separatedBy: Terminal.ansi.reset).count - 1
        XCTAssertEqual(resetCount, 1, "selection reset should only appear once, at row end")
        XCTAssertTrue(row.hasSuffix(Terminal.ansi.reset))
        // Match close should be [24m, not [0m.
        XCTAssertTrue(row.contains("b" + Terminal.ansi.underlineOff))
    }

    func testComposeRowTruncatesPathLongerThanWidth() {
        let row = TUIController.composeRow(
            entry: matched("this-is-a-very-long-name.md"),
            width: 12,
            selected: false
        )
        // width 12, prefix 2 → keep 10 path chars ("this-is-a-") and emit no padding.
        XCTAssertEqual(row, "  this-is-a-")
    }

    // MARK: - drawBoxFrame

    func testDrawBoxFrameOnePane() {
        // rows=5, cols=20, 1-pane. Frame layout:
        // row 1: ┌─ FILES 1/2 ─────┐  (title padded to cols)
        // row 2: │                  │  (content, single row)
        // row 3: ├──────────────────┤  (middle separator)
        // row 4: │ ❯ q               │  (status: prompt + query + padding)
        // row 5: └──────────────────┘  (bottom)
        let frame = TUIController.drawBoxFrame(
            rows: 5, cols: 20,
            splitCol: nil,
            filesTitle: "FILES 1/2",
            previewTitle: nil,
            query: "q"
        )
        // Top-left + bottom-right corners present
        XCTAssertTrue(frame.contains(Terminal.box.tl))
        XCTAssertTrue(frame.contains(Terminal.box.br))
        // Title embedded after "┌─ "
        XCTAssertTrue(frame.contains("┌─ FILES 1/2"))
        // Prompt + query on status line
        XCTAssertTrue(frame.contains("❯ q"))
        // Middle separator has teeRight + teeLeft (no teeUp because 1-pane)
        XCTAssertTrue(frame.contains(Terminal.box.teeRight))
        XCTAssertTrue(frame.contains(Terminal.box.teeLeft))
        XCTAssertFalse(frame.contains(Terminal.box.teeUp))
        XCTAssertFalse(frame.contains(Terminal.box.teeDown))
    }

    func testDrawBoxFrameTwoPane() {
        // 2-pane: teeDown on top row, teeUp on middle row, vertical splitter
        let frame = TUIController.drawBoxFrame(
            rows: 6, cols: 40,
            splitCol: 20,
            filesTitle: "FILES 5/10",
            previewTitle: "PREVIEW",
            query: ""
        )
        XCTAssertTrue(frame.contains("┌─ FILES 5/10"))
        XCTAssertTrue(frame.contains("┬─ PREVIEW"))
        XCTAssertTrue(frame.contains(Terminal.box.teeUp))
        XCTAssertTrue(frame.contains(Terminal.box.teeDown))
    }

    func testDrawBoxFrameCursorMovesCoverEveryRow() {
        // Each row should be addressed by a moveCursor escape.
        let frame = TUIController.drawBoxFrame(
            rows: 5, cols: 20,
            splitCol: nil,
            filesTitle: "FILES 0/0",
            previewTitle: nil,
            query: ""
        )
        for row in 1...5 {
            XCTAssertTrue(
                frame.contains(Terminal.ansi.moveCursor(row: row, col: 1)),
                "frame should address row \(row)"
            )
        }
    }

    // MARK: - previewLines

    func testPreviewLinesReturnsUnavailableForEmptyFile() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-test-\(UUID().uuidString).md")
        try Data().write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let lines = TUIController.previewLines(for: tmp, maxLines: 5)
        XCTAssertEqual(lines, ["(preview unavailable)"])
    }

    func testPreviewLinesReturnsUnavailableForWhitespaceOnlyFile() throws {
        // `echo "" > empty.md` 는 1바이트(`\n`) 파일을 만든다. 사용자 기대는 "빈 파일" 취급.
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-test-\(UUID().uuidString).md")
        try Data("\n".utf8).write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let lines = TUIController.previewLines(for: tmp, maxLines: 5)
        XCTAssertEqual(lines, ["(preview unavailable)"])
    }

    func testPreviewLinesReturnsUnavailableForSpacesAndNewlinesOnly() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-test-\(UUID().uuidString).md")
        try Data("   \n\t\n  \n".utf8).write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let lines = TUIController.previewLines(for: tmp, maxLines: 5)
        XCTAssertEqual(lines, ["(preview unavailable)"])
    }

    func testPreviewLinesReturnsContentForNonEmptyFile() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-test-\(UUID().uuidString).md")
        try Data("# Hello\n".utf8).write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let lines = TUIController.previewLines(for: tmp, maxLines: 5)
        XCTAssertEqual(lines.first, "# Hello")
    }
}
