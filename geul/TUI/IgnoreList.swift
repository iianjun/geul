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
}
