import Darwin
import Foundation

enum Terminal {
    // swiftlint:disable:next type_name
    enum ansi {
        static let moveCursorHome = "\u{1B}[H"
        static let clearScreen = "\u{1B}[2J"
        static let altScreenEnter = "\u{1B}[?1049h"
        static let altScreenLeave = "\u{1B}[?1049l"
        static let hideCursor = "\u{1B}[?25l"
        static let showCursor = "\u{1B}[?25h"
        static let reset = "\u{1B}[0m"
        static let inverseOn = "\u{1B}[7m"
        static let underlineOn = "\u{1B}[4m"
        static func moveCursor(row: Int, col: Int) -> String {
            "\u{1B}[\(row);\(col)H"
        }
    }

    private static var originalTermios: termios?
    private static var didSetup = false

    static func enterRawMode() {
        var term = termios()
        tcgetattr(STDIN_FILENO, &term)
        originalTermios = term
        term.c_lflag &= ~tcflag_t(ICANON | ECHO | ISIG)
        term.c_cc.16 = 1 // VMIN — block until at least 1 byte is read
        term.c_cc.17 = 0 // VTIME
        tcsetattr(STDIN_FILENO, TCSANOW, &term)
        didSetup = true
    }

    static func enterAltScreen() {
        write(ansi.altScreenEnter)
        write(ansi.hideCursor)
    }

    static func cleanup() {
        guard didSetup else { return }
        didSetup = false
        // Order: show cursor → exit alt screen → restore termios
        write(ansi.showCursor)
        write(ansi.altScreenLeave)
        write(ansi.reset)
        if var term = originalTermios {
            tcsetattr(STDIN_FILENO, TCSANOW, &term)
        }
    }

    static func write(_ text: String) {
        FileHandle.standardOutput.write(Data(text.utf8))
    }

    static func currentSize() -> (rows: Int, cols: Int) {
        var winSize = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &winSize) == 0, winSize.ws_row > 0, winSize.ws_col > 0 {
            return (Int(winSize.ws_row), Int(winSize.ws_col))
        }
        return (24, 80) // fallback
    }
}
