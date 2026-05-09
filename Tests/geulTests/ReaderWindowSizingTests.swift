import AppKit
import WebKit
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

    func testZoomAppliesOnlyToAttachedWebView() {
        let window = AppDelegate.makeReaderWindow(for: URL(fileURLWithPath: "/tmp/example.md"))
        let otherWindow = AppDelegate.makeReaderWindow(for: URL(fileURLWithPath: "/tmp/other.md"))
        defer {
            window.close()
            otherWindow.close()
        }
        let webView = WKWebView()
        let otherWebView = WKWebView()
        window.attachMarkdownWebView(webView)
        otherWindow.attachMarkdownWebView(otherWebView)

        window.zoomIn()

        XCTAssertEqual(webView.pageZoom, 1.1, accuracy: 0.001)
        XCTAssertEqual(window.readerState.zoomPercent, 110)
        XCTAssertEqual(otherWebView.pageZoom, 1, accuracy: 0.001)
        XCTAssertEqual(otherWindow.readerState.zoomPercent, 100)
    }

    func testZoomClampsToReadableRange() {
        let window = AppDelegate.makeReaderWindow(for: URL(fileURLWithPath: "/tmp/example.md"))
        defer { window.close() }
        let webView = WKWebView()
        window.attachMarkdownWebView(webView)

        for _ in 0..<40 {
            window.zoomOut()
        }
        XCTAssertEqual(webView.pageZoom, 0.5, accuracy: 0.001)
        XCTAssertEqual(window.readerState.zoomPercent, 50)

        for _ in 0..<40 {
            window.zoomIn()
        }
        XCTAssertEqual(webView.pageZoom, 3, accuracy: 0.001)
        XCTAssertEqual(window.readerState.zoomPercent, 300)
    }

    func testResetZoomRestoresActualSize() {
        let window = AppDelegate.makeReaderWindow(for: URL(fileURLWithPath: "/tmp/example.md"))
        defer { window.close() }
        let webView = WKWebView()
        window.attachMarkdownWebView(webView)

        window.zoomIn()
        window.resetZoom()

        XCTAssertEqual(webView.pageZoom, 1, accuracy: 0.001)
        XCTAssertEqual(window.readerState.zoomPercent, 100)
    }
}
