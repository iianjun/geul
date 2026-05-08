import XCTest
@testable import geul

final class HTMLTemplateFindTests: XCTestCase {
    private let theme = Theme(
        name: "Find Test",
        colors: [
            "--accent": "#0a84ff",
            "--accent-soft": "#d8ebff",
            "--bg-code": "#f6f8fa",
            "--bg-code-border": "#d0d7de",
            "--bg-primary": "#ffffff",
            "--bg-secondary": "#f6f8fa",
            "--border": "#d0d7de",
            "--border-strong": "#8c959f",
            "--shadow-subtle": "none",
            "--text-primary": "#24292f",
            "--text-secondary": "#57606a",
            "--text-tertiary": "#6e7781"
        ]
    )

    func testComposeInjectsFindScriptWithoutDocumentFindStyle() {
        let html = HTMLTemplate.compose(
            body: "<p>Alpha beta alpha</p>",
            title: "find.md",
            theme: theme
        )

        XCTAssertFalse(html.contains("<style id=\"geul-find-style\">"))
        XCTAssertFalse(html.contains("mark.geul-find-match"))
        XCTAssertTrue(html.contains("window.geulFind = {"))
    }

    func testUpdateContentPreservesActiveFindQuery() {
        XCTAssertTrue(HTMLTemplate.mermaidInitScript.contains("findSnapshot"))
        XCTAssertTrue(HTMLTemplate.mermaidInitScript.contains("prepareForContentUpdate()"))
        XCTAssertTrue(HTMLTemplate.mermaidInitScript.contains("restoreAfterContentUpdate(findSnapshot)"))
    }

    func testUpdateContentAwaitsMermaidBeforeRestoringFindQuery() {
        XCTAssertTrue(HTMLTemplate.mermaidInitScript.contains("async function updateContent(html)"))
        XCTAssertTrue(HTMLTemplate.mermaidInitScript.contains("await renderMermaidDiagrams(container)"))
    }

    func testFindScriptExcludesSVGAndDoesNotMutateRenderedText() {
        XCTAssertTrue(HTMLTemplate.findScript.contains("parent.closest('svg')"))
        XCTAssertTrue(HTMLTemplate.findScript.contains("createTreeWalker"))
        XCTAssertTrue(HTMLTemplate.findScript.contains("countMatches"))
        XCTAssertFalse(HTMLTemplate.findScript.contains("createElement('mark')"))
        XCTAssertFalse(HTMLTemplate.findScript.contains("splitText"))
        XCTAssertFalse(HTMLTemplate.findScript.contains("replaceChild"))
        XCTAssertFalse(HTMLTemplate.findScript.contains("mark.geul-find-match"))
    }

    func testFindScriptUsesDeterministicCaseFolding() {
        XCTAssertTrue(HTMLTemplate.findScript.contains("toLowerCase()"))
        XCTAssertTrue(HTMLTemplate.findScript.contains("query.toLowerCase()"))
        XCTAssertFalse(HTMLTemplate.findScript.contains("toLocaleLowerCase"))
    }

    func testFindScriptUsesOriginalTextOffsetsForCaseInsensitiveMatches() {
        XCTAssertFalse(HTMLTemplate.findScript.contains("haystack.indexOf"))
        XCTAssertTrue(HTMLTemplate.findScript.contains("text.slice(i, i + query.length).toLowerCase()"))
    }

    func testLiveReloadAwaitsAsyncUpdateContentFromSwift() throws {
        let source = try String(contentsOf: Self.markdownWebViewSourceURL(), encoding: .utf8)

        XCTAssertTrue(source.contains("callAsyncJavaScript("))
        XCTAssertTrue(source.contains("return await updateContent(html);"))
    }

    func testFindScriptVersionsQueriesAroundAsyncLiveReload() {
        XCTAssertTrue(HTMLTemplate.findScript.contains("version: 0"))
        XCTAssertTrue(HTMLTemplate.findScript.contains("state.version += 1"))
        XCTAssertTrue(HTMLTemplate.findScript.contains("state.version === snapshot.version"))
    }

    func testMarkdownWebViewUsesNativeWebKitFindForHighlighting() throws {
        let source = try String(contentsOf: Self.markdownWebViewSourceURL(), encoding: .utf8)

        XCTAssertTrue(source.contains("WKFindConfiguration"))
        XCTAssertTrue(source.contains("webView.find("))
        XCTAssertTrue(source.contains("clearNativeFindSelection"))
    }

    private static func markdownWebViewSourceURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/MarkdownWebView.swift")
    }
}
