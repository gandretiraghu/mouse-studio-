import Foundation
import MouseStudioShared

/// Structured logger with a level threshold, a bounded in-memory ring buffer
/// (for the GUI Logs view), and lightweight perf timing (TDD §5.1, §14, §15).
///
/// Thread-safe via a small lock; log calls are cheap and never allocate on the
/// event-tap hot path (perf logging is opt-in).
public final class Logger {
    private let lock = NSLock()
    private var _level: LogLevel
    private var buffer: [LogEntry]
    private let capacity: Int
    /// Optional sink for out-of-process forwarding / stdout in the service.
    public var sink: ((LogEntry) -> Void)?

    public init(level: LogLevel = .info, capacity: Int = 2000) {
        self._level = level
        self.capacity = max(1, capacity)
        self.buffer = []
        self.buffer.reserveCapacity(self.capacity)
    }

    public var level: LogLevel {
        get { lock.lock(); defer { lock.unlock() }; return _level }
        set { lock.lock(); _level = newValue; lock.unlock() }
    }

    public func setLevel(_ level: LogLevel) {
        self.level = level
    }

    public func debug(_ message: @autoclosure () -> String, subsystem: String = "core") {
        log(.debug, subsystem, message)
    }

    public func info(_ message: @autoclosure () -> String, subsystem: String = "core") {
        log(.info, subsystem, message)
    }

    public func warn(_ message: @autoclosure () -> String, subsystem: String = "core") {
        log(.warn, subsystem, message)
    }

    public func error(_ message: @autoclosure () -> String, subsystem: String = "core") {
        log(.error, subsystem, message)
    }

    /// Log the elapsed time (ms) since `startNanos` under `label`, at debug level.
    public func perf(_ label: String, since startNanos: UInt64, subsystem: String = "perf") {
        guard level <= .debug else { return }
        let elapsedMs = Double(DispatchTime.now().uptimeNanoseconds &- startNanos) / 1_000_000.0
        log(.debug, subsystem, { String(format: "%@ took %.3f ms", label, elapsedMs) })
    }

    /// Most recent entries, newest last, capped at `limit`.
    public func recent(_ limit: Int = 200) -> [LogEntry] {
        lock.lock(); defer { lock.unlock() }
        return Array(buffer.suffix(max(0, limit)))
    }

    // MARK: - Internal

    private func log(_ level: LogLevel, _ subsystem: String, _ message: () -> String) {
        lock.lock()
        guard level >= _level else { lock.unlock(); return }
        let entry = LogEntry(level: level, subsystem: subsystem, message: message())
        buffer.append(entry)
        if buffer.count > capacity {
            buffer.removeFirst(buffer.count - capacity)
        }
        let sink = self.sink
        lock.unlock()
        sink?(entry)
    }
}
