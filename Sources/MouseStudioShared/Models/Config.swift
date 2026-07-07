import Foundation

/// Logging preferences persisted in config (TDD §9.1).
public struct LoggingConfig: Codable, Equatable, Sendable {
    public var level: LogLevel
    public var perf: Bool

    public init(level: LogLevel = .info, perf: Bool = false) {
        self.level = level
        self.perf = perf
    }

    private enum CodingKeys: String, CodingKey { case level, perf }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        level = try c.decodeIfPresent(LogLevel.self, forKey: .level) ?? .info
        perf = try c.decodeIfPresent(Bool.self, forKey: .perf) ?? false
    }
}

/// Top-level, global configuration (TDD §9.1). Rules live in profiles, not here.
public struct Config: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var activeProfile: String
    public var timing: TimingConfig
    public var logging: LoggingConfig

    public init(
        schemaVersion: Int = 1,
        activeProfile: String,
        timing: TimingConfig = .default,
        logging: LoggingConfig = LoggingConfig()
    ) {
        self.schemaVersion = schemaVersion
        self.activeProfile = activeProfile
        self.timing = timing
        self.logging = logging
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, activeProfile, timing, logging
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        activeProfile = try c.decode(String.self, forKey: .activeProfile)
        timing = try c.decodeIfPresent(TimingConfig.self, forKey: .timing) ?? .default
        logging = try c.decodeIfPresent(LoggingConfig.self, forKey: .logging) ?? LoggingConfig()
    }
}
