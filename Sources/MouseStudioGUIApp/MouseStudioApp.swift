import Foundation
import MouseStudioGUI
import MouseStudioConfig
import MouseStudioShared

#if canImport(SwiftUI)
import SwiftUI
import AppKit

/// Ensures the window comes back when the user clicks the Dock icon after
/// closing it (default single-window SwiftUI apps otherwise stay running with no
/// way to reopen).
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        sender.activate(ignoringOtherApps: true)
        return true
    }
}

/// The Mouse Studio settings application entry point. Edits config on disk; the
/// background service picks up changes automatically (TDD §4).
@main
struct MouseStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let store = FileConfigStore(paths: ConfigPaths.defaultUserPaths())
    // Connect to the running service; fall back to a stub for offline editing.
    private let ipc: IPCClient = makeIPCClient()

    var body: some Scene {
        WindowGroup("Mouse Studio") {
            RootView(store: store, ipc: ipc)
        }
        .windowResizability(.contentMinSize)
    }
}
#else
// Non-macOS fallback so the package still builds everywhere.
@main
struct MouseStudioApp {
    static func main() {
        FileHandle.standardError.write(Data("Mouse Studio GUI requires macOS.\n".utf8))
    }
}
#endif
