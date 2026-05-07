import XCTest
@testable import geul

final class FindCommandBridgeTests: XCTestCase {
    func testInitialRequestDoesNothing() {
        let bridge = FindCommandBridge()

        XCTAssertEqual(bridge.request.id, 0)
        XCTAssertEqual(bridge.request.command, .none)
    }

    func testDispatchPublishesIncreasingRequestIDs() {
        let bridge = FindCommandBridge()

        bridge.dispatch(.showFindInterface)
        let first = bridge.request
        bridge.dispatch(.nextMatch)
        let second = bridge.request

        XCTAssertEqual(first.id, 1)
        XCTAssertEqual(first.command, .showFindInterface)
        XCTAssertEqual(second.id, 2)
        XCTAssertEqual(second.command, .nextMatch)
    }

    func testAvailabilityUpdatesForMenuValidation() {
        let bridge = FindCommandBridge()

        bridge.updateAvailability(
            canFind: true,
            isFindVisible: true,
            hasQuery: true
        )

        XCTAssertTrue(bridge.canFind)
        XCTAssertTrue(bridge.isFindVisible)
        XCTAssertTrue(bridge.hasQuery)
    }

    func testAppDelegateRoutesFindCommandsThroughStandardActionOnKeyWindow() throws {
        let source = try String(contentsOf: Self.geulAppSourceURL(), encoding: .utf8)

        XCTAssertTrue(source.contains("NSApp.sendAction("))
        XCTAssertTrue(source.contains("#selector(NSResponder.performTextFinderAction(_:))"))
        XCTAssertTrue(source.contains("NSApp.keyWindow as? MarkdownWindow"))
        XCTAssertFalse(source.contains("NSApp.mainWindow as? MarkdownWindow"))
    }

    private static func geulAppSourceURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/GeulApp.swift")
    }
}
