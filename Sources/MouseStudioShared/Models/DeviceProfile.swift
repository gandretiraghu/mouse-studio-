import Foundation

/// Criteria used to recognize a connected device. All present fields must match
/// for the criteria to apply. Empty criteria match nothing (they mark a generic
/// fallback profile) — TDD §9.3.
public struct MatchCriteria: Codable, Equatable, Sendable {
    public var vendorId: Int?
    public var productId: Int?
    public var productName: String?

    public init(vendorId: Int? = nil, productId: Int? = nil, productName: String? = nil) {
        self.vendorId = vendorId
        self.productId = productId
        self.productName = productName
    }

    public var isEmpty: Bool {
        vendorId == nil && productId == nil && productName == nil
    }

    /// True if every present field equals the device's corresponding value.
    /// A case-insensitive substring test is used for `productName` so "GM100"
    /// matches "ANT Esports GM100".
    public func matches(vendorId: Int?, productId: Int?, productName: String?) -> Bool {
        if isEmpty { return false }
        if let v = self.vendorId, v != vendorId { return false }
        if let p = self.productId, p != productId { return false }
        if let name = self.productName {
            guard let deviceName = productName,
                  deviceName.lowercased().contains(name.lowercased()) else { return false }
        }
        return true
    }
}

/// Describes one button on a device.
public struct ButtonDescriptor: Codable, Equatable, Sendable {
    public var id: ButtonID
    public var displayName: String
    /// False for hardware-only buttons the software can't see (e.g., DPI).
    public var detectable: Bool

    public init(id: ButtonID, displayName: String, detectable: Bool) {
        self.id = id
        self.displayName = displayName
        self.detectable = detectable
    }
}

/// A supported device. GM100 is one of these; unknown mice fall back to a
/// generic profile (TDD §3, §9.3).
public struct DeviceProfile: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var displayName: String
    public var match: MatchCriteria
    public var buttons: [ButtonDescriptor]
    public var supportedGestures: [GestureKind]

    public init(
        id: String,
        displayName: String,
        match: MatchCriteria = MatchCriteria(),
        buttons: [ButtonDescriptor] = [],
        supportedGestures: [GestureKind] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.match = match
        self.buttons = buttons
        self.supportedGestures = supportedGestures
    }

    /// The buttons that software can detect and bind.
    public var detectableButtons: [ButtonDescriptor] {
        buttons.filter { $0.detectable }
    }
}
