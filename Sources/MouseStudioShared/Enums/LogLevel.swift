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
}
