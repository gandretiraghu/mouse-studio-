// MouseStudioService — background daemon (LaunchAgent) that hosts the Core engine
// and exposes the XPC IPC server. The GUI never taps mouse events; only this
// process does (least-privilege, TDD §11, §12, §13).
//
// Phase 4 components: EngineHost, IPCServer, MenuBarController.
// Phase 0: scaffold entry point only.

import Foundation
import MouseStudioCore
import MouseStudioActions
import MouseStudioConfig
import MouseStudioShared

print("Mouse Studio Service \(MouseStudio.version) — scaffold (Phase 0). Engine not yet wired.")
