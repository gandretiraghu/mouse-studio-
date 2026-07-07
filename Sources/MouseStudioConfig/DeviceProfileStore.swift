import Foundation
import MouseStudioShared

/// Loads shipped/user device profiles (JSON) from a directory (TDD §9.3).
/// Device profiles are additive: dropping a new JSON adds device support with
/// no code change.
public final class DeviceProfileStore {
    private let directory: URL
    private let fileManager: FileManager
    private let decoder = JSONDecoder()

    public init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    /// Load all valid device profiles from the directory. Invalid files are
    /// skipped (never fatal) — TDD §15.
    public func load() -> [DeviceProfile] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return contents
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(DeviceProfile.self, from: data)
            }
    }
}
