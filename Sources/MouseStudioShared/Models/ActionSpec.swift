import Foundation

/// A declarative description of an action to perform, resolved from config.
/// `type` is a namespaced identifier like `"app.launch"` or `"clipboard.copy"`.
public struct ActionSpec: Codable, Equatable, Sendable {
    public let type: String
    public let params: [String: JSONValue]

    public init(type: String, params: [String: JSONValue] = [:]) {
        self.type = type
        self.params = params
    }

    /// The namespace portion of `type` (before the first dot), used to route to a provider.
    public var namespace: String {
        String(type.prefix { $0 != "." })
    }
}

/// Result of attempting an action. Actions never throw; they return one of these
/// so the engine can never be crashed by an action (TDD §15).
public enum ActionResult: Equatable, Sendable {
    case ok
    case ignored(reason: String)
    case failed(error: String)
}
