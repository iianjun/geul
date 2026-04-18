import AppKit
import Combine
import Foundation

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    /// All themes grouped by `name`, sorted alphabetically with Default first.
    @Published private(set) var groups: [ThemeGroup] = []
    /// The user's selection (`Theme.name`). Persisted to settings.json.
    @Published private(set) var selectedName: String
    /// The resolved light theme for the active selection. Always non-nil.
    @Published private(set) var resolvedLight: Theme
    /// The resolved dark theme for the active selection. Always non-nil.
    @Published private(set) var resolvedDark: Theme

    private let configDir: URL
    private let themesDir: URL
    private let settingsURL: URL

    private struct Settings: Codable {
        var theme: String?
    }

    enum ThemeStoreError: LocalizedError {
        case cannotImportBuiltInName

        var errorDescription: String? {
            switch self {
            case .cannotImportBuiltInName:
                return "The name Default is reserved for geul's built-in theme."
            }
        }
    }

    private init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.configDir = home.appendingPathComponent(".config/geul")
        self.themesDir = configDir.appendingPathComponent("themes")
        self.settingsURL = configDir.appendingPathComponent("settings.json")

        let loaded = Self.loadAllThemes(userDir: themesDir)
        let groups = Self.makeGroups(from: loaded)
        let settings = (try? JSONDecoder().decode(
            Settings.self,
            from: Data(contentsOf: settingsURL)
        )) ?? Settings()
        let initialName = settings.theme ?? "Default"

        let resolvedGroup = groups.first(where: { $0.name == initialName })
            ?? groups.first(where: { $0.name == "Default" })
            ?? Self.defaultGroup()

        self.groups = groups
        self.selectedName = resolvedGroup.name
        self.resolvedLight = resolvedGroup.light?.theme
            ?? resolvedGroup.dark?.theme
            ?? Self.hardcodedDefault(.light)
        self.resolvedDark = resolvedGroup.dark?.theme
            ?? resolvedGroup.light?.theme
            ?? Self.hardcodedDefault(.dark)
    }

    // MARK: - Public API

    func reload() {
        let loaded = Self.loadAllThemes(userDir: themesDir)
        groups = Self.makeGroups(from: loaded)
        // Re-resolve in case the selected theme was removed externally.
        selectInternal(name: selectedName, persist: false)
    }

    func select(name: String) {
        selectInternal(name: name, persist: true)
    }

    /// Copy `url` into `~/.config/geul/themes/<name>-<type>.json`, reload list.
    /// Throws a user-friendly error if the file cannot be decoded or the copy fails.
    func importTheme(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let theme = try JSONDecoder().decode(Theme.self, from: data)
        guard theme.name.localizedCaseInsensitiveCompare("Default") != .orderedSame else {
            throw ThemeStoreError.cannotImportBuiltInName
        }

        try FileManager.default.createDirectory(
            at: themesDir,
            withIntermediateDirectories: true
        )

        let slug = Self.slugify(theme.name)
        let dest = themesDir.appendingPathComponent("\(slug)-\(theme.type.rawValue).json")

        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: url, to: dest)
        reload()
    }

    /// Delete both variants (if present) of the given user theme name.
    /// No-op for built-in themes. Falls back to "Default" if the active theme was removed.
    func removeUserTheme(name: String) {
        guard let group = groups.first(where: { $0.name == name }) else { return }
        guard !group.isBuiltIn else { return }

        for loaded in [group.light, group.dark].compactMap({ $0 }) where !loaded.isBuiltIn {
            try? FileManager.default.removeItem(at: loaded.sourceURL)
        }
        reload()
    }

    /// Open `~/.config/geul/themes/` in Finder, creating it if needed.
    func revealThemesFolder() {
        try? FileManager.default.createDirectory(
            at: themesDir,
            withIntermediateDirectories: true
        )
        NSWorkspace.shared.activateFileViewerSelecting([themesDir])
    }

    // MARK: - Private

    private func selectInternal(name: String, persist: Bool) {
        let group = groups.first(where: { $0.name == name })
            ?? groups.first(where: { $0.name == "Default" })
            ?? Self.defaultGroup()

        selectedName = group.name
        resolvedLight = group.light?.theme
            ?? group.dark?.theme
            ?? Self.hardcodedDefault(.light)
        resolvedDark = group.dark?.theme
            ?? group.light?.theme
            ?? Self.hardcodedDefault(.dark)

        if persist {
            persistSettings(name: group.name)
        }
    }

    private func persistSettings(name: String) {
        do {
            try FileManager.default.createDirectory(
                at: configDir,
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(Settings(theme: name))
            try data.write(to: settingsURL, options: .atomic)
        } catch {
            print("[geul] Failed to persist settings: \(error)")
        }
    }

    private static func loadAllThemes(userDir: URL) -> [LoadedTheme] {
        var results: [LoadedTheme] = []

        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif

        if let urls = bundle.urls(
            forResourcesWithExtension: "json",
            subdirectory: "Resources/themes"
        ) {
            for url in urls {
                if let theme = decode(url: url) {
                    results.append(LoadedTheme(theme: theme, sourceURL: url, isBuiltIn: true))
                }
            }
        }

        if let contents = try? FileManager.default.contentsOfDirectory(
            at: userDir,
            includingPropertiesForKeys: nil
        ) {
            for url in contents where url.pathExtension == "json" {
                if let theme = decode(url: url) {
                    results.append(LoadedTheme(theme: theme, sourceURL: url, isBuiltIn: false))
                }
            }
        }

        return ensureDefaultThemes(in: results)
    }

    private static func ensureDefaultThemes(in themes: [LoadedTheme]) -> [LoadedTheme] {
        var result = themes
        let hasDefaultLight = result.contains {
            $0.name == "Default" && $0.type == .light && $0.isBuiltIn
        }
        let hasDefaultDark = result.contains {
            $0.name == "Default" && $0.type == .dark && $0.isBuiltIn
        }

        if !hasDefaultLight {
            result.append(defaultLoadedTheme(.light))
        }
        if !hasDefaultDark {
            result.append(defaultLoadedTheme(.dark))
        }
        return result
    }

    private static func defaultLoadedTheme(_ type: Theme.ThemeType) -> LoadedTheme {
        LoadedTheme(
            theme: hardcodedDefault(type),
            sourceURL: URL(fileURLWithPath: "built-in-default-\(type.rawValue).json"),
            isBuiltIn: true
        )
    }

    private static func defaultGroup() -> ThemeGroup {
        ThemeGroup(
            name: "Default",
            light: defaultLoadedTheme(.light),
            dark: defaultLoadedTheme(.dark)
        )
    }

    private static func makeGroups(from themes: [LoadedTheme]) -> [ThemeGroup] {
        // User themes with the same (name, type) override bundled ones.
        var byKey: [String: LoadedTheme] = [:]
        for theme in themes {
            let key = "\(theme.name)|\(theme.type.rawValue)"
            if let existing = byKey[key], existing.isBuiltIn && !theme.isBuiltIn {
                byKey[key] = theme
            } else if byKey[key] == nil {
                byKey[key] = theme
            }
        }

        var grouped: [String: (light: LoadedTheme?, dark: LoadedTheme?)] = [:]
        for loaded in byKey.values {
            var entry = grouped[loaded.name] ?? (nil, nil)
            switch loaded.type {
            case .light: entry.light = loaded
            case .dark: entry.dark = loaded
            }
            grouped[loaded.name] = entry
        }

        let result = grouped.map { name, pair in
            ThemeGroup(name: name, light: pair.light, dark: pair.dark)
        }

        // Default first, then alphabetical.
        return result.sorted { lhs, rhs in
            if lhs.name == "Default" { return true }
            if rhs.name == "Default" { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private static func decode(url: URL) -> Theme? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Theme.self, from: data)
        } catch {
            print("[geul] Failed to load theme \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    private static func slugify(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let lowered = name.lowercased().replacingOccurrences(of: " ", with: "-")
        return lowered.unicodeScalars
            .map { allowed.contains($0) ? String($0) : "" }
            .joined()
    }

    private static func hardcodedDefault(_ type: Theme.ThemeType) -> Theme {
        // Last-resort fallback if bundled JSON is missing. Should not be needed in practice.
        let light: [String: String] = [
            "--bg-primary": "#fafaf9",
            "--bg-secondary": "#f5f5f4",
            "--bg-code": "#f5f5f4",
            "--bg-code-border": "#0d9488",
            "--text-primary": "#1c1917",
            "--text-secondary": "#78716c",
            "--text-tertiary": "#a8a29e",
            "--accent": "#0d9488",
            "--accent-soft": "rgba(13, 148, 136, 0.08)",
            "--border": "#e7e5e4",
            "--border-strong": "#d6d3d1",
            "--shadow-subtle": "0 1px 2px rgba(28, 25, 23, 0.04)"
        ]
        let dark: [String: String] = [
            "--bg-primary": "#1c1917",
            "--bg-secondary": "#292524",
            "--bg-code": "#292524",
            "--bg-code-border": "#2dd4bf",
            "--text-primary": "#fafaf9",
            "--text-secondary": "#a8a29e",
            "--text-tertiary": "#78716c",
            "--accent": "#2dd4bf",
            "--accent-soft": "rgba(45, 212, 191, 0.08)",
            "--border": "#44403c",
            "--border-strong": "#57534e",
            "--shadow-subtle": "0 1px 2px rgba(0, 0, 0, 0.2)"
        ]
        return Theme(name: "Default", type: type, colors: type == .light ? light : dark)
    }
}
