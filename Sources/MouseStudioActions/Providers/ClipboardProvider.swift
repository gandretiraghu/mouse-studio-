import Foundation
import MouseStudioCore
import MouseStudioShared

/// Clipboard and editing actions, emitted as standard keyboard shortcuts
/// (TDD Clipboard Module).
public final class ClipboardProvider: ActionProvider {
    public let namespace = "clipboard"
    private let keyboard: KeyboardShortcutEmitting

    private static let shortcuts: [String: String] = [
        "clipboard.copy": "cmd+c",
        "clipboard.paste": "cmd+v",
        "clipboard.cut": "cmd+x",
        "clipboard.undo": "cmd+z",
        "clipboard.redo": "cmd+shift+z",
        "clipboard.selectAll": "cmd+a"
    ]

    public init(keyboard: KeyboardShortcutEmitting) { self.keyboard = keyboard }

    public func supportedActions() -> [ActionDescriptor] {
        Self.shortcuts.keys.sorted().map {
            ActionDescriptor(type: $0, displayName: $0.replacingOccurrences(of: "clipboard.", with: "").capitalized, category: "Clipboard")
        }
    }

    public func perform(_ spec: ActionSpec) -> ActionResult {
        guard let combo = Self.shortcuts[spec.type], let shortcut = KeyShortcut(parsing: combo) else {
            return .ignored(reason: "unknown action \(spec.type)")
        }
        keyboard.emit(shortcut)
        return .ok
    }
}
