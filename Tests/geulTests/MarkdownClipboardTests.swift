import AppKit
import XCTest
@testable import geul

final class MarkdownClipboardTests: XCTestCase {
    private var pasteboard: NSPasteboard?

    override func setUp() {
        super.setUp()
        pasteboard = NSPasteboard.withUniqueName()
    }

    override func tearDown() {
        pasteboard?.clearContents()
        pasteboard = nil
        super.tearDown()
    }

    func testCopyWritesOriginalMarkdownExactly() throws {
        let pasteboard = try XCTUnwrap(pasteboard)
        let markdown = """
        ---
        title: Copy Test
        ---

        # Heading

        ```swift
        print("hello")
        ```

        <!-- source comment -->

        """

        XCTAssertTrue(MarkdownClipboard.copy(markdown, pasteboard: pasteboard))
        XCTAssertEqual(pasteboard.string(forType: .string), markdown)
    }

    func testCopyPreservesLoadedEmptyMarkdown() throws {
        let pasteboard = try XCTUnwrap(pasteboard)

        XCTAssertTrue(MarkdownClipboard.copy("", pasteboard: pasteboard))
        XCTAssertEqual(pasteboard.string(forType: .string), "")
    }
}
