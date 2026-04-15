import Foundation

final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private let onDelete: (Bool) -> Void

    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var pollingTimer: DispatchSourceTimer?
    private var debounceWork: DispatchWorkItem?

    private let queue = DispatchQueue(label: "com.geul.filewatcher", qos: .utility)

    init(url: URL, onChange: @escaping () -> Void, onDelete: @escaping (Bool) -> Void) {
        self.url = url
        self.onChange = onChange
        self.onDelete = onDelete
    }

    func start() {
        startMonitoring()
    }

    func stop() {
        source?.cancel()
        source = nil
        pollingTimer?.cancel()
        pollingTimer = nil
        debounceWork?.cancel()
        debounceWork = nil
        closeDescriptor()
    }

    deinit {
        stop()
    }

    // MARK: - Private

    private func startMonitoring() {
        let path = url.path
        let fileDesc = open(path, O_EVTONLY)
        guard fileDesc >= 0 else { return }
        fileDescriptor = fileDesc

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDesc,
            eventMask: [.write, .delete, .rename],
            queue: queue
        )

        src.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = src.data

            if flags.contains(.delete) || flags.contains(.rename) {
                self.handleDeletion()
            } else if flags.contains(.write) {
                self.scheduleDebounce()
            }
        }

        src.setCancelHandler { [weak self] in
            self?.closeDescriptor()
        }

        source = src
        src.resume()
    }

    private func scheduleDebounce() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { self.onChange() }
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    private func handleDeletion() {
        source?.cancel()
        source = nil

        DispatchQueue.main.async { self.onDelete(true) }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            if FileManager.default.fileExists(atPath: self.url.path) {
                self.pollingTimer?.cancel()
                self.pollingTimer = nil
                DispatchQueue.main.async { self.onDelete(false) }
                self.startMonitoring()
                self.scheduleDebounce()
            }
        }
        pollingTimer = timer
        timer.resume()
    }

    private func closeDescriptor() {
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }
}
