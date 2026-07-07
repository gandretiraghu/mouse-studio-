import Foundation
import MouseStudioShared

/// Filtering, searching, and grouping for the rules list. Kept pure and O(n) so
/// the UI stays responsive with 1000+ rules (TDD §19.8).
public struct RuleListViewModel {
    public var searchText: String = ""
    public var enabledOnly: Bool = false
    public var groupByButton: Bool = false

    public init(searchText: String = "", enabledOnly: Bool = false, groupByButton: Bool = false) {
        self.searchText = searchText
        self.enabledOnly = enabledOnly
        self.groupByButton = groupByButton
    }

    /// Apply the current filters to a rule set.
    public func filtered(_ rules: [Rule]) -> [Rule] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return rules.filter { rule in
            if enabledOnly && !rule.enabled { return false }
            guard !query.isEmpty else { return true }
            return matches(rule, query: query)
        }
    }

    /// Rules grouped by anchor button, in button order, filters applied.
    public func grouped(_ rules: [Rule]) -> [(button: ButtonID, rules: [Rule])] {
        let filteredRules = filtered(rules)
        return ButtonID.allCases.compactMap { button in
            let group = filteredRules.filter { $0.trigger.button == button }
            return group.isEmpty ? nil : (button, group)
        }
    }

    private func matches(_ rule: Rule, query: String) -> Bool {
        if rule.id.lowercased().contains(query) { return true }
        if rule.trigger.button.rawValue.lowercased().contains(query) { return true }
        if rule.trigger.gesture.rawValue.lowercased().contains(query) { return true }
        if rule.action.type.lowercased().contains(query) { return true }
        if let descriptor = ActionCatalog.descriptor(for: rule.action.type),
           descriptor.displayName.lowercased().contains(query) { return true }
        return false
    }
}
