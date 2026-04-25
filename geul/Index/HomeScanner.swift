import Foundation

actor HomeScanner {
    private static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd"]

    init() {}

    func scan(roots: [URL]) async throws -> [IndexedFile] {
        var out: [IndexedFile] = []
        for root in roots {
            try Task.checkCancellation()
            out.append(contentsOf: try await scanOne(root: root))
        }
        return out
    }

    private func scanOne(root: URL) async throws -> [IndexedFile] {
        let manager = FileManager.default
        guard manager.fileExists(atPath: root.path) else { return [] }
        var results: [IndexedFile] = []
        try collect(at: root, results: &results)
        return results
    }

    private nonisolated func collect(at dir: URL, results: inout [IndexedFile]) throws {
        try Task.checkCancellation()
        let manager = FileManager.default
        let keys: [URLResourceKey] = [
            .isDirectoryKey, .contentModificationDateKey, .fileSizeKey
        ]
        let localGitignore = Self.loadLocalGitignorePatterns(dir: dir)

        guard let contents = try? manager.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        for url in contents {
            let name = url.lastPathComponent
            if IgnoreList.directoryNames.contains(name) { continue }
            if localGitignore.contains(where: { IgnoreList.matches(name: name, pattern: $0) }) {
                continue
            }

            let isDir = (try? url.resourceValues(
                forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                try collect(at: url, results: &results)
            } else {
                let ext = url.pathExtension.lowercased()
                guard Self.markdownExtensions.contains(ext) else { continue }
                let values = try? url.resourceValues(forKeys: Set(keys))
                let mtime = values?.contentModificationDate ?? Date()
                let size = Int64(values?.fileSize ?? 0)
                results.append(IndexedFile(
                    url: url.standardizedFileURL,
                    name: url.lastPathComponent,
                    modifiedAt: mtime,
                    size: size
                ))
            }
        }
    }

    private nonisolated static func loadLocalGitignorePatterns(dir: URL) -> [String] {
        let gitignore = dir.appendingPathComponent(".gitignore")
        guard let content = try? String(contentsOf: gitignore, encoding: .utf8) else { return [] }
        return IgnoreList.parseGitignore(content)
    }
}
