import XCTest
@testable import MouseStudioService
@testable import MouseStudioCore
import MouseStudioConfig
import MouseStudioShared

final class IPCRouterTests: XCTestCase {

    private func makeHostAndRouter() -> (EngineHost, IPCRouter, URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MSRouter-\(UUID().uuidString)", isDirectory: true)
        let store = FileConfigStore(paths: ConfigPaths(root: root))
        let host = EngineHost(
            store: store,
            eventSource: SimulatedEventSource(),
            scheduler: ManualScheduler(),
            providers: [],
            permission: StubPermissionChecker(trusted: true),
            logger: Logger(level: .error)
        )
        _ = host.startup()
        return (host, IPCRouter(host: host), root)
    }

    func testGetStatusReturnsStatus() {
        let (host, router, root) = makeHostAndRouter()
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertEqual(router.handle(.getStatus), .status(host.status))
    }

    func testPauseResumeAck() {
        let (host, router, root) = makeHostAndRouter()
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertEqual(router.handle(.pauseEngine), .ack)
        XCTAssertTrue(host.isPaused)
        XCTAssertEqual(router.handle(.resumeEngine), .ack)
        XCTAssertFalse(host.isPaused)
    }

    func testLearningModeToggleViaRouter() {
        let (host, router, root) = makeHostAndRouter()
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertEqual(router.handle(.enterLearningMode), .ack)
        XCTAssertEqual(host.status, .learning)
        XCTAssertEqual(router.handle(.exitLearningMode), .ack)
    }

    func testTestRuleReturnsResult() {
        let (_, router, root) = makeHostAndRouter()
        defer { try? FileManager.default.removeItem(at: root) }
        let rule = Rule(id: "r", trigger: TriggerSpec(button: .button4, gesture: .double),
                        action: ActionSpec(type: "app.launch"))
        if case .testResult(let result) = router.handle(.testRule(rule)) {
            XCTAssertTrue(result.matched)
            XCTAssertEqual(result.actionType, "app.launch")
        } else {
            XCTFail("expected testResult")
        }
    }

    func testGetRecentLogsReturnsLogs() {
        let (_, router, root) = makeHostAndRouter()
        defer { try? FileManager.default.removeItem(at: root) }
        if case .logs = router.handle(.getRecentLogs(limit: 10)) { } else { XCTFail("expected logs") }
    }

    func testIPCRequestCodableRoundTrip() throws {
        let requests: [IPCRequest] = [
            .getStatus, .reloadConfig, .setActiveProfile("x"), .enterLearningMode,
            .getRecentLogs(limit: 5), .pauseEngine,
            .testRule(Rule(id: "r", trigger: TriggerSpec(button: .left, gesture: .single), action: ActionSpec(type: "a")))
        ]
        let encoder = JSONEncoder(); let decoder = JSONDecoder()
        for req in requests {
            let data = try encoder.encode(req)
            XCTAssertEqual(try decoder.decode(IPCRequest.self, from: data), req)
        }
    }
}
