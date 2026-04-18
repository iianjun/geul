import Foundation

struct Theme: Codable, Equatable, Hashable {
    let name: String
    let colors: [String: String]
}

/// A theme plus the file it was loaded from (used for deletion).
struct LoadedTheme: Identifiable, Equatable {
    let theme: Theme
    let sourceURL: URL
    let isBuiltIn: Bool

    var id: String { theme.name }
    var name: String { theme.name }
}
