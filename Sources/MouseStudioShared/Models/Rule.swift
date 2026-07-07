import Foundation

/// The trigger portion of a rule: which button + gesture (+ optional chord partner)
/// fires it (TDD §9.2).
public struct TriggerSpec: Codable, Equatable, Sendable, Hashable {
    public let button: ButtonID
    public let gesture: GestureKind
    /// Required only for `.chordClick` (the secondary button); nil otherwise.
    public let chordWith: ButtonID?

    public init(button: ButtonID, gesture: GestureKind, chordWith: ButtonID? = nil) {
        self.button = button
        self.gesture = gesture
        self.chordWith = chordWith
    }
}

/// A single configurable mapping from a trigger to an action (TDD §9.2, §19.7).
public struct Rule: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var enabled: Bool
    /// Higher priority wins when two enabled rules share a trigger key. Default 0.
    public var priority: Int
    public let trigger: TriggerSpec
    public let action: ActionSpec

    public init(
        id: String,
        enabled: Bool = true,
        priority: Int = 0,
        trigger: TriggerSpec,
        action: ActionSpec
    ) {
        self.id = id
        self.enabled = enabled
        self.priority = priority
        self.trigger = trigger
        self.action = action
    }

    private enum CodingKeys: String, CodingKey {
        case id, enabled, priority, trigger, action
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        priority = try c.decodeIfPresent(Int.self, forKey: .priority) ?? 0
        trigger = try c.decode(TriggerSpec.self, forKey: .trigger)
        action = try c.decode(ActionSpec.self, forKey: .action)
    }
}
