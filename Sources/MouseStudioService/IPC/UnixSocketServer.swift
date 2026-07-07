import Foundation
import MouseStudioShared
#if canImport(Darwin)
import Darwin
#endif

/// A minimal AF_UNIX SOCK_STREAM server. Accepts multiple clients, decodes framed
/// `IPCMessage`s, answers requests via `onRequest`, and can broadcast events to
/// all connected clients (TDD §11, §13). Runtime-only (not exercised on CI).
public final class UnixSocketServer {
    private let path: String
    private var listenFD: Int32 = -1
    private var clientFDs: [Int32] = []
    private let lock = NSLock()
    private var running = false

    /// Answers a request with a response (called on a background queue).
    public var onRequest: ((IPCRequest) -> IPCResponse)?

    public init(path: String) {
        self.path = path
    }

    public func start() throws {
        // Ensure the parent directory exists and remove any stale socket file.
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        unlink(path)

        listenFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard listenFD >= 0 else { throw POSIXError(.EADDRNOTAVAIL) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        _ = withUnsafeMutablePointer(to: &addr.sun_path) {
            $0.withMemoryRebound(to: CChar.self, capacity: 104) { dst in
                strncpy(dst, path, 103)
            }
        }
        let size = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(listenFD, $0, size) }
        }
        guard bindResult == 0 else {
            close(listenFD); listenFD = -1
            throw POSIXError(.EADDRINUSE)
        }
        guard listen(listenFD, 8) == 0 else {
            close(listenFD); listenFD = -1
            throw POSIXError(.EADDRINUSE)
        }
        // Restrict the socket to the current user.
        chmod(path, 0o600)

        running = true
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.acceptLoop() }
    }

    public func stop() {
        running = false
        lock.lock()
        for fd in clientFDs { close(fd) }
        clientFDs.removeAll()
        lock.unlock()
        if listenFD >= 0 { close(listenFD); listenFD = -1 }
        unlink(path)
    }

    /// Send an event to every connected client.
    public func broadcast(_ event: IPCEvent) {
        guard let data = try? IPCFraming.encode(.event(event)) else { return }
        lock.lock(); let fds = clientFDs; lock.unlock()
        for fd in fds { _ = writeAll(fd, data) }
    }

    // MARK: - Private

    private func acceptLoop() {
        while running {
            let clientFD = accept(listenFD, nil, nil)
            if clientFD < 0 {
                if running { usleep(50_000); continue } else { break }
            }
            lock.lock(); clientFDs.append(clientFD); lock.unlock()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.readLoop(clientFD)
            }
        }
    }

    private func readLoop(_ fd: Int32) {
        let decoder = FrameDecoder()
        var buf = [UInt8](repeating: 0, count: 8192)
        while running {
            let n = read(fd, &buf, buf.count)
            if n <= 0 { break }
            let chunk = Data(buf[0..<n])
            guard let messages = try? decoder.feed(chunk) else { break }
            for message in messages {
                guard case .request(let request) = message else { continue }
                let response = onRequest?(request) ?? .error("no handler")
                if let out = try? IPCFraming.encode(.response(response)) {
                    _ = writeAll(fd, out)
                }
            }
        }
        lock.lock(); clientFDs.removeAll { $0 == fd }; lock.unlock()
        close(fd)
    }

    @discardableResult
    private func writeAll(_ fd: Int32, _ data: Data) -> Bool {
        data.withUnsafeBytes { raw -> Bool in
            guard let base = raw.baseAddress else { return false }
            var offset = 0
            let total = raw.count
            while offset < total {
                let written = write(fd, base + offset, total - offset)
                if written <= 0 { return false }
                offset += written
            }
            return true
        }
    }
}
