import XCTest
@testable import geul

final class TUIControllerStateTests: XCTestCase {
    private func entry(_ path: String) -> FileEntry {
        FileEntry(url: URL(fileURLWithPath: "/tmp/\(path)"),
                  relativePath: path, depth: 0, mtime: Date())
    }

    private func initialState(entries: [FileEntry]) -> TUIState {
        TUIState(
            entries: entries,
            query: "",
            visible: entries.map { MatchedEntry(entry: $0, score: 0, matchIndices: []) },
            cursor: 0,
            scrollOffset: 0,
            winSize: (rows: 24, cols: 80)
        )
    }

    func testCharAppendsToQueryAndRefilters() {
        var state = initialState(entries: [entry("apple.md"), entry("banana.md")])
        state = TUIController.reduce(state: state, event: .char("a"))
        XCTAssertEqual(state.query, "a")
        XCTAssertEqual(state.visible.count, 2) // 둘 다 'a' 포함
    }

    func testBackspaceRemovesLastChar() {
        var state = initialState(entries: [entry("a.md")])
        state.query = "ab"
        state = TUIController.reduce(state: state, event: .backspace)
        XCTAssertEqual(state.query, "a")
    }

    func testBackspaceOnEmptyQueryIsNoOp() {
        var state = initialState(entries: [entry("a.md")])
        state = TUIController.reduce(state: state, event: .backspace)
        XCTAssertEqual(state.query, "")
    }

    func testArrowDownMovesCursor() {
        var state = initialState(entries: [entry("a.md"), entry("b.md"), entry("c.md")])
        state = TUIController.reduce(state: state, event: .arrow(.down))
        XCTAssertEqual(state.cursor, 1)
    }

    func testArrowUpClampsAtZero() {
        var state = initialState(entries: [entry("a.md")])
        state = TUIController.reduce(state: state, event: .arrow(.up))
        XCTAssertEqual(state.cursor, 0)
    }

    func testArrowDownClampsAtLast() {
        var state = initialState(entries: [entry("a.md"), entry("b.md")])
        state.cursor = 1
        state = TUIController.reduce(state: state, event: .arrow(.down))
        XCTAssertEqual(state.cursor, 1)
    }

    func testQueryResetsCursorToZero() {
        var state = initialState(entries: [entry("aa.md"), entry("ab.md"), entry("ac.md")])
        state.cursor = 2
        state = TUIController.reduce(state: state, event: .char("a"))
        XCTAssertEqual(state.cursor, 0)
    }

    func testScrollOffsetFollowsCursorWithMargin() {
        // 가시 높이 = winSize.rows - 1 (상태줄) - margin 3 등
        // 리스트 length = 30, winSize.rows = 10 (가시 9줄 가정)
        var state = TUIState(
            entries: (0..<30).map { entry("f\($0).md") },
            query: "",
            visible: (0..<30).map { MatchedEntry(entry: entry("f\($0).md"), score: 0, matchIndices: []) },
            cursor: 0,
            scrollOffset: 0,
            winSize: (rows: 10, cols: 80)
        )
        // 아래로 여러 번 누르면 scrollOffset > 0 되어야 함
        for _ in 0..<20 {
            state = TUIController.reduce(state: state, event: .arrow(.down))
        }
        XCTAssertGreaterThan(state.scrollOffset, 0)
        XCTAssertLessThan(state.scrollOffset, state.cursor)
    }

    func testResizeUpdatesWinSize() {
        var state = initialState(entries: [])
        state = TUIController.reduce(
            state: state,
            event: .resize,
            newWinSize: (rows: 40, cols: 120)
        )
        XCTAssertEqual(state.winSize.rows, 40)
        XCTAssertEqual(state.winSize.cols, 120)
    }

    func testEmptyEntriesKeepsCursorAtZero() {
        var state = initialState(entries: [])
        state = TUIController.reduce(state: state, event: .arrow(.down))
        XCTAssertEqual(state.cursor, 0)
    }
}
