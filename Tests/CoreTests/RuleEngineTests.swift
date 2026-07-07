import XCTest
@testable import MouseStudioCore
import MouseStudioShared

final class RuleEngineTests: XCTestCase {

    private func rule(
        _ id: String,
        button: ButtonID,
        gesture: GestureKind,
        chordWith: ButtonID? = nil,
        action: String,
        enabled: Bool = true,
        priority: Int = 0
    ) -> Rule {
        Rule(
            id: id,
            enabled: enabled,
            priority: priority,
            trigger: TriggerSpec(button: button, gesture: gesture, chordWith: chordWith),
            action: ActionSpec(type: action)
        )
    }

    func testMatchesConfiguredTrigger() {
        let engine = RuleEngine()
        engine.load([rule("r1", button: .button4, gesture: .double, action: "app.launch")])
        let g = Gesture(anchor: .button4, kind: .double)
        XCTAssertEqual(engine.match(g)?.action.type, "app.launch")
    }

    func testNoMatchReturnsNil() {
        let engine = RuleEngine()
        engine.load([rule("r1", button: .button4, gesture: .single, action: "a")])
        XCTAssertNil(engine.match(Gesture(anchor: .button4, kind: .double)))
    }

    func testDisabledRulesAreExcluded() {
        let engine = RuleEngine()
        engine.load([rule("r1", button: .middle, gesture: .single, action: "a", enabled: false)])
        XCTAssertNil(engine.match(Gesture(anchor: .middle, kind: .single)))
        XCTAssertEqual(engine.ruleCount, 0)
    }

    func testPriorityWinsAndLowerIsShadowed() {
        let engine = RuleEngine()
        engine.load([
            rule("low", button: .button4, gesture: .single, action: "low", priority: 1),
            rule("high", button: .button4, gesture: .single, action: "high", priority: 10)
        ])
        XCTAssertEqual(engine.match(Gesture(anchor: .button4, kind: .single))?.action.type, "high")
        XCTAssertEqual(engine.shadowedRuleIDs, ["low"])
    }

    func testTieBreaksByInputOrder() {
        let engine = RuleEngine()
        engine.load([
            rule("first", button: .right, gesture: .single, action: "first"),
            rule("second", button: .right, gesture: .single, action: "second")
        ])
        XCTAssertEqual(engine.match(Gesture(anchor: .right, kind: .single))?.action.type, "first")
        XCTAssertEqual(engine.shadowedRuleIDs, ["second"])
    }

    func testChordClickKeyDistinguishesPartner() {
        let engine = RuleEngine()
        engine.load([
            rule("c1", button: .button4, gesture: .chordClick, chordWith: .left, action: "chrome"),
            rule("c2", button: .button4, gesture: .chordClick, chordWith: .right, action: "edge")
        ])
        XCTAssertEqual(engine.match(Gesture(anchor: .button4, kind: .chordClick, chordButton: .left))?.action.type, "chrome")
        XCTAssertEqual(engine.match(Gesture(anchor: .button4, kind: .chordClick, chordButton: .right))?.action.type, "edge")
        XCTAssertTrue(engine.shadowedRuleIDs.isEmpty)
    }

    func testDoubleMappedButtons() {
        let engine = RuleEngine()
        engine.load([
            rule("r1", button: .button4, gesture: .double, action: "a"),
            rule("r2", button: .button5, gesture: .single, action: "b"),
            rule("r3", button: .middle, gesture: .double, action: "c")
        ])
        XCTAssertEqual(engine.doubleMappedButtons(), [.button4, .middle])
    }

    func testOwnedButtonsCoversAllAnchors() {
        let engine = RuleEngine()
        engine.load([
            rule("r1", button: .button4, gesture: .double, action: "a"),
            rule("r2", button: .button4, gesture: .single, action: "a2"),
            rule("r3", button: .button5, gesture: .chordScrollUp, action: "b"),
            rule("r4", button: .middle, gesture: .single, action: "c", enabled: false)
        ])
        // Disabled rule's button is not owned.
        XCTAssertEqual(engine.ownedButtons(), [.button4, .button5])
    }
}

/// A spy event source that records the owned-buttons set pushed by the engine.
final class OwnedButtonsSpySource: EventSource {
    var onEvent: ((RawEvent) -> Void)?
    private(set) var owned: Set<ButtonID> = []
    func start() throws {}
    func stop() {}
    func setOwnedButtons(_ buttons: Set<ButtonID>) { owned = buttons }
}

final class EngineOwnedButtonsTests: XCTestCase {
    func testReloadPushesOwnedButtonsToEventSource() {
        let source = OwnedButtonsSpySource()
        let engine = Engine(eventSource: source, scheduler: ManualScheduler(), logger: Logger(level: .error))
        engine.reload(rules: [
            Rule(id: "r", trigger: TriggerSpec(button: .button4, gesture: .double), action: ActionSpec(type: "app.launch"))
        ])
        XCTAssertEqual(source.owned, [.button4])
    }
}
