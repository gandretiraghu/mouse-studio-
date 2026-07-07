import Foundation
import MouseStudioShared

/// Maps `IPCRequest`s to actions on the `EngineHost` and produces `IPCResponse`s
/// (TDD §10.2). This is the transport-independent core of the IPC server; the
/// concrete transport (XPC / local socket) wraps it in a later phase.
public final class IPCRouter {
    private let host: EngineHost

    public init(host: EngineHost) {
        self.host = host
    }

    public func handle(_ request: IPCRequest) -> IPCResponse {
        switch request {
        case .getStatus:
            return .status(host.status)
        case .reloadConfig:
            host.reloadConfig()
            return .ack
        case .setActiveProfile(let id):
            host.setActiveProfile(id)
            return .ack
        case .enterLearningMode:
            host.enterLearningMode()
            return .ack
        case .exitLearningMode:
            host.exitLearningMode()
            return .ack
        case .getRecentLogs(let limit):
            return .logs(host.recentLogs(limit: limit))
        case .pauseEngine:
            host.pause()
            return .ack
        case .resumeEngine:
            host.resume()
            return .ack
        case .testRule(let rule):
            return .testResult(host.testRule(rule))
        }
    }
}
