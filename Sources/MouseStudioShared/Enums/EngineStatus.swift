import Foundation

/// Lifecycle state of the automation engine (TDD §8.2).
public enum EngineStatus: String, Codable, Sendable, Hashable {
    case stopped
    case starting
    case running
    case permissionRequired
    case learning
    case reloading
}
