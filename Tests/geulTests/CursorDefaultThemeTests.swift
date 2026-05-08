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

    func testCursorDarkPaletteProducesExpectedCSSAndDarkHighlightVariant() {
        let theme = Theme(name: "Default Dark", colors: Self.cursorDarkColors)
        let css = HTMLTemplate.themeCSS(theme)

        XCTAssertTrue(css.contains("--bg-primary: #141414;"))
        XCTAssertTrue(css.contains("--bg-secondary: #1E1E1E;"))
        XCTAssertTrue(css.contains("--accent: #81A1C1;"))
        XCTAssertTrue(css.contains("--text-primary: #E4E4E4EB;"))
        XCTAssertTrue(css.contains("--border: #E4E4E413;"))
        XCTAssertEqual(ThemeSanitizer.hljsVariantKey(for: theme), "dark")
    }

    func testBaseCSSUsesCursorMarkdownRootRules() {
        let css = HTMLTemplate.baseCSS

        XCTAssertTrue(css.contains("font-size: 14px;"))
        XCTAssertTrue(css.contains("line-height: 22px;"))
        XCTAssertTrue(css.contains(".markdown-root,"))
        XCTAssertTrue(css.contains("max-width: 800px;"))
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

    func testMermaidUsesCursorCodeBlockContainerAndThemeVariables() {
        let loadingCSS = HTMLTemplate.loadingCSS
        let mermaidScript = HTMLTemplate.mermaidInitScript

        XCTAssertTrue(loadingCSS.contains(".mermaid-container {"))
        XCTAssertTrue(loadingCSS.contains("border-radius: var(--radius-lg);"))
        XCTAssertTrue(loadingCSS.contains("border: 1px solid var(--border);"))
        XCTAssertTrue(loadingCSS.contains("background-color: var(--bg-primary);"))
        XCTAssertFalse(loadingCSS.contains("box-shadow: var(--shadow-subtle);"))
        XCTAssertTrue(mermaidScript.contains("primaryColor: colors['--bg-primary']"))
        XCTAssertTrue(mermaidScript.contains("mainBkg: colors['--bg-primary']"))
        XCTAssertTrue(mermaidScript.contains("nodeBorder: colors['--border-strong']"))
        XCTAssertTrue(mermaidScript.contains("clusterBorder: colors['--border']"))
        XCTAssertFalse(mermaidScript.contains("primaryColor: colors['--bg-secondary']"))
    }

    func testHighlightOverrideUsesCursorTokenColors() {
        let css = HTMLTemplate.cursorDarkHighlightOverrideCSS

        XCTAssertTrue(css.contains("color: #82D2CE;"))
        XCTAssertTrue(css.contains("color: #efb080;"))
        XCTAssertTrue(css.contains("color: #e394dc;"))
        XCTAssertTrue(css.contains("color: #AAA0FA;"))
        XCTAssertTrue(css.contains("color: #E4E4E45E;"))
        XCTAssertTrue(css.contains("""
        .hljs-title.function_,
        .hljs-title.class_ {
            color: #efb080;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-title.class_.inherited__ {
            color: #efb080;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-meta .hljs-string {
            color: #e394dc;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-meta .hljs-keyword {
            color: #82D2CE;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-doctag,
        .hljs-template-tag,
        .hljs-selector-pseudo {
            color: #82D2CE;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-variable.language_ {
            color: #AAA0FA;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-operator,
        .hljs-selector-attr,
        .hljs-selector-class,
        .hljs-selector-id {
            color: #AAA0FA;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-regexp {
            color: #e394dc;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-code,
        .hljs-formula,
        .hljs-subst {
            color: var(--text-primary);
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-emphasis {
            color: var(--text-primary);
            font-style: italic;
        }
        """))
        XCTAssertTrue(css.contains("""
        .hljs-strong {
            color: var(--text-primary);
            font-weight: bold;
        }
        """))
        XCTAssertFalse(css.contains("#c9d1d9"))
    }

    func testHighlightOverrideOnlyAppliesToDarkHighlightVariant() {
        XCTAssertEqual(HTMLTemplate.highlightOverrideCSS(forHLJSVariantKey: "default"), "")
        XCTAssertEqual(HTMLTemplate.highlightOverrideCSS(forHLJSVariantKey: "light"), "")
        XCTAssertEqual(
            HTMLTemplate.highlightOverrideCSS(forHLJSVariantKey: "dark"),
            HTMLTemplate.cursorDarkHighlightOverrideCSS
        )
    }

    func testComposedHTMLScopesHighlightOverrideByInitialVariantAndRuntimeMap() {
        let lightTheme = Theme(
            name: "Light",
            colors: Self.cursorDarkColors.merging(["--bg-primary": "#ffffff"]) { _, new in new }
        )
        let darkHTML = HTMLTemplate.compose(
            body: "<pre><code></code></pre>",
            title: "Dark",
            theme: Theme(name: "Default Dark", colors: Self.cursorDarkColors)
        )
        let lightHTML = HTMLTemplate.compose(
            body: "<pre><code></code></pre>",
            title: "Light",
            theme: lightTheme
        )

        XCTAssertTrue(darkHTML.contains(#"<style id="geul-hljs-override">"#))
        XCTAssertTrue(darkHTML.contains("window.__geulHljsOverrideCSS"))
        XCTAssertTrue(darkHTML.contains(".hljs-comment"))
        XCTAssertTrue(lightHTML.contains(#"<style id="geul-hljs-override"></style>"#))
        XCTAssertTrue(lightHTML.contains("window.__geulHljsOverrideCSS"))
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
}
