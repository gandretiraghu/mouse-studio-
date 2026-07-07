import Foundation

/// A normalized low-level input event produced by the event layer and fed into
/// the state machine (TDD §5.1, §6). Device specifics are already resolved.
public struct RawEvent: Equatable, Sendable {
    public let type: RawEventType
    /// Present for `.buttonDown` / `.buttonUp`; nil for `.scroll`.
    public let button: ButtonID?
    /// Present for `.scroll`; nil otherwise.
    public let scrollDirection: ScrollDirection?
    /// Monotonic timestamp in nanoseconds (for perf/latency measurement).
    public let timestampNanos: UInt64

    public init(
        type: RawEventType,
        button: ButtonID? = nil,
        scrollDirection: ScrollDirection? = nil,
        timestampNanos: UInt64 = 0
    ) {
        self.type = type
        self.button = button
        self.scrollDirection = scrollDirection
        self.timestampNanos = timestampNanos
    }

    // MARK: Factory helpers

    public static func down(_ button: ButtonID, at t: UInt64 = 0) -> RawEvent {
        RawEvent(type: .buttonDown, button: button, timestampNanos: t)
    }

    public static func up(_ button: ButtonID, at t: UInt64 = 0) -> RawEvent {
        RawEvent(type: .buttonUp, button: button, timestampNanos: t)
    }

    public static func scroll(_ direction: ScrollDirection, at t: UInt64 = 0) -> RawEvent {
        RawEvent(type: .scroll, scrollDirection: direction, timestampNanos: t)
    }
}
