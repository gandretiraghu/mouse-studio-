import Foundation

/// Resolves the on-disk locations Mouse Studio uses (TDD §13, §19.5).
///
/// Default root: `~/Library/Application Support/MouseStudio/`. Tests inject a
/// temporary root so they never touch the real user directory.
public struct ConfigPaths {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    /// The default per-user Application Support location.
    public static func defaultUserPaths(fileManager: FileManager = .default) -> ConfigPaths {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return ConfigPaths(root: base.appendingPathComponent("MouseStudio", isDirectory: true))
    }

    public var configFile: URL { root.appendingPathComponent("config.json") }
    public var profilesDir: URL { root.appendingPathComponent("profiles", isDirectory: true) }
    public var backupsDir: URL { root.appendingPathComponent("backups", isDirectory: true) }

    public func profileFile(id: String) -> URL {
        profilesDir.appendingPathComponent("\(id).json")
    }
}
