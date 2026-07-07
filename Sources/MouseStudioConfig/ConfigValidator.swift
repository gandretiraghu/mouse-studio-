import Foundation
import MouseStudioShared

/// Validates config + profiles, returning all problems found (TDD §15, §19.3).
public struct ConfigValidator {
    public static let supportedSchemaVersion = MouseStudio.schemaVersion

    // Timing bounds mirror the JSON schema (TDD §9.1).
    public static let doubleClickRange = 100...600
    public static let longPressRange = 150...1000

    public init() {}

    /// Validate a config together with the profiles it references. The order is:
    /// errors first (would block loading), then warnings (conflicts).
    public func validate(config: Config, profiles: [Profile]) -> [ValidationError] {
        var errors: [ValidationError] = []

        if config.schemaVersion != Self.supportedSchemaVersion {
            errors.append(.unsupportedSchemaVersion(config.schemaVersion))
        }
        if !Self.doubleClickRange.contains(config.timing.doubleClickMs) {
            errors.append(.timingOutOfRange(field: "doubleClickMs", value: config.timing.doubleClickMs))
        }
        if !Self.longPressRange.contains(config.timing.longPressMs) {
            errors.append(.timingOutOfRange(field: "longPressMs", value: config.timing.longPressMs))
        }
        if !profiles.contains(where: { $0.id == config.activeProfile }) {
            errors.append(.unknownActiveProfile(config.activeProfile))
        }

        for profile in profiles {
            errors.append(contentsOf: validate(profile: profile))
        }
        return errors
    }

    /// Validate a single profile: id, rule ids, chord partners, and conflicts.
    public func validate(profile: Profile) -> [ValidationError] {
        var errors: [ValidationError] = []

        if profile.id.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.emptyProfileID)
        }

        var seenIDs = Set<String>()
        for rule in profile.rules {
            if !seenIDs.insert(rule.id).inserted {
                errors.append(.duplicateRuleID(rule.id))
            }
            if rule.trigger.gesture == .chordClick && rule.trigger.chordWith == nil {
                errors.append(.chordClickMissingPartner(ruleID: rule.id))
            }
        }

        errors.append(contentsOf: conflicts(in: profile))
        return errors
    }

    /// Group enabled rules by effective trigger key; any group with 2+ rules is a conflict.
    public func conflicts(in profile: Profile) -> [ValidationError] {
        struct Key: Hashable {
            let button: ButtonID
            let gesture: GestureKind
            let chordWith: ButtonID?
        }
        var groups: [Key: [String]] = [:]
        for rule in profile.rules where rule.enabled {
            let t = rule.trigger
            let key = Key(
                button: t.button,
                gesture: t.gesture,
                chordWith: t.gesture == .chordClick ? t.chordWith : nil
            )
            groups[key, default: []].append(rule.id)
        }
        return groups.values
            .filter { $0.count > 1 }
            .map { .conflict(ruleIDs: $0.sorted()) }
    }
}
