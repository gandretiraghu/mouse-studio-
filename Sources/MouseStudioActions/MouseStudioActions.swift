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

public enum MouseStudioActions {
    public static let module = "MouseStudioActions"
}
