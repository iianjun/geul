import WebKit
import XCTest
@testable import geul

@MainActor
final class FindScriptWebViewTests: XCTestCase {
    func testCountMatchesAcrossSplitHighlightedTextNodes() async throws {
        let webView = try await loadFindFixture(
            """
            <pre><code><span class="hljs-keyword">let</span> a = <span class="hljs-title class_">IndexedFile</span></code></pre>
            """
        )

        let indexedFileCount = try await countMatches("IndexedFile", in: webView)
        let splitLineCount = try await countMatches("let a = IndexedFile", in: webView)

        XCTAssertEqual(indexedFileCount, 1)
        XCTAssertEqual(splitLineCount, 1)
    }

    func testCountMatchesTreatsSpecialCharactersAsPlainText() async throws {
        let webView = try await loadFindFixture(
            """
            <p>Use cmd + find for search.</p>
            <p>Read foo.bar and array[0].</p>
            <p>Compare a == b.</p>
            """
        )

        let commandCount = try await countMatches("cmd + find", in: webView)
        let dotCount = try await countMatches("foo.bar", in: webView)
        let bracketCount = try await countMatches("array[0]", in: webView)
        let equalityCount = try await countMatches("a == b", in: webView)

        XCTAssertEqual(commandCount, 1)
        XCTAssertEqual(dotCount, 1)
        XCTAssertEqual(bracketCount, 1)
        XCTAssertEqual(equalityCount, 1)
    }

    func testCountMatchesStillExcludesSVGAndBlockedTags() async throws {
        let webView = try await loadFindFixture(
            """
            <p>Visible IndexedFile</p>
            <svg><text>IndexedFile</text></svg>
            <script>var hidden = 'IndexedFile';</script>
            <style>.hidden::before { content: 'IndexedFile'; }</style>
            <textarea>IndexedFile</textarea>
            <noscript>IndexedFile</noscript>
            """
        )

        let count = try await countMatches("IndexedFile", in: webView)

        XCTAssertEqual(count, 1)
    }

    private func loadFindFixture(_ body: String) async throws -> WKWebView {
        let webView = WKWebView(frame: .zero)
        let delegate = FixtureNavigationDelegate()
        webView.navigationDelegate = delegate

        let finished = expectation(description: "fixture loaded")
        delegate.onFinish = {
            finished.fulfill()
        }
        delegate.onFail = { error in
            XCTFail("Fixture failed to load: \(error)")
            finished.fulfill()
        }

        let html = """
        <!doctype html>
        <html>
        <body>
            <article id="content">
            \(body)
            </article>
            <script>
            \(try Self.resourceString("js/geul-find.js"))
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
        await fulfillment(of: [finished], timeout: 5)
        return webView
    }

    private func countMatches(_ query: String, in webView: WKWebView) async throws -> Int {
        let literal = try Self.javascriptStringLiteral(query)
        return try await evaluateInt(
            "window.geulFind.countMatches(\(literal));",
            in: webView
        )
    }

    private func evaluateInt(_ script: String, in webView: WKWebView) async throws -> Int {
        let value = try await evaluateJavaScript(script, in: webView)

        if let intValue = value as? Int {
            return intValue
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        return try XCTUnwrap(value as? Int)
    }

    private func evaluateJavaScript(_ script: String, in webView: WKWebView) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript(script) { value, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: value)
            }
        }
    }

    private static func javascriptStringLiteral(_ value: String) throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: value,
            options: .fragmentsAllowed
        )
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    private static func resourceString(_ relativePath: String) throws -> String {
        try String(
            contentsOf: repositoryRoot()
                .appendingPathComponent("geul/Resources")
                .appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private static func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private final class FixtureNavigationDelegate: NSObject, WKNavigationDelegate {
    var onFinish: (() -> Void)?
    var onFail: ((Error) -> Void)?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onFinish?()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onFail?(error)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        onFail?(error)
    }
}
