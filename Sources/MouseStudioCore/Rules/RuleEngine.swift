import Foundation
import MouseStudioShared

/// Compiles enabled rules into an O(1) trigger→rule lookup and resolves gestures
/// to rules at runtime. Priority decides the winner when rules share a trigger
/// key; lower-priority rules on the same key are reported as "shadowed"
/// (TDD §14, §19.3, §19.7).
///
/// The compile step (`load`) does all the sorting work; the runtime `match` is a
/// single hash lookup, keeping the dispatch hot path within the < 5 ms budget.
public final class RuleEngine {

    /// The identity of a trigger for lookup purposes.
    struct TriggerKey: Hashable {
        let button: ButtonID
        let gesture: GestureKind
        let chordWith: ButtonID?
    }

    private var compiled: [TriggerKey: Rule] = [:]
    private(set) public var shadowedRuleIDs: [String] = []

    public init() {}

    /// Compile the given rules. Only `enabled` rules participate. Within a shared
    /// trigger key, the highest `priority` wins; ties break by input order (stable).
    public func load(_ rules: [Rule]) {
        var map: [TriggerKey: Rule] = [:]
        var shadowed: [String] = []

        let ordered = rules
            .filter { $0.enabled }
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.priority != rhs.element.priority {
                    return lhs.element.priority > rhs.element.priority   // higher priority first
                }
                return lhs.offset < rhs.offset                            // stable tiebreak
            }
            .map { $0.element }

        for rule in ordered {
            let key = Self.key(for: rule.trigger)
            if map[key] == nil {
                map[key] = rule
            } else {
                shadowed.append(rule.id)   // a higher-priority rule already owns this key
            }
        }

        compiled = map
        shadowedRuleIDs = shadowed
    }

    /// Resolve a gesture to the winning rule, if any.
    public func match(_ gesture: Gesture) -> Rule? {
        compiled[Self.key(for: gesture)]
    }

    /// Buttons that have a `.double` trigger among the currently compiled rules.
    /// The state machine uses this to enable the double-click wait only where needed.
    public func doubleMappedButtons() -> Set<ButtonID> {
        var set: Set<ButtonID> = []
        for key in compiled.keys where key.gesture == .double {
            set.insert(key.button)
        }
        return set
    }

    /// Anchor buttons that own at least one rule. The event tap swallows the raw
    /// OS events for these so the mapped button doesn't also trigger its default
    /// system/app behavior (e.g. browser Back) — TDD §6.2.
    public func ownedButtons() -> Set<ButtonID> {
        Set(compiled.keys.map { $0.button })
    }

    public var ruleCount: Int { compiled.count }

    // MARK: - Key derivation

    private static func key(for trigger: TriggerSpec) -> TriggerKey {
        TriggerKey(
            button: trigger.button,
            gesture: trigger.gesture,
            chordWith: trigger.gesture == .chordClick ? trigger.chordWith : nil
        )
    }

    private static func key(for gesture: Gesture) -> TriggerKey {
        TriggerKey(
            button: gesture.anchor,
            gesture: gesture.kind,
            chordWith: gesture.kind == .chordClick ? gesture.chordButton : nil
        )
    }
}
