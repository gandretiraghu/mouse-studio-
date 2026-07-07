import Foundation
import MouseStudioShared

/// An in-memory event source that injects synthetic events. Used by tests and by
/// the GUI "test rule" feature to exercise the full engine without real hardware
/// or Accessibility permission (TDD §16.4, §19.4).
public final class SimulatedEventSource: EventSource {
    public var onEvent: ((RawEvent) -> Void)?
    private var running = false

    public init() {}

    public func start() throws { running = true }
    public func stop() { running = false }

    /// Inject a raw event (no-op if not started).
    public func inject(_ event: RawEvent) {
        guard running else { return }
        onEvent?(event)
    }

    // MARK: Convenience injectors

    public func down(_ button: ButtonID, at t: UInt64 = 0) { inject(.down(button, at: t)) }
    public func up(_ button: ButtonID, at t: UInt64 = 0) { inject(.up(button, at: t)) }
    public func scroll(_ dir: ScrollDirection, at t: UInt64 = 0) { inject(.scroll(dir, at: t)) }
}
