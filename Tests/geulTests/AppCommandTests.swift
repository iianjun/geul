import XCTest
@testable import geul

final class AppCommandTests: XCTestCase {
    func testNumberedTabShortcutsAreRegistered() throws {
        let source = try String(contentsOf: Self.geulAppSourceURL(), encoding: .utf8)

        XCTAssertTrue(source.contains("ForEach(1...9, id: \\.self)"))
        XCTAssertTrue(source.contains("AppDelegate.selectWindowTab(at: number - 1)"))
        XCTAssertTrue(source.contains("KeyEquivalent(Character(String(number)))"))
        XCTAssertTrue(source.contains("modifiers: .command"))
        XCTAssertFalse(source.contains("Button(\"Select Tab 9\")"))
    }

    private static func geulAppSourceURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("geul/GeulApp.swift")
    }
}
