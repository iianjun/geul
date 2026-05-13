import XCTest

final class CLIWrapperResourceTests: XCTestCase {
    private var resourcesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/Resources")
    }

    func testBundledCLIWrapperUsesGlName() {
        let glWrapper = resourcesDirectory.appendingPathComponent("gl")
        let geulWrapper = resourcesDirectory.appendingPathComponent("geul")

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: glWrapper.path),
            "Expected CLI wrapper resource to exist at \(glWrapper.path)"
        )
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: geulWrapper.path),
            "Expected legacy CLI wrapper resource to be removed at \(geulWrapper.path)"
        )
    }

    func testCLIWrapperReportsGlInUserFacingErrors() throws {
        let wrapper = resourcesDirectory.appendingPathComponent("gl")
        guard FileManager.default.fileExists(atPath: wrapper.path) else {
            XCTFail("Expected CLI wrapper resource to exist before reading it at \(wrapper.path)")
            return
        }

        let content = try String(contentsOf: wrapper, encoding: .utf8)

        XCTAssertTrue(content.contains("gl: cannot locate app binary"))
        XCTAssertFalse(content.contains("geul: cannot locate app binary"))
        XCTAssertTrue(content.contains("/usr/local/bin/gl"))
        XCTAssertFalse(content.contains("/usr/local/bin/geul"))
    }
}
