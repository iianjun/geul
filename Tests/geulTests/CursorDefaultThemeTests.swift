import XCTest
@testable import geul

final class CursorDefaultThemeTests: XCTestCase {
    func testBundledDefaultDarkMatchesCursorDarkPalette() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/Resources/themes/default-dark.json")
        let data = try Data(contentsOf: url)
        let theme = try JSONDecoder().decode(Theme.self, from: data)

        XCTAssertEqual(theme.name, "Default Dark")
        XCTAssertEqual(theme.colors, Self.cursorDarkColors)
    }

    func testBundledDefaultLightMatchesCursorLightPalette() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/Resources/themes/default-light.json")
        let data = try Data(contentsOf: url)
        let theme = try JSONDecoder().decode(Theme.self, from: data)

        XCTAssertEqual(theme.name, "Default Light")
        XCTAssertEqual(theme.colors, Self.cursorLightColors)
    }

    func testCursorDarkPaletteProducesExpectedConfigAndDarkHighlightVariant() throws {
        let theme = Theme(name: "Default Dark", colors: Self.cursorDarkColors)
        let html = HTMLTemplate.compose(body: "<p>Theme</p>", title: "Theme", theme: theme)

        XCTAssertTrue(html.contains(##""--bg-primary":"#141414""##))
        XCTAssertTrue(html.contains(##""--bg-secondary":"#1E1E1E""##))
        XCTAssertTrue(html.contains(##""--accent":"#81A1C1""##))
        XCTAssertTrue(html.contains(##""--text-primary":"#E4E4E4EB""##))
        XCTAssertTrue(html.contains(##""--border":"#E4E4E413""##))
        XCTAssertTrue(html.contains(#""hljsTheme":"dark""#))
        XCTAssertEqual(ThemeSanitizer.hljsVariantKey(for: theme), "dark")
    }

    func testBaseCSSUsesCursorMarkdownRootRules() throws {
        let css = try Self.resourceString("css/globals.css")

        XCTAssertTrue(css.contains("font-size: 14px;"))
        XCTAssertTrue(css.contains("line-height: 22px;"))
        XCTAssertTrue(css.contains(".markdown-root,"))
        XCTAssertTrue(css.contains(".markdown-root.reader-align-center,"))
        XCTAssertTrue(css.contains("max-width: 800px;"))
        XCTAssertTrue(css.contains("margin: 0 auto;"))
        XCTAssertTrue(css.contains("padding: 32px 24px 64px;"))
        XCTAssertTrue(css.contains("font-size: 1.6em;"))
        XCTAssertTrue(css.contains("padding: 1.5px 4px;"))
        XCTAssertTrue(css.contains("border-radius: 5px;"))
        XCTAssertTrue(css.contains("border-left: 3px solid var(--border-strong);"))
        XCTAssertTrue(css.contains("border: 1px solid var(--border);"))
        XCTAssertTrue(css.contains("border-radius: var(--radius-md);"))
        XCTAssertTrue(css.contains("border-right: 1px solid var(--border);"))
        XCTAssertTrue(css.contains("padding: 5px 9px;"))
        XCTAssertFalse(css.contains("table > tbody > tr + tr > td"))
        XCTAssertFalse(css.contains("padding-bottom: 0.3em;"))
        XCTAssertFalse(css.contains("border-left: 5px solid"))
        XCTAssertFalse(css.contains("border-left: 3px solid var(--bg-code-border);"))
        XCTAssertFalse(css.contains("letter-spacing: -0.015em;"))
    }

    func testMermaidUsesCursorCodeBlockContainerAndThemeVariables() throws {
        let css = try Self.resourceString("css/globals.css")
        let runtime = try Self.resourceString("js/geul-runtime.js")

        XCTAssertTrue(css.contains(".mermaid-container {"))
        XCTAssertTrue(css.contains("border-radius: var(--radius-lg);"))
        XCTAssertTrue(css.contains("border: 1px solid var(--border);"))
        XCTAssertTrue(css.contains("background-color: var(--bg-primary);"))
        XCTAssertFalse(css.contains("box-shadow: var(--shadow-subtle);"))
        XCTAssertTrue(runtime.contains("primaryColor: colors['--bg-primary']"))
        XCTAssertTrue(runtime.contains("mainBkg: colors['--bg-primary']"))
        XCTAssertTrue(runtime.contains("nodeBorder: colors['--border-strong']"))
        XCTAssertTrue(runtime.contains("clusterBorder: colors['--border']"))
        XCTAssertFalse(runtime.contains("primaryColor: colors['--bg-secondary']"))
    }

    func testHighlightOverrideUsesCursorTokenColors() throws {
        let css = try Self.resourceString("css/globals.css")

        Self.assertScopedHighlightRule(css, selector: ".hljs-title.function_", color: "#efb080")
        Self.assertScopedHighlightRule(css, selector: ".hljs-title.class_", color: "#efb080")
        Self.assertScopedHighlightRule(css, selector: ".hljs-title.class_.inherited__", color: "#efb080")
        Self.assertScopedHighlightRule(css, selector: ".hljs-meta .hljs-string", color: "#e394dc")
        Self.assertScopedHighlightRule(css, selector: ".hljs-meta .hljs-keyword", color: "#82D2CE")
        Self.assertScopedHighlightRule(css, selector: ".hljs-doctag", color: "#82D2CE")
        Self.assertScopedHighlightRule(css, selector: ".hljs-template-tag", color: "#82D2CE")
        Self.assertScopedHighlightRule(css, selector: ".hljs-selector-pseudo", color: "#82D2CE")
        Self.assertScopedHighlightRule(css, selector: ".hljs-variable.language_", color: "#AAA0FA")
        Self.assertScopedHighlightRule(css, selector: ".hljs-operator", color: "#AAA0FA")
        Self.assertScopedHighlightRule(css, selector: ".hljs-selector-attr", color: "#AAA0FA")
        Self.assertScopedHighlightRule(css, selector: ".hljs-selector-class", color: "#AAA0FA")
        Self.assertScopedHighlightRule(css, selector: ".hljs-selector-id", color: "#AAA0FA")
        Self.assertScopedHighlightRule(css, selector: ".hljs-regexp", color: "#e394dc")
        Self.assertScopedHighlightRule(css, selector: ".hljs-code", color: "var(--text-primary)")
        Self.assertScopedHighlightRule(css, selector: ".hljs-formula", color: "var(--text-primary)")
        Self.assertScopedHighlightRule(css, selector: ".hljs-subst", color: "var(--text-primary)")
        Self.assertScopedHighlightRule(css, selector: ".hljs-emphasis", color: "var(--text-primary)")
        Self.assertScopedHighlightRule(css, selector: ".hljs-emphasis", property: "font-style", value: "italic")
        Self.assertScopedHighlightRule(css, selector: ".hljs-strong", color: "var(--text-primary)")
        Self.assertScopedHighlightRule(css, selector: ".hljs-strong", property: "font-weight", value: "bold")
        XCTAssertFalse(css.contains("#c9d1d9"))
    }

    func testHighlightOverrideOnlyAppliesToDarkHighlightVariant() throws {
        let css = try Self.resourceString("css/globals.css")
        let lightHTML = HTMLTemplate.compose(
            body: "<pre><code></code></pre>",
            title: "Light",
            theme: Theme(
                name: "Light",
                colors: Self.cursorDarkColors.merging(["--bg-primary": "#ffffff"]) { _, new in new }
            )
        )
        let darkHTML = HTMLTemplate.compose(
            body: "<pre><code></code></pre>",
            title: "Dark",
            theme: Theme(name: "Default Dark", colors: Self.cursorDarkColors)
        )

        XCTAssertTrue(css.contains(#"html[data-hljs-theme="dark"] .hljs-comment"#))
        XCTAssertFalse(css.contains(#"html[data-hljs-theme="default"] .hljs-comment"#))
        XCTAssertTrue(lightHTML.contains(#"<html lang="en" data-hljs-theme="default">"#))
        XCTAssertTrue(lightHTML.contains(#"id="geul-hljs-light">"#))
        XCTAssertTrue(lightHTML.contains(#"id="geul-hljs-dark" disabled>"#))
        XCTAssertTrue(darkHTML.contains(#"<html lang="en" data-hljs-theme="dark">"#))
        XCTAssertTrue(darkHTML.contains(#"id="geul-hljs-light" disabled>"#))
        XCTAssertTrue(darkHTML.contains(#"id="geul-hljs-dark">"#))
    }

    func testHighlightedCodeBlockPaddingResetAppliesInsideMarkdownContainers() throws {
        let css = try Self.resourceString("css/globals.css")

        Self.assertHighlightCodeBlockRule(css, selector: ".markdown-root pre code.hljs", property: "padding", value: "0")
        Self.assertHighlightCodeBlockRule(css, selector: ".markdown-body pre code.hljs", property: "padding", value: "0")
        XCTAssertFalse(css.contains(#"html[data-hljs-theme="default"] pre code.hljs"#))
        XCTAssertFalse(css.contains(#"html[data-hljs-theme="dark"] pre code.hljs"#))
    }

    @MainActor
    func testHardcodedDefaultDarkFallbackMatchesCursorDarkPalette() {
        XCTAssertEqual(ThemeStore.hardcodedDarkColors, Self.cursorDarkColors)
    }

    @MainActor
    func testHardcodedDefaultLightFallbackMatchesCursorLightPalette() {
        XCTAssertEqual(ThemeStore.hardcodedLightColors, Self.cursorLightColors)
    }

    private static let cursorDarkColors: [String: String] = [
        "--bg-primary": "#141414",
        "--bg-secondary": "#1E1E1E",
        "--bg-code": "#1E1E1E",
        "--bg-code-border": "#E4E4E413",
        "--text-primary": "#E4E4E4EB",
        "--text-secondary": "#E4E4E48D",
        "--text-tertiary": "#E4E4E45E",
        "--accent": "#81A1C1",
        "--accent-soft": "rgba(129, 161, 193, 0.14)",
        "--border": "#E4E4E413",
        "--border-strong": "#E4E4E426",
        "--shadow-subtle": "none"
    ]

    private static let cursorLightColors: [String: String] = [
        "--bg-primary": "#FCFCFC",
        "--bg-secondary": "#F3F3F3",
        "--bg-code": "#F3F3F3",
        "--bg-code-border": "#14141413",
        "--text-primary": "#141414EB",
        "--text-secondary": "#1414148D",
        "--text-tertiary": "#1414145E",
        "--accent": "#3C7CAB",
        "--accent-soft": "rgba(60, 124, 171, 0.12)",
        "--border": "#14141413",
        "--border-strong": "#14141426",
        "--shadow-subtle": "none"
    ]

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

    private static func assertScopedHighlightRule(
        _ css: String,
        selector: String,
        color: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertScopedHighlightRule(
            css,
            selector: selector,
            property: "color",
            value: color,
            file: file,
            line: line
        )
    }

    private static func assertHighlightCodeBlockRule(
        _ css: String,
        selector: String,
        property: String,
        value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let pattern = NSRegularExpression.escapedPattern(for: selector)
            + #"[^{}]*\{[^}]*"#
            + NSRegularExpression.escapedPattern(for: property)
            + #"\s*:\s*"#
            + NSRegularExpression.escapedPattern(for: value)
            + #"\s*;"#
            + #"[^}]*\}"#
        XCTAssertNotNil(
            css.range(of: pattern, options: [.regularExpression]),
            "Missing highlight code block rule for \(selector) with \(property): \(value)",
            file: file,
            line: line
        )
    }

    private static func assertScopedHighlightRule(
        _ css: String,
        selector: String,
        property: String,
        value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let scopedSelector = #"html[data-hljs-theme="dark"] \#(selector)"#
        let pattern = NSRegularExpression.escapedPattern(for: scopedSelector)
            + #"[^{]*\{[^}]*"#
            + NSRegularExpression.escapedPattern(for: property)
            + #"\s*:\s*"#
            + NSRegularExpression.escapedPattern(for: value)
            + #"\s*;"#
            + #"[^}]*\}"#
        XCTAssertNotNil(
            css.range(of: pattern, options: [.regularExpression]),
            "Missing scoped highlight rule for \(selector) with \(property): \(value)",
            file: file,
            line: line
        )
    }
}
