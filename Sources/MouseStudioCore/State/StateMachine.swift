import Foundation
import MouseStudioShared

/// Resolves raw button/scroll events into high-level gestures — single, double,
/// long press, chord click, and chord scroll — without conflicts (TDD §8).
///
/// The machine is driven entirely by `feed(_:)` and by timeouts scheduled through
/// an injected `Scheduler`, so its timing behavior is fully deterministic under
/// test (`ManualScheduler`) and lock-free in production (all calls happen on the
/// engine's serial queue).
///
/// Concurrency: NOT thread-safe on its own. Call all methods from a single queue.
public final class StateMachine {

    // MARK: Per-button phase

    private enum Phase {
        case idle
        case pendingDown      // pressed; waiting to become single / double / long / chord
        case longActive       // held past long-press threshold; long emitted on release
        case waitSecond       // released; waiting for a possible second click (double)
        case doubleDown       // second press seen within window; double emitted on release
        case chordMember      // participating in a chord; release is silent
    }

    private final class ButtonState {
        var phase: Phase = .idle
        var longToken: ScheduledToken?
        var doubleToken: ScheduledToken?
        var chordFired = false
    }

    // MARK: Configuration

    public var timing: TimingConfig
    private var doubleMapped: Set<ButtonID> = []

    /// Called on the same queue whenever a gesture is resolved.
    public var onGesture: ((Gesture) -> Void)?

    private let scheduler: Scheduler
    private var states: [ButtonID: ButtonState] = [:]

    public init(timing: TimingConfig = .default, scheduler: Scheduler) {
        self.timing = timing
        self.scheduler = scheduler
    }

    /// Buttons that have a `.double` mapping. Buttons NOT in this set skip the
    /// double-click wait and emit `.single` immediately on release (TDD §8.1, §14).
    public func setDoubleMappedButtons(_ set: Set<ButtonID>) {
        doubleMapped = set
    }

    /// Reset all per-button state (e.g., on config reload or engine restart).
    public func reset() {
        for state in states.values {
            state.longToken?.cancel()
            state.doubleToken?.cancel()
        }
        states.removeAll()
    }

    // MARK: Event intake

    public func feed(_ event: RawEvent) {
        switch event.type {
        case .buttonDown:
            guard let button = event.button else { return }
            handleDown(button, at: event.timestampNanos)
        case .buttonUp:
            guard let button = event.button else { return }
            handleUp(button, at: event.timestampNanos)
        case .scroll:
            guard let dir = event.scrollDirection else { return }
            handleScroll(dir, at: event.timestampNanos)
        }
    }

    // MARK: - Down

    private func handleDown(_ button: ButtonID, at t: UInt64) {
        // If another button is physically held, this press is a chord click on it.
        if let anchor = heldAnchor(excluding: button) {
            fireChordClick(anchor: anchor, chordButton: button, at: t)
            // The pressed button becomes a silent chord member until released.
            let s = state(for: button)
            cancelTimers(s)
            s.phase = .chordMember
            s.chordFired = true
            return
        }

        let s = state(for: button)
        switch s.phase {
        case .idle, .chordMember:
            s.chordFired = false
            s.phase = .pendingDown
            cancelTimers(s)
            s.longToken = scheduler.schedule(afterMs: timing.longPressMs) { [weak s] in
                guard let s, s.phase == .pendingDown else { return }
                s.phase = .longActive   // long is emitted on release (TDD §8.1)
            }
        case .waitSecond:
            // Second press within the double window → candidate double.
            s.doubleToken?.cancel()
            s.doubleToken = nil
            s.phase = .doubleDown
        default:
            // Unexpected order; defensively restart this button.
            cancelTimers(s)
            s.phase = .pendingDown
            s.chordFired = false
            s.longToken = scheduler.schedule(afterMs: timing.longPressMs) { [weak s] in
                guard let s, s.phase == .pendingDown else { return }
                s.phase = .longActive
            }
        }
    }

    // MARK: - Up

    private func handleUp(_ button: ButtonID, at t: UInt64) {
        let s = state(for: button)
        switch s.phase {
        case .pendingDown:
            cancelTimers(s)
            if doubleMapped.contains(button) {
                s.phase = .waitSecond
                s.doubleToken = scheduler.schedule(afterMs: timing.doubleClickMs) { [weak self, weak s] in
                    guard let self, let s, s.phase == .waitSecond else { return }
                    s.phase = .idle
                    self.emit(Gesture(anchor: button, kind: .single, timestampNanos: t))
                }
            } else {
                s.phase = .idle
                emit(Gesture(anchor: button, kind: .single, timestampNanos: t))
            }

        case .longActive:
            cancelTimers(s)
            s.phase = .idle
            emit(Gesture(anchor: button, kind: .long, timestampNanos: t))

        case .doubleDown:
            cancelTimers(s)
            s.phase = .idle
            emit(Gesture(anchor: button, kind: .double, timestampNanos: t))

        case .chordMember:
            // Anchor (or member) release after a chord: suppress its own single.
            cancelTimers(s)
            s.phase = .idle
            s.chordFired = false

        case .idle, .waitSecond:
            // Nothing meaningful to do on release in these phases.
            break
        }
    }

    // MARK: - Scroll

    private func handleScroll(_ dir: ScrollDirection, at t: UInt64) {
        guard let anchor = heldAnchor(excluding: nil) else {
            // Plain scroll with no anchor held: not our concern (passed through).
            return
        }
        let a = state(for: anchor)
        cancelTimers(a)
        a.phase = .chordMember
        a.chordFired = true
        let kind: GestureKind = (dir == .up) ? .chordScrollUp : .chordScrollDown
        emit(Gesture(anchor: anchor, kind: kind, scroll: dir, timestampNanos: t))
    }

    // MARK: - Helpers

    private func fireChordClick(anchor: ButtonID, chordButton: ButtonID, at t: UInt64) {
        let a = state(for: anchor)
        cancelTimers(a)
        a.phase = .chordMember
        a.chordFired = true
        emit(Gesture(anchor: anchor, kind: .chordClick, chordButton: chordButton, timestampNanos: t))
    }

    /// A button currently physically pressed that can serve as a chord anchor.
    private func heldAnchor(excluding: ButtonID?) -> ButtonID? {
        for (button, s) in states {
            if button == excluding { continue }
            switch s.phase {
            case .pendingDown, .longActive, .chordMember:
                return button
            default:
                continue
            }
        }
        return nil
    }

    private func state(for button: ButtonID) -> ButtonState {
        if let s = states[button] { return s }
        let s = ButtonState()
        states[button] = s
        return s
    }

    private func cancelTimers(_ s: ButtonState) {
        s.longToken?.cancel(); s.longToken = nil
        s.doubleToken?.cancel(); s.doubleToken = nil
    }

    private func emit(_ gesture: Gesture) {
        onGesture?(gesture)
    }
}
