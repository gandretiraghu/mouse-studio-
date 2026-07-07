import Foundation

/// The canonical, data-only catalog of MVP actions. The GUI Action Browser reads
/// this to present categories and search without depending on the Actions module
/// (TDD §19.2). Action providers implement these same `type` identifiers.
public enum ActionCatalog {

    public static let all: [ActionDescriptor] = [
        // App
        ActionDescriptor(type: "app.launch", displayName: "Launch Application",
                         params: [appParam], category: "App",
                         keywords: ["open", "start", "run"]),
        ActionDescriptor(type: "app.switch", displayName: "Switch to Application",
                         params: [appParam], category: "App",
                         keywords: ["focus", "activate", "front"]),

        // Clipboard
        clip("clipboard.copy", "Copy", ["cmd+c"]),
        clip("clipboard.paste", "Paste", ["cmd+v"]),
        clip("clipboard.cut", "Cut", ["cmd+x"]),
        clip("clipboard.undo", "Undo", ["revert"]),
        clip("clipboard.redo", "Redo", ["again"]),
        clip("clipboard.selectAll", "Select All", ["all"]),

        // Screenshot
        shot("screenshot.area", "Screenshot: Selected Area", ["capture", "region"]),
        shot("screenshot.window", "Screenshot: Window", ["capture"]),
        shot("screenshot.clipboard", "Screenshot: Area to Clipboard", ["capture", "copy"]),
        shot("screenshot.desktop", "Screenshot: Full Screen", ["capture", "fullscreen"]),

        // Volume
        cat("volume.up", "Volume Up", "Volume", ["sound", "louder"]),
        cat("volume.down", "Volume Down", "Volume", ["sound", "quieter"]),
        cat("volume.mute", "Toggle Mute", "Volume", ["sound", "silence"]),

        // Brightness
        cat("brightness.up", "Brightness Up", "Brightness", ["display", "brighter"]),
        cat("brightness.down", "Brightness Down", "Brightness", ["display", "dimmer"]),

        // Desktop
        cat("desktop.nextSpace", "Next Desktop", "Desktop", ["space", "workspace"]),
        cat("desktop.prevSpace", "Previous Desktop", "Desktop", ["space", "workspace"]),
        cat("desktop.missionControl", "Mission Control", "Desktop", ["expose", "windows"]),
        cat("desktop.showDesktop", "Show Desktop", "Desktop", ["minimize"]),
        cat("desktop.launchpad", "Launchpad", "Desktop", ["apps"]),

        // Keyboard
        ActionDescriptor(type: "keystroke.send", displayName: "Send Keyboard Shortcut",
                         params: [ParamSpec(key: "keys", displayName: "Keys (e.g. cmd+[)", kind: .string)],
                         category: "Keyboard", keywords: ["hotkey", "shortcut", "key"])
    ]

    /// Category names in display order.
    public static let categories: [String] = {
        var seen = Set<String>()
        var ordered: [String] = []
        for descriptor in all {
            let c = descriptor.category ?? "Other"
            if seen.insert(c).inserted { ordered.append(c) }
        }
        return ordered
    }()

    /// Look up a descriptor by its `type`.
    public static func descriptor(for type: String) -> ActionDescriptor? {
        all.first { $0.type == type }
    }

    // MARK: Builders

    private static let appParam = ParamSpec(key: "bundleID", displayName: "Application", kind: .appBundleID)

    private static func clip(_ type: String, _ name: String, _ keywords: [String]) -> ActionDescriptor {
        ActionDescriptor(type: type, displayName: name, category: "Clipboard", keywords: keywords)
    }
    private static func shot(_ type: String, _ name: String, _ keywords: [String]) -> ActionDescriptor {
        ActionDescriptor(type: type, displayName: name, category: "Screenshot", keywords: keywords)
    }
    private static func cat(_ type: String, _ name: String, _ category: String, _ keywords: [String]) -> ActionDescriptor {
        ActionDescriptor(type: type, displayName: name, category: category, keywords: keywords)
    }
}
