import XCTest
@testable import MouseStudioConfig
import MouseStudioShared

final class ConfigStoreTests: XCTestCase {

    private var tempRoot: URL!
    private var store: FileConfigStore!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MouseStudioTests-\(UUID().uuidString)", isDirectory: true)
        store = FileConfigStore(paths: ConfigPaths(root: tempRoot), maxBackups: 3)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testBootstrapCreatesDefaultConfigAndProfile() throws {
        try store.bootstrapIfNeeded()
        let config = try store.loadConfig()
        XCTAssertEqual(config.activeProfile, DefaultConfig.defaultProfileID)
        XCTAssertEqual(config.schemaVersion, 1)

        let profiles = try store.loadProfiles()
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.id, "default")
        XCTAssertFalse(profiles.first?.rules.isEmpty ?? true)
    }

    func testBootstrapIsIdempotent() throws {
        try store.bootstrapIfNeeded()
        // Mutate then bootstrap again — must NOT overwrite existing files.
        var config = try store.loadConfig()
        config.activeProfile = "custom"
        try store.saveConfig(config)
        try store.saveProfile(Profile(id: "custom", displayName: "Custom"))

        try store.bootstrapIfNeeded()
        XCTAssertEqual(try store.loadConfig().activeProfile, "custom")
    }

    func testConfigRoundTrip() throws {
        let original = Config(
            activeProfile: "p1",
            timing: TimingConfig(doubleClickMs: 220, longPressMs: 400),
            logging: LoggingConfig(level: .debug, perf: true)
        )
        try store.saveConfig(original)
        XCTAssertEqual(try store.loadConfig(), original)
    }

    func testProfileRoundTripAndDelete() throws {
        let profile = Profile(
            id: "gaming",
            displayName: "Gaming",
            rules: [Rule(id: "r", trigger: TriggerSpec(button: .button4, gesture: .single), action: ActionSpec(type: "app.launch"))]
        )
        try store.saveProfile(profile)
        XCTAssertEqual(try store.loadProfiles().first, profile)

        try store.deleteProfile(id: "gaming")
        XCTAssertTrue(try store.loadProfiles().isEmpty)
    }

    func testExportImportRoundTrip() throws {
        try store.bootstrapIfNeeded()
        let exportURL = tempRoot.appendingPathComponent("export.mousestudio.json")
        try store.exportBundle(to: exportURL)

        // Import into a fresh store.
        let otherRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MouseStudioImport-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: otherRoot) }
        let other = FileConfigStore(paths: ConfigPaths(root: otherRoot))

        let bundle = try other.importBundle(from: exportURL)
        XCTAssertEqual(bundle.config.activeProfile, "default")
        XCTAssertEqual(try other.loadConfig().activeProfile, "default")
        XCTAssertEqual(try other.loadProfiles().count, 1)
    }

    func testSnapshotAndRestore() throws {
        try store.bootstrapIfNeeded()
        // Take a snapshot of the default state.
        _ = try store.snapshot()
        let backups = store.listBackups()
        XCTAssertEqual(backups.count, 1)

        // Mutate: change active profile + add a profile.
        var config = try store.loadConfig()
        config.activeProfile = "temp"
        try store.saveConfig(config)
        try store.saveProfile(Profile(id: "temp", displayName: "Temp"))
        XCTAssertEqual(try store.loadProfiles().count, 2)

        // Restore the first backup.
        try store.restore(backups[0])
        XCTAssertEqual(try store.loadConfig().activeProfile, "default")
        XCTAssertEqual(try store.loadProfiles().map { $0.id }, ["default"])
    }

    func testBackupRetentionPrunesOldest() throws {
        try store.bootstrapIfNeeded()
        // maxBackups = 3; create 5 snapshots.
        for _ in 0..<5 {
            _ = try store.snapshot()
            usleep(5000) // ensure distinct timestamps (ms precision)
        }
        XCTAssertLessThanOrEqual(store.listBackups().count, 3)
    }

    func testAtomicSaveLeavesNoTempFiles() throws {
        try store.bootstrapIfNeeded()
        try store.saveConfig(try store.loadConfig())
        let contents = try FileManager.default.contentsOfDirectory(atPath: tempRoot.path)
        XCTAssertFalse(contents.contains { $0.contains(".tmp-") }, "temp files should be cleaned up")
    }
}
