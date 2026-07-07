import Foundation

/// Result of a dry-run rule test (TDD §19.4).
public struct TestResult: Codable, Equatable, Sendable {
    public let matched: Bool
    public let actionType: String?
    public let error: String?

    public init(matched: Bool, actionType: String? = nil, error: String? = nil) {
        self.matched = matched
        self.actionType = actionType
        self.error = error
    }
}

/// Requests the GUI sends to the background service (TDD §10.2).
/// Swift synthesizes `Codable` for enums with associated values.
public enum IPCRequest: Codable, Equatable, Sendable {
    case getStatus
    case reloadConfig
    case setActiveProfile(String)
    case enterLearningMode
    case exitLearningMode
    case getRecentLogs(limit: Int)
    case pauseEngine
    case resumeEngine
    case testRule(Rule)
}

/// Responses the service sends back.
public enum IPCResponse: Codable, Equatable, Sendable {
    case status(EngineStatus)
    case ack
    case logs([LogEntry])
    case testResult(TestResult)
    case error(String)
}

/// Asynchronous events the service pushes to subscribed GUI clients.
public enum IPCEvent: Codable, Equatable, Sendable {
    case liveButton(ButtonID)
    case engineStateChanged(EngineStatus)
}
