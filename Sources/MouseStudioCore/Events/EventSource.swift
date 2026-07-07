import Foundation
import MouseStudioShared

/// Abstraction over a source of normalized `RawEvent`s. Production uses
/// `EventTap` (CGEventTap); tests and the "test rule" feature use
/// `SimulatedEventSource` (TDD §16.4).
public protocol EventSource: AnyObject {
    /// Invoked for each normalized event. Set before `start()`.
    var onEvent: ((RawEvent) -> Void)? { get set }
    /// Begin delivering events. May throw if the OS resource can't be acquired.
    func start() throws
    /// Stop delivering events and release resources.
    func stop()
}

/// Errors an `EventSource` may throw when starting.
public enum EventSourceError: Error, Equatable {
    /// The event tap could not be created (commonly: Accessibility not granted).
    case tapCreationFailed
    case accessibilityNotTrusted
}
