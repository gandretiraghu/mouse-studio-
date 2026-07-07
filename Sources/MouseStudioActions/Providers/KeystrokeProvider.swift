import Foundation
import MouseStudioCore
import MouseStudioShared

/// Sends an arbitrary configured keyboard shortcut (e.g. browser back "cmd+[")
/// — TDD Action System "Keyboard Shortcut".
public final class KeystrokeProvider: ActionProvider {
    public let namespace = "keystroke"
    private let keyboard: KeyboardShortcutEmitting

    public init(keyboard: KeyboardShortcutEmitting) { self.keyboard = keyboard }

    public func supportedActions() -> [ActionDescriptor] {
        [ActionDescriptor(
            type: "keystroke.send",
            displayName: "Send Keyboard Shortcut",
            params: [ParamSpec(key: "keys", displayName: "Keys (e.g. cmd+[)", kind: .string)],
            category: "Keyboard"
        )]
    }

    public func perform(_ spec: ActionSpec) -> ActionResult {
        guard spec.type == "keystroke.send" else {
            return .ignored(reason: "unknown action \(spec.type)")
        }
        guard let keys = spec.params["keys"]?.stringValue, let shortcut = KeyShortcut(parsing: keys) else {
            return .failed(error: "invalid or missing 'keys'")
        }
        keyboard.emit(shortcut)
        return .ok
    }
}
