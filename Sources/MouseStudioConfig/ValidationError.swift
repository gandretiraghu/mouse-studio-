import Foundation
import MouseStudioShared

/// A configuration validation problem. Both the GUI and CI surface these
/// (TDD §15, §19.3). `conflict` and `shadowed` are non-fatal warnings.
public enum ValidationError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
    case timingOutOfRange(field: String, value: Int)
    case emptyProfileID
    case duplicateRuleID(String)
    case chordClickMissingPartner(ruleID: String)
    /// Two or more enabled rules resolve from the same trigger key.
    case conflict(ruleIDs: [String])
    /// The active profile id does not correspond to any known profile.
    case unknownActiveProfile(String)

    /// Warnings don't prevent loading; errors do.
    public var isWarning: Bool {
        switch self {
        case .conflict:
            return true
        default:
            return false
        }
    }
}
