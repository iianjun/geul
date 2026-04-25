import CoreServices
import Foundation

enum HomeWatcherEvent {
    case changed(URL)
    case removed(URL)
    case rescanRequired
}

final class HomeWatcher {
    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "com.geul.homewatcher", qos: .utility)
    private var debounceWork: DispatchWorkItem?
    private var pendingEvents: [HomeWatcherEvent] = []
    private var currentRoots: [URL] = []
    private var gitignoreCache: [String: [String]] = [:]

    let onBatch: @Sendable ([HomeWatcherEvent]) -> Void

    init(onBatch: @escaping @Sendable ([HomeWatcherEvent]) -> Void) {
        self.onBatch = onBatch
    }

    func start(roots: [URL]) {
        stop()
        guard !roots.isEmpty else { return }
        let standardized = roots.map { $0.standardizedFileURL }
        queue.async { [weak self] in
            self?.currentRoots = standardized
            self?.gitignoreCache.removeAll()
        }
        let paths = standardized.map { $0.path } as CFArray

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        guard let createdStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            HomeWatcher.callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.2,
            UInt32(
                kFSEventStreamCreateFlagUseCFTypes |
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagNoDefer
            )
        ) else { return }

        FSEventStreamSetDispatchQueue(createdStream, queue)
        FSEventStreamStart(createdStream)
        stream = createdStream
    }

    func stop() {
        if let existing = stream {
            FSEventStreamStop(existing)
            FSEventStreamInvalidate(existing)
            FSEventStreamRelease(existing)
            stream = nil
        }
        queue.async { [weak self] in
            self?.debounceWork?.cancel()
            self?.debounceWork = nil
            self?.pendingEvents.removeAll()
            self?.gitignoreCache.removeAll()
            self?.currentRoots.removeAll()
        }
    }

    deinit { stop() }

    fileprivate func handle(paths: [String], flags: [FSEventStreamEventFlags]) {
        queue.async { [weak self] in
            guard let self else { return }
            for (path, flag) in zip(paths, flags) {
                let url = URL(fileURLWithPath: path).standardizedFileURL
                let mustRescan =
                    (flag & UInt32(kFSEventStreamEventFlagMustScanSubDirs)) != 0 ||
                    (flag & UInt32(kFSEventStreamEventFlagUserDropped)) != 0 ||
                    (flag & UInt32(kFSEventStreamEventFlagKernelDropped)) != 0 ||
                    (flag & UInt32(kFSEventStreamEventFlagRootChanged)) != 0
                if mustRescan {
                    pendingEvents.append(.rescanRequired)
                    continue
                }

                if url.pathComponents.contains(where: {
                    IgnoreList.directoryNames.contains($0)
                }) {
                    continue
                }

                let isDirectoryEvent =
                    (flag & UInt32(kFSEventStreamEventFlagItemIsDir)) != 0
                let renamedFlag =
                    (flag & UInt32(kFSEventStreamEventFlagItemRenamed)) != 0
                let removedFlag =
                    (flag & UInt32(kFSEventStreamEventFlagItemRemoved)) != 0
                if isDirectoryEvent && (renamedFlag || removedFlag) {
                    pendingEvents.append(.rescanRequired)
                    continue
                }

                let ext = url.pathExtension.lowercased()
                let isMarkdown = ["md", "markdown", "mdown", "mkd"].contains(ext)
                if !isMarkdown {
                    if renamedFlag { pendingEvents.append(.rescanRequired) }
                    continue
                }

                let excluded = currentRoots.contains { root in
                    IgnoreList.isIgnoredByAncestorGitignore(
                        url: url, underRoot: root, cache: &self.gitignoreCache)
                }
                if excluded { continue }

                let fileMissing = !FileManager.default.fileExists(atPath: path)
                if removedFlag || fileMissing {
                    pendingEvents.append(.removed(url))
                } else {
                    pendingEvents.append(.changed(url))
                }
            }
            scheduleFlush()
        }
    }

    private func scheduleFlush() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let batch = pendingEvents
            pendingEvents.removeAll()
            guard !batch.isEmpty else { return }
            DispatchQueue.main.async {
                self.onBatch(batch)
            }
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + 0.2, execute: work)
    }

    private static let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, _ in
        guard let info else { return }
        let watcher = Unmanaged<HomeWatcher>.fromOpaque(info).takeUnretainedValue()
        let cfArray = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue()
        guard let paths = cfArray as? [String] else { return }
        let flagBuf = UnsafeBufferPointer(start: eventFlags, count: numEvents)
        let flags = Array(flagBuf)
        watcher.handle(paths: paths, flags: flags)
    }
}
