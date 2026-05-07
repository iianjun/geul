import XCTest
@testable import geul

final class FindStateTests: XCTestCase {
    func testInitialRequestDoesNothing() {
        XCTAssertEqual(FindRequest.initial.id, 0)
        XCTAssertEqual(FindRequest.initial.action, .none)
    }

    func testRequestsWithDifferentIdentifiersAreDifferent() {
        let search = FindRequest(id: 1, action: .search("reader"))
        let next = FindRequest(id: 2, action: .next)

        XCTAssertNotEqual(search, next)
        XCTAssertEqual(search.action, .search("reader"))
        XCTAssertEqual(next.action, .next)
    }

    func testEmptyResultHasNoDisplayText() {
        XCTAssertEqual(FindResult.empty.query, "")
        XCTAssertEqual(FindResult.empty.currentIndex, -1)
        XCTAssertEqual(FindResult.empty.total, 0)
        XCTAssertEqual(FindResult.empty.displayText, "")
        XCTAssertFalse(FindResult.empty.hasMatches)
    }

    func testNoMatchesDisplayText() {
        let result = FindResult(query: "missing", currentIndex: -1, total: 0)

        XCTAssertEqual(result.displayText, "No matches")
        XCTAssertFalse(result.hasMatches)
    }

    func testMatchDisplayTextIsOneBased() {
        let result = FindResult(query: "reader", currentIndex: 1, total: 3)

        XCTAssertEqual(result.displayText, "2 of 3")
        XCTAssertTrue(result.hasMatches)
    }

    func testPendingFindRequestQueuePreservesSearchBeforeNavigation() {
        var queue = PendingFindRequestQueue()
        let search = FindRequest(id: 1, action: .search("reader"))
        let next = FindRequest(id: 2, action: .next)

        queue.enqueue(search, lastAppliedRequestID: 0)
        queue.enqueue(next, lastAppliedRequestID: 0)

        XCTAssertEqual(queue.drain(), [search, next])
    }

    func testPendingFindRequestQueueIgnoresNoneAppliedAndDuplicateRequests() {
        var queue = PendingFindRequestQueue()
        let applied = FindRequest(id: 1, action: .search("old"))
        let search = FindRequest(id: 2, action: .search("reader"))

        queue.enqueue(.initial, lastAppliedRequestID: 0)
        queue.enqueue(applied, lastAppliedRequestID: 1)
        queue.enqueue(search, lastAppliedRequestID: 1)
        queue.enqueue(search, lastAppliedRequestID: 1)

        XCTAssertEqual(queue.drain(), [search])
        XCTAssertEqual(queue.drain(), [])
    }
}
