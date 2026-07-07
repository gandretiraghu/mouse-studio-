import Foundation
import MouseStudioCore
import MouseStudioShared

/// Spaces / Mission Control / Launchpad actions (TDD Desktop Module).
///
/// Space switching and Mission Control use the standard system shortcuts, which
/// must be enabled in System Settings › Keyboard Shortcuts (documented in the
/// GUI). Launchpad is opened via `open`.
public final class DesktopProvider: ActionProvider {
    public let namespace = "desktop"
    private let keyboard: KeyboardShortcutEmitting
    private let process: ProcessRunning

    public init(keyboard: KeyboardShortcutEmitting, process: ProcessRunning) {
        self.keyboard = keyboard
        self.process = process
    }

    public func supportedActions() -> [ActionDescriptor] {
        [
            ActionDescriptor(type: "desktop.nextSpace", displayName: "Next Desktop", category: "Desktop"),
            ActionDescriptor(type: "desktop.prevSpace", displayName: "Previous Desktop", category: "Desktop"),
            ActionDescriptor(type: "desktop.missionControl", displayName: "Mission Control", category: "Desktop"),
            ActionDescriptor(type: "desktop.showDesktop", displayName: "Show Desktop", category: "Desktop"),
            ActionDescriptor(type: "desktop.launchpad", displayName: "Launchpad", category: "Desktop")
        ]
    }

    public func perform(_ spec: ActionSpec) -> ActionResult {
        switch spec.type {
        case "desktop.nextSpace":
            return emit("ctrl+right")
        case "desktop.prevSpace":
            return emit("ctrl+left")
        case "desktop.missionControl":
            return emit("ctrl+up")
        case "desktop.showDesktop":
            return emit("f11")
        case "desktop.launchpad":
            return process.run("/usr/bin/open", ["-a", "Launchpad"]) ? .ok : .failed(error: "could not open Launchpad")
        default:
            return .ignored(reason: "unknown action \(spec.type)")
        }
    }

    private func emit(_ combo: String) -> ActionResult {
        guard let shortcut = KeyShortcut(parsing: combo) else {
            return .failed(error: "bad shortcut \(combo)")
        }
        keyboard.emit(shortcut)
        return .ok
    }
}
