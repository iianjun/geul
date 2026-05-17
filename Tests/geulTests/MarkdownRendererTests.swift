import XCTest
@testable import geul

final class MarkdownRendererTests: XCTestCase {
    func testCodeFenceStillRendersHighlightedPreCodeOutput() {
        let html = MarkdownRenderer.render("""
        ```swift
        let value = 1
        ```
        """)

        XCTAssertTrue(html.contains(#"<pre><code class="hljs language-swift">"#))
        XCTAssertTrue(html.contains("value"))
        XCTAssertTrue(html.contains("</code></pre>"))
    }

    func testMermaidFenceStillRendersContainerWithLoadingBars() {
        let html = MarkdownRenderer.render("""
        ```mermaid
        graph TD
            A --> B
        ```
        """)

        XCTAssertTrue(html.contains(#"<div class="mermaid-container">"#))
        XCTAssertTrue(html.contains(#"<div class="geul-loading">"#))
        XCTAssertTrue(html.contains(#"<pre class="mermaid" style="display:none;">"#))
        XCTAssertTrue(html.contains("graph TD"))
        XCTAssertTrue(html.contains("A --&gt; B"))
    }

    func testRawHTMLIsEscaped() {
        let html = MarkdownRenderer.render("<script>alert('x')</script>")

        XCTAssertTrue(
            html.contains("&lt;script&gt;alert('x')&lt;/script&gt;")
                || html.contains("&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;")
        )
        XCTAssertFalse(html.contains("<script"))
        XCTAssertFalse(html.contains("</script>"))
    }

    func testEmptyMarkdownDoesNotUseFailureFallback() {
        let html = MarkdownRenderer.render("")

        XCTAssertNotEqual(html, "<p>Failed to render markdown</p>")
    }

    func testMarkdownRendererSourceLoadsRendererResourceAndKeepsFallback() throws {
        let source = try String(
            contentsOf: Self.repositoryRoot().appendingPathComponent("geul/MarkdownRenderer.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(#""js/markdown-renderer.js""#))
        XCTAssertTrue(source.contains(#""<p>Failed to render markdown</p>""#))
    }

    private static func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
