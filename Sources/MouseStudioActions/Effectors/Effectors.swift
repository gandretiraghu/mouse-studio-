import Foundation

/// The side-effect surfaces that action providers depend on. Injecting these
/// keeps providers testable: unit tests use spies, production uses the real
/// macOS implementations (TDD §5.2 "each action isolated").
public protocol KeyboardShortcutEmitting: AnyObject {
    /// Post the given key combination to the system.
    func emit(_ shortcut: KeyShortcut)
}

public protocol AppControlling: AnyObject {
    /// Launch (or focus) an app by bundle identifier. Returns success.
    func launch(bundleID: String) -> Bool
    /// Bring an already-running app to the front. Returns success.
    func activate(bundleID: String) -> Bool
}

public protocol ScriptRunning: AnyObject {
    /// Run an AppleScript source string. Returns success.
    func run(_ source: String) -> Bool
}

public protocol ProcessRunning: AnyObject {
    /// Run an executable with arguments. Returns success.
    func run(_ launchPath: String, _ arguments: [String]) -> Bool
}

public protocol SystemKeyPosting: AnyObject {
    func postBrightnessUp()
    func postBrightnessDown()
}

/// A bundle of effectors passed to the provider factory.
public struct Effectors {
    public let keyboard: KeyboardShortcutEmitting
    public let app: AppControlling
    public let script: ScriptRunning
    public let process: ProcessRunning
    public let systemKey: SystemKeyPosting

    public init(
        keyboard: KeyboardShortcutEmitting,
        app: AppControlling,
        script: ScriptRunning,
        process: ProcessRunning,
        systemKey: SystemKeyPosting
    ) {
        self.keyboard = keyboard
        self.app = app
        self.script = script
        self.process = process
        self.systemKey = systemKey
    }
}
