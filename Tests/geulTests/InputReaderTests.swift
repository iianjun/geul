import XCTest
@testable import geul

final class InputReaderTests: XCTestCase {
    /// 완성된 시퀀스만 들어오는 경우 편의 헬퍼 — flushEsc=true 로 잔여 ESC 도 즉시 emit.
    private func parseAll(_ bytes: [UInt8]) -> [KeyEvent] {
        let (events, remaining) = InputReader.parse(bytes: bytes, flushEsc: true)
        XCTAssertTrue(remaining.isEmpty, "expected full consumption but got remaining: \(remaining)")
        return events
    }

    func testPlainChar() {
        XCTAssertEqual(parseAll([0x61]), [.char("a")])
    }

    func testMultibyteUTF8Char() {
        // '가' = 0xEA 0xB0 0x80
        XCTAssertEqual(parseAll([0xEA, 0xB0, 0x80]), [.char("가")])
    }

    func testBackspaceDEL() {
        XCTAssertEqual(parseAll([0x7F]), [.backspace])
    }

    func testBackspaceBS() {
        XCTAssertEqual(parseAll([0x08]), [.backspace])
    }

    func testEnter() {
        XCTAssertEqual(parseAll([0x0D]), [.enter])
    }

    func testEnterLF() {
        XCTAssertEqual(parseAll([0x0A]), [.enter])
    }

    func testEscAloneWithFlushEmitsEsc() {
        XCTAssertEqual(parseAll([0x1B]), [.esc])
    }

    func testCtrlC() {
        XCTAssertEqual(parseAll([0x03]), [.ctrlC])
    }

    func testArrowUp() {
        XCTAssertEqual(parseAll([0x1B, 0x5B, 0x41]), [.arrow(.up)])
    }

    func testArrowDown() {
        XCTAssertEqual(parseAll([0x1B, 0x5B, 0x42]), [.arrow(.down)])
    }

    func testArrowLeftAndRightIgnored() {
        // Phase 6 에서는 좌우 화살표 미사용 — 무시 (이벤트 0개)
        XCTAssertEqual(parseAll([0x1B, 0x5B, 0x43]), [])
        XCTAssertEqual(parseAll([0x1B, 0x5B, 0x44]), [])
    }

    func testMixedSequence() {
        // "ab" + arrow down + Enter
        let bytes: [UInt8] = [0x61, 0x62, 0x1B, 0x5B, 0x42, 0x0D]
        XCTAssertEqual(parseAll(bytes),
                       [.char("a"), .char("b"), .arrow(.down), .enter])
    }

    // --- 파편화(split escape sequence) 처리 ---

    func testBareEscWithoutFlushIsPending() {
        // ESC 단독 + flushEsc=false → esc 방출 안 됨, 잔여에 ESC 남음
        let (events, remaining) = InputReader.parse(bytes: [0x1B], flushEsc: false)
        XCTAssertTrue(events.isEmpty)
        XCTAssertEqual(remaining, [0x1B])
    }

    func testEscPlusLeftBracketPendingWithoutFlush() {
        // ESC [ 까지만 왔을 때 — 다음 바이트 기다림
        let (events, remaining) = InputReader.parse(bytes: [0x1B, 0x5B], flushEsc: false)
        XCTAssertTrue(events.isEmpty)
        XCTAssertEqual(remaining, [0x1B, 0x5B])
    }

    func testEscPlusLeftBracketPendingEvenWithFlush() {
        // ESC [ 파편은 flushEsc=true 여도 pending 유지 (arrow 완성 가능성 있음 — 다음 read 로 완성 시도)
        let (events, remaining) = InputReader.parse(bytes: [0x1B, 0x5B], flushEsc: true)
        XCTAssertTrue(events.isEmpty)
        XCTAssertEqual(remaining, [0x1B, 0x5B])
    }

    func testSplitArrowStitchedAcrossCalls() {
        // 1차 read: ESC만. 2차 read: [ B. 누적 버퍼 처리로 arrow down 한 번만 emit.
        var buffer: [UInt8] = [0x1B]
        var (events, remaining) = InputReader.parse(bytes: buffer, flushEsc: false)
        XCTAssertTrue(events.isEmpty)
        XCTAssertEqual(remaining, [0x1B])

        // 2차 read 모사
        buffer = remaining + [0x5B, 0x42]
        (events, remaining) = InputReader.parse(bytes: buffer, flushEsc: true)
        XCTAssertEqual(events, [.arrow(.down)])
        XCTAssertTrue(remaining.isEmpty)
    }

    func testEscFollowedByNonBracketEmitsEscAndContinues() {
        // ESC + 'a' — ESC 는 진짜 ESC (timeout 없이도 알 수 있음: 다음 바이트가 '[' 아님)
        XCTAssertEqual(parseAll([0x1B, 0x61]), [.esc, .char("a")])
    }

    func testTrailingIncompleteUTF8IsPending() {
        // '가' (3바이트)의 리딩 바이트만 도착
        let (events, remaining) = InputReader.parse(bytes: [0x61, 0xEA], flushEsc: true)
        XCTAssertEqual(events, [.char("a")])
        XCTAssertEqual(remaining, [0xEA])
    }
}
