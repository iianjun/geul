import Foundation

/// Filters a theme's color map to only keys the viewer actually consumes, and
/// rejects values that could escape the `<style>` tag, inject declarations, or
/// open CSS comments. Used by both the initial HTML compose and the runtime
/// `setTheme` patch so a malformed theme file cannot become a rendering or
/// code-injection vector.
enum ThemeSanitizer {
    static let allowedKeys: Set<String> = [
        "--bg-primary",
        "--bg-secondary",
        "--bg-code",
        "--bg-code-border",
        "--text-primary",
        "--text-secondary",
        "--text-tertiary",
        "--accent",
        "--accent-soft",
        "--border",
        "--border-strong",
        "--shadow-subtle"
    ]

    static func sanitized(_ colors: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in colors where allowedKeys.contains(key) && isSafeValue(value) {
            result[key] = value
        }
        return result
    }

    private static let safeValueChars: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "abcdefghijklmnopqrstuvwxyz")
        set.insert(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        set.insert(charactersIn: "0123456789")
        set.insert(charactersIn: " \t.,%#()-+_")
        return set
    }()

    /// Allowlist-based CSS value check. Blocks `<`, `>`, `{`, `}`, `@`, `;`,
    /// `\`, `/`, `*`, quotes, and control characters.
    private static func isSafeValue(_ value: String) -> Bool {
        if value.isEmpty { return false }
        for scalar in value.unicodeScalars where !safeValueChars.contains(scalar) {
            return false
        }
        return true
    }
}
