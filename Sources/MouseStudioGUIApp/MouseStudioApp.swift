import Foundation
import MouseStudioGUI
import MouseStudioConfig
import MouseStudioShared

#if canImport(SwiftUI)
import SwiftUI

/// The Mouse Studio settings application entry point. Edits config on disk; the
/// background service picks up changes automatically (TDD §4).
@main
struct MouseStudioApp: App {
    private let store = FileConfigStore(paths: ConfigPaths.defaultUserPaths())
    private let ipc: IPCClient = StubIPCClient()

    var body: some Scene {
        WindowGroup("Mouse Studio") {
            RootView(store: store, ipc: ipc)
        }
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
