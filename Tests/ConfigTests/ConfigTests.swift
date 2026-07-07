import XCTest
@testable import MouseStudioConfig
import MouseStudioShared

// Phase 2+: schema validation, load/save round-trip, import/export bundles,
// backup/restore, migrations, last-known-good fallback (TDD §16.2).
final class ConfigTests: XCTestCase {
    func testScaffoldModuleLoads() {
        XCTAssertEqual(MouseStudioConfig.module, "MouseStudioConfig")
        XCTAssertEqual(MouseStudioConfig.supportDirectoryName, "MouseStudio")
    }
}
