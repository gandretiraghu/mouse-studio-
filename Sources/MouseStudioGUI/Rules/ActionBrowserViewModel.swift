import Foundation
import MouseStudioShared

/// Backs the Action Browser: categorized + searchable list of available actions,
/// driven entirely by `ActionCatalog` so new actions appear automatically
/// (TDD §19.2).
public struct ActionBrowserViewModel {
    public var searchText: String = ""

    public init(searchText: String = "") {
        self.searchText = searchText
    }

    private var matches: [ActionDescriptor] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return ActionCatalog.all }
        return ActionCatalog.all.filter { descriptor in
            if descriptor.displayName.lowercased().contains(query) { return true }
            if descriptor.type.lowercased().contains(query) { return true }
            if let keywords = descriptor.keywords,
               keywords.contains(where: { $0.lowercased().contains(query) }) { return true }
            return false
        }
    }

    /// Matching actions grouped by category, in catalog category order.
    public func groupedResults() -> [(category: String, actions: [ActionDescriptor])] {
        let results = matches
        return ActionCatalog.categories.compactMap { category in
            let group = results.filter { ($0.category ?? "Other") == category }
            return group.isEmpty ? nil : (category, group)
        }
    }

    public var isEmpty: Bool { matches.isEmpty }
}
