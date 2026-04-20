import Darwin
import Foundation

// SIGWINCH 플래그 — signal handler는 @convention(c) 라 전역 var 만 안전하게 건드림.
// swift-tools 5.9 (현재 Package.swift 버전) 에서는 strict concurrency 경고 없이 허용.
private var sigwinchFlag: sig_atomic_t = 0

private func handleSigwinch(_ signum: Int32) {
    sigwinchFlag = 1
}

struct TUIState {
    let entries: [FileEntry]
    var query: String
    var visible: [MatchedEntry]
    var cursor: Int
    var scrollOffset: Int
    var winSize: (rows: Int, cols: Int)
}

enum TUIController {
    private static let scrollMargin = 3

    /// 순수 상태 전이 함수. 렌더나 I/O 없음.
    /// `.resize` 는 새 winSize 가 외부에서 들어와야 하므로 오버로드 제공.
    static func reduce(state: TUIState, event: KeyEvent) -> TUIState {
        reduce(state: state, event: event, newWinSize: state.winSize)
    }

    static func reduce(state: TUIState, event: KeyEvent,
                       newWinSize: (rows: Int, cols: Int)) -> TUIState {
        var next = state
        switch event {
        case .char(let character):
            next.query.append(character)
            next.visible = FuzzyMatcher.filter(next.entries, query: next.query)
            next.cursor = 0
            next.scrollOffset = 0
        case .backspace:
            if !next.query.isEmpty { next.query.removeLast() }
            next.visible = FuzzyMatcher.filter(next.entries, query: next.query)
            next.cursor = 0
            next.scrollOffset = 0
        case .arrow(.up):
            next.cursor = max(0, next.cursor - 1)
            next.scrollOffset = adjustScroll(cursor: next.cursor,
                                             offset: next.scrollOffset,
                                             total: next.visible.count,
                                             visibleHeight: visibleListHeight(next.winSize.rows))
        case .arrow(.down):
            let upperBound = max(0, next.visible.count - 1)
            next.cursor = min(upperBound, next.cursor + 1)
            next.scrollOffset = adjustScroll(cursor: next.cursor,
                                             offset: next.scrollOffset,
                                             total: next.visible.count,
                                             visibleHeight: visibleListHeight(next.winSize.rows))
        case .resize:
            next.winSize = newWinSize
            next.scrollOffset = adjustScroll(cursor: next.cursor,
                                             offset: next.scrollOffset,
                                             total: next.visible.count,
                                             visibleHeight: visibleListHeight(newWinSize.rows))
        case .enter, .esc, .ctrlC:
            // 종료/액션은 호출자(run)가 처리. 상태는 건드리지 않음.
            break
        }
        return next
    }

    static func visibleListHeight(_ rows: Int) -> Int {
        max(1, rows - 1) // 상태줄 1줄 제외
    }

    static func adjustScroll(cursor: Int, offset: Int, total: Int, visibleHeight: Int) -> Int {
        guard total > 0 else { return 0 }
        var newOffset = offset
        // 위쪽 마진
        if cursor - newOffset < scrollMargin {
            newOffset = max(0, cursor - scrollMargin)
        }
        // 아래쪽 마진
        if cursor - newOffset >= visibleHeight - scrollMargin {
            newOffset = cursor - visibleHeight + scrollMargin + 1
        }
        // clamp
        newOffset = max(0, min(newOffset, max(0, total - visibleHeight)))
        return newOffset
    }

    private static var previewCache: [URL: [String]] = [:]
    private static let previewCacheLimit = 5
    private static var previewCacheOrder: [URL] = []

