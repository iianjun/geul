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
