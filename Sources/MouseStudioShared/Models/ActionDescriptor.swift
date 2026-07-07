import Foundation

/// UI metadata describing an action a provider supports. Drives the GUI Action
/// Browser and parameter forms (TDD §10.1, §19.2).
public struct ActionDescriptor: Codable, Equatable, Sendable {
    public let type: String
    public let displayName: String
    public let params: [ParamSpec]
    /// Optional grouping for the Action Browser (defaults to namespace).
    public let category: String?
    /// Optional search keywords.
    public let keywords: [String]?

    public init(
        type: String,
        displayName: String,
        params: [ParamSpec] = [],
        category: String? = nil,
        keywords: [String]? = nil
    ) {
        self.type = type
        self.displayName = displayName
        self.params = params
        self.category = category
        self.keywords = keywords
    }
}

/// Describes a single parameter of an action, used to render a GUI form field.
public struct ParamSpec: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case string
        case appBundleID
        case integer
        case bool
        case enumChoice
    }

    public let key: String
    public let displayName: String
    public let kind: Kind
    public let choices: [String]?
    public let required: Bool

    public init(
        key: String,
        displayName: String,
        kind: Kind,
        choices: [String]? = nil,
        required: Bool = true
    ) {
        self.key = key
        self.displayName = displayName
        self.kind = kind
        self.choices = choices
        self.required = required
    }
}
