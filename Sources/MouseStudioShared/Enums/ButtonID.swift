import Foundation

/// Semantic mouse button identifiers. Raw device button numbers are normalized
/// into these by the event layer, isolating device specifics (TDD §5.1).
public enum ButtonID: String, Codable, CaseIterable, Sendable, Hashable {
    case left = "Left"
    case right = "Right"
    case middle = "Middle"
    case button4 = "Button4"
    case button5 = "Button5"

    /// Maps a macOS CGEvent mouse button number to a semantic button, when applicable.
    /// 0 = left, 1 = right, 2 = middle, 3 = Button4 (back), 4 = Button5 (forward).
    public init?(cgButtonNumber: Int) {
        switch cgButtonNumber {
        case 0: self = .left
        case 1: self = .right
        case 2: self = .middle
        case 3: self = .button4
        case 4: self = .button5
        default: return nil
        }
    }
}
