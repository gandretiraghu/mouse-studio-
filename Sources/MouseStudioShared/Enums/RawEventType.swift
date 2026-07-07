import Foundation

/// The kind of a normalized low-level input event fed into the state machine.
public enum RawEventType: String, Codable, Sendable, Hashable {
    case buttonDown
    case buttonUp
    case scroll
}