    /// Entry point. Exit code: 0 = selected & launched, 130 = cancelled, 1 = launch failed.
    static func runMain() -> Int32 {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let entries = FileScanner.scan(cwd)

        Terminal.enterRawMode()
        Terminal.enterAltScreen()
        atexit { Terminal.cleanup() }
        signal(SIGWINCH, handleSigwinch)

        var state = TUIState(
            entries: entries,
            query: "",
            visible: entries.map { MatchedEntry(entry: $0, score: 0, matchIndices: []) },
            cursor: 0,
            scrollOffset: 0,
            winSize: Terminal.currentSize()
        )

        render(state)

        while true {
            if sigwinchFlag != 0 {
                sigwinchFlag = 0
                state = reduce(state: state, event: .resize,
                               newWinSize: Terminal.currentSize())
                render(state)
            }
            let events = InputReader.readNextBatch()
            if events.isEmpty { continue }
            for event in events {
                switch event {
                case .enter:
                    guard !state.visible.isEmpty else { continue }
                    let selected = state.visible[state.cursor].entry
                    Terminal.cleanup()
                    return launchGUI(for: selected.url)
                case .esc, .ctrlC:
                    Terminal.cleanup()
                    return 130
                case .resize:
                    state = reduce(state: state, event: .resize,
                                   newWinSize: Terminal.currentSize())
                default:
                    state = reduce(state: state, event: event)
                }
            }
            render(state)
        }
    }

    private static func launchGUI(for url: URL) -> Int32 {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        proc.arguments = ["-a", "geul", url.path]
        // 실패 메시지가 TUI 복원 후 사용자 터미널에 안정적으로 보이도록 stderr 를 파이프로
        let errPipe = Pipe()
        proc.standardError = errPipe

        do {
            try proc.run()
            proc.waitUntilExit() // `open` 자체는 즉시 반환 (앱 실행은 비동기)
        } catch {
            FileHandle.standardError.write(
                Data("geul: failed to spawn /usr/bin/open: \(error)\n".utf8))
            return 1
        }

        guard proc.terminationStatus == 0 else {
            let errData = (try? errPipe.fileHandleForReading.readToEnd()) ?? Data()
            var msg = "geul: `open -a geul` exited with status \(proc.terminationStatus)\n"
            if !errData.isEmpty, let errString = String(data: errData, encoding: .utf8),
               !errString.isEmpty {
                msg += "open stderr: \(errString)"
                if !msg.hasSuffix("\n") { msg += "\n" }
            }
            FileHandle.standardError.write(Data(msg.utf8))
            return 1
        }
        return 0
    }

    // swiftlint:disable:next function_body_length
    private static func render(_ state: TUIState) {
        var buf = Terminal.ansi.moveCursorHome + Terminal.ansi.clearScreen

        let rows = state.winSize.rows
        let cols = state.winSize.cols

        // Too small to draw the frame: print a single placeholder line.
        guard rows >= 5, cols >= 10 else {
            buf += "geul: terminal too small"
            Terminal.write(buf)
            return
        }

        let hasPreview = cols >= 80 && !state.entries.isEmpty
        let splitCol: Int? = hasPreview
            ? max(20, min(cols - 30, cols * 6 / 10))
            : nil
        let previewSplit = splitCol ?? 0
        let listWidth = hasPreview ? previewSplit - 2 : cols - 2
        let previewWidth = hasPreview ? cols - previewSplit - 1 : 0
        let contentRows = rows - 4 // title(1) + separator(1) + status(1) + bottom(1)

        let matched = state.visible.count
        let total = state.entries.count
        let filesTitle = "FILES \(matched)/\(total)"

        // 1) Frame
        buf += drawBoxFrame(
            rows: rows, cols: cols,
            splitCol: splitCol,
            filesTitle: filesTitle,
            previewTitle: hasPreview ? "PREVIEW" : nil,
            query: state.query
        )

        // 2) List cell
        if state.entries.isEmpty {
            buf += centeredMessage("No markdown files here",
                                   atRow: 2 + contentRows / 2,
                                   col: 2,
                                   width: cols - 2)
        } else if state.visible.isEmpty {
            buf += centeredMessage("No matches",
                                   atRow: 2 + contentRows / 2,
                                   col: 2,
                                   width: listWidth)
        } else {
            for localRow in 0..<contentRows {
                let listIdx = state.scrollOffset + localRow
                guard listIdx < state.visible.count else { break }
                let row = 2 + localRow
                buf += Terminal.ansi.moveCursor(row: row, col: 2)
                buf += composeRow(
                    entry: state.visible[listIdx],
                    width: listWidth,
                    selected: listIdx == state.cursor
                )
            }
        }

        // 3) Preview cell
        if hasPreview, !state.visible.isEmpty {
            let previewRows = previewLines(
                for: state.visible[state.cursor].entry.url,
                maxLines: contentRows
            )
            for localRow in 0..<contentRows {
                let row = 2 + localRow
                guard localRow < previewRows.count else { break }
                buf += Terminal.ansi.moveCursor(row: row, col: previewSplit + 1)
                buf += truncate(previewRows[localRow], to: previewWidth)
            }
        }

        Terminal.write(buf)
    }

