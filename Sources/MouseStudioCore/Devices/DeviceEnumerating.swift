import Foundation

/// A connected pointing device as reported by the OS (identity fields only).
public struct DetectedDevice: Equatable, Sendable {
    public var vendorId: Int?
    public var productId: Int?
    public var productName: String?

    public init(vendorId: Int? = nil, productId: Int? = nil, productName: String? = nil) {
        self.vendorId = vendorId
        self.productId = productId
        self.productName = productName
    }
}

/// Abstraction over device discovery so `DeviceManager` matching is testable
/// without hardware. A real IOKit HID enumerator is added in a later phase; the
/// primary "Detect Mouse" flow uses the event-tap learning mode (TDD §7.3).
public protocol DeviceEnumerating: AnyObject {
    func connectedPointingDevices() -> [DetectedDevice]
}

/// A stub enumerator returning a fixed device list (used by tests and as a safe
/// default until the IOKit enumerator lands).
public final class StaticDeviceEnumerator: DeviceEnumerating {
    private let devices: [DetectedDevice]
    public init(devices: [DetectedDevice] = []) { self.devices = devices }
    public func connectedPointingDevices() -> [DetectedDevice] { devices }
}
