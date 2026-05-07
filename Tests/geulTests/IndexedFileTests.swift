import XCTest
@testable import geul

final class IndexedFileTests: XCTestCase {
    func testEquatableMatchesOnURL() {
        let a = IndexedFile(
            url: URL(fileURLWithPath: "/tmp/a.md"),
            name: "a.md",
            modifiedAt: Date(timeIntervalSince1970: 0),
            size: 10
        )
        let b = IndexedFile(
            url: URL(fileURLWithPath: "/tmp/a.md"),
            name: "a.md",
            modifiedAt: Date(timeIntervalSince1970: 0),
            size: 10
        )
        XCTAssertEqual(a, b)
    }

    func testDifferentURLsNotEqual() {
        let a = IndexedFile(
            url: URL(fileURLWithPath: "/tmp/a.md"),
            name: "a.md", modifiedAt: Date(), size: 1)
        let b = IndexedFile(
            url: URL(fileURLWithPath: "/tmp/b.md"),
            name: "b.md", modifiedAt: Date(), size: 1)
        XCTAssertNotEqual(a, b)
    }
}
