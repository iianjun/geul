import XCTest

final class CLIWrapperResourceTests: XCTestCase {
    private var resourcesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/Resources")
    }

    func testBundledCLIWrapperUsesGeName() {
        let geWrapper = resourcesDirectory.appendingPathComponent("ge")
        let geulWrapper = resourcesDirectory.appendingPathComponent("geul")
        let glWrapper = resourcesDirectory.appendingPathComponent("gl")

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: geWrapper.path),
            "Expected primary CLI wrapper resource to exist at \(geWrapper.path)"
        )
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: geulWrapper.path),
            "Expected geul command to be installed as a symlink, not duplicated as \(geulWrapper.path)"
        )
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: glWrapper.path),
            "Expected conflicting gl wrapper resource to be removed at \(glWrapper.path)"
        )
    }

    func testCLIWrapperReportsInvokedCommandNameAndSupportedInstallPaths() throws {
        let wrapper = resourcesDirectory.appendingPathComponent("ge")
        guard FileManager.default.fileExists(atPath: wrapper.path) else {
            XCTFail("Expected CLI wrapper resource to exist before reading it at \(wrapper.path)")
            return
        }

        let content = try String(contentsOf: wrapper, encoding: .utf8)

        XCTAssertTrue(content.contains("# ge - CLI entry point."))
        XCTAssertTrue(content.contains("command_name=\"$(basename \"$0\")\""))
        XCTAssertTrue(content.contains("echo \"$command_name: cannot locate app binary"))
        XCTAssertTrue(content.contains("/usr/local/bin/ge or /usr/local/bin/geul"))
        XCTAssertFalse(content.contains("/usr/local/bin/gl"))
        XCTAssertFalse(content.contains("gl: cannot locate app binary"))
    }
}
