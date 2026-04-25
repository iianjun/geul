import Foundation

enum IgnoreList {
    static let directoryNames: Set<String> = [
        // VCS
        ".git", ".hg", ".svn",
        // Node
        "node_modules",
        // Swift
        ".build", ".swiftpm", "DerivedData",
        // JS frameworks
        ".next", ".nuxt",
        // Build outputs
        "dist", "build", "out",
        // Python
        ".venv", "venv", "__pycache__",
        // Editor
        ".idea", ".vscode",
        // Git worktrees
        ".worktrees",
    ]

    static func parseGitignore(_ content: String) -> [String] {
        content.split(whereSeparator: { $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    static func matches(name: String, pattern: String) -> Bool {
        let trimmed = pattern.hasSuffix("/") ? String(pattern.dropLast()) : pattern
        if !trimmed.contains("*") && !trimmed.contains("?") {
            return name == trimmed
        }
        return fnmatch(trimmed, name)
    }

    private static func fnmatch(_ pattern: String, _ name: String) -> Bool {
        let patternChars = Array(pattern)
        let nameChars = Array(name)
        return fnmatchRecurse(patternChars, 0, nameChars, 0)
    }

    private static func fnmatchRecurse(
        _ pattern: [Character], _ pIndex: Int,
        _ name: [Character], _ nIndex: Int
    ) -> Bool {
        if pIndex == pattern.count { return nIndex == name.count }
        if pattern[pIndex] == "*" {
            var nextP = pIndex
            while nextP < pattern.count && pattern[nextP] == "*" { nextP += 1 }
            if nextP == pattern.count { return true }
            for nextN in nIndex...name.count {
                if fnmatchRecurse(pattern, nextP, name, nextN) { return true }
            }
            return false
        }
        if nIndex == name.count { return false }
        if pattern[pIndex] == "?" || pattern[pIndex] == name[nIndex] {
            return fnmatchRecurse(pattern, pIndex + 1, name, nIndex + 1)
        }
        return false
    }

    /// True if `url` is excluded by a toplevel `.gitignore` in any ancestor
    /// directory between `url` and (inclusive) `root`.
    ///
    /// - Walks ancestors from `url.deletingLastPathComponent()` up to `root`.
    /// - At each ancestor dir, checks whether its toplevel `.gitignore` patterns
    ///   match the child path component that lies on the walk.
    /// - `cache` memoizes parsed patterns by dir path across calls (caller owns
    ///   lifetime / reset). Pass the same cache between calls to avoid re-reads.
    /// - Consistent with `HomeScanner`'s per-directory toplevel-only filter.
    ///   Nested / negative patterns intentionally out of scope (spec §10).
    static func isIgnoredByAncestorGitignore(
        url: URL,
        underRoot root: URL,
        cache: inout [String: [String]]
    ) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let urlPath = url.standardizedFileURL.path
        let rootPrefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard urlPath == rootPath || urlPath.hasPrefix(rootPrefix) else {
            return false
        }

        var ancestor = url.deletingLastPathComponent()
        var child = url
        while ancestor.path.count >= rootPath.count {
            let patterns: [String]
            if let cached = cache[ancestor.path] {
                patterns = cached
            } else {
                let gitignore = ancestor.appendingPathComponent(".gitignore")
                if let content = try? String(contentsOf: gitignore, encoding: .utf8) {
                    patterns = IgnoreList.parseGitignore(content)
                } else {
                    patterns = []
                }
                cache[ancestor.path] = patterns
            }
            if !patterns.isEmpty {
                let childName = child.lastPathComponent
                if patterns.contains(where: {
                    IgnoreList.matches(name: childName, pattern: $0)
                }) {
                    return true
                }
            }
            if ancestor.path == rootPath { break }
            child = ancestor
            ancestor = ancestor.deletingLastPathComponent()
        }
        return false
    }
}
