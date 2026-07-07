import XCTest
@testable import MouseStudioActions
import MouseStudioShared

final class ProviderTests: XCTestCase {

    // MARK: App

    func testAppLaunchAndSwitch() {
        let spy = AppControlSpy()
        let provider = AppLaunchProvider(app: spy)
        XCTAssertEqual(provider.perform(ActionSpec(type: "app.launch", params: ["bundleID": .string("com.apple.finder")])), .ok)
        XCTAssertEqual(spy.launched, ["com.apple.finder"])
        XCTAssertEqual(provider.perform(ActionSpec(type: "app.switch", params: ["bundleID": .string("com.google.Chrome")])), .ok)
        XCTAssertEqual(spy.activated, ["com.google.Chrome"])
    }

    func testAppLaunchMissingBundleIDFails() {
        let provider = AppLaunchProvider(app: AppControlSpy())
        if case .failed = provider.perform(ActionSpec(type: "app.launch")) { } else { XCTFail("expected failure") }
    }

    func testAppLaunchPropagatesFailure() {
        let spy = AppControlSpy(); spy.launchResult = false
        let provider = AppLaunchProvider(app: spy)
        if case .failed = provider.perform(ActionSpec(type: "app.launch", params: ["bundleID": .string("x")])) { } else { XCTFail() }
    }

    // MARK: Clipboard

    func testClipboardEmitsShortcuts() {
        let kb = KeyboardSpy()
        let provider = ClipboardProvider(keyboard: kb)
        XCTAssertEqual(provider.perform(ActionSpec(type: "clipboard.copy")), .ok)
        XCTAssertEqual(provider.perform(ActionSpec(type: "clipboard.redo")), .ok)
        XCTAssertEqual(kb.emitted.first, KeyShortcut(modifiers: [.command], key: "c"))
        XCTAssertEqual(kb.emitted.last, KeyShortcut(modifiers: [.command, .shift], key: "z"))
    }

    func testClipboardUnknownIsIgnored() {
        let provider = ClipboardProvider(keyboard: KeyboardSpy())
        if case .ignored = provider.perform(ActionSpec(type: "clipboard.nope")) { } else { XCTFail() }
    }

    // MARK: Keystroke

    func testKeystrokeSendParsesAndEmits() {
        let kb = KeyboardSpy()
        let provider = KeystrokeProvider(keyboard: kb)
        XCTAssertEqual(provider.perform(ActionSpec(type: "keystroke.send", params: ["keys": .string("cmd+[")])), .ok)
        XCTAssertEqual(kb.emitted.first, KeyShortcut(modifiers: [.command], key: "["))
    }

    func testKeystrokeInvalidFails() {
        let provider = KeystrokeProvider(keyboard: KeyboardSpy())
        if case .failed = provider.perform(ActionSpec(type: "keystroke.send", params: ["keys": .string("hyper+q")])) { } else { XCTFail() }
    }

    // MARK: Screenshot

    func testScreenshotVariantsRunScreencapture() {
        let proc = ProcessSpy()
        let provider = ScreenshotProvider(process: proc, destinationDirectory: URL(fileURLWithPath: "/tmp"))
        XCTAssertEqual(provider.perform(ActionSpec(type: "screenshot.area")), .ok)
        XCTAssertEqual(provider.perform(ActionSpec(type: "screenshot.clipboard")), .ok)
        XCTAssertEqual(proc.calls.first?.path, "/usr/sbin/screencapture")
        XCTAssertTrue(proc.calls.first?.args.contains("-i") ?? false)
        XCTAssertTrue(proc.calls.last?.args.contains("-c") ?? false)
    }

    // MARK: Volume

    func testVolumeScripts() {
        let script = ScriptSpy()
        let provider = VolumeProvider(script: script, step: 6)
        XCTAssertEqual(provider.perform(ActionSpec(type: "volume.up")), .ok)
        XCTAssertEqual(provider.perform(ActionSpec(type: "volume.mute")), .ok)
        XCTAssertTrue(script.scripts.first?.contains("+ 6") ?? false)
        XCTAssertTrue(script.scripts.last?.contains("muted") ?? false)
    }

    // MARK: Brightness

    func testBrightnessPostsKeys() {
        let sys = SystemKeySpy()
        let provider = BrightnessProvider(systemKey: sys)
        XCTAssertEqual(provider.perform(ActionSpec(type: "brightness.up")), .ok)
        XCTAssertEqual(provider.perform(ActionSpec(type: "brightness.down")), .ok)
        XCTAssertEqual(sys.brightnessUp, 1)
        XCTAssertEqual(sys.brightnessDown, 1)
    }

    // MARK: Desktop

    func testDesktopSpacesAndLaunchpad() {
        let kb = KeyboardSpy(); let proc = ProcessSpy()
        let provider = DesktopProvider(keyboard: kb, process: proc)
        XCTAssertEqual(provider.perform(ActionSpec(type: "desktop.nextSpace")), .ok)
        XCTAssertEqual(kb.emitted.first, KeyShortcut(modifiers: [.control], key: "right"))
        XCTAssertEqual(provider.perform(ActionSpec(type: "desktop.launchpad")), .ok)
        XCTAssertEqual(proc.calls.first?.path, "/usr/bin/open")
        XCTAssertEqual(proc.calls.first?.args, ["-a", "Launchpad"])
    }

    // MARK: Factory + descriptors

    func testMakeDefaultProvidersCoversAllNamespaces() {
        let (effectors, _, _, _, _, _) = Effectors.spies()
        let providers = MouseStudioActions.makeDefaultProviders(effectors: effectors)
        let namespaces = Set(providers.map { $0.namespace })
        XCTAssertEqual(namespaces, ["app", "clipboard", "keystroke", "screenshot", "volume", "brightness", "desktop"])
        // Every provider advertises at least one action.
        XCTAssertTrue(providers.allSatisfy { !$0.supportedActions().isEmpty })
    }

    func testDefaultConfigActionsAreAllRoutable() {
        // Every action type used by the default rules must map to a registered provider.
        let (effectors, _, _, _, _, _) = Effectors.spies()
        let providers = MouseStudioActions.makeDefaultProviders(effectors: effectors)
        let namespaces = Set(providers.map { $0.namespace })
        let usedNamespaces = ["screenshot", "app", "keystroke", "volume", "desktop", "clipboard", "brightness"]
        for ns in usedNamespaces {
            XCTAssertTrue(namespaces.contains(ns), "no provider for namespace \(ns)")
        }
    }
}
