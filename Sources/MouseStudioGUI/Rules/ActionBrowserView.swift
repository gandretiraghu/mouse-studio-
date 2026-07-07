#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// A searchable, categorized picker of available actions (TDD §19.2).
public struct ActionBrowserView: View {
    @State private var search = ""
    let onSelect: (ActionDescriptor) -> Void

    public init(onSelect: @escaping (ActionDescriptor) -> Void) {
        self.onSelect = onSelect
    }

    private var model: ActionBrowserViewModel { ActionBrowserViewModel(searchText: search) }

    public var body: some View {
        VStack(spacing: 0) {
            TextField("Search actions", text: $search)
                .textFieldStyle(.roundedBorder)
                .padding(8)
            Divider()
            List {
                ForEach(model.groupedResults(), id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.actions, id: \.type) { action in
                            Button {
                                onSelect(action)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(action.displayName)
                                    Text(action.type).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
#endif
