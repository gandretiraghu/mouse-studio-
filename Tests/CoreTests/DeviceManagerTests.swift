import XCTest
@testable import MouseStudioCore
import MouseStudioShared

final class DeviceManagerTests: XCTestCase {

    private func gm100() -> DeviceProfile {
        DeviceProfile(
            id: "ant-gm100",
            displayName: "ANT Esports GM100",
            match: MatchCriteria(productName: "GM100"),
            buttons: [
                ButtonDescriptor(id: .left, displayName: "L", detectable: true),
                ButtonDescriptor(id: .right, displayName: "R", detectable: true),
                ButtonDescriptor(id: .middle, displayName: "M", detectable: true),
                ButtonDescriptor(id: .button4, displayName: "B4", detectable: true),
                ButtonDescriptor(id: .button5, displayName: "B5", detectable: true)
            ],
            supportedGestures: GestureKind.allCases
        )
    }

    private func generic5() -> DeviceProfile {
        DeviceProfile(
            id: "generic-5button",
            displayName: "Generic 5-Button",
            match: MatchCriteria(),
            buttons: (0..<5).map { _ in ButtonDescriptor(id: .left, displayName: "x", detectable: true) }
        )
    }

    private func generic3() -> DeviceProfile {
        DeviceProfile(
            id: "generic-3button",
            displayName: "Generic 3-Button",
            match: MatchCriteria(),
            buttons: (0..<3).map { _ in ButtonDescriptor(id: .left, displayName: "x", detectable: true) }
        )
    }

    func testSpecificMatchByProductNameSubstring() {
        let manager = DeviceManager(profiles: [generic5(), gm100()])
        let matched = manager.match(DetectedDevice(productName: "ANT Esports GM100"))
        XCTAssertEqual(matched?.id, "ant-gm100")
    }

    func testFallbackToGeneric5WhenNoSpecificMatch() {
        let manager = DeviceManager(profiles: [generic3(), generic5(), gm100()])
        let chosen = manager.selectProfile(for: DetectedDevice(productName: "Unknown Mouse"))
        XCTAssertEqual(chosen?.id, "generic-5button")
    }

    func testFallbackToMostButtonsWhenNoGeneric5() {
        let manager = DeviceManager(profiles: [generic3()])
        let chosen = manager.selectProfile(for: nil)
        XCTAssertEqual(chosen?.id, "generic-3button")
    }

    func testDetectActiveProfileUsesEnumerator() {
        let enumerator = StaticDeviceEnumerator(devices: [DetectedDevice(productName: "My GM100 Pro")])
        let manager = DeviceManager(profiles: [generic5(), gm100()], enumerator: enumerator)
        let chosen = manager.detectActiveProfile()
        XCTAssertEqual(chosen?.id, "ant-gm100")
        XCTAssertEqual(manager.active?.id, "ant-gm100")
    }

    func testEmptyCriteriaDoesNotMatchSpecificDevice() {
        let manager = DeviceManager(profiles: [generic5()])
        XCTAssertNil(manager.match(DetectedDevice(productName: "Anything")))
    }

    func testMakeLearnedProfileFromDetectedButtons() {
        let manager = DeviceManager(profiles: [])
        let profile = manager.makeLearnedProfile(
            id: "learned",
            displayName: "My Mouse",
            detectedButtons: [.left, .right, .button4]
        )
        XCTAssertEqual(profile.buttons.map { $0.id }, [.left, .right, .button4])
        XCTAssertTrue(profile.buttons.allSatisfy { $0.detectable })
    }
}
