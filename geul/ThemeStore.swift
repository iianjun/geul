import AppKit
import Foundation

@MainActor
final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    static let defaultThemeName = "Default Dark"
    private static let reservedBuiltInNames: Set<String> = ["Default Dark", "Default Light"]

    /// All themes, sorted with Default Dark first, Default Light second, then others alphabetical.
    @Published private(set) var themes: [LoadedTheme] = []
    /// The user's selection (`Theme.name`). Persisted to settings.json.
    @Published private(set) var selectedName: String
    /// The currently resolved theme. Always non-nil.
    @Published private(set) var resolved: Theme

    private let configDir: URL
    private let themesDir: URL

    enum ThemeStoreError: LocalizedError {
        case cannotImportBuiltInName(String)
        case invalidThemeName(String)
        case slugCollision(incoming: String, existing: String)

        var errorDescription: String? {
            switch self {
            case .cannotImportBuiltInName(let name):
                return "The name \"\(name)\" is reserved for geul's built-in themes."
            case .invalidThemeName(let name):
                return "\"\(name)\" is not a valid theme name — use letters, digits, or dashes."
            case .slugCollision(let incoming, let existing):
                return "\"\(incoming)\" conflicts with existing theme \"\(existing)\" — rename one of them."
            }
        }
    }

    private init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.configDir = home.appendingPathComponent(".config/geul")
        self.themesDir = configDir.appendingPathComponent("themes")

        let loaded = Self.loadAllThemes(userDir: themesDir)
        let initialName = SettingsStore.shared.settings.theme

        let active = loaded.first(where: { $0.name == initialName })
            ?? loaded.first(where: { $0.name == Self.defaultThemeName })
            ?? Self.fallbackDefaultLoaded()

        self.themes = loaded
        self.selectedName = active.name
        self.resolved = active.theme
    }

    // MARK: - Public API

    func reload() {
        themes = Self.loadAllThemes(userDir: themesDir)
        // Re-resolve in case the selected theme was removed externally.
        selectInternal(name: selectedName, persist: false)
    }

    func select(name: String) {
        selectInternal(name: name, persist: true)
    }

    /// Copy `url` into `~/.config/geul/themes/<slug>.json`, reload list.
    /// Throws a user-friendly error if decoding, slug validation, collision detection, or I/O fails.
    func importTheme(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let theme = try JSONDecoder().decode(Theme.self, from: data)
        if Self.reservedBuiltInNames.contains(where: {
            $0.localizedCaseInsensitiveCompare(theme.name) == .orderedSame
        }) {
            throw ThemeStoreError.cannotImportBuiltInName(theme.name)
        }

        let slug = Self.slugify(theme.name)
        guard !slug.isEmpty else {
            throw ThemeStoreError.invalidThemeName(theme.name)
        }

        try FileManager.default.createDirectory(
            at: themesDir,
            withIntermediateDirectories: true
        )

        let dest = themesDir.appendingPathComponent("\(slug).json")

        // No-op if the user picked the file that's already our destination.
        let canonicalSource = url.resolvingSymlinksInPath().standardizedFileURL
        let canonicalDest = dest.resolvingSymlinksInPath().standardizedFileURL
        if canonicalSource == canonicalDest {
            reload()
            return
        }

        // Slug collision: a different theme name already occupies this path.
        if let existing = try? Data(contentsOf: dest),
           let existingTheme = try? JSONDecoder().decode(Theme.self, from: existing),
           existingTheme.name.localizedCaseInsensitiveCompare(theme.name) != .orderedSame {
            throw ThemeStoreError.slugCollision(
                incoming: theme.name,
                existing: existingTheme.name
            )
        }

        // Stage to a temp file on the same volume, then atomically replace.
        let tmpURL = themesDir.appendingPathComponent(".import-\(UUID().uuidString).json")
        try data.write(to: tmpURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        if FileManager.default.fileExists(atPath: dest.path) {
            _ = try FileManager.default.replaceItemAt(dest, withItemAt: tmpURL)
        } else {
            try FileManager.default.moveItem(at: tmpURL, to: dest)
        }

        reload()
    }

    /// Delete the given user theme. No-op for built-in themes.
    /// Falls back to Default Dark if the active theme was removed.
    func removeUserTheme(name: String) {
        guard let loaded = themes.first(where: { $0.name == name }), !loaded.isBuiltIn else {
            return
        }
        try? FileManager.default.removeItem(at: loaded.sourceURL)
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
        let active = themes.first(where: { $0.name == name })
            ?? themes.first(where: { $0.name == Self.defaultThemeName })
            ?? Self.fallbackDefaultLoaded()

        selectedName = active.name
        resolved = active.theme

        if persist {
            SettingsStore.shared.update { $0.theme = active.name }
        }
    }

    private static func loadAllThemes(userDir: URL) -> [LoadedTheme] {
        var byName: [String: LoadedTheme] = [:]
        for loaded in loadBundledThemes() {
            byName[loaded.name] = loaded
        }
        for loaded in loadUserThemes(userDir: userDir) {
            byName[loaded.name] = loaded
        }
        var result = Array(byName.values)
        if !result.contains(where: { $0.name == defaultThemeName }) {
            result.append(fallbackDefaultLoaded())
        }
        if !result.contains(where: { $0.name == "Default Light" }) {
            result.append(fallbackDefaultLightLoaded())
        }
        return result.sorted(by: sortOrder)
    }

    private static func loadBundledThemes() -> [LoadedTheme] {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        guard let urls = bundle.urls(
            forResourcesWithExtension: "json",
            subdirectory: "Resources/themes"
        ) else { return [] }
        return urls.compactMap { url in
            guard let theme = decode(url: url) else { return nil }
            return LoadedTheme(theme: theme, sourceURL: url, isBuiltIn: true)
        }
    }

    private static func loadUserThemes(userDir: URL) -> [LoadedTheme] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: userDir,
            includingPropertiesForKeys: nil
        ) else { return [] }
        return contents.compactMap { url in
            guard url.pathExtension == "json",
                  let theme = decode(url: url),
                  !reservedBuiltInNames.contains(theme.name) else { return nil }
            return LoadedTheme(theme: theme, sourceURL: url, isBuiltIn: false)
        }
    }

    /// Default Dark first, Default Light second, then alphabetical.
    private static func sortOrder(_ lhs: LoadedTheme, _ rhs: LoadedTheme) -> Bool {
        if lhs.name == defaultThemeName { return true }
        if rhs.name == defaultThemeName { return false }
        if lhs.name == "Default Light" { return true }
        if rhs.name == "Default Light" { return false }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
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

    // MARK: - Hardcoded fallbacks (used only if the bundled JSON is missing).

    private static func fallbackDefaultLoaded() -> LoadedTheme {
        LoadedTheme(
            theme: Theme(name: defaultThemeName, colors: hardcodedDarkColors),
            sourceURL: URL(fileURLWithPath: "built-in-default-dark.json"),
            isBuiltIn: true
        )
    }

    private static func fallbackDefaultLightLoaded() -> LoadedTheme {
        LoadedTheme(
            theme: Theme(name: "Default Light", colors: hardcodedLightColors),
            sourceURL: URL(fileURLWithPath: "built-in-default-light.json"),
            isBuiltIn: true
        )
    }

    private static let hardcodedDarkColors: [String: String] = [
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

    private static let hardcodedLightColors: [String: String] = [
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
}
