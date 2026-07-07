import Foundation
import MouseStudioShared

/// Metadata about a stored backup snapshot (TDD §19.5).
public struct BackupInfo: Equatable, Sendable, Identifiable {
    public let url: URL
    public let createdAt: Date
    public var id: String { url.lastPathComponent }
}

/// Persistence contract for configuration (TDD §10.3, §19.5).
public protocol ConfigStoring: AnyObject {
    func loadConfig() throws -> Config
    func saveConfig(_ config: Config) throws
    func loadProfiles() throws -> [Profile]
    func saveProfile(_ profile: Profile) throws
    func deleteProfile(id: String) throws

    func validate() throws -> [ValidationError]

    func exportBundle(to url: URL) throws
    @discardableResult
    func importBundle(from url: URL) throws -> ExportBundle

    @discardableResult
    func snapshot() throws -> URL
    func listBackups() -> [BackupInfo]
    func restore(_ backup: BackupInfo) throws
}

/// File-backed config store. Writes are atomic (temp file + rename) so a crash
/// or full disk can never corrupt the live config (TDD §11, §15). On first run
/// it bootstraps the default config + profile.
public final class FileConfigStore: ConfigStoring {
    public let paths: ConfigPaths
    private let fileManager: FileManager
    private let validator = ConfigValidator()
    private let maxBackups: Int

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(paths: ConfigPaths, fileManager: FileManager = .default, maxBackups: Int = 20) {
        self.paths = paths
        self.fileManager = fileManager
        self.maxBackups = maxBackups

        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    // MARK: - Bootstrap

    /// Create directories and default files if they don't exist yet.
    public func bootstrapIfNeeded() throws {
        try ensureDirectories()
        if !fileManager.fileExists(atPath: paths.configFile.path) {
            try saveConfig(DefaultConfig.config())
        }
        if try loadProfiles().isEmpty {
            try saveProfile(DefaultConfig.profile())
        }
    }

    private func ensureDirectories() throws {
        for dir in [paths.root, paths.profilesDir, paths.backupsDir] {
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - Config

    public func loadConfig() throws -> Config {
        let data = try Data(contentsOf: paths.configFile)
        return try decoder.decode(Config.self, from: data)
    }

    public func saveConfig(_ config: Config) throws {
        try ensureDirectories()
        try writeAtomically(try encoder.encode(config), to: paths.configFile)
    }

    // MARK: - Profiles

    public func loadProfiles() throws -> [Profile] {
        try ensureDirectories()
        let contents = try fileManager.contentsOfDirectory(
            at: paths.profilesDir,
            includingPropertiesForKeys: nil
        )
        return try contents
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { try decoder.decode(Profile.self, from: try Data(contentsOf: $0)) }
    }

    public func saveProfile(_ profile: Profile) throws {
        try ensureDirectories()
        try writeAtomically(try encoder.encode(profile), to: paths.profileFile(id: profile.id))
    }

    public func deleteProfile(id: String) throws {
        let url = paths.profileFile(id: id)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Validation

    public func validate() throws -> [ValidationError] {
        let config = try loadConfig()
        let profiles = try loadProfiles()
        return validator.validate(config: config, profiles: profiles)
    }

    // MARK: - Import / Export

    public func exportBundle(to url: URL) throws {
        let bundle = ExportBundle(config: try loadConfig(), profiles: try loadProfiles())
        try writeAtomically(try encoder.encode(bundle), to: url)
    }

    @discardableResult
    public func importBundle(from url: URL) throws -> ExportBundle {
        let bundle = try decoder.decode(ExportBundle.self, from: try Data(contentsOf: url))
        // Take a restore point before mutating anything.
        _ = try? snapshot()
        try saveConfig(bundle.config)
        for profile in bundle.profiles {
            try saveProfile(profile)
        }
        return bundle
    }

    // MARK: - Backup / Restore

    @discardableResult
    public func snapshot() throws -> URL {
        try ensureDirectories()
        let bundle = ExportBundle(config: try loadConfig(), profiles: try loadProfiles())
        let stamp = Self.timestampFormatter.string(from: Date())
        let url = paths.backupsDir.appendingPathComponent("\(stamp).mousestudio.json")
        try writeAtomically(try encoder.encode(bundle), to: url)
        pruneBackups()
        return url
    }

    public func listBackups() -> [BackupInfo] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: paths.backupsDir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return [] }

        return contents
            .filter { $0.lastPathComponent.hasSuffix(".mousestudio.json") }
            .map { url in
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                return BackupInfo(url: url, createdAt: date)
            }
            .sorted { $0.createdAt > $1.createdAt }   // newest first
    }

    public func restore(_ backup: BackupInfo) throws {
        // Restore is itself reversible: snapshot current state first.
        _ = try? snapshot()
        let bundle = try decoder.decode(ExportBundle.self, from: try Data(contentsOf: backup.url))
        try saveConfig(bundle.config)
        // Replace profiles wholesale with the backup's set.
        for existing in try loadProfiles() {
            try deleteProfile(id: existing.id)
        }
        for profile in bundle.profiles {
            try saveProfile(profile)
        }
    }

    private func pruneBackups() {
        let backups = listBackups()
        guard backups.count > maxBackups else { return }
        for stale in backups.dropFirst(maxBackups) {
            try? fileManager.removeItem(at: stale.url)
        }
    }

    // MARK: - Atomic write

    private func writeAtomically(_ data: Data, to url: URL) throws {
        let tmp = url.deletingLastPathComponent()
            .appendingPathComponent(".\(url.lastPathComponent).tmp-\(UUID().uuidString)")
        try data.write(to: tmp, options: .atomic)
        // Replace destination atomically.
        if fileManager.fileExists(atPath: url.path) {
            _ = try fileManager.replaceItemAt(url, withItemAt: tmp)
        } else {
            try fileManager.moveItem(at: tmp, to: url)
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH-mm-ss-SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}
