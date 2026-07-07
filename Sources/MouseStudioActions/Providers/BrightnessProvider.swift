import Foundation
import MouseStudioCore
import MouseStudioShared

/// Display brightness control via system-defined media keys (TDD Brightness Module).
public final class BrightnessProvider: ActionProvider {
    public let namespace = "brightness"
    private let systemKey: SystemKeyPosting

    public init(systemKey: SystemKeyPosting) { self.systemKey = systemKey }

    public func supportedActions() -> [ActionDescriptor] {
        [
            ActionDescriptor(type: "brightness.up", displayName: "Brightness Up", category: "Brightness"),
            ActionDescriptor(type: "brightness.down", displayName: "Brightness Down", category: "Brightness")
        ]
    }

    public func perform(_ spec: ActionSpec) -> ActionResult {
        switch spec.type {
        case "brightness.up": systemKey.postBrightnessUp()
        case "brightness.down": systemKey.postBrightnessDown()
        default: return .ignored(reason: "unknown action \(spec.type)")
        }
        return .ok
    }
}
