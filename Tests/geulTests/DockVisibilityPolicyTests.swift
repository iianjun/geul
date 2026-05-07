import AppKit
import XCTest
@testable import geul

final class DockVisibilityPolicyTests: XCTestCase {
    func testAgentLaunchStartsHiddenFromDock() {
        XCTAssertEqual(
            DockVisibilityPolicy.launchActivationPolicy(launchedFromCLIWrapper: false),
            .accessory
        )
    }

    func testCLIWrapperLaunchStartsVisibleInDock() {
        XCTAssertEqual(
            DockVisibilityPolicy.launchActivationPolicy(launchedFromCLIWrapper: true),
            .regular
        )
    }

    func testOpeningReaderWindowShowsDock() {
        XCTAssertEqual(DockVisibilityPolicy.readerWindowOpenedPolicy, .regular)
    }

    func testAgentWithNoReaderWindowsHidesDockAgain() {
        XCTAssertEqual(
            DockVisibilityPolicy.readerWindowsDidChangePolicy(
                isAgentMode: true,
                readerWindowCount: 0
            ),
            .accessory
        )
    }

    func testCLIWithoutReaderWindowsDoesNotChangeDockPolicy() {
        XCTAssertNil(
            DockVisibilityPolicy.readerWindowsDidChangePolicy(
                isAgentMode: false,
                readerWindowCount: 0
            )
        )
    }

    func testAgentWithReaderWindowsDoesNotChangeDockPolicy() {
        XCTAssertNil(
            DockVisibilityPolicy.readerWindowsDidChangePolicy(
                isAgentMode: true,
                readerWindowCount: 1
            )
        )
    }
}
