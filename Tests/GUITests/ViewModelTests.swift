import XCTest
@testable import MouseStudioGUI
import MouseStudioShared

final class RuleListViewModelTests: XCTestCase {
    private func rule(_ id: String, _ button: ButtonID, _ gesture: GestureKind, _ action: String, enabled: Bool = true) -> Rule {
        Rule(id: id, enabled: enabled, trigger: TriggerSpec(button: button, gesture: gesture), action: ActionSpec(type: action))
    }

    func testSearchMatchesButtonGestureAndAction() {
        let rules = [
            rule("a", .button4, .single, "app.launch"),
            rule("b", .button5, .double, "clipboard.copy")
        ]
        XCTAssertEqual(RuleListViewModel(searchText: "button4").filtered(rules).map { $0.id }, ["a"])
        XCTAssertEqual(RuleListViewModel(searchText: "double").filtered(rules).map { $0.id }, ["b"])
        XCTAssertEqual(RuleListViewModel(searchText: "copy").filtered(rules).map { $0.id }, ["b"])
    }

    func testEnabledOnlyFilter() {
        let rules = [rule("a", .button4, .single, "app.launch", enabled: false),
                     rule("b", .button5, .single, "app.launch")]
        XCTAssertEqual(RuleListViewModel(enabledOnly: true).filtered(rules).map { $0.id }, ["b"])
    }

    func testGroupingByButton() {
        let rules = [rule("a", .button4, .single, "x"), rule("b", .button4, .double, "y"), rule("c", .left, .single, "z")]
        let groups = RuleListViewModel().grouped(rules)
        XCTAssertEqual(groups.first?.button, .left)   // ButtonID.allCases order: left first
        XCTAssertEqual(groups.first(where: { $0.button == .button4 })?.rules.count, 2)
    }

    func testHandlesLargeRuleSetQuickly() {
        let rules = (0..<5000).map { rule("r\($0)", .button4, .single, "app.launch") }
        let start = Date()
        _ = RuleListViewModel(searchText: "button4").filtered(rules)
        XCTAssertLessThan(Date().timeIntervalSince(start), 1.0)
    }
}

final class ActionBrowserViewModelTests: XCTestCase {
    func testGroupsByCategory() {
        let groups = ActionBrowserViewModel().groupedResults()
        XCTAssertTrue(groups.contains { $0.category == "App" })
        XCTAssertTrue(groups.contains { $0.category == "Clipboard" })
    }

    func testSearchFiltersByKeyword() {
        let vm = ActionBrowserViewModel(searchText: "louder")
        let all = vm.groupedResults().flatMap { $0.actions }
        XCTAssertEqual(all.map { $0.type }, ["volume.up"])
    }

    func testSearchByDisplayName() {
        let vm = ActionBrowserViewModel(searchText: "finder")
        XCTAssertTrue(vm.isEmpty, "no action literally named finder in catalog")
    }
}

final class RuleWizardViewModelTests: XCTestCase {
    func testBuildsRuleFromSteps() {
        let vm = RuleWizardViewModel()
        vm.button = .button4
        vm.gesture = .double
        vm.actionType = "desktop.nextSpace"
        let rule = vm.buildRule(id: "w1")
        XCTAssertEqual(rule?.trigger.button, .button4)
        XCTAssertEqual(rule?.trigger.gesture, .double)
        XCTAssertEqual(rule?.action.type, "desktop.nextSpace")
    }

    func testChordClickRequiresPartner() {
        let vm = RuleWizardViewModel()
        vm.button = .button4
        vm.gesture = .chordClick
        vm.actionType = "clipboard.copy"
        XCTAssertNil(vm.buildRule(), "chordClick without partner should not build")
        vm.chordWith = .left
        XCTAssertNotNil(vm.buildRule())
    }

    func testCanAdvanceGating() {
        let vm = RuleWizardViewModel()
        XCTAssertFalse(vm.canAdvance)         // no button yet
        vm.button = .middle
        XCTAssertTrue(vm.canAdvance)
    }

    func testRequiredParamGating() {
        let vm = RuleWizardViewModel()
        vm.button = .middle; vm.gesture = .single; vm.actionType = "app.launch"
        vm.step = .params
        XCTAssertFalse(vm.canAdvance, "app.launch needs bundleID")
        vm.params["bundleID"] = .string("com.apple.finder")
        XCTAssertTrue(vm.canAdvance)
    }
}

final class MouseTesterViewModelTests: XCTestCase {
    func testDetectsButtonsFromLiveEvents() {
        let ipc = StubIPCClient()
        let vm = MouseTesterViewModel(ipc: ipc)
        vm.startDetecting()
        ipc.emitLiveButton(.button4)
        ipc.emitLiveButton(.button5)
        XCTAssertEqual(vm.detected, [.button4, .button5])
        XCTAssertEqual(vm.lastPressed, .button5)
        XCTAssertTrue(ipc.sent.contains(.enterLearningMode))
    }

    func testIgnoresEventsWhenNotDetecting() {
        let ipc = StubIPCClient()
        let vm = MouseTesterViewModel(ipc: ipc)
        ipc.emitLiveButton(.button4)
        XCTAssertTrue(vm.detected.isEmpty)
    }

    func testStopSendsExitLearning() {
        let ipc = StubIPCClient()
        let vm = MouseTesterViewModel(ipc: ipc)
        vm.startDetecting(); vm.stopDetecting()
        XCTAssertTrue(ipc.sent.contains(.exitLearningMode))
        XCTAssertFalse(vm.isDetecting)
    }
}
