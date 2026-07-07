import XCTest
@testable import MouseStudioCore
import MouseStudioShared

/// End-to-end tests driving the full engine (SimulatedEventSource → StateMachine
/// → RuleEngine → ActionDispatcher) with a spy provider and a virtual clock
/// (TDD §16.3, §16.4).
final class IntegrationTests: XCTestCase {

    private func makeEngine(
        rules: [Rule]
    ) -> (Engine, SimulatedEventSource, ManualScheduler, RecordingProvider) {
        let source = SimulatedEventSource()
        let scheduler = ManualScheduler()
        let engine = Engine(eventSource: source, scheduler: scheduler, logger: Logger(level: .error))
        let provider = RecordingProvider(namespace: "app")
        engine.dispatcher.register(provider)
        engine.reload(rules: rules)
        try? engine.start()
        return (engine, source, scheduler, provider)
    }

    func testDoubleClickLaunchesApp() {
        let rule = Rule(
            id: "finder",
            trigger: TriggerSpec(button: .button4, gesture: .double),
            action: ActionSpec(type: "app.launch", params: ["bundleID": .string("com.apple.finder")])
        )
        let (engine, source, scheduler, provider) = makeEngine(rules: [rule])
        withExtendedLifetime(engine) {
            source.down(.button4)
            source.up(.button4)
            source.down(.button4)
            source.up(.button4)

            XCTAssertEqual(provider.performed.map { $0.type }, ["app.launch"])
            XCTAssertEqual(provider.performed.first?.params["bundleID"], .string("com.apple.finder"))

            scheduler.advance(byMs: 500)
            XCTAssertEqual(provider.performed.count, 1, "no stray single-click action after double")
        }
    }

    func testChordClickResolvesEndToEnd() {
        let rule = Rule(
            id: "chrome",
            trigger: TriggerSpec(button: .button4, gesture: .chordClick, chordWith: .left),
            action: ActionSpec(type: "app.switch", params: ["bundleID": .string("com.google.Chrome")])
        )
        let (engine, source, _, provider) = makeEngine(rules: [rule])
        withExtendedLifetime(engine) {
            source.down(.button4)
            source.down(.left)
            source.up(.left)
            source.up(.button4)

            XCTAssertEqual(provider.performed.map { $0.type }, ["app.switch"])
        }
    }

    func testUnmappedGestureDispatchesNothing() {
        let (engine, source, scheduler, provider) = makeEngine(rules: [])
        withExtendedLifetime(engine) {
            source.down(.middle)
            source.up(.middle)
            scheduler.advance(byMs: 500)
            XCTAssertTrue(provider.performed.isEmpty)
        }
    }

    func testLearningModeForwardsButtonsInsteadOfDispatching() {
        let rule = Rule(
            id: "x",
            trigger: TriggerSpec(button: .button5, gesture: .single),
            action: ActionSpec(type: "app.launch")
        )
        let (engine, source, _, provider) = makeEngine(rules: [rule])
        withExtendedLifetime(engine) {
            var detected: [ButtonID] = []
            engine.onLearningButton = { detected.append($0) }
            engine.enterLearningMode()

            source.down(.button5)
            source.up(.button5)

            XCTAssertEqual(detected, [.button5])
            XCTAssertTrue(provider.performed.isEmpty, "no actions dispatched while learning")
        }
    }

    /// The synchronous resolve+dispatch hot path should be well within the < 5 ms
    /// budget. Averaged over many iterations to be robust on shared CI runners
    /// (TDD §14).
    func testDispatchHotPathIsFast() {
        let rule = Rule(
            id: "r",
            trigger: TriggerSpec(button: .button4, gesture: .single),
            action: ActionSpec(type: "app.launch")
        )
        let engine = Engine(
            eventSource: SimulatedEventSource(),
            scheduler: ManualScheduler(),
            logger: Logger(level: .error)
        )
        engine.dispatcher.register(RecordingProvider(namespace: "app"))
        engine.reload(rules: [rule])

        let gesture = Gesture(anchor: .button4, kind: .single)
        let iterations = 5000
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<iterations {
            if let matched = engine.ruleEngine.match(gesture) {
                engine.dispatcher.dispatch(matched.action)
            }
        }
        let elapsedMs = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000.0
        let avgMs = elapsedMs / Double(iterations)
        XCTAssertLessThan(avgMs, 5.0, "average dispatch \(avgMs) ms exceeds 5 ms budget")
    }
}

/// A recording action provider for integration assertions.
final class RecordingProvider: ActionProvider {
    let namespace: String
    private(set) var performed: [ActionSpec] = []
    init(namespace: String) { self.namespace = namespace }
    func supportedActions() -> [ActionDescriptor] { [] }
    func perform(_ spec: ActionSpec) -> ActionResult {
        performed.append(spec)
        return .ok
    }
}
