import Foundation

/// A named set of rules the user can switch between (TDD §9.2, §19). Only rules
/// live here; global settings are in `Config`.
public struct Profile: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var displayName: String
    /// Optional device-profile id this profile is designed for.
    public var deviceProfile: String?
    public var rules: [Rule]

    public init(
        id: String,
        displayName: String,
        deviceProfile: String? = nil,
        rules: [Rule] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.deviceProfile = deviceProfile
        self.rules = rules
    }

    private enum CodingKeys: String, CodingKey {
        case id, displayName, deviceProfile, rules
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        displayName = try c.decode(String.self, forKey: .displayName)
        deviceProfile = try c.decodeIfPresent(String.self, forKey: .deviceProfile)
        rules = try c.decodeIfPresent([Rule].self, forKey: .rules) ?? []
    }
}
