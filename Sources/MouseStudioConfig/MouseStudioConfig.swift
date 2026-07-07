// MouseStudioConfig
// ConfigStore: read / write / validate JSON config and profiles.
// Responsibilities (see docs/TechnicalDesignDocument.md §9, §10.3, §19.5):
//   - Atomic saves (write temp + rename)
//   - Schema validation + last-known-good fallback
//   - Import/Export bundles (*.mousestudio.json)
//   - Backup & Restore (rolling snapshots, restore points)
//   - Schema migrations (schemaVersion)

import Foundation
import MouseStudioShared

public enum MouseStudioConfig {
    public static let module = "MouseStudioConfig"

    /// Default on-disk location for user configuration.
    public static var supportDirectoryName: String { "MouseStudio" }
}
