import Foundation
import MouseStudioShared

/// Ships a usable out-of-the-box configuration: the default profile encodes the
/// GM100 SHORTCUT DATABASE from the project spec (TDD §9, project brief). This is
/// pure data — no hardcoded behavior in the engine.
public enum DefaultConfig {
    public static let defaultProfileID = "default"

    public static func config() -> Config {
        Config(activeProfile: defaultProfileID)
    }

    public static func profile() -> Profile {
        Profile(
            id: defaultProfileID,
            displayName: "Default",
            deviceProfile: "ant-gm100",
            rules: rules()
        )
    }

    /// The default mappings. Every entry is configurable by the user later.
    public static func rules() -> [Rule] {
        func rule(
            _ id: String,
            _ button: ButtonID,
            _ gesture: GestureKind,
            _ actionType: String,
            chordWith: ButtonID? = nil,
            params: [String: JSONValue] = [:]
        ) -> Rule {
            Rule(
                id: id,
                trigger: TriggerSpec(button: button, gesture: gesture, chordWith: chordWith),
                action: ActionSpec(type: actionType, params: params)
            )
        }

        return [
            // Middle button
            rule("mid-single", .middle, .single, "screenshot.area"),
            rule("mid-double", .middle, .double, "app.launch", params: ["bundleID": .string("dev.kiro.app")]),

            // Button4 (Side Back)
            rule("b4-single", .button4, .single, "keystroke.send", params: ["keys": .string("cmd+[")]),
            rule("b4-double", .button4, .double, "app.launch", params: ["bundleID": .string("com.apple.finder")]),
            rule("b4-chord-left", .button4, .chordClick, "app.switch", chordWith: .left, params: ["bundleID": .string("com.google.Chrome")]),
            rule("b4-chord-right", .button4, .chordClick, "app.switch", chordWith: .right, params: ["bundleID": .string("com.microsoft.edgemac")]),
            rule("b4-scroll-up", .button4, .chordScrollUp, "volume.up"),
            rule("b4-scroll-down", .button4, .chordScrollDown, "volume.down"),

            // Button5 (Side Forward)
            rule("b5-single", .button5, .single, "keystroke.send", params: ["keys": .string("cmd+]")]),
            rule("b5-double", .button5, .double, "desktop.nextSpace"),
            rule("b5-chord-left", .button5, .chordClick, "clipboard.copy", chordWith: .left),
            rule("b5-chord-right", .button5, .chordClick, "clipboard.paste", chordWith: .right),
            rule("b5-scroll-up", .button5, .chordScrollUp, "brightness.up"),
            rule("b5-scroll-down", .button5, .chordScrollDown, "brightness.down")
        ]
    }
}
