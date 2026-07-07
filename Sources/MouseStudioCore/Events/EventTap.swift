#if canImport(CoreGraphics)
import Foundation
import CoreGraphics
import MouseStudioShared

/// Production event source backed by a `CGEventTap`. Captures mouse button and
/// scroll events, normalizes them into `RawEvent`s, and forwards them.
///
/// Requires Accessibility permission to actually receive events (TDD §12). It
/// also self-heals if macOS disables the tap (`kCGEventTapDisabledByTimeout` /
/// `ByUserInput`), a common production pitfall.
///
/// For Phase 1 the tap passes every event through unchanged; event suppression
/// (swallowing mapped buttons) is layered on in a later phase.
public final class EventTap: EventSource {
    public var onEvent: ((RawEvent) -> Void)?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let runLoop: CFRunLoop

    /// - Parameter runLoop: the run loop to attach the tap to (defaults to current).
    public init(runLoop: CFRunLoop = CFRunLoopGetCurrent()) {
        self.runLoop = runLoop
    }

    public func start() throws {
        guard tap == nil else { return }

        let mask: CGEventMask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.rightMouseUp.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue)

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: refcon
        ) else {
            throw EventSourceError.tapCreationFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.runLoopSource = source
    }

    public func stop() {
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
        }
        runLoopSource = nil
        tap = nil
    }

    /// Re-enable the tap after macOS disables it. Called from the callback.
    fileprivate func reEnable() {
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    /// Normalize a CGEvent into a RawEvent, or nil if it isn't one we care about.
    fileprivate func normalize(type: CGEventType, event: CGEvent) -> RawEvent? {
        let t = DispatchTime.now().uptimeNanoseconds
        switch type {
        case .leftMouseDown:  return .down(.left, at: t)
        case .leftMouseUp:    return .up(.left, at: t)
        case .rightMouseDown: return .down(.right, at: t)
        case .rightMouseUp:   return .up(.right, at: t)
        case .otherMouseDown, .otherMouseUp:
            let number = Int(event.getIntegerValueField(.mouseEventButtonNumber))
            guard let button = ButtonID(cgButtonNumber: number) else { return nil }
            return type == .otherMouseDown ? .down(button, at: t) : .up(button, at: t)
        case .scrollWheel:
            let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
            if delta == 0 { return nil }
            return .scroll(delta > 0 ? .up : .down, at: t)
        default:
            return nil
        }
    }
}

/// Top-level C callback for the CGEventTap. Recovers the `EventTap` from refcon.
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        tap.reEnable()
        return Unmanaged.passUnretained(event)
    }

    if let raw = tap.normalize(type: type, event: event) {
        tap.onEvent?(raw)
    }

    // Phase 1: pass every event through unchanged.
    return Unmanaged.passUnretained(event)
}
#endif
