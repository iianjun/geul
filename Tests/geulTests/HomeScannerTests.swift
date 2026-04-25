import XCTest
@testable import geul

final class HomeScannerTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-scanner-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func writeFile(_ relative: String, content: String = "x") throws -> URL {
        let url = tempDir.appendingPathComponent(relative)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testCollectsMarkdownFiles() async throws {
        _ = try writeFile("README.md")
        _ = try writeFile("docs/note.md")
        _ = try writeFile("docs/ignored.txt")

        let scanner = HomeScanner()
        let results = try await scanner.scan(roots: [tempDir])

        let names = Set(results.map { $0.name })
        XCTAssertTrue(names.contains("README.md"))
        XCTAssertTrue(names.contains("note.md"))
        XCTAssertFalse(names.contains("ignored.txt"))
    }

    func testRecognizesMarkdownExtensions() async throws {
        _ = try writeFile("a.md")
        _ = try writeFile("b.markdown")
        _ = try writeFile("c.mdown")
        _ = try writeFile("d.mkd")

        let scanner = HomeScanner()
        let results = try await scanner.scan(roots: [tempDir])
        XCTAssertEqual(results.count, 4)
    }

    func testHonorsIgnoreListDirectories() async throws {
        _ = try writeFile("src/a.md")
        _ = try writeFile("node_modules/x.md")
        _ = try writeFile(".git/HEAD-note.md")

        let scanner = HomeScanner()
        let results = try await scanner.scan(roots: [tempDir])
        let names = Set(results.map { $0.name })
        XCTAssertTrue(names.contains("a.md"))
        XCTAssertFalse(names.contains("x.md"))
        XCTAssertFalse(names.contains("HEAD-note.md"))
    }

    func testNonexistentRootReturnsEmpty() async throws {
        let bogus = URL(fileURLWithPath: "/nonexistent-geul-\(UUID().uuidString)")
        let scanner = HomeScanner()
        let results = try await scanner.scan(roots: [bogus])
        XCTAssertEqual(results.count, 0)
    }

    func testHonorsToplevelGitignore() async throws {
        _ = try writeFile("keep.md")
        _ = try writeFile("drop/inside.md")
        try "drop/\n"
            .write(to: tempDir.appendingPathComponent(".gitignore"),
                   atomically: true, encoding: .utf8)

        let scanner = HomeScanner()
        let results = try await scanner.scan(roots: [tempDir])
        let names = Set(results.map { $0.name })
        XCTAssertTrue(names.contains("keep.md"))
        XCTAssertFalse(names.contains("inside.md"),
            "Files under a .gitignore-listed directory should be excluded")
    }
}
