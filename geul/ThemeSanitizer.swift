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

    /// Pick the highlight.js variant ('dark' or 'default') by inspecting the
    /// theme's --bg-primary brightness. Hex-only; unknown formats fall back
    /// to 'default' (light).
    static func hljsVariantKey(for theme: Theme) -> String {
        guard let background = theme.colors["--bg-primary"],
              let luma = relativeLuminance(of: background) else { return "default" }
        return luma < 0.5 ? "dark" : "default"
    }

    private static func relativeLuminance(of cssColor: String) -> Double? {
        let trimmed = cssColor.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }
        let hex = String(trimmed.dropFirst())
        guard let rgb = UInt32(hex, radix: 16) else { return nil }
        let red, green, blue: Double
        switch hex.count {
        case 6:
            red = Double((rgb >> 16) & 0xFF) / 255.0
            green = Double((rgb >> 8) & 0xFF) / 255.0
            blue = Double(rgb & 0xFF) / 255.0
        case 3:
            red = Double(((rgb >> 8) & 0xF) * 0x11) / 255.0
            green = Double(((rgb >> 4) & 0xF) * 0x11) / 255.0
            blue = Double((rgb & 0xF) * 0x11) / 255.0
        default:
            return nil
        }
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    /// Safely embed a string as a JS string literal using JSON escaping.
    static func jsStringLiteral(_ value: String) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: value,
            options: .fragmentsAllowed
        ), let literal = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return literal
    }
}
