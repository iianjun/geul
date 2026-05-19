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

        XCTAssertTrue(content.contains("INSTALL_APP=\"/Applications/geul.app\""))
        XCTAssertTrue(content.contains("WRAPPER=\"$$INSTALL_APP/Contents/Resources/Resources/ge\""))
        XCTAssertTrue(content.contains("PRIMARY=\"/usr/local/bin/ge\""))
        XCTAssertTrue(content.contains("FALLBACK=\"/usr/local/bin/geul\""))
        XCTAssertTrue(content.contains("LEGACY=\"/usr/local/bin/gl\""))
        XCTAssertTrue(content.contains("ln -sf \"$$WRAPPER\" \"$$PRIMARY\""))
        XCTAssertTrue(content.contains("ln -sf \"$$WRAPPER\" \"$$FALLBACK\""))
        XCTAssertTrue(content.contains("Installed: /usr/local/bin/ge and /usr/local/bin/geul"))
    }

    func testInstallRecipeCopiesAppBundleToApplications() throws {
        let content = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertTrue(content.contains("BUILT_APP=\"$$BUILT/geul.app\""))
        XCTAssertTrue(content.contains("/usr/bin/ditto \"$$BUILT_APP\" \"$$INSTALL_APP\""))
        XCTAssertTrue(content.contains("/usr/bin/touch \"$$INSTALL_APP\""))
        XCTAssertTrue(content.contains("CFBundleIdentifier"))
        XCTAssertTrue(content.contains("com.geul.app"))
        XCTAssertTrue(content.contains("LaunchServices -> $$INSTALL_APP"))
    }

    func testInstallRecipeNoLongerInstallsGl() throws {
        let content = try String(contentsOf: makefileURL, encoding: .utf8)

        XCTAssertFalse(content.contains("NEW=\"/usr/local/bin/gl\""))
        XCTAssertFalse(content.contains("Installed: /usr/local/bin/gl"))
        XCTAssertFalse(content.contains("ln -sf \"$$WRAPPER\" \"$$NEW\""))
    }
}
