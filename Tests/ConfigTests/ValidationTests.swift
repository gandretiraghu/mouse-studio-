import XCTest
@testable import MouseStudioConfig
import MouseStudioShared

final class ValidationTests: XCTestCase {

    private let validator = ConfigValidator()

    private func rule(
        _ id: String,
        _ button: ButtonID,
        _ gesture: GestureKind,
        chordWith: ButtonID? = nil,
        enabled: Bool = true
    ) -> Rule {
        Rule(id: id, enabled: enabled,
             trigger: TriggerSpec(button: button, gesture: gesture, chordWith: chordWith),
             action: ActionSpec(type: "app.launch"))
    }

    func testValidDefaultConfigHasNoErrors() {
        let errors = validator.validate(config: DefaultConfig.config(), profiles: [DefaultConfig.profile()])
        XCTAssertTrue(errors.isEmpty, "default config should be clean, got \(errors)")
    }

    func testUnsupportedSchemaVersion() {
        let config = Config(schemaVersion: 99, activeProfile: "default")
        let errors = validator.validate(config: config, profiles: [Profile(id: "default", displayName: "D")])
        XCTAssertTrue(errors.contains(.unsupportedSchemaVersion(99)))
    }

    func testTimingOutOfRange() {
        let config = Config(activeProfile: "default", timing: TimingConfig(doubleClickMs: 50, longPressMs: 5000))
        let errors = validator.validate(config: config, profiles: [Profile(id: "default", displayName: "D")])
        XCTAssertTrue(errors.contains(.timingOutOfRange(field: "doubleClickMs", value: 50)))
        XCTAssertTrue(errors.contains(.timingOutOfRange(field: "longPressMs", value: 5000)))
    }

    func testUnknownActiveProfile() {
        let config = Config(activeProfile: "missing")
        let errors = validator.validate(config: config, profiles: [Profile(id: "default", displayName: "D")])
        XCTAssertTrue(errors.contains(.unknownActiveProfile("missing")))
    }

    func testChordClickMissingPartner() {
        let profile = Profile(id: "p", displayName: "P", rules: [
            rule("bad", .button4, .chordClick, chordWith: nil)
        ])
        XCTAssertTrue(validator.validate(profile: profile).contains(.chordClickMissingPartner(ruleID: "bad")))
    }

    func testDuplicateRuleID() {
        let profile = Profile(id: "p", displayName: "P", rules: [
            rule("dup", .button4, .single),
            rule("dup", .button5, .single)
        ])
        XCTAssertTrue(validator.validate(profile: profile).contains(.duplicateRuleID("dup")))
    }

    func testConflictDetectedForSameTriggerKey() {
        let profile = Profile(id: "p", displayName: "P", rules: [
            rule("a", .button4, .single),
            rule("b", .button4, .single)
        ])
        let conflicts = validator.conflicts(in: profile)
        XCTAssertEqual(conflicts, [.conflict(ruleIDs: ["a", "b"])])
        XCTAssertTrue(conflicts.allSatisfy { $0.isWarning })
    }

    func testDisabledRulesDoNotConflict() {
        let profile = Profile(id: "p", displayName: "P", rules: [
            rule("a", .button4, .single),
            rule("b", .button4, .single, enabled: false)
        ])
        XCTAssertTrue(validator.conflicts(in: profile).isEmpty)
    }

    func testChordClickDifferentPartnersDoNotConflict() {
        let profile = Profile(id: "p", displayName: "P", rules: [
            rule("a", .button4, .chordClick, chordWith: .left),
            rule("b", .button4, .chordClick, chordWith: .right)
        ])
        XCTAssertTrue(validator.conflicts(in: profile).isEmpty)
    }
}
