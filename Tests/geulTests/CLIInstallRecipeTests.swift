import XCTest

final class CLIInstallRecipeTests: XCTestCase {
    private var makefileURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Makefile")
    }

    func testInstallRecipeLinksGeAndGeulCommands() throws {
        let content = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(content.contains("WRAPPER=\"$$APP/Contents/Resources/Resources/ge\""))
        XCTAssertTrue(content.contains("PRIMARY=\"/usr/local/bin/ge\""))
        XCTAssertTrue(content.contains("FALLBACK=\"/usr/local/bin/geul\""))
        XCTAssertTrue(content.contains("LEGACY=\"/usr/local/bin/gl\""))
        XCTAssertTrue(content.contains("ln -sf \"$$WRAPPER\" \"$$PRIMARY\""))
        XCTAssertTrue(content.contains("ln -sf \"$$WRAPPER\" \"$$FALLBACK\""))
        XCTAssertTrue(content.contains("Installed: /usr/local/bin/ge and /usr/local/bin/geul"))
    }

    func testInstallRecipeNoLongerInstallsGl() throws {
        let content = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertFalse(content.contains("NEW=\"/usr/local/bin/gl\""))
        XCTAssertFalse(content.contains("Installed: /usr/local/bin/gl"))
        XCTAssertFalse(content.contains("ln -sf \"$$WRAPPER\" \"$$NEW\""))
    }
}
