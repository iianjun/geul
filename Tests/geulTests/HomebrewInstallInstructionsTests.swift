import XCTest

final class HomebrewInstallInstructionsTests: XCTestCase {
    private var readmeURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("README.md")
    }

    func testHomebrewInstructionsDocumentTapTrustAndCaskInstall() throws {
        let content = try String(contentsOf: readmeURL, encoding: .utf8)

        XCTAssertTrue(content.contains("brew tap iianjun/geul"))
        XCTAssertTrue(content.contains("brew trust iianjun/geul"))
        XCTAssertTrue(content.contains("brew install --cask geul"))
        XCTAssertTrue(content.contains("Refusing to load cask"))
        XCTAssertTrue(content.contains("untrusted tap"))
    }
}
