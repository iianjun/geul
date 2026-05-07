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

    func testCursorDarkPaletteProducesExpectedCSSAndDarkHighlightVariant() {
        let theme = Theme(name: "Default Dark", colors: Self.cursorDarkColors)
        let css = HTMLTemplate.themeCSS(theme)

        XCTAssertTrue(css.contains("--bg-primary: #181818;"))
        XCTAssertTrue(css.contains("--accent: #81A1C1;"))
        XCTAssertTrue(css.contains("--text-primary: #E4E4E4EB;"))
        XCTAssertEqual(ThemeSanitizer.hljsVariantKey(for: theme), "dark")
    }

    func testBaseCSSUsesCursorMarkdownPreviewRules() {
        let css = HTMLTemplate.baseCSS

        XCTAssertTrue(css.contains("font-size: 14px;"))
        XCTAssertTrue(css.contains("line-height: 22px;"))
        XCTAssertTrue(css.contains("padding: 0 26px 96px;"))
        XCTAssertTrue(css.contains("border-left: 5px solid var(--text-tertiary);"))
        XCTAssertTrue(css.contains("table > tbody > tr + tr > td"))
        XCTAssertTrue(css.contains("padding: 5px 10px;"))
        XCTAssertFalse(css.contains("border-left: 3px solid var(--bg-code-border);"))
        XCTAssertFalse(css.contains("letter-spacing: -0.015em;"))
    }

    private static let cursorDarkColors: [String: String] = [
        "--bg-primary": "#181818",
        "--bg-secondary": "#2B2B2B",
        "--bg-code": "#2B2B2B",
        "--bg-code-border": "#313131",
        "--text-primary": "#E4E4E4EB",
        "--text-secondary": "#E4E4E48D",
        "--text-tertiary": "#E4E4E45E",
        "--accent": "#81A1C1",
        "--accent-soft": "rgba(129, 161, 193, 0.14)",
        "--border": "rgba(255, 255, 255, 0.18)",
        "--border-strong": "rgba(255, 255, 255, 0.69)",
        "--shadow-subtle": "none"
    ]
}
