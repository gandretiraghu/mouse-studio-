import XCTest
@testable import MouseStudioCore
@testable import MouseStudioActions
@testable import MouseStudioConfig
import MouseStudioShared

// Phase 3+: simulated end-to-end (SimulatedEventSource → StateMachine → RuleEngine
// → Dispatcher spies), asserting dispatched ActionSpec sequence + latency (TDD §16.3, §16.4).
final class IntegrationTests: XCTestCase {
    func testScaffoldModulesInteroperate() {
        XCTAssertEqual(MouseStudioCore.module, "MouseStudioCore")
        XCTAssertEqual(MouseStudioActions.module, "MouseStudioActions")
        XCTAssertEqual(MouseStudioConfig.module, "MouseStudioConfig")
    }
}
