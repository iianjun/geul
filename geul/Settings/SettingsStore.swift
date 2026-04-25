import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    struct HotkeySettings: Codable, Equatable {
        var enabled: Bool = false
    }

    struct Settings: Codable, Equatable {
        var theme: String = "Default Dark"
        var indexRoots: [String] = [NSHomeDirectory()]
        var hotkey: HotkeySettings = .init()
        var launchAtLogin: Bool = false
        var recentFilesCount: Int = 10

        init() {}

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.theme = try container.decodeIfPresent(String.self, forKey: .theme)
                ?? "Default Dark"
            self.indexRoots = try container.decodeIfPresent([String].self, forKey: .indexRoots)
                ?? [NSHomeDirectory()]
            self.hotkey = try container.decodeIfPresent(HotkeySettings.self, forKey: .hotkey)
                ?? HotkeySettings()
            self.launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin)
                ?? false
            self.recentFilesCount = try container.decodeIfPresent(Int.self, forKey: .recentFilesCount)
                ?? 10
        }
    }

    @Published var settings: Settings

    private let configDir: URL
    private let settingsURL: URL
    private var persistWork: DispatchWorkItem?

    private init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.configDir = home.appendingPathComponent(".config/geul")
        self.settingsURL = configDir.appendingPathComponent("settings.json")
        self.settings = Self.loadOrBackup(settingsURL: settingsURL)
    }

    nonisolated static func loadOrBackup(settingsURL: URL) -> Settings {
        guard let data = try? Data(contentsOf: settingsURL) else {
            return Settings()
        }
        do {
            return try JSONDecoder().decode(Settings.self, from: data)
        } catch {
            let bak = settingsURL.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: bak)
            try? FileManager.default.moveItem(at: settingsURL, to: bak)
            print("[geul] settings.json could not be decoded — backed up to \(bak.lastPathComponent). Error: \(error)")
            return Settings()
        }
    }

    var indexRootsURLs: [URL] {
        settings.indexRoots.map { URL(fileURLWithPath: $0) }
    }

    func update(_ mutate: (inout Settings) -> Void) {
        mutate(&settings)
        schedulePersist()
    }

    private func schedulePersist() {
        persistWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in self?.persistNow() }
        }
        persistWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    private func persistNow() {
        do {
            try FileManager.default.createDirectory(
                at: configDir,
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL, options: .atomic)
        } catch {
            print("[geul] Failed to persist settings: \(error)")
        }
    }
}
