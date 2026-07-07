import Foundation
import MouseStudioShared

/// The GUI's connection to the background service. A concrete transport (local
/// socket / XPC) is wired when the apps are packaged together; the GUI is coded
/// against this protocol so it stays decoupled and testable (TDD §10.2).
public protocol IPCClient: AnyObject {
    /// Send a request and receive the service's response.
    func send(_ request: IPCRequest) -> IPCResponse
    /// Push channel for asynchronous events (live tester buttons, status).
    var onEvent: ((IPCEvent) -> Void)? { get set }
}

/// A no-op / in-memory client used for previews, tests, and when the service is
/// not reachable. Records sent requests and can emit events on demand.
public final class StubIPCClient: IPCClient {
    public var onEvent: ((IPCEvent) -> Void)?
    public private(set) var sent: [IPCRequest] = []
    public var status: EngineStatus
    public var logs: [LogEntry]

    public init(status: EngineStatus = .running, logs: [LogEntry] = []) {
        self.status = status
        self.logs = logs
    }

    public func send(_ request: IPCRequest) -> IPCResponse {
        sent.append(request)
        switch request {
        case .getStatus: return .status(status)
        case .getRecentLogs: return .logs(logs)
        case .testRule(let rule):
            return .testResult(TestResult(matched: true, actionType: rule.action.type))
        default:
            return .ack
        }
    }

    /// Simulate a live button press coming from the service (for the Live Tester).
    public func emitLiveButton(_ button: ButtonID) {
        onEvent?(.liveButton(button))
    }
}
