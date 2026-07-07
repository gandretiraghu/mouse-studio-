// MouseStudioCore
// The automation engine. Headless and independently testable — NO AppKit/SwiftUI UI.
// May use CoreGraphics/IOKit for event taps.
//
// Contents (see docs/TechnicalDesignDocument.md §4, §5.1):
//   Events/   — EventTap, RawEvent normalization
//   State/    — StateMachine, per-button state, one-shot timers
//   Rules/    — RuleEngine, Trigger matching, Condition evaluation
//   Dispatch/ — ActionDispatcher
//   Devices/  — DeviceManager, DeviceProfile loading, learning mode
//   Logging/  — Logger, bounded log ring buffer, perf timing

import Foundation
import MouseStudioShared

public enum MouseStudioCore {
    public static let module = "MouseStudioCore"
}
