import Foundation
import MouseStudioShared

/// The contract every action module conforms to. This is the seam that the
/// future plugin system plugs into — new providers register with the dispatcher
/// without any change to the core engine (TDD §5.2, §10.1, §17).
///
/// Implementations MUST NOT throw and MUST be safe to call on the engine queue;
/// they return an `ActionResult` describing the outcome.
public protocol ActionProvider: AnyObject {
    /// The namespace this provider owns, e.g. "app", "clipboard", "volume".
    var namespace: String { get }

    /// UI metadata for the GUI Action Browser and parameter forms.
    func supportedActions() -> [ActionDescriptor]

    /// Execute the given action spec. Never throws.
    func perform(_ spec: ActionSpec) -> ActionResult
}
