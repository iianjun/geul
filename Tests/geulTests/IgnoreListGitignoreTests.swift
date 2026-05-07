import XCTest
@testable import geul

final class IgnoreListGitignoreTests: XCTestCase {
    func testParsesSimpleGitignorePatterns() {
        let content = """
        # comment
        build/
        *.log

        node_modules
        """
        let patterns = IgnoreList.parseGitignore(content)
        XCTAssertEqual(patterns, ["build/", "*.log", "node_modules"])
    }

    func testStripsBlankAndCommentLines() {
        let content = """


        # A comment
          # Indented comment
        dist
        """
        let patterns = IgnoreList.parseGitignore(content)
        XCTAssertEqual(patterns, ["dist"])
    }

    func testMatchesDirectoryPattern() {
        XCTAssertTrue(IgnoreList.matches(name: "build", pattern: "build/"))
        XCTAssertTrue(IgnoreList.matches(name: "build", pattern: "build"))
        XCTAssertFalse(IgnoreList.matches(name: "building", pattern: "build/"))
    }

    func testMatchesGlobPattern() {
        XCTAssertTrue(IgnoreList.matches(name: "debug.log", pattern: "*.log"))
        XCTAssertFalse(IgnoreList.matches(name: "debug.txt", pattern: "*.log"))
    }

    func testAncestorGitignoreExcludesDescendantFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-ignore-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let buildDir = tempDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(
            at: buildDir, withIntermediateDirectories: true)
        try "build/\n".write(
            to: tempDir.appendingPathComponent(".gitignore"),
            atomically: true, encoding: .utf8)
        let file = buildDir.appendingPathComponent("note.md")
        try "x".write(to: file, atomically: true, encoding: .utf8)

        var cache: [String: [String]] = [:]
        XCTAssertTrue(IgnoreList.isIgnoredByAncestorGitignore(
            url: file, underRoot: tempDir, cache: &cache))
    }

    func testAncestorGitignoreAllowsUnmatchedFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-ignore-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true)
        try "build/\n".write(
            to: tempDir.appendingPathComponent(".gitignore"),
            atomically: true, encoding: .utf8)
        let file = tempDir.appendingPathComponent("note.md")
        try "x".write(to: file, atomically: true, encoding: .utf8)

        var cache: [String: [String]] = [:]
        XCTAssertFalse(IgnoreList.isIgnoredByAncestorGitignore(
            url: file, underRoot: tempDir, cache: &cache))
    }
}
