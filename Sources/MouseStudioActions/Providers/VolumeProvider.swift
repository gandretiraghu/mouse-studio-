import Foundation
import MouseStudioCore
import MouseStudioShared

/// System output volume control via AppleScript (TDD Volume Module).
public final class VolumeProvider: ActionProvider {
    public let namespace = "volume"
    private let script: ScriptRunning
    private let step: Int

    public init(script: ScriptRunning, step: Int = 6) {
        self.script = script
        self.step = step
    }

    public func supportedActions() -> [ActionDescriptor] {
        [
            ActionDescriptor(type: "volume.up", displayName: "Volume Up", category: "Volume"),
            ActionDescriptor(type: "volume.down", displayName: "Volume Down", category: "Volume"),
            ActionDescriptor(type: "volume.mute", displayName: "Toggle Mute", category: "Volume")
        ]
    }

    public func perform(_ spec: ActionSpec) -> ActionResult {
        let source: String
        switch spec.type {
        case "volume.up":
            source = "set volume output volume ((output volume of (get volume settings)) + \(step))"
        case "volume.down":
            source = "set volume output volume ((output volume of (get volume settings)) - \(step))"
        case "volume.mute":
            source = "set volume output muted (not (output muted of (get volume settings)))"
        default:
            return .ignored(reason: "unknown action \(spec.type)")
        }
        return script.run(source) ? .ok : .failed(error: "volume script failed")
    }
}
