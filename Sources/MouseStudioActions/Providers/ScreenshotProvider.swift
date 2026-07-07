import Foundation
import MouseStudioCore
import MouseStudioShared

/// Screenshot actions via the system `screencapture` tool (TDD Screenshot Module).
public final class ScreenshotProvider: ActionProvider {
    public let namespace = "screenshot"
    private let process: ProcessRunning
    private let destinationDirectory: URL

    private static let tool = "/usr/sbin/screencapture"

    public init(process: ProcessRunning, destinationDirectory: URL? = nil) {
        self.process = process
        self.destinationDirectory = destinationDirectory
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }

    public func supportedActions() -> [ActionDescriptor] {
        [
            ActionDescriptor(type: "screenshot.area", displayName: "Screenshot: Selected Area", category: "Screenshot"),
            ActionDescriptor(type: "screenshot.window", displayName: "Screenshot: Window", category: "Screenshot"),
            ActionDescriptor(type: "screenshot.clipboard", displayName: "Screenshot: Area to Clipboard", category: "Screenshot"),
            ActionDescriptor(type: "screenshot.desktop", displayName: "Screenshot: Full Screen", category: "Screenshot")
        ]
    }

    public func perform(_ spec: ActionSpec) -> ActionResult {
        let args: [String]
        switch spec.type {
        case "screenshot.area":      args = ["-i", newFilePath()]
        case "screenshot.window":    args = ["-i", "-W", newFilePath()]
        case "screenshot.clipboard": args = ["-i", "-c"]
        case "screenshot.desktop":   args = [newFilePath()]
        default: return .ignored(reason: "unknown action \(spec.type)")
        }
        return process.run(Self.tool, args) ? .ok : .failed(error: "screencapture failed")
    }

    private func newFilePath() -> String {
        let stamp = Self.formatter.string(from: Date())
        return destinationDirectory.appendingPathComponent("Screenshot-\(stamp).png").path
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
