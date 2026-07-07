import Foundation
import MouseStudioShared
#if canImport(Darwin)
import Darwin
#endif

/// Connects to the background service's Unix domain socket. Requests are answered
/// synchronously (with a timeout); pushed events arrive on a background read loop
/// and are delivered via `onEvent` (TDD §10.2).
public final class SocketIPCClient: IPCClient {
    public var onEvent: ((IPCEvent) -> Void)?

    private var fd: Int32 = -1
    private let sendLock = NSLock()
    private let responseLock = NSLock()
    private var pendingResponse: IPCResponse?
    private let responseSem = DispatchSemaphore(value: 0)
    private let decoder = FrameDecoder()
    private let timeout: TimeInterval

    /// Returns nil if the socket can't be reached (caller falls back to a stub).
    public init?(path: String = IPCSocketPath.default(), timeout: TimeInterval = 2.0) {
        self.timeout = timeout
        guard connect(to: path) else { return nil }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in self?.readLoop() }
    }

    deinit { if fd >= 0 { close(fd) } }

    public func send(_ request: IPCRequest) -> IPCResponse {
        sendLock.lock(); defer { sendLock.unlock() }
        guard fd >= 0, let data = try? IPCFraming.encode(.request(request)) else {
            return .error("not connected")
        }
        responseLock.lock(); pendingResponse = nil; responseLock.unlock()
        guard writeAll(data) else { return .error("write failed") }

        if responseSem.wait(timeout: .now() + timeout) == .timedOut {
            return .error("timeout")
        }
        responseLock.lock(); let response = pendingResponse; responseLock.unlock()
        return response ?? .error("no response")
    }

    // MARK: - Private

    private func connect(to path: String) -> Bool {
        fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        _ = withUnsafeMutablePointer(to: &addr.sun_path) {
            $0.withMemoryRebound(to: CChar.self, capacity: 104) { dst in
                strncpy(dst, path, 103)
            }
        }
        let size = socklen_t(MemoryLayout<sockaddr_un>.size)
        let rc = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.connect(fd, $0, size) }
        }
        if rc != 0 { close(fd); fd = -1; return false }
        return true
    }

    private func readLoop() {
        var buf = [UInt8](repeating: 0, count: 8192)
        while fd >= 0 {
            let n = read(fd, &buf, buf.count)
            if n <= 0 { break }
            let chunk = Data(buf[0..<n])
            guard let messages = try? decoder.feed(chunk) else { break }
            for message in messages {
                switch message {
                case .response(let response):
                    responseLock.lock(); pendingResponse = response; responseLock.unlock()
                    responseSem.signal()
                case .event(let event):
                    onEvent?(event)
                case .request:
                    break   // clients never receive requests
                }
            }
        }
    }

    @discardableResult
    private func writeAll(_ data: Data) -> Bool {
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

/// Returns a live socket client if the service is reachable, otherwise a stub so
/// the GUI still works for offline config editing.
public func makeIPCClient(path: String = IPCSocketPath.default()) -> IPCClient {
    SocketIPCClient(path: path) ?? StubIPCClient(status: .stopped)
}
