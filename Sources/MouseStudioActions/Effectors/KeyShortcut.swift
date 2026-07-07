import Foundation

/// A parsed keyboard shortcut (modifiers + a single key), independent of any OS
/// API so it can be unit-tested. Real emission happens in the effector layer.
public struct KeyShortcut: Equatable, Sendable {
    public enum Modifier: String, Sendable, CaseIterable {
        case command, shift, option, control
    }

    public let modifiers: Set<Modifier>
    /// Normalized (lowercase) key token, e.g. "c", "[", "right", "f11".
    public let key: String

    public init(modifiers: Set<Modifier>, key: String) {
        self.modifiers = modifiers
        self.key = key.lowercased()
    }

    /// Parse a string like "cmd+shift+4" / "cmd+[" / "ctrl+right".
    /// Returns nil if a modifier token is unknown or the key is unmapped.
    public init?(parsing string: String) {
        let tokens = string
            .split(separator: "+", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard let keyToken = tokens.last, !keyToken.isEmpty, tokens.count >= 1 else { return nil }

        var mods: Set<Modifier> = []
        for token in tokens.dropLast() {
            guard let mod = Self.modifier(for: token) else { return nil }
            mods.insert(mod)
        }
        // The key must be mappable to a virtual keycode.
        guard KeyCodeMap.code(for: keyToken) != nil else { return nil }
        self.modifiers = mods
        self.key = keyToken
    }

    /// The US virtual keycode for `key`.
    public var keyCode: UInt16? { KeyCodeMap.code(for: key) }

    private static func modifier(for token: String) -> Modifier? {
        switch token {
        case "cmd", "command", "⌘": return .command
        case "shift", "⇧": return .shift
        case "opt", "option", "alt", "⌥": return .option
        case "ctrl", "control", "⌃": return .control
        default: return nil
        }
    }
}

/// US ANSI virtual keycode table for the keys Mouse Studio needs.
public enum KeyCodeMap {
    private static let map: [String: UInt16] = [
        // Letters
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8,
        "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
        "o": 31, "u": 32, "i": 34, "p": 35, "l": 37, "j": 38, "k": 40, "n": 45, "m": 46,
        // Digits
        "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25, "0": 29,
        // Punctuation
        "[": 33, "]": 30, ";": 41, "'": 39, ",": 43, ".": 47, "/": 44,
        "\\": 42, "-": 27, "=": 24, "`": 50,
        // Named keys
        "space": 49, "return": 36, "enter": 36, "tab": 48, "escape": 53, "esc": 53,
        "delete": 51, "left": 123, "right": 124, "down": 125, "up": 126,
        // Function keys
        "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97,
        "f7": 98, "f8": 100, "f9": 101, "f10": 109, "f11": 103, "f12": 111
    ]

    public static func code(for key: String) -> UInt16? {
        map[key.lowercased()]
    }
}
