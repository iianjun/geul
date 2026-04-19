import XCTest
@testable import geul

final class FuzzyMatcherTests: XCTestCase {
    private func entry(_ path: String) -> FileEntry {
        FileEntry(
            url: URL(fileURLWithPath: "/tmp/\(path)"),
            relativePath: path,
            depth: path.filter { $0 == "/" }.count,
            mtime: Date(timeIntervalSince1970: 0)
        )
    }

    func testEmptyQueryMatchesAllInOriginalOrder() {
        let input = [entry("b.md"), entry("a.md"), entry("c.md")]
        let result = FuzzyMatcher.filter(input, query: "")
        XCTAssertEqual(result.map(\.entry.relativePath), ["b.md", "a.md", "c.md"])
    }

    func testCaseInsensitiveMatch() {
        let result = FuzzyMatcher.filter([entry("README.md")], query: "readme")
        XCTAssertEqual(result.count, 1)
    }

    func testSubsequenceMatches() {
        let result = FuzzyMatcher.filter([entry("docs/pm/PROGRESS.md")], query: "prog")
        XCTAssertEqual(result.count, 1)
        XCTAssertFalse(result[0].matchIndices.isEmpty)
    }

    func testNoMatchReturnsEmpty() {
        let result = FuzzyMatcher.filter([entry("a.md")], query: "zzz")
        XCTAssertTrue(result.isEmpty)
    }

    func testConsecutiveBonusPrefersTighterMatch() {
        // "prd" 가 docs/PRD.md 에서는 연속, docs/pm/project.md 에서는 분산
        let tight = entry("docs/PRD.md")
        let loose = entry("docs/pm/project.md")
        let result = FuzzyMatcher.filter([loose, tight], query: "prd")
        XCTAssertEqual(result.first?.entry.relativePath, "docs/PRD.md",
                       "consecutive match should outrank scattered match")
    }

    func testWordBoundaryBonus() {
        // "pm" 이 docs/pm/x.md 에서는 '/' 뒤라 경계, docs/lampmd.md 에서는 경계 아님
        let boundary = entry("docs/pm/x.md")
        let midWord = entry("docs/lampmd.md")
        let result = FuzzyMatcher.filter([midWord, boundary], query: "pm")
        XCTAssertEqual(result.first?.entry.relativePath, "docs/pm/x.md")
    }

    func testTieBrokenAlphabetically() {
        let a = entry("aaa.md")
        let b = entry("bbb.md")
        // 둘 다 쿼리 "a" 로 매치되지만 basename 의 단어 경계 점수가 다를 수 있음
        // 여기선 쿼리를 "m" 으로 써서 두 경로에서 동일 점수가 나오도록
        let result = FuzzyMatcher.filter([b, a], query: "m")
        XCTAssertEqual(result.map(\.entry.relativePath), ["aaa.md", "bbb.md"])
    }

    func testMatchIndicesArePositionsInRelativePath() {
        let result = FuzzyMatcher.filter([entry("docs/PRD.md")], query: "drd")
        XCTAssertEqual(result.count, 1)
        let indices = result[0].matchIndices
        let chars = Array("docs/PRD.md")
        let matched = indices.map { chars[$0] }
        XCTAssertEqual(String(matched).lowercased(), "drd")
    }
}
