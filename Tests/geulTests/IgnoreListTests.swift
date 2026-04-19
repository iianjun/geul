import XCTest
@testable import geul

final class IgnoreListTests: XCTestCase {
    func testContainsCommonVCSAndBuildDirs() {
        XCTAssertTrue(IgnoreList.directoryNames.contains(".git"))
        XCTAssertTrue(IgnoreList.directoryNames.contains("node_modules"))
        XCTAssertTrue(IgnoreList.directoryNames.contains(".build"))
        XCTAssertTrue(IgnoreList.directoryNames.contains("DerivedData"))
        XCTAssertTrue(IgnoreList.directoryNames.contains(".worktrees"))
    }

    func testDoesNotContainDocs() {
        // docs/, notes/ 같은 일반 디렉토리는 스캔에 포함되어야 함
        XCTAssertFalse(IgnoreList.directoryNames.contains("docs"))
        XCTAssertFalse(IgnoreList.directoryNames.contains("notes"))
        XCTAssertFalse(IgnoreList.directoryNames.contains("src"))
    }
}
