import Foundation

#if canImport(ApplicationServices)
import ApplicationServices
#endif

/// Abstraction over the Accessibility permission check so `EngineHost` is
/// testable without real TCC state (TDD §12).
public protocol PermissionChecking: AnyObject {
    /// Whether the process is trusted for Accessibility (required by CGEventTap).
    func isAccessibilityTrusted() -> Bool
    /// Prompt the user (shows the system dialog / opens Settings deep link).
    func promptForAccessibility()
}

/// Production checker backed by the Accessibility API.
public final class SystemPermissionChecker: PermissionChecking {
    public init() {}

    public func isAccessibilityTrusted() -> Bool {
        #if canImport(ApplicationServices)
        return AXIsProcessTrusted()
        #else
        return false
        #endif
    }

    public func promptForAccessibility() {
        #if canImport(ApplicationServices)
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        #endif
    }
}

/// A test double with a settable trusted flag.
public final class StubPermissionChecker: PermissionChecking {
    public var trusted: Bool
    public private(set) var promptCount = 0
    public init(trusted: Bool) { self.trusted = trusted }
    public func isAccessibilityTrusted() -> Bool { trusted }
    public func promptForAccessibility() { promptCount += 1 }
}
