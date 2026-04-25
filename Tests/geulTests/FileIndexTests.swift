import XCTest
@testable import geul

final class FileIndexTests: XCTestCase {
    @MainActor
    private func makeFile(_ name: String) -> IndexedFile {
        IndexedFile(
            url: URL(fileURLWithPath: "/tmp/\(name)"),
            name: name,
            modifiedAt: Date(timeIntervalSince1970: 0),
            size: 1
        )
    }

    @MainActor
    func testInsertAndSearchByName() {
        let idx = FileIndex(files: [makeFile("README.md"), makeFile("NOTES.md")])
        let results = idx.search("READ", limit: 10)
        XCTAssertEqual(results.map { $0.name }, ["README.md"])
    }

    @MainActor
    func testRemoveByURL() {
        let idx = FileIndex(files: [makeFile("a.md"), makeFile("b.md")])
        idx.remove(at: URL(fileURLWithPath: "/tmp/a.md"))
        XCTAssertEqual(idx.files.map { $0.name }, ["b.md"])
    }

    @MainActor
    func testInsertReplacesExistingByURL() {
        let idx = FileIndex(files: [makeFile("a.md")])
        let updated = IndexedFile(
            url: URL(fileURLWithPath: "/tmp/a.md"),
            name: "a.md",
            modifiedAt: Date(timeIntervalSince1970: 100),
            size: 999
        )
        idx.insert(updated)
        XCTAssertEqual(idx.files.count, 1)
        XCTAssertEqual(idx.files.first?.size, 999)
    }

    @MainActor
    func testSearchLimit() {
        let files = (0..<50).map { makeFile("file\($0).md") }
        let idx = FileIndex(files: files)
        let results = idx.search("file", limit: 5)
        XCTAssertEqual(results.count, 5)
    }

    @MainActor
    func testEmptyQueryReturnsEmptyList() {
        let idx = FileIndex(files: [makeFile("a.md")])
        XCTAssertEqual(idx.search("", limit: 10), [])
    }
}
