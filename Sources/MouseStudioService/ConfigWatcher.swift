import Foundation

/// Watches the configuration directory and fires (debounced) when files change,
/// so edits made by the GUI are applied to the running engine live — a simple,
/// transport-free GUI↔service link for config changes (TDD §7.4).
public final class ConfigWatcher {
    private let directory: URL
    private let onChange: () -> Void
    private let debounceMs: Int

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var pending: DispatchWorkItem?

    public init(directory: URL, debounceMs: Int = 300, onChange: @escaping () -> Void) {
        self.directory = directory
        self.debounceMs = debounceMs
        self.onChange = onChange
    }

    public func start() {
        stop()
        fileDescriptor = open(directory.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: .main
        )
        src.setEventHandler { [weak self] in self?.scheduleChange() }
        src.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 { close(fd) }
            self?.fileDescriptor = -1
        }
        source = src
        src.resume()
    }

    public func stop() {
        source?.cancel()
        source = nil
    }

    private func scheduleChange() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(debounceMs), execute: work)
    }

    deinit { stop() }
}
