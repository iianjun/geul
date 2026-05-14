import XCTest
@testable import geul

final class CLIRouteTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-cli-route-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func route(_ userArgs: [String], interactive: Bool = true) -> CLIRoute {
        CLIMain.route(
            arguments: ["ge"] + userArgs,
            isInteractiveTerminal: interactive,
            currentDirectory: tempDir
        )
    }

    func testNoArgsInInteractiveTerminalRoutesToCurrentDirectoryTUI() {
        XCTAssertEqual(route([]), .tui(tempDir.standardizedFileURL))
    }

    func testSingleDirectoryArgInInteractiveTerminalRoutesToFolderTUI() throws {
        let folder = tempDir.appendingPathComponent("notes")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        XCTAssertEqual(route([folder.path]), .tui(folder.standardizedFileURL))
    }

    func testMarkdownFileArgRoutesToApp() throws {
        let file = tempDir.appendingPathComponent("note.md")
        try "# Note\n".write(to: file, atomically: true, encoding: .utf8)

        XCTAssertEqual(route([file.path]), .app)
    }

    func testDirectoryArgInNonInteractiveTerminalRoutesToApp() throws {
        let folder = tempDir.appendingPathComponent("notes")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        XCTAssertEqual(route([folder.path], interactive: false), .app)
    }

    func testMultipleArgsRouteToApp() throws {
        let first = tempDir.appendingPathComponent("first")
        let second = tempDir.appendingPathComponent("second")
        try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)

        XCTAssertEqual(route([first.path, second.path]), .app)
    }
}
