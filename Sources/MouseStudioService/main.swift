// MouseStudioService — background daemon (LaunchAgent) that hosts the Core engine
// and exposes the XPC IPC server. The GUI never taps mouse events; only this
// process does (least-privilege, TDD §11, §12, §13).
//
// Phase 3: constructs the action providers and shows the wiring. Full engine
// start (event tap + run loop + permission handling) and the IPC server arrive
// in Phase 4.

import Foundation
import MouseStudioCore
import MouseStudioActions
import MouseStudioConfig
import MouseStudioShared

let logger = Logger(level: .info)
logger.sink = { entry in
    print("[\(entry.level.label)] \(entry.subsystem): \(entry.message)")
}

// Register the full MVP action set.
let providers = MouseStudioActions.makeDefaultProviders()
let dispatcher = ActionDispatcher(logger: logger)
for provider in providers {
    dispatcher.register(provider)
}

let actionCount = dispatcher.allSupportedActions().count
logger.info("Mouse Studio Service \(MouseStudio.version) — \(providers.count) providers, \(actionCount) actions registered", subsystem: "service")
logger.info("Namespaces: \(dispatcher.registeredNamespaces().joined(separator: ", "))", subsystem: "service")
logger.info("Engine start + IPC server arrive in Phase 4 (scaffold).", subsystem: "service")
