import Foundation

/// A resolved gesture emitted by the state machine and consumed by the rule
/// engine (TDD §5.1, §8).
public struct Gesture: Equatable, Sendable {
    /// The primary button the gesture is attributed to (the chord anchor for chords).
    public let anchor: ButtonID
    public let kind: GestureKind
    /// The secondary button for `.chordClick`; nil otherwise.
    public let chordButton: ButtonID?
    /// The scroll direction for `.chordScrollUp` / `.chordScrollDown`; nil otherwise.
    public let scroll: ScrollDirection?
    public let timestampNanos: UInt64

    public init(
        anchor: ButtonID,
        kind: GestureKind,
        chordButton: ButtonID? = nil,
        scroll: ScrollDirection? = nil,
        timestampNanos: UInt64 = 0
    ) {
        self.anchor = anchor
        self.kind = kind
        self.chordButton = chordButton
        self.scroll = scroll
        self.timestampNanos = timestampNanos
    }
}
