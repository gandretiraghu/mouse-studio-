import Foundation

/// Logging verbosity levels, ordered by increasing severity.
public enum LogLevel: Int, Codable, Comparable, Sendable, CaseIterable {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3

    public var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The lowercase token used in JSON config (matches the schema in TDD §9.1).
    public var token: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warn: return "warn"
        case .error: return "error"
        }
    }

    public init?(token: String) {
        switch token.lowercased() {
        case "debug": self = .debug
        case "info": self = .info
        case "warn": self = .warn
        case "error": self = .error
        default: return nil
        }
    }

    // Encode/decode as a lowercase string so config JSON reads naturally.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let level = LogLevel(token: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown log level '\(raw)'"
            )
        }
        self = level
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(token)
    }
}
