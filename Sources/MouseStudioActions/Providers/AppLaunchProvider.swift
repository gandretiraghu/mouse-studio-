import Foundation
import MouseStudioCore
import MouseStudioShared

/// Launches and switches between applications (TDD Application Manager).
public final class AppLaunchProvider: ActionProvider {
    public let namespace = "app"
    private let app: AppControlling

    public init(app: AppControlling) { self.app = app }

    public func supportedActions() -> [ActionDescriptor] {
        let bundleParam = ParamSpec(key: "bundleID", displayName: "Application", kind: .appBundleID)
        return [
            ActionDescriptor(type: "app.launch", displayName: "Launch Application",
                             params: [bundleParam], category: "App"),
            ActionDescriptor(type: "app.switch", displayName: "Switch to Application",
                             params: [bundleParam], category: "App")
        ]
    }

    public func perform(_ spec: ActionSpec) -> ActionResult {
        guard let bundleID = spec.params["bundleID"]?.stringValue, !bundleID.isEmpty else {
            return .failed(error: "missing 'bundleID'")
        }
        let ok: Bool
        switch spec.type {
        case "app.launch": ok = app.launch(bundleID: bundleID)
        case "app.switch": ok = app.activate(bundleID: bundleID)
        default: return .ignored(reason: "unknown action \(spec.type)")
        }
        return ok ? .ok : .failed(error: "could not resolve app \(bundleID)")
    }
}
