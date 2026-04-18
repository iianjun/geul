import Foundation

struct Theme: Codable, Equatable, Hashable {
    enum ThemeType: String, Codable {
        case light
        case dark
    }

    let name: String
    let type: ThemeType
    let colors: [String: String]
}

/// A theme plus the file it was loaded from (used for deletion).
struct LoadedTheme: Equatable {
    let theme: Theme
    let sourceURL: URL
    let isBuiltIn: Bool

    var name: String { theme.name }
    var type: Theme.ThemeType { theme.type }
}

/// A group of themes that share the same `name` — lets the UI show one entry
/// even when both a light and a dark variant are present.
struct ThemeGroup: Identifiable, Equatable {
    let name: String
    let light: LoadedTheme?
    let dark: LoadedTheme?

    var id: String { name }
    var isBuiltIn: Bool { (light?.isBuiltIn ?? false) || (dark?.isBuiltIn ?? false) }
    var hasBothVariants: Bool { light != nil && dark != nil }

    var metaLabel: String {
        if hasBothVariants {
            return "light + dark · auto switch"
        } else if light != nil {
            return "light only — used in both modes"
        } else {
            return "dark only — used in both modes"
        }
    }
}
