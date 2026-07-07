import XCTest
@testable import MouseStudioGUI
import MouseStudioConfig
import MouseStudioShared

final class AppStateTests: XCTestCase {
    private var tempRoot: URL!
    private var store: FileConfigStore!
    private var ipc: StubIPCClient!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MSGuiTests-\(UUID().uuidString)", isDirectory: true)
        store = FileConfigStore(paths: ConfigPaths(root: tempRoot))
        ipc = StubIPCClient()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    private func makeState() -> AppState { AppState(store: store, ipc: ipc) }

    func testBootstrapsDefaultProfileOnInit() {
        let state = makeState()
        XCTAssertEqual(state.config.activeProfile, DefaultConfig.defaultProfileID)
        XCTAssertNotNil(state.activeProfile)
        XCTAssertFalse(state.activeProfile?.rules.isEmpty ?? true)
    }

    func testAddUpdateDeleteRulePersistsAndNotifies() throws {
        let state = makeState()
        let rule = Rule(id: "new", trigger: TriggerSpec(button: .left, gesture: .long), action: ActionSpec(type: "clipboard.copy"))
        state.addRule(rule)
        XCTAssertTrue(state.activeProfile?.rules.contains { $0.id == "new" } ?? false)
        XCTAssertTrue(ipc.sent.contains(.reloadConfig))

        // Persisted to disk?
        let reloaded = try store.loadProfiles().first { $0.id == state.config.activeProfile }
        XCTAssertTrue(reloaded?.rules.contains { $0.id == "new" } ?? false)

        state.deleteRule(id: "new")
        XCTAssertFalse(state.activeProfile?.rules.contains { $0.id == "new" } ?? true)
    }

    func testToggleRuleEnabled() {
        let state = makeState()
        let firstID = state.activeProfile!.rules.first!.id
        state.setRuleEnabled(id: firstID, enabled: false)
        XCTAssertEqual(state.activeProfile?.rules.first?.enabled, false)
    }

    func testConflictDetectionSurfacesIDs() {
        let state = makeState()
        // Add two rules on the same trigger key as an existing single? Use a fresh profile.
        let a = Rule(id: "ca", trigger: TriggerSpec(button: .right, gesture: .long), action: ActionSpec(type: "x"))
        let b = Rule(id: "cb", trigger: TriggerSpec(button: .right, gesture: .long), action: ActionSpec(type: "y"))
        state.addRule(a); state.addRule(b)
        XCTAssertEqual(state.conflictingRuleIDs(), ["ca", "cb"])
    }

    func testSetActiveProfileSwitches() {
        let state = makeState()
        state.addProfile(Profile(id: "gaming", displayName: "Gaming"))
        state.setActiveProfile("gaming")
        XCTAssertEqual(state.config.activeProfile, "gaming")
    }

    func testExportImportRoundTrip() throws {
        let state = makeState()
        let url = tempRoot.appendingPathComponent("out.mousestudio.json")
        state.exportBundle(to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // Fresh store/state imports it.
        let otherRoot = FileManager.default.temporaryDirectory.appendingPathComponent("MSGui2-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: otherRoot) }
        let otherState = AppState(store: FileConfigStore(paths: ConfigPaths(root: otherRoot)), ipc: StubIPCClient())
        otherState.importBundle(from: url)
        XCTAssertEqual(otherState.config.activeProfile, state.config.activeProfile)
    }

    func testCannotDeleteLastProfile() {
        let state = makeState()
        let onlyID = state.profiles.first!.id
        state.deleteProfile(id: onlyID)
        XCTAssertNotNil(state.lastError)
        XCTAssertEqual(state.profiles.count, 1)
    }
}
