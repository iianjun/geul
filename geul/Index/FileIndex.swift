import AppKit
import Foundation

@MainActor
final class FileIndex: ObservableObject {
    static let shared = FileIndex()

    @Published private(set) var files: [IndexedFile]
    @Published private(set) var isScanning: Bool = false

    private let scanner: HomeScanner
    private var watcher: HomeWatcher?
    private var unmountObserver: NSObjectProtocol?
    private var currentRoots: [URL] = []
    private var scanTask: Task<Void, Never>?
    private var scanGeneration = 0

    init(files: [IndexedFile] = [], scanner: HomeScanner = HomeScanner()) {
        self.files = files
        self.scanner = scanner
        observeVolumeUnmount()
    }

    private func observeVolumeUnmount() {
        unmountObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didUnmountNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let volumeURL = note.userInfo?[NSWorkspace.volumeURLUserInfoKey]
                    as? URL else { return }
            Task { @MainActor in self.purgeFiles(underPathPrefix: volumeURL.path) }
        }
    }

    private func purgeFiles(underPathPrefix prefix: String) {
        files.removeAll { $0.url.path.hasPrefix(prefix) }
    }

    deinit {
        if let token = unmountObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
    }

    // MARK: - Bootstrap / rescan

    func bootstrap(roots: [URL]) {
        rescan(roots: roots)
    }

    func rescan(roots: [URL]) {
        let liveRoots = roots.filter { FileManager.default.fileExists(atPath: $0.path) }
        currentRoots = liveRoots
        scanGeneration += 1
        let generation = scanGeneration
        scanTask?.cancel()
        watcher?.stop()
        watcher = nil
        isScanning = true
        scanTask = Task { @MainActor in
            let newFiles = (try? await scanner.scan(roots: liveRoots)) ?? []
            guard !Task.isCancelled, generation == self.scanGeneration else { return }
            self.files = newFiles
            self.isScanning = false
            guard !liveRoots.isEmpty else { return }
            let newWatcher = HomeWatcher { [weak self] batch in
                Task { @MainActor in self?.applyBatch(batch) }
            }
            newWatcher.start(roots: liveRoots)
            self.watcher = newWatcher
        }
    }

    // MARK: - Mutations

    func insert(_ file: IndexedFile) {
        if let idx = files.firstIndex(where: { $0.url == file.url }) {
            files[idx] = file
        } else {
            files.append(file)
        }
    }

    func remove(at url: URL) {
        files.removeAll { $0.url == url }
    }

    // MARK: - Search

    func search(_ query: String, limit: Int) -> [IndexedFile] {
        guard !query.isEmpty else { return [] }
        let lowercaseQuery = query.lowercased()
        let scored: [(IndexedFile, Int)] = files.compactMap { file in
            if let result = FuzzyMatcher.score(query: lowercaseQuery, in: file.name) {
                return (file, result.score + 10)
            }
            if let result = FuzzyMatcher.score(query: lowercaseQuery, in: file.url.path) {
                return (file, result.score)
            }
            return nil
        }
        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    // MARK: - Private

    private func applyBatch(_ events: [HomeWatcherEvent]) {
        for event in events {
            switch event {
            case .changed(let url):
                if let file = makeIndexedFile(from: url) {
                    insert(file)
                }
            case .removed(let url):
                remove(at: url)
            case .rescanRequired:
                rescan(roots: currentRoots)
                return
            }
        }
    }

    private func makeIndexedFile(from url: URL) -> IndexedFile? {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey]
        guard let values = try? url.resourceValues(forKeys: keys) else { return nil }
        return IndexedFile(
            url: url.standardizedFileURL,
            name: url.lastPathComponent,
            modifiedAt: values.contentModificationDate ?? Date(),
            size: Int64(values.fileSize ?? 0)
        )
    }
}