    /// Place a short message horizontally centered inside the given cell, with ANSI move-cursor.
    private static func centeredMessage(_ text: String, atRow row: Int, col startCol: Int, width: Int) -> String {
        let pad = max(0, (width - text.count) / 2)
        return Terminal.ansi.moveCursor(row: row, col: startCol + pad) + text
    }

    static func composeRow(entry: MatchedEntry, width: Int, selected: Bool) -> String {
        let prefix = selected ? "❯ " : "  "
        let path = entry.entry.relativePath
        let rendered = highlight(path: path, indices: Set(entry.matchIndices))
        let plainLength = 2 + path.count // prefix + path (ANSI 제외)
        let trimmed: String
        if plainLength > width {
            // 오른쪽을 자름
            let keep = max(0, width - 2)
            trimmed = prefix + String(path.prefix(keep))
        } else {
            trimmed = prefix + rendered + String(repeating: " ",
                                                 count: max(0, width - plainLength))
        }
        return selected
            ? Terminal.ansi.inverseOn + trimmed + Terminal.ansi.reset
            : trimmed
    }

    /// Emit the static frame: top border with titles, left/right borders for each content row,
    /// middle separator above the status bar, status bar with prompt + query, bottom border.
    /// Content cells are left empty — `render(_:)` overlays them.
    static func drawBoxFrame(
        rows: Int,
        cols: Int,
        splitCol: Int?,           // nil = 1-pane, otherwise the col index of the vertical splitter
        filesTitle: String,
        previewTitle: String?,    // nil = 1-pane
        query: String
    ) -> String {
        var buf = ""
        // swiftlint:disable:next identifier_name
        let h = Terminal.box.h

        // --- Row 1: top border with titles ---
        buf += Terminal.ansi.moveCursor(row: 1, col: 1)
        if let splitCol, let previewTitle {
            // 2-pane. teeDown lands at col splitCol, so the left title segment covers
            // cols 2..splitCol-1 = splitCol - 2 glyphs; the right covers splitCol+1..cols-1.
            let leftInner = splitCol - 2
            let rightInner = cols - splitCol - 1
            buf += Terminal.box.tl + topTitleSegment(title: filesTitle, innerWidth: leftInner)
            buf += Terminal.box.teeDown + topTitleSegment(title: previewTitle, innerWidth: rightInner)
            buf += Terminal.box.tr
        } else {
            // 1-pane
            buf += Terminal.box.tl + topTitleSegment(title: filesTitle, innerWidth: cols - 2)
            buf += Terminal.box.tr
        }

        // --- Rows 2 .. rows-3: content body (borders + splitter only) ---
        for row in 2...(rows - 3) {
            buf += Terminal.ansi.moveCursor(row: row, col: 1)
            buf += Terminal.box.v
            if let splitCol {
                buf += String(repeating: " ", count: splitCol - 2)
                buf += Terminal.box.v
                buf += String(repeating: " ", count: cols - splitCol - 1)
            } else {
                buf += String(repeating: " ", count: cols - 2)
            }
            buf += Terminal.box.v
        }

        // --- Row rows-2: middle separator ---
        buf += Terminal.ansi.moveCursor(row: rows - 2, col: 1)
        if let splitCol {
            // ├─…─┴─…─┤
            buf += Terminal.box.teeRight
            buf += String(repeating: h, count: splitCol - 2)
            buf += Terminal.box.teeUp
            buf += String(repeating: h, count: cols - splitCol - 1)
            buf += Terminal.box.teeLeft
        } else {
            // ├─…─┤
            buf += Terminal.box.teeRight
            buf += String(repeating: h, count: cols - 2)
            buf += Terminal.box.teeLeft
        }

        // --- Row rows-1: status bar ---
        // Layout: "│" + " " + "❯ <query>" + padding + "│"  (total width = cols)
        // If the query outgrows the remaining space, keep the tail so the latest keystrokes stay visible.
        buf += Terminal.ansi.moveCursor(row: rows - 1, col: 1)
        let maxQueryLen = max(0, cols - 5) // cols - "│ ❯ " (4) - trailing "│" (1)
        let shownQuery = query.count > maxQueryLen
            ? String(query.suffix(maxQueryLen))
            : query
        let status = "❯ \(shownQuery)"
        let padTarget = max(0, cols - 3 - status.count)
        buf += Terminal.box.v + " " + status + String(repeating: " ", count: padTarget)
        buf += Terminal.box.v

        // --- Row rows: bottom border ---
        buf += Terminal.ansi.moveCursor(row: rows, col: 1)
        buf += Terminal.box.bl + String(repeating: h, count: cols - 2) + Terminal.box.br

        return buf
    }

