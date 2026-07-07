import XCTest
@testable import MouseStudioCore
import MouseStudioShared

// Phase 1+: StateMachine transition tables, RuleEngine compilation/priority,
// ActionDispatcher routing, DeviceManager matching (TDD §16.1).
final class CoreTests: XCTestCase {
    func testScaffoldModuleLoads() {
        XCTAssertEqual(MouseStudioCore.module, "MouseStudioCore")
        XCTAssertEqual(MouseStudio.schemaVersion, 1)
    }
}
