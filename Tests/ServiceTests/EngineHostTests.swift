import XCTest
@testable import MouseStudioService
@testable import MouseStudioCore
import MouseStudioConfig
import MouseStudioShared

final class EngineHostTests: XCTestCase {

    private var tempRoot: URL!
    private var store: FileConfigStore!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MSHostTests-\(UUID().uuidString)", isDirectory: true)
        store = FileConfigStore(paths: ConfigPaths(root: tempRoot))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    /// A provider that records dispatched specs and claims a chosen namespace.
    private final class SpyProvider: ActionProvider {
        let namespace: String
        private(set) var performed: [ActionSpec] = []
        init(namespace: String) { self.namespace = namespace }
        func supportedActions() -> [ActionDescriptor] { [] }
        func perform(_ spec: ActionSpec) -> ActionResult { performed.append(spec); return .ok }
    }

    private func makeHost(
        trusted: Bool,
        providers: [ActionProvider]
    ) -> (EngineHost, SimulatedEventSource, ManualScheduler) {
        let source = SimulatedEventSource()
        let scheduler = ManualScheduler()
        let host = EngineHost(
            store: store,
            eventSource: source,
            scheduler: scheduler,
            providers: providers,
            permission: StubPermissionChecker(trusted: trusted),
            logger: Logger(level: .error)
        )
        return (host, source, scheduler)
    }

    private func writeProfile(activeRuleAction: String) throws {
        try store.saveConfig(Config(activeProfile: "t"))
        let rule = Rule(id: "r", trigger: TriggerSpec(button: .button4, gesture: .single),
                        action: ActionSpec(type: activeRuleAction))
        try store.saveProfile(Profile(id: "t", displayName: "T", rules: [rule]))
    }

    func testStartupLoadsRulesAndDispatches() throws {
        try writeProfile(activeRuleAction: "spy.do")
        let spy = SpyProvider(namespace: "spy")
        let (host, source, _) = makeHost(trusted: true, providers: [spy])

        XCTAssertEqual(host.startup(), .running)
        source.down(.button4)
        source.up(.button4)   // single (not double-mapped) fires immediately
        XCTAssertEqual(spy.performed.map { $0.type }, ["spy.do"])
    }

    func testPermissionRequiredDoesNotStart() throws {
        try writeProfile(activeRuleAction: "spy.do")
        let spy = SpyProvider(namespace: "spy")
        let (host, source, _) = makeHost(trusted: false, providers: [spy])

        XCTAssertEqual(host.startup(), .permissionRequired)
        source.down(.button4)
        source.up(.button4)
        XCTAssertTrue(spy.performed.isEmpty, "engine must not receive events without permission")
    }

    func testBootstrapCreatesDefaultsWhenEmpty() throws {
        let (host, _, _) = makeHost(trusted: true, providers: [])
        _ = host.startup()
        // Default config + profile should now exist.
        XCTAssertEqual(try store.loadConfig().activeProfile, DefaultConfig.defaultProfileID)
        XCTAssertFalse(try store.loadProfiles().isEmpty)
    }

    func testPauseBlocksDispatch() throws {
        try writeProfile(activeRuleAction: "spy.do")
        let spy = SpyProvider(namespace: "spy")
        let (host, source, _) = makeHost(trusted: true, providers: [spy])
        _ = host.startup()

        host.pause()
        source.down(.button4); source.up(.button4)
        XCTAssertTrue(spy.performed.isEmpty)

        host.resume()
        source.down(.button4); source.up(.button4)
        XCTAssertEqual(spy.performed.count, 1)
    }

    func testSetActiveProfileReloads() throws {
        // Two profiles; switch active and verify the new rule fires.
        try store.saveConfig(Config(activeProfile: "a"))
        try store.saveProfile(Profile(id: "a", displayName: "A", rules: [
            Rule(id: "ra", trigger: TriggerSpec(button: .button4, gesture: .single), action: ActionSpec(type: "spy.a"))
        ]))
        try store.saveProfile(Profile(id: "b", displayName: "B", rules: [
            Rule(id: "rb", trigger: TriggerSpec(button: .button4, gesture: .single), action: ActionSpec(type: "spy.b"))
        ]))
        let spy = SpyProvider(namespace: "spy")
        let (host, source, _) = makeHost(trusted: true, providers: [spy])
        _ = host.startup()

        host.setActiveProfile("b")
        source.down(.button4); source.up(.button4)
        XCTAssertEqual(spy.performed.map { $0.type }, ["spy.b"])
        XCTAssertEqual(try store.loadConfig().activeProfile, "b")
    }

    func testLearningModeForwardsButtons() throws {
        try writeProfile(activeRuleAction: "spy.do")
        let spy = SpyProvider(namespace: "spy")
        let (host, source, _) = makeHost(trusted: true, providers: [spy])
        _ = host.startup()

        var detected: [ButtonID] = []
        host.onLearningButton = { detected.append($0) }
        host.enterLearningMode()
        source.down(.button5); source.up(.button5)
        XCTAssertEqual(detected, [.button5])
        XCTAssertTrue(spy.performed.isEmpty)
        XCTAssertEqual(host.status, .learning)
    }
}
