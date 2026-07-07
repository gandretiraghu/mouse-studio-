import XCTest
@testable import MouseStudioCore
import MouseStudioShared

final class DispatcherTests: XCTestCase {

    func testRoutesToProviderByNamespace() {
        let logger = Logger(level: .warn)
        let dispatcher = ActionDispatcher(logger: logger)
        let spy = SpyProvider(namespace: "test")
        dispatcher.register(spy)

        let result = dispatcher.dispatch(ActionSpec(type: "test.do", params: ["k": .string("v")]))
        XCTAssertEqual(result, .ok)
        XCTAssertEqual(spy.performed.map { $0.type }, ["test.do"])
        XCTAssertEqual(spy.performed.first?.params["k"], .string("v"))
    }

    func testUnknownNamespaceIsIgnoredNotFatal() {
        let dispatcher = ActionDispatcher(logger: Logger(level: .error))
        let result = dispatcher.dispatch(ActionSpec(type: "nope.do"))
        if case .ignored = result { /* ok */ } else { XCTFail("expected .ignored, got \(result)") }
    }

    func testProviderFailurePropagates() {
        let dispatcher = ActionDispatcher(logger: Logger(level: .error))
        let spy = SpyProvider(namespace: "test", result: .failed(error: "boom"))
        dispatcher.register(spy)
        XCTAssertEqual(dispatcher.dispatch(ActionSpec(type: "test.x")), .failed(error: "boom"))
    }
}

/// A test double that records the specs it was asked to perform.
final class SpyProvider: ActionProvider {
    let namespace: String
    private let result: ActionResult
    private(set) var performed: [ActionSpec] = []

    init(namespace: String, result: ActionResult = .ok) {
        self.namespace = namespace
        self.result = result
    }

    func supportedActions() -> [ActionDescriptor] {
        [ActionDescriptor(type: "\(namespace).do", displayName: "Do")]
    }

    func perform(_ spec: ActionSpec) -> ActionResult {
        performed.append(spec)
        return result
    }
}
