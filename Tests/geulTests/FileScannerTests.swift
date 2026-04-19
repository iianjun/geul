import XCTest
@testable import geul

final class FileScannerTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-scanner-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func write(_ content: String, to path: String) throws {
        let url = tempDir.appendingPathComponent(path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func testFlatDirectory() throws {
        try write("# a", to: "a.md")
        try write("# b", to: "b.md")
        try write("not markdown", to: "c.txt")

        let entries = FileScanner.scan(tempDir)

        XCTAssertEqual(entries.map(\.relativePath).sorted(), ["a.md", "b.md"])
    }

    func testNestedDirectories() throws {
        try write("#", to: "README.md")
        try write("#", to: "docs/PRD.md")
        try write("#", to: "docs/pm/PROGRESS.md")

        let entries = FileScanner.scan(tempDir)

        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(entries.contains { $0.relativePath == "README.md" })
        XCTAssertTrue(entries.contains { $0.relativePath == "docs/PRD.md" })
        XCTAssertTrue(entries.contains { $0.relativePath == "docs/pm/PROGRESS.md" })
    }

    func testIgnoreListExcludesDirectories() throws {
        try write("#", to: "README.md")
        try write("#", to: ".git/HEAD.md")
        try write("#", to: "node_modules/pkg/README.md")
        try write("#", to: ".build/log.md")

        let entries = FileScanner.scan(tempDir)

        XCTAssertEqual(entries.map(\.relativePath), ["README.md"])
    }

    func testSortByDepthThenAlpha() throws {
        try write("#", to: "b.md")
        try write("#", to: "a.md")
        try write("#", to: "zzz/a.md")
        try write("#", to: "aaa/b.md")

        let entries = FileScanner.scan(tempDir)

        XCTAssertEqual(entries.map(\.relativePath), [
            "a.md",
            "b.md",
            "aaa/b.md",
            "zzz/a.md",
        ])
    }

    func testSkipsNonMarkdown() throws {
        try write("#", to: "a.md")
        try write("x", to: "a.txt")
        try write("x", to: "a.MD")  // 대소문자 구분: .md 만 인정 (간단함 유지)
        try write("x", to: "README")

        let entries = FileScanner.scan(tempDir)

        XCTAssertEqual(entries.map(\.relativePath), ["a.md"])
    }
}
