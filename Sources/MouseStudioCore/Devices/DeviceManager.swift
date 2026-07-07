import Foundation
import MouseStudioShared

/// Chooses the active device profile for the connected mouse and supports
/// building a learned profile from detected buttons (TDD §5.1, §7.3, §9.3).
///
/// Matching precedence: a profile whose `match` criteria match the device wins;
/// otherwise a generic fallback is chosen (preferring the id `generic-5button`,
/// then the profile with the most detectable buttons).
public final class DeviceManager {
    private var profiles: [DeviceProfile]
    private let enumerator: DeviceEnumerating
    private let logger: Logger?

    private(set) public var active: DeviceProfile?

    public init(
        profiles: [DeviceProfile] = [],
        enumerator: DeviceEnumerating = StaticDeviceEnumerator(),
        logger: Logger? = nil
    ) {
        self.profiles = profiles
        self.enumerator = enumerator
        self.logger = logger
    }

    public func setProfiles(_ profiles: [DeviceProfile]) {
        self.profiles = profiles
    }

    public var availableProfiles: [DeviceProfile] { profiles }

    /// Find a profile whose criteria specifically match the given device.
    public func match(_ device: DetectedDevice) -> DeviceProfile? {
        profiles.first {
            $0.match.matches(
                vendorId: device.vendorId,
                productId: device.productId,
                productName: device.productName
            )
        }
    }

    /// Choose the best profile for a device (specific match, else generic fallback).
    public func selectProfile(for device: DetectedDevice?) -> DeviceProfile? {
        if let device, let matched = match(device) {
            return matched
        }
        return genericFallback()
    }

    /// Detect the connected device and set `active`. Returns the chosen profile.
    @discardableResult
    public func detectActiveProfile() -> DeviceProfile? {
        let device = enumerator.connectedPointingDevices().first
        let chosen = selectProfile(for: device)
        active = chosen
        if let chosen {
            logger?.info("Selected device profile '\(chosen.id)' for \(device?.productName ?? "unknown device")", subsystem: "devices")
        } else {
            logger?.warn("No device profile available", subsystem: "devices")
        }
        return chosen
    }

    /// Build a device profile from a set of buttons discovered via the Live
    /// Tester learning mode.
    public func makeLearnedProfile(
        id: String,
        displayName: String,
        detectedButtons: Set<ButtonID>
    ) -> DeviceProfile {
        let buttons = ButtonID.allCases
            .filter { detectedButtons.contains($0) }
            .map { ButtonDescriptor(id: $0, displayName: $0.rawValue, detectable: true) }
        return DeviceProfile(
            id: id,
            displayName: displayName,
            match: MatchCriteria(),
            buttons: buttons,
            supportedGestures: GestureKind.allCases
        )
    }

    // MARK: - Private

    private func genericFallback() -> DeviceProfile? {
        if let five = profiles.first(where: { $0.id == "generic-5button" }) {
            return five
        }
        return profiles.max { $0.detectableButtons.count < $1.detectableButtons.count }
    }
}
