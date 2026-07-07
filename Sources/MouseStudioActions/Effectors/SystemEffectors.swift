import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Keyboard

/// Emits keyboard shortcuts via synthetic CGEvents.
public final class SystemKeyboardEmitter: KeyboardShortcutEmitting {
    public init() {}

    public func emit(_ shortcut: KeyShortcut) {
        #if canImport(CoreGraphics)
        guard let keyCode = shortcut.keyCode else { return }
        let source = CGEventSource(stateID: .combinedSessionState)
        var flags: CGEventFlags = []
        if shortcut.modifiers.contains(.command) { flags.insert(.maskCommand) }
        if shortcut.modifiers.contains(.shift) { flags.insert(.maskShift) }
        if shortcut.modifiers.contains(.option) { flags.insert(.maskAlternate) }
        if shortcut.modifiers.contains(.control) { flags.insert(.maskControl) }

        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        #endif
    }
}

// MARK: - App control

/// Launches / activates apps via NSWorkspace.
public final class SystemAppController: AppControlling {
    public init() {}

    public func launch(bundleID: String) -> Bool {
        #if canImport(AppKit)
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return false
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
        return true
        #else
        return false
        #endif
    }

    public func activate(bundleID: String) -> Bool {
        #if canImport(AppKit)
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if let app = running.first {
            return app.activate(options: [.activateAllWindows])
        }
        // Not running yet — launch it.
        return launch(bundleID: bundleID)
        #else
        return false
        #endif
    }
}

// MARK: - AppleScript

/// Runs AppleScript via NSAppleScript.
public final class SystemScriptRunner: ScriptRunning {
    public init() {}

    public func run(_ source: String) -> Bool {
        #if canImport(AppKit)
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        return error == nil
        #else
        return false
        #endif
    }
}

// MARK: - Process

/// Runs external executables via Process.
public final class SystemProcessRunner: ProcessRunning {
    public init() {}

    public func run(_ launchPath: String, _ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - System (brightness) keys

/// Posts system-defined brightness key events (no public brightness API exists).
public final class SystemMediaKeyPoster: SystemKeyPosting {
    // NX_KEYTYPE_BRIGHTNESS_UP / DOWN
    private let brightnessUp = 2
    private let brightnessDown = 3

    public init() {}

    public func postBrightnessUp() { postAuxKey(brightnessUp) }
    public func postBrightnessDown() { postAuxKey(brightnessDown) }

    private func postAuxKey(_ keyCode: Int) {
        #if canImport(AppKit)
        func post(down: Bool) {
            let flags: NSEvent.ModifierFlags = down ? NSEvent.ModifierFlags(rawValue: 0xA00) : NSEvent.ModifierFlags(rawValue: 0xB00)
            let data1 = (keyCode << 16) | ((down ? 0xA : 0xB) << 8)
            guard let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            ) else { return }
            event.cgEvent?.post(tap: .cghidEventTap)
        }
        post(down: true)
        post(down: false)
        #endif
    }
}

// MARK: - Factory helper

public extension Effectors {
    /// The production effector bundle wired to real macOS APIs.
    static func system() -> Effectors {
        Effectors(
            keyboard: SystemKeyboardEmitter(),
            app: SystemAppController(),
            script: SystemScriptRunner(),
            process: SystemProcessRunner(),
            systemKey: SystemMediaKeyPoster()
        )
    }
}
