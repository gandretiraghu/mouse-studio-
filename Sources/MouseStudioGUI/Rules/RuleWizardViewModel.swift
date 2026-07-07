import Foundation
import MouseStudioShared

/// Drives the beginner Rule Creation Wizard: a small step machine that collects
/// a trigger + action and produces a valid `Rule` (TDD §19.1).
public final class RuleWizardViewModel: ObservableObject {
    public enum Step: Int, CaseIterable {
        case button, gesture, action, params, review
    }

    @Published public var step: Step = .button
    @Published public var button: ButtonID?
    @Published public var gesture: GestureKind?
    @Published public var chordWith: ButtonID?
    @Published public var actionType: String?
    @Published public var params: [String: JSONValue] = [:]

    public init() {}

    /// Whether the current step has enough input to advance.
    public var canAdvance: Bool {
        switch step {
        case .button:  return button != nil
        case .gesture:
            guard gesture != nil else { return false }
            // A chord-click needs a partner button.
            if gesture == .chordClick { return chordWith != nil }
            return true
        case .action:  return actionType != nil
        case .params:  return requiredParamsSatisfied
        case .review:  return true
        }
    }

    public func advance() {
        guard canAdvance, let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    public func back() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        step = prev
    }

    /// Build the rule if all inputs are present.
    public func buildRule(id: String = UUID().uuidString) -> Rule? {
        guard let button, let gesture, let actionType else { return nil }
        if gesture == .chordClick && chordWith == nil { return nil }
        guard requiredParamsSatisfied else { return nil }
        return Rule(
            id: id,
            trigger: TriggerSpec(button: button, gesture: gesture,
                                 chordWith: gesture == .chordClick ? chordWith : nil),
            action: ActionSpec(type: actionType, params: params)
        )
    }

    /// A plain-language summary for the review step.
    public var summary: String {
        let gestureText = gesture?.rawValue ?? "?"
        let buttonText = button?.rawValue ?? "?"
        let actionText = actionType.flatMap { ActionCatalog.descriptor(for: $0)?.displayName } ?? (actionType ?? "?")
        return "\(gestureText) on \(buttonText) → \(actionText)"
    }

    private var requiredParamsSatisfied: Bool {
        guard let actionType, let descriptor = ActionCatalog.descriptor(for: actionType) else { return true }
        for spec in descriptor.params where spec.required {
            guard let value = params[spec.key] else { return false }
            if let text = value.stringValue, text.isEmpty { return false }
        }
        return true
    }
}
