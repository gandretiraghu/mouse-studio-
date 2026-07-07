import Foundation
@testable import MouseStudioActions

/// Spy effectors that record calls instead of touching the OS, so provider
/// behavior can be asserted deterministically in unit tests.
final class KeyboardSpy: KeyboardShortcutEmitting {
    private(set) var emitted: [KeyShortcut] = []
    func emit(_ shortcut: KeyShortcut) { emitted.append(shortcut) }
}

final class AppControlSpy: AppControlling {
    private(set) var launched: [String] = []
    private(set) var activated: [String] = []
    var launchResult = true
    var activateResult = true
    func launch(bundleID: String) -> Bool { launched.append(bundleID); return launchResult }
    func activate(bundleID: String) -> Bool { activated.append(bundleID); return activateResult }
}

final class ScriptSpy: ScriptRunning {
    private(set) var scripts: [String] = []
    var result = true
    func run(_ source: String) -> Bool { scripts.append(source); return result }
}

final class ProcessSpy: ProcessRunning {
    private(set) var calls: [(path: String, args: [String])] = []
    var result = true
    func run(_ launchPath: String, _ arguments: [String]) -> Bool {
        calls.append((launchPath, arguments)); return result
    }
}

final class SystemKeySpy: SystemKeyPosting {
    private(set) var brightnessUp = 0
    private(set) var brightnessDown = 0
    func postBrightnessUp() { brightnessUp += 1 }
    func postBrightnessDown() { brightnessDown += 1 }
}

extension Effectors {
    /// A bundle of spies for tests.
    static func spies() -> (Effectors, KeyboardSpy, AppControlSpy, ScriptSpy, ProcessSpy, SystemKeySpy) {
        let kb = KeyboardSpy()
        let app = AppControlSpy()
        let script = ScriptSpy()
        let proc = ProcessSpy()
        let sys = SystemKeySpy()
        return (Effectors(keyboard: kb, app: app, script: script, process: proc, systemKey: sys),
                kb, app, script, proc, sys)
    }
}
