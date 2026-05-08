import AppKit
import XCTest
@testable import geul

@MainActor
final class ReaderWindowSizingTests: XCTestCase {
    func testReaderWindowFactoryUsesDefaultAndMinimumContentSizes() {
        let url = URL(fileURLWithPath: "/tmp/example.md")
        let window = AppDelegate.makeReaderWindow(for: url)
        defer { window.close() }

        let contentSize = window.contentRect(forFrameRect: window.frame).size

        XCTAssertEqual(contentSize.width, ReaderWindowSizing.defaultContentSize.width)
        XCTAssertEqual(contentSize.height, ReaderWindowSizing.defaultContentSize.height)
        XCTAssertEqual(window.contentMinSize.width, ReaderWindowSizing.minimumContentSize.width)
        XCTAssertEqual(window.contentMinSize.height, ReaderWindowSizing.minimumContentSize.height)
        XCTAssertEqual(window.title, "example.md")
        XCTAssertNotNil(window.contentViewController)
    }
}
