// MouseStudioGUI — SwiftUI configuration app and IPC client.
// Depends only on Config + Shared; reaches the engine through IPC contracts.
//
// Phase 5+ views (TDD §4, §19): Rule Editor, Rule Creation Wizard, Action Browser,
// Live Mouse Tester, Profiles, Import/Export, Backup/Restore, Logs.
// Phase 0: scaffold entry point only (SwiftUI wired in Phase 5).

import Foundation
import MouseStudioConfig
import MouseStudioShared

print("Mouse Studio GUI \(MouseStudio.version) — scaffold (Phase 0). SwiftUI wired in Phase 5.")