    /// "─ TITLE ────…─" padded with horizontal-dash to exactly `innerWidth` glyphs.
    /// If "─ TITLE " is already longer than `innerWidth`, truncate from the right so the frame stays flush.
    /// Used between ┌/┬ and ┬/┐ corners.
    private static func topTitleSegment(title: String, innerWidth: Int) -> String {
        // swiftlint:disable:next identifier_name
        let h = Terminal.box.h
        let full = "\(h) \(title) "
        if full.count >= innerWidth {
            return String(full.prefix(innerWidth))
        }
        return full + String(repeating: h, count: innerWidth - full.count)
    }

    static func highlight(path: String, indices: Set<Int>) -> String {
        guard !indices.isEmpty else { return path }
        var out = ""
        for (idx, char) in path.enumerated() {
            if indices.contains(idx) {
                out += Terminal.ansi.underlineOn + String(char) + Terminal.ansi.underlineOff
            } else {
                out += String(char)
            }
        }
        return out
    }

    private static func truncate(_ text: String, to width: Int) -> String {
        guard text.count > width else { return text }
        return String(text.prefix(max(0, width)))
    }

    private static func previewLines(for url: URL, maxLines: Int) -> [String] {
        if let cached = previewCache[url] {
            previewCacheOrder.removeAll { $0 == url }
            previewCacheOrder.append(url)
            return cached
        }
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return ["(preview unavailable)"]
        }
        defer { try? handle.close() }
        let maxBytes = maxLines * 256
        let data = (try? handle.read(upToCount: maxBytes)) ?? Data()
        guard let str = String(data: data, encoding: .utf8) else {
            return ["(preview unavailable)"]
        }
        let split = str.split(separator: "\n", omittingEmptySubsequences: false)
        let lines = split.prefix(maxLines).map(String.init)
        previewCache[url] = lines
        previewCacheOrder.append(url)
        if previewCacheOrder.count > previewCacheLimit {
            let evict = previewCacheOrder.removeFirst()
            previewCache.removeValue(forKey: evict)
        }
        return lines
    }
}
