import XCTest
@testable import geul

final class SettingsStoreTests: XCTestCase {
    func testDecodesLegacyPhase4FileWithOnlyThemeField() throws {
        let legacyJSON = Data("""
        { "theme": "Default Dark" }
        """.utf8)

        let decoder = JSONDecoder()
        let settings = try decoder.decode(SettingsStore.Settings.self, from: legacyJSON)

        XCTAssertEqual(settings.theme, "Default Dark")
        XCTAssertEqual(settings.indexRoots, [NSHomeDirectory()])
        XCTAssertFalse(settings.hotkey.enabled)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertEqual(settings.recentFilesCount, 10)
    }

    func testDefaultsWhenFileMissing() {
        let settings = SettingsStore.Settings()
        XCTAssertEqual(settings.theme, "Default Dark")
        XCTAssertEqual(settings.indexRoots, [NSHomeDirectory()])
        XCTAssertFalse(settings.hotkey.enabled)
        XCTAssertEqual(settings.recentFilesCount, 10)
    }

    func testEncodeThenDecodeRoundTrip() throws {
        var original = SettingsStore.Settings()
        original.indexRoots = ["/Users/foo", "/Volumes/Data"]
        original.hotkey.enabled = true
        original.launchAtLogin = true
        original.recentFilesCount = 15

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SettingsStore.Settings.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testBacksUpCorruptJSON() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("geul-settings-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let settingsURL = tempDir.appendingPathComponent("settings.json")
        try "not json".write(to: settingsURL, atomically: true, encoding: .utf8)

        _ = SettingsStore.loadOrBackup(settingsURL: settingsURL)

        let bakURL = settingsURL.appendingPathExtension("bak")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: bakURL.path),
            "Corrupt settings.json should be backed up to .bak")
    }
}
