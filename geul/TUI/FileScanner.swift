import Foundation

struct FileEntry: Equatable {
    let url: URL            // 절대 경로
    let relativePath: String // 스캔 root 기준 상대 경로 (표시용)
    let depth: Int           // relativePath 내 '/' 개수
    let mtime: Date
}

enum FileScanner {
    static func scan(_ root: URL) -> [FileEntry] {
        let rootPath = root.standardizedFileURL.path
        var entries: [FileEntry] = []
        collect(at: root, rootPath: rootPath, into: &entries)
        entries.sort { lhs, rhs in
            if lhs.depth != rhs.depth { return lhs.depth < rhs.depth }
            return lhs.relativePath < rhs.relativePath
        }
        return entries
    }

    private static func collect(at dir: URL, rootPath: String, into entries: inout [FileEntry]) {
        let fileManager = FileManager.default
        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return // permission denied 등 — 해당 디렉토리 skip
        }

        for url in contents {
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                if IgnoreList.directoryNames.contains(url.lastPathComponent) { continue }
                collect(at: url, rootPath: rootPath, into: &entries)
            } else {
                guard url.pathExtension == "md" else { continue }
                let absPath = url.standardizedFileURL.path
                guard absPath.hasPrefix(rootPath + "/") || absPath == rootPath else { continue }
                let relative = String(absPath.dropFirst(rootPath.count + 1))
                let mtime = (try? url.resourceValues(
                    forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
                let depth = relative.filter { $0 == "/" }.count
                entries.append(FileEntry(
                    url: url, relativePath: relative, depth: depth, mtime: mtime
                ))
            }
        }
    }
}
