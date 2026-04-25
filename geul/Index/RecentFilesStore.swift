import Foundation

struct RecentEntry: Codable, Equatable {
    let path: String
    let openedAt: Date
}

@MainActor
final class RecentFilesStore: ObservableObject {
    static let shared = RecentFilesStore()

    @Published private(set) var items: [RecentEntry] = []

    private let configDir: URL
    private let recentURL: URL
    private let capacity: Int
    private var persistWork: DispatchWorkItem?

    init(
        configDir: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/geul"),
        capacity: Int = 10
    ) {
        self.configDir = configDir
        self.recentURL = configDir.appendingPathComponent("recent.json")
        self.capacity = capacity
        self.items = Self.loadPruned(url: recentURL)
    }

    func bump(_ url: URL) {
        let path = url.standardizedFileURL.path
        var updated = items.filter { $0.path != path }
        updated.insert(RecentEntry(path: path, openedAt: Date()), at: 0)
        if updated.count > capacity {
            updated = Array(updated.prefix(capacity))
        }
        items = updated
        schedulePersist()
    }

    func flush() {
        persistWork?.cancel()
        persistNow()
    }

    func flushForTesting() {
        flush()
    }

    // MARK: - Private

    nonisolated private static func loadPruned(url: URL) -> [RecentEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let entries = try decoder.decode([RecentEntry].self, from: data)
            let manager = FileManager.default
            return entries.filter { manager.fileExists(atPath: $0.path) }
        } catch {
            let bak = url.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: bak)
            try? FileManager.default.moveItem(at: url, to: bak)
            print("[geul] recent.json could not be decoded — backed up to \(bak.lastPathComponent). Error: \(error)")
            return []
        }
    }

    private func schedulePersist() {
        persistWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in self?.persistNow() }
        }
        persistWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: work)
    }

    private func persistNow() {
        do {
            try FileManager.default.createDirectory(
                at: configDir, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            try data.write(to: recentURL, options: .atomic)
        } catch {
            print("[geul] Failed to persist recent.json: \(error)")
        }
    }
}
