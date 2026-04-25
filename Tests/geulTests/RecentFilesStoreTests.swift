import XCTest
@testable import geul

final class RecentFilesStoreTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-recent-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    @MainActor
    func testBumpInsertsAtTop() async {
        let store = RecentFilesStore(configDir: tempDir, capacity: 3)
        store.bump(URL(fileURLWithPath: "/tmp/a.md"))
        store.bump(URL(fileURLWithPath: "/tmp/b.md"))
        XCTAssertEqual(store.items.first?.path, "/tmp/b.md")
        XCTAssertEqual(store.items.count, 2)
    }

    @MainActor
    func testBumpDeduplicates() async {
        let store = RecentFilesStore(configDir: tempDir, capacity: 3)
        store.bump(URL(fileURLWithPath: "/tmp/a.md"))
        store.bump(URL(fileURLWithPath: "/tmp/b.md"))
        store.bump(URL(fileURLWithPath: "/tmp/a.md"))
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.first?.path, "/tmp/a.md")
    }

    @MainActor
    func testCapacityCapsAtMax() async {
        let store = RecentFilesStore(configDir: tempDir, capacity: 2)
        store.bump(URL(fileURLWithPath: "/tmp/a.md"))
        store.bump(URL(fileURLWithPath: "/tmp/b.md"))
        store.bump(URL(fileURLWithPath: "/tmp/c.md"))
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.map { $0.path }, ["/tmp/c.md", "/tmp/b.md"])
    }

    @MainActor
    func testPersistAndLoad() async throws {
        let file = tempDir.appendingPathComponent("persist.md")
        try "x".write(to: file, atomically: true, encoding: .utf8)

        let s1 = RecentFilesStore(configDir: tempDir, capacity: 3)
        s1.bump(file)
        s1.flushForTesting()

        let s2 = RecentFilesStore(configDir: tempDir, capacity: 3)
        XCTAssertEqual(s2.items.first?.path, file.standardizedFileURL.path)
    }

    @MainActor
    func testPrunesMissingPathsOnLoad() async throws {
        let existing = tempDir.appendingPathComponent("exists.md")
        try "content".write(to: existing, atomically: true, encoding: .utf8)

        let recentJSON = """
        [
          {"path": "\(existing.path)", "openedAt": "2026-04-23T00:00:00Z"},
          {"path": "/does/not/exist.md", "openedAt": "2026-04-23T00:00:00Z"}
        ]
        """
        try recentJSON.write(
            to: tempDir.appendingPathComponent("recent.json"),
            atomically: true, encoding: .utf8)

        let store = RecentFilesStore(configDir: tempDir, capacity: 3)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.path, existing.path)
    }

    @MainActor
    func testBacksUpCorruptJSON() async throws {
        let recentURL = tempDir.appendingPathComponent("recent.json")
        try "not json".write(to: recentURL, atomically: true, encoding: .utf8)

        let store = RecentFilesStore(configDir: tempDir, capacity: 3)
        XCTAssertEqual(store.items.count, 0)
        let bakURL = recentURL.appendingPathExtension("bak")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: bakURL.path),
            "Corrupt recent.json should be backed up to .bak")
    }
}
