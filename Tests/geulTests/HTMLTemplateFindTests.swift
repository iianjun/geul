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
        XCTAssertTrue(html.contains(#"<script src="js/geul-find.js"></script>"#))
        XCTAssertFalse(html.contains("window.geulFind = {"))
    }

    func testMarkdownBodyDefaultsToLeftAlignedFullWindowWidth() throws {
        let css = try Self.resourceString("css/globals.css")

        XCTAssertTrue(css.contains("margin: 0;"))
        XCTAssertTrue(css.contains(".markdown-root.reader-align-center,"))
        XCTAssertTrue(css.contains("max-width: 800px"))
        XCTAssertTrue(css.contains("margin: 0 auto"))
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
        let runtime = try Self.resourceString("js/geul-runtime.js")

        XCTAssertTrue(runtime.contains("findSnapshot"))
        XCTAssertTrue(runtime.contains("prepareForContentUpdate()"))
        XCTAssertTrue(runtime.contains("restoreAfterContentUpdate(findSnapshot)"))
    }

    func testUpdateContentAwaitsMermaidBeforeRestoringFindQuery() throws {
        let runtime = try Self.resourceString("js/geul-runtime.js")

        XCTAssertTrue(runtime.contains("async function updateContent(html)"))
        XCTAssertTrue(runtime.contains("await renderMermaidDiagrams(container)"))
    }

    func testUpdateContentPreservesScrollPositionAroundDOMPatch() throws {
        let runtime = try Self.resourceString("js/geul-runtime.js")
        let updateContent = try Self.sourceRange(
            in: runtime,
            from: "async function updateContent(html)",
            to: "async function setTheme(colors, hljsKey)"
        )

        XCTAssertTrue(updateContent.contains("var scrollSnapshot = captureScrollPosition();"))
        XCTAssertTrue(updateContent.contains("restoreScrollPosition(scrollSnapshot);"))
        XCTAssertLessThan(
            try XCTUnwrap(updateContent.range(of: "restoreAfterContentUpdate(findSnapshot)")?.lowerBound),
            try XCTUnwrap(updateContent.range(of: "restoreScrollPosition(scrollSnapshot);")?.lowerBound)
        )
    }

    func testThemeChangePreservesScrollPositionAroundThemePatch() throws {
        let runtime = try Self.resourceString("js/geul-runtime.js")
        let setTheme = try Self.sourceRange(
            in: runtime,
            from: "async function setTheme(colors, hljsKey)",
            to: "function setReaderAlignment(alignment)"
        )

        XCTAssertTrue(setTheme.contains("var scrollSnapshot = captureScrollPosition();"))
        XCTAssertTrue(setTheme.contains("restoreScrollPosition(scrollSnapshot);"))
        XCTAssertTrue(setTheme.contains("await renderMermaidDiagrams(content)"))
    }

    func testFindScriptExcludesSVGAndDoesNotMutateRenderedText() throws {
        let findScript = try Self.resourceString("js/geul-find.js")

        XCTAssertTrue(findScript.contains("parent.closest('svg')"))
        XCTAssertTrue(findScript.contains("createTreeWalker"))
        XCTAssertTrue(findScript.contains("buildRenderedTextIndex"))
        XCTAssertTrue(findScript.contains("countTextMatches"))
        XCTAssertTrue(findScript.contains("countMatches"))
        XCTAssertFalse(findScript.contains("createElement('mark')"))
        XCTAssertFalse(findScript.contains("splitText"))
        XCTAssertFalse(findScript.contains("replaceChild"))
        XCTAssertFalse(findScript.contains("mark.geul-find-match"))
    }

    func testFindScriptUsesDeterministicCaseFolding() throws {
        let findScript = try Self.resourceString("js/geul-find.js")

        XCTAssertTrue(findScript.contains("toLowerCase()"))
        XCTAssertTrue(findScript.contains("query.toLowerCase()"))
        XCTAssertFalse(findScript.contains("toLocaleLowerCase"))
    }

    func testFindScriptUsesOriginalTextOffsetsForCaseInsensitiveMatches() throws {
        let findScript = try Self.resourceString("js/geul-find.js")

        XCTAssertFalse(findScript.contains("haystack.indexOf"))
        XCTAssertTrue(findScript.contains("text.slice(i, i + query.length).toLowerCase()"))
    }

    func testLiveReloadAwaitsAsyncUpdateContentFromSwift() throws {
        let source = try String(contentsOf: Self.markdownWebViewSourceURL(), encoding: .utf8)

        XCTAssertTrue(source.contains("callAsyncJavaScript("))
        XCTAssertTrue(source.contains("return await window.geul.updateContent(html);"))
    }

    func testFindScriptVersionsQueriesAroundAsyncLiveReload() throws {
        let findScript = try Self.resourceString("js/geul-find.js")

        XCTAssertTrue(findScript.contains("version: 0"))
        XCTAssertTrue(findScript.contains("state.version += 1"))
        XCTAssertTrue(findScript.contains("state.version === snapshot.version"))
    }

    func testMarkdownWebViewUsesNativeWebKitFindForHighlighting() throws {
        let source = try String(contentsOf: Self.markdownWebViewSourceURL(), encoding: .utf8)

        XCTAssertTrue(source.contains("WKFindConfiguration"))
        XCTAssertTrue(source.contains("webView.find("))
        XCTAssertTrue(source.contains("clearNativeFindSelection"))
    }

    func testMarkdownWebViewPreservesJavaScriptFindResultWhenNativeFindMisses() throws {
        let source = try String(contentsOf: Self.markdownWebViewSourceURL(), encoding: .utf8)
        let runNativeFind = try Self.sourceRange(
            in: source,
            from: "private func runNativeFindIfNeeded",
            to: "private func clearNativeFindSelection"
        )

        XCTAssertTrue(runNativeFind.contains("webView.find(query, configuration: configuration)"))
        XCTAssertFalse(runNativeFind.contains("FindResult(query: query, currentIndex: -1, total: 0)"))
        XCTAssertFalse(runNativeFind.contains("emptyResult"))
    }

    func testMarkdownWebViewRestoresNativeFindWithoutChangingScroll() throws {
        let source = try String(contentsOf: Self.markdownWebViewSourceURL(), encoding: .utf8)
        let restoreNativeFind = try Self.sourceRange(
            in: source,
            from: "private func restoreNativeFindAfterContentUpdate",
            to: "private func runNativeFindIfNeeded"
        )

        XCTAssertTrue(restoreNativeFind.contains("captureScrollPositionScript"))
        XCTAssertTrue(restoreNativeFind.contains("restoreScrollPositionScript"))
    }

    func testMarkdownWebViewAppliesReaderAlignmentWithoutReloading() throws {
        let source = try String(contentsOf: Self.markdownWebViewSourceURL(), encoding: .utf8)
        let runtime = try Self.resourceString("js/geul-runtime.js")

        XCTAssertTrue(source.contains("applyReaderAlignment"))
        XCTAssertTrue(source.contains("window.geul.setReaderAlignment(alignment);"))
        XCTAssertTrue(runtime.contains("function setReaderAlignment(alignment)"))
        XCTAssertTrue(runtime.contains("content.classList.remove("))
        XCTAssertTrue(runtime.contains("reader-align-center"))
        XCTAssertTrue(runtime.contains("content.classList.add"))
    }

    private static func resourceString(_ relativePath: String) throws -> String {
        try String(
            contentsOf: repositoryRoot()
                .appendingPathComponent("geul/Resources")
                .appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private static func sourceRange(in source: String, from start: String, to end: String) throws -> String {
        let startRange = try XCTUnwrap(source.range(of: start))
        let endRange = try XCTUnwrap(source.range(of: end, range: startRange.upperBound..<source.endIndex))
        return String(source[startRange.lowerBound..<endRange.lowerBound])
    }

    private static func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func markdownWebViewSourceURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/MarkdownWebView.swift")
    }
}
