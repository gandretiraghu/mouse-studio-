import Foundation
import MouseStudioShared

/// Bridges the Unix socket server to the `EngineHost` via `IPCRouter`, and
/// broadcasts live-tester buttons and status changes to connected GUI clients
/// (TDD §7.3, §10.2).
public final class SocketIPCServer {
    private let server: UnixSocketServer
    private let router: IPCRouter
    private let host: EngineHost

    public init(host: EngineHost, path: String = IPCSocketPath.default()) {
        self.host = host
        self.router = IPCRouter(host: host)
        self.server = UnixSocketServer(path: path)
    }

    public func start() throws {
        server.onRequest = { [router] request in
            router.handle(request)
        }
        // Push live-tester buttons and status changes to clients.
        host.onLearningButton = { [weak self] button in
            self?.server.broadcast(.liveButton(button))
        }
        host.onStatusChange = { [weak self] status in
            self?.server.broadcast(.engineStateChanged(status))
        }
        try server.start()
    }

    public func stop() {
        server.stop()
    }
}
