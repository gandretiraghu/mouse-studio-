import Foundation

/// Resolved gesture kinds emitted by the state machine (TDD §8).
public enum GestureKind: String, Codable, CaseIterable, Sendable, Hashable {
    case single
    case double
    case long
    case chordClick
    case chordScrollUp
    case chordScrollDown
}
