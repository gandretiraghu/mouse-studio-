// MouseStudioActions
// Concrete ActionProvider implementations (the future plugin seam is ActionProvider).
//
// Phase 3 providers (see docs/TechnicalDesignDocument.md §4, §5.2):
//   AppLaunchProvider   — app.launch
//   ClipboardProvider   — clipboard.copy/paste/cut/undo/redo/selectAll
//   ScreenshotProvider  — screenshot.area/window/clipboard/desktop
//   VolumeProvider      — volume.up/down/mute
//   BrightnessProvider  — brightness.up/down
//   DesktopProvider     — desktop.nextSpace/prevSpace/missionControl/showDesktop/launchpad
//   KeystrokeProvider   — keystroke.send (browser back/forward, etc.)

import Foundation
import MouseStudioCore
import MouseStudioShared

import MouseStudioCore

public enum MouseStudioActions {
    public static let module = "MouseStudioActions"

    /// Build the full set of MVP action providers wired to real macOS effectors.
    /// The service registers these with the dispatcher (TDD §3, §5.2).
    public static func makeDefaultProviders(effectors: Effectors = .system()) -> [ActionProvider] {
        [
            AppLaunchProvider(app: effectors.app),
            ClipboardProvider(keyboard: effectors.keyboard),
            KeystrokeProvider(keyboard: effectors.keyboard),
            ScreenshotProvider(process: effectors.process),
            VolumeProvider(script: effectors.script),
            BrightnessProvider(systemKey: effectors.systemKey),
            DesktopProvider(keyboard: effectors.keyboard, process: effectors.process)
        ]
    }
}
