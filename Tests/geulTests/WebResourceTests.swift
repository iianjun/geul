import Foundation
import XCTest
@testable import geul

final class WebResourceTests: XCTestCase {
    func testAppOwnedWebResourcesExistInRepository() throws {
        for path in Self.appOwnedResourcePaths {
            let url = Self.repositoryRoot()
                .appendingPathComponent("geul/Resources")
                .appendingPathComponent(path)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: url.path),
                "Missing resource at \(path)"
            )
        }
    }

    func testAppResourceResolvesAppOwnedWebResources() {
        for path in Self.appOwnedResourcePaths {
            XCTAssertNotNil(AppResource.url(path), "AppResource did not resolve \(path)")
        }
    }

    func testWebBaseURLPointsAtDirectoryContainingWebAssets() throws {
        let baseURL = try XCTUnwrap(AppResource.webBaseURL)

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: baseURL.appendingPathComponent("css/globals.css").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: baseURL.appendingPathComponent("js/geul-runtime.js").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: baseURL.appendingPathComponent("github.min.css").path
            )
        )
    }

    func testTemplateReferencesExternalResourcesAndConfigJSON() throws {
        let html = HTMLTemplate.compose(
            body: "<p>Hello</p>",
            title: "resource.md",
            theme: Self.darkTheme,
            readerAlignment: .right
        )

        XCTAssertTrue(html.contains(#"<html lang="en" data-hljs-theme="dark">"#))
        XCTAssertTrue(html.contains(#"<link rel="stylesheet" href="css/globals.css">"#))
        XCTAssertTrue(html.contains(#"<link rel="stylesheet" href="github.min.css" id="geul-hljs-light" disabled>"#))
        XCTAssertTrue(html.contains(#"<link rel="stylesheet" href="github-dark.min.css" id="geul-hljs-dark">"#))
        XCTAssertTrue(html.contains(#"<link rel="stylesheet" href="katex.min.css">"#))
        XCTAssertTrue(html.contains(#"<script id="geul-config" type="application/json">"#))
        XCTAssertTrue(html.contains(#"<script src="katex.min.js"></script>"#))
        XCTAssertTrue(html.contains(#"<script src="auto-render.min.js"></script>"#))
        XCTAssertTrue(html.contains(#"<script src="mermaid.min.js"></script>"#))
        XCTAssertTrue(html.contains(#"<script src="js/geul-find.js"></script>"#))
        XCTAssertTrue(html.contains(#"<script src="js/geul-runtime.js"></script>"#))
        XCTAssertTrue(html.contains(#"class="markdown-root markdown-body reader-align-right""#))

        let config = try Self.configJSON(from: html)
        XCTAssertEqual(config["hljsTheme"] as? String, "dark")
        XCTAssertEqual(config["readerAlignment"] as? String, "right")
        let colors = try XCTUnwrap(config["colors"] as? [String: String])
        XCTAssertEqual(colors["--bg-primary"], "#141414")
        XCTAssertEqual(colors["--accent"], "#81A1C1")
    }

    func testTemplateDoesNotInlineAppOwnedCSSOrJSImplementations() {
        let html = HTMLTemplate.compose(
            body: "<p>Hello</p>",
            title: "resource.md",
            theme: Self.darkTheme
        )

        XCTAssertFalse(html.contains("<style id=\"geul-theme\">"))
        XCTAssertFalse(html.contains("<style id=\"geul-hljs\">"))
        XCTAssertFalse(html.contains("<style id=\"geul-hljs-override\">"))
        XCTAssertFalse(html.contains("window.__geulCurrentColors"))
        XCTAssertFalse(html.contains("window.__geulHljsCSS"))
        XCTAssertFalse(html.contains("window.geulFind = {"))
        XCTAssertFalse(html.contains("function buildMermaidThemeVariables"))
        XCTAssertFalse(html.contains(".markdown-root,"))
        XCTAssertFalse(html.contains(".geul-loading"))
    }

    private static let appOwnedResourcePaths = [
        "css/globals.css",
        "js/geul-find.js",
        "js/geul-runtime.js",
        "js/markdown-renderer.js"
    ]

    private static let darkTheme = Theme(
        name: "Default Dark",
        colors: [
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
    )

    private static func configJSON(from html: String) throws -> [String: Any] {
        let regex = try NSRegularExpression(
            pattern: #"<script id="geul-config" type="application/json">\s*(.*?)\s*</script>"#,
            options: [.dotMatchesLineSeparators]
        )
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let match = try XCTUnwrap(regex.firstMatch(in: html, range: range))
        let configRange = try XCTUnwrap(Range(match.range(at: 1), in: html))
        let data = Data(html[configRange].utf8)
        return try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
    }

    private static func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
