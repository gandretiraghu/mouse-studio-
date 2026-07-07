import Foundation

/// A structured log record, surfaced in the GUI Logs view (TDD §15).
public struct LogEntry: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let level: LogLevel
    public let subsystem: String
    public let message: String
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        level: LogLevel,
        subsystem: String,
        message: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.level = level
        self.subsystem = subsystem
        self.message = message
        self.timestamp = timestamp
    }
}
