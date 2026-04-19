import Darwin
import Foundation

enum Direction: Equatable {
    // swiftlint:disable:next identifier_name
    case up, down
}

enum KeyEvent: Equatable {
    case char(Character)
    case backspace
    case arrow(Direction)
    case enter
    case esc
    case ctrlC
    case resize
}

enum InputReader {
    /// read() 호출 사이에 누적되는 incomplete escape / UTF-8 바이트.
    private static var pendingBytes: [UInt8] = []

    /// Pure parser. `bytes` 에서 완성된 KeyEvent 들을 뽑고, 끝에 매달린 incomplete 바이트는 `remaining` 으로 반환.
    ///
    /// - Parameter flushEsc: true 이면 버퍼 끝에 남은 `ESC` 단독 바이트를 `.esc` 로 emit.
    ///   `ESC [` 조합은 arrow 완성 여부를 알 수 없으므로 여전히 pending 으로 남김 (호출자가 timeout 후 재호출 필요).
    // swiftlint:disable:next cyclomatic_complexity
    static func parse(bytes: [UInt8], flushEsc: Bool = false) -> (events: [KeyEvent], remaining: [UInt8]) {
        var events: [KeyEvent] = []
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            switch byte {
            case 0x03:
                events.append(.ctrlC); index += 1
            case 0x0A, 0x0D:
                events.append(.enter); index += 1
            case 0x08, 0x7F:
                events.append(.backspace); index += 1
            case 0x1B:
                if index + 1 >= bytes.count {
                    // ESC 만 있음
                    if flushEsc {
                        events.append(.esc)
                        index += 1
                    } else {
                        return (events, Array(bytes[index...]))
                    }
                } else if bytes[index + 1] == 0x5B {
                    if index + 2 >= bytes.count {
                        // ESC [ 까지만 — 완성 대기 (flushEsc 여부와 무관하게 pending)
                        return (events, Array(bytes[index...]))
                    }
                    switch bytes[index + 2] {
                    case 0x41: events.append(.arrow(.up))
                    case 0x42: events.append(.arrow(.down))
                    default: break // C/D (좌/우) 및 기타 — 무시
                    }
                    index += 3
                } else {
                    // ESC + non-'[' → ESC 확정 + 다음 바이트부터 정상 파싱
                    events.append(.esc)
                    index += 1
                }
            case 0x00..<0x20:
                index += 1 // 기타 제어 문자 — 무시
            default:
                let sequenceLength = utf8SequenceLength(leadingByte: byte)
                if index + sequenceLength > bytes.count {
                    // UTF-8 multibyte 도중 — 다음 read 기다림
                    return (events, Array(bytes[index...]))
                }
                let slice = Array(bytes[index..<(index + sequenceLength)])
                if let decoded = String(bytes: slice, encoding: .utf8), let character = decoded.first {
                    events.append(.char(character))
                }
                index += sequenceLength
            }
        }
        return (events, [])
    }

    private static func utf8SequenceLength(leadingByte: UInt8) -> Int {
        if leadingByte & 0x80 == 0 { return 1 }
        if leadingByte & 0xE0 == 0xC0 { return 2 }
        if leadingByte & 0xF0 == 0xE0 { return 3 }
        if leadingByte & 0xF8 == 0xF0 { return 4 }
        return 1
    }

    /// Blocking read + 상태 유지 파싱.
    /// 누적 버퍼 끝에 단독 ESC 가 남으면 최대 50ms 추가 대기 (arrow 완성 기회 제공).
    /// 타임아웃 이후엔 `.esc` 로 확정 emit.
    static func readNextBatch() -> [KeyEvent] {
        let chunk = readChunk()
        pendingBytes.append(contentsOf: chunk)

        // 단독 ESC 로 끝날 경우 — arrow 일 수도 있으니 짧게 기다림
        if pendingBytes.last == 0x1B {
            if let extra = pollAndRead(timeoutMs: 50), !extra.isEmpty {
                pendingBytes.append(contentsOf: extra)
            }
        }

        let (events, remaining) = parse(bytes: pendingBytes, flushEsc: true)
        pendingBytes = remaining
        return events
    }

    private static func readChunk() -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 64)
        let bytesRead = read(STDIN_FILENO, &buffer, buffer.count)
        guard bytesRead > 0 else { return [] }
        return Array(buffer[0..<Int(bytesRead)])
    }

    private static func pollAndRead(timeoutMs: Int32) -> [UInt8]? {
        var pfd = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        let ready = poll(&pfd, 1, timeoutMs)
        guard ready > 0, (pfd.revents & Int16(POLLIN)) != 0 else { return nil }
        return readChunk()
    }
}
