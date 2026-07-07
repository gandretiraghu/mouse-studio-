// MouseStudioServiceApp — thin executable entry point for the background service.
// All logic lives in the MouseStudioService library so it can be unit-tested.

import Foundation
import MouseStudioService

#if canImport(AppKit)
ServiceApplication.run()
#else
FileHandle.standardError.write(Data("Mouse Studio Service requires macOS (AppKit).\n".utf8))
#endif
