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
}
