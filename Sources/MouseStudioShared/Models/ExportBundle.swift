import Foundation

/// A portable bundle of config + profiles for Import/Export and Backup/Restore
/// (TDD §9.5, §19.5).
public struct ExportBundle: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var exportedAt: Date
    public var app: String
    public var config: Config
    public var profiles: [Profile]

    public init(
        schemaVersion: Int = 1,
        exportedAt: Date = Date(),
        app: String = "Mouse Studio",
        config: Config,
        profiles: [Profile]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.app = app
        self.config = config
        self.profiles = profiles
    }
}
