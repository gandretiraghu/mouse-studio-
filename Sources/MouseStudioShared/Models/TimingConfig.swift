import Foundation

/// Tunable timing thresholds for gesture disambiguation (TDD §8, §9.1).
public struct TimingConfig: Codable, Equatable, Sendable {
    /// Max gap between two clicks to count as a double click.
    public var doubleClickMs: Int
    /// Hold duration after which a press becomes a long press.
    public var longPressMs: Int

    public init(doubleClickMs: Int = 250, longPressMs: Int = 350) {
        self.doubleClickMs = doubleClickMs
        self.longPressMs = longPressMs
    }

    public static let `default` = TimingConfig()
}
