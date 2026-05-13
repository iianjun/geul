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

    func testAttachedWebViewAllowsTrackpadMagnification() {
        let window = AppDelegate.makeReaderWindow(for: URL(fileURLWithPath: "/tmp/example.md"))
        defer { window.close() }
        let webView = WKWebView()

        window.attachMarkdownWebView(webView)

        XCTAssertTrue(webView.allowsMagnification)
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

    func testOpenWindowReusesExistingWindowForSameStandardizedFileURL() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-window-reuse-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("note.md")
        try "# Note\n".write(to: fileURL, atomically: true, encoding: .utf8)
        let equivalentURL = URL(
            fileURLWithPath: tempDir.appendingPathComponent("subdir/../note.md").path
        )
        _ = NSApplication.shared
        let delegate = AppDelegate()
        defer { delegate.windows.forEach { $0.close() } }

        delegate.openWindow(for: fileURL)
        let firstWindow = try XCTUnwrap(delegate.windows.first as? MarkdownWindow)

        delegate.openWindow(for: equivalentURL)

        XCTAssertEqual(delegate.windows.count, 1)
        XCTAssertTrue(delegate.windows.first.map { $0 === firstWindow } ?? false)
        XCTAssertEqual(firstWindow.fileURL, fileURL.standardizedFileURL)
    }

    func testNumberedTabSelectionUsesCurrentTabbedWindowOrder() {
        let firstWindow = AppDelegate.makeReaderWindow(for: URL(fileURLWithPath: "/tmp/first.md"))
        let secondWindow = AppDelegate.makeReaderWindow(for: URL(fileURLWithPath: "/tmp/second.md"))
        let thirdWindow = AppDelegate.makeReaderWindow(for: URL(fileURLWithPath: "/tmp/third.md"))
        defer {
            firstWindow.close()
            secondWindow.close()
            thirdWindow.close()
        }

        firstWindow.addTabbedWindow(secondWindow, ordered: .above)
        firstWindow.addTabbedWindow(thirdWindow, ordered: .above)
        let tabbedWindows = firstWindow.tabbedWindows ?? []

        XCTAssertEqual(tabbedWindows.count, 3)
        for index in tabbedWindows.indices {
            XCTAssertTrue(AppDelegate.windowTab(in: firstWindow, at: index) === tabbedWindows[index])
        }
        XCTAssertNil(AppDelegate.windowTab(in: firstWindow, at: 3))
        XCTAssertNil(AppDelegate.windowTab(in: firstWindow, at: -1))
    }
}
