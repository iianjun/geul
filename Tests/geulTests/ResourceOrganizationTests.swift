import XCTest
@testable import geul

final class ResourceOrganizationTests: XCTestCase {
    private var resourcesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/Resources")
    }

    func testBundledResourcesUseTypeBasedFolders() {
        let expectedFiles = [
            "bin/ge",
            "scripts/auto-render.min.js",
            "scripts/highlight.min.js",
            "scripts/katex.min.js",
            "scripts/marked.min.js",
            "scripts/mermaid-init.js",
            "scripts/mermaid.min.js",
            "styles/github-dark.min.css",
            "styles/github.min.css",
            "styles/katex.min.css",
            "styles/loading.css",
            "themes/default-dark.json",
            "themes/default-light.json"
        ]

        for relativePath in expectedFiles {
            let url = resourcesDirectory.appendingPathComponent(relativePath)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: url.path),
                "Expected bundled resource at \(relativePath)"
            )
        }
    }

    func testMovedResourcesNoLongerLiveAtResourceRoot() {
        let movedRootFiles = [
            "auto-render.min.js",
            "ge",
            "github-dark.min.css",
            "github.min.css",
            "highlight.min.js",
            "katex.min.css",
            "katex.min.js",
            "marked.min.js",
            "mermaid.min.js"
        ]

        for fileName in movedRootFiles {
            let url = resourcesDirectory.appendingPathComponent(fileName)
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: url.path),
                "Expected \(fileName) to be moved out of the resource root"
            )
        }
    }

    func testMarkdownRendererLoadsOrganizedScriptResources() {
        let html = MarkdownRenderer.render("""
        ```swift
        let value = 1
        ```
        """)

        XCTAssertTrue(html.contains("hljs"))
        XCTAssertFalse(html.contains("Failed to render markdown"))
    }
}
