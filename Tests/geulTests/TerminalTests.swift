import XCTest
@testable import geul

final class TerminalTests: XCTestCase {
    func testMoveCursorEscape() {
        XCTAssertEqual(Terminal.ansi.moveCursorHome, "\u{1B}[H")
    }

    func testClearScreenEscape() {
        XCTAssertEqual(Terminal.ansi.clearScreen, "\u{1B}[2J")
    }

    func testAltScreenEnter() {
        XCTAssertEqual(Terminal.ansi.altScreenEnter, "\u{1B}[?1049h")
    }

    func testAltScreenLeave() {
        XCTAssertEqual(Terminal.ansi.altScreenLeave, "\u{1B}[?1049l")
    }

    func testHideCursor() {
        XCTAssertEqual(Terminal.ansi.hideCursor, "\u{1B}[?25l")
    }

    func testShowCursor() {
        XCTAssertEqual(Terminal.ansi.showCursor, "\u{1B}[?25h")
    }

    func testResetAttributes() {
        XCTAssertEqual(Terminal.ansi.reset, "\u{1B}[0m")
    }

    func testInverseOn() {
        XCTAssertEqual(Terminal.ansi.inverseOn, "\u{1B}[7m")
    }

    func testUnderlineOn() {
        XCTAssertEqual(Terminal.ansi.underlineOn, "\u{1B}[4m")
    }

    func testUnderlineOff() {
        XCTAssertEqual(Terminal.ansi.underlineOff, "\u{1B}[24m")
    }

    func testMoveCursorToRowCol() {
        XCTAssertEqual(Terminal.ansi.moveCursor(row: 5, col: 10), "\u{1B}[5;10H")
    }
}
