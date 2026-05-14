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

    func testMarkdownBodyDefaultsToLeftAlignedFullWindowWidth() {
        XCTAssertTrue(HTMLTemplate.baseCSS.contains("margin: 0;"))
        XCTAssertTrue(HTMLTemplate.baseCSS.contains(".markdown-root.reader-align-center,"))
        XCTAssertTrue(HTMLTemplate.baseCSS.contains("max-width: 800px"))
        XCTAssertTrue(HTMLTemplate.baseCSS.contains("margin: 0 auto"))
    }

    func testComposeAppliesReaderAlignmentClass() {
        let html = HTMLTemplate.compose(
            body: "<p>Aligned</p>",
            title: "aligned.md",
            theme: theme,
            readerAlignment: .right
        )

        XCTAssertTrue(html.contains("reader-align-right"))
    }

    func testUpdateContentPreservesActiveFindQuery() throws {
        let mermaidScript = try Self.resourceText(HTMLTemplate.mermaidInitScriptPath)

        XCTAssertTrue(mermaidScript.contains("findSnapshot"))
        XCTAssertTrue(mermaidScript.contains("prepareForContentUpdate()"))
        XCTAssertTrue(mermaidScript.contains("restoreAfterContentUpdate(findSnapshot)"))
    }

    func testUpdateContentAwaitsMermaidBeforeRestoringFindQuery() throws {
        let mermaidScript = try Self.resourceText(HTMLTemplate.mermaidInitScriptPath)

        XCTAssertTrue(mermaidScript.contains("async function updateContent(html)"))
        XCTAssertTrue(mermaidScript.contains("await renderMermaidDiagrams(container)"))
    }

    func testMermaidZoomOverlayClosesBeforeContentAndThemeRerender() throws {
        let mermaidScript = try Self.resourceText(HTMLTemplate.mermaidInitScriptPath)

        let updateStart = try XCTUnwrap(mermaidScript.range(of: "async function updateContent(html)"))
        let contentReplace = try XCTUnwrap(mermaidScript.range(
            of: "container.innerHTML = html;",
            range: updateStart.upperBound..<mermaidScript.endIndex
        ))
        let updateClose = try XCTUnwrap(mermaidScript.range(
            of: "closeMermaidZoomOverlay();",
            range: updateStart.upperBound..<contentReplace.lowerBound
        ))
        XCTAssertLessThan(updateClose.lowerBound, contentReplace.lowerBound)

        let themeStart = try XCTUnwrap(mermaidScript.range(of: "function setTheme(colors, hljsKey)"))
        let themeRerender = try XCTUnwrap(mermaidScript.range(
            of: "var containers = content.querySelectorAll('.mermaid-container');",
            range: themeStart.upperBound..<mermaidScript.endIndex
        ))
        let themeClose = try XCTUnwrap(mermaidScript.range(
            of: "closeMermaidZoomOverlay();",
            range: themeStart.upperBound..<themeRerender.lowerBound
        ))
        XCTAssertLessThan(themeClose.lowerBound, themeRerender.lowerBound)
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

    func testMarkdownWebViewAppliesReaderAlignmentWithoutReloading() throws {
        let source = try String(contentsOf: Self.markdownWebViewSourceURL(), encoding: .utf8)

        XCTAssertTrue(source.contains("applyReaderAlignment"))
        XCTAssertTrue(source.contains("content.classList.remove("))
        XCTAssertTrue(source.contains("reader-align-center"))
        XCTAssertTrue(source.contains("content.classList.add"))
    }

    private static func markdownWebViewSourceURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/MarkdownWebView.swift")
    }

    private static func resourceText(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul")
            .appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }
}
