import Darwin
import Foundation

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
}
