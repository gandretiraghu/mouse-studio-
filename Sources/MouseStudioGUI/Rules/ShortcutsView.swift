#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// The main screen: shortcuts grouped by button in modern cards, with an easy
/// add/edit flow.
public struct ShortcutsView: View {
    @ObservedObject var state: AppState
    @State private var search = ""
    @State private var editing: Rule?
    @State private var addingNew = false

    public init(state: AppState) {
        self.state = state
    }

    private var rules: [Rule] { state.activeProfile?.rules ?? [] }
    private var groups: [(button: ButtonID, rules: [Rule])] {
        RuleListViewModel(searchText: search).grouped(rules)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if !rules.isEmpty { searchField }
                if rules.isEmpty {
                    emptyState
                } else if groups.isEmpty {
                    Text("No shortcuts match “\(search)”.").foregroundStyle(.secondary).padding(.top, 40)
                } else {
                    ForEach(groups, id: \.button) { group in
                        buttonCard(group.button, group.rules)
                    }
                }
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $addingNew) {
            EditShortcutSheet { state.addRule($0) }
        }
        .sheet(item: $editing) { rule in
            EditShortcutSheet(rule: rule) { state.updateRule($0) }
        }
    }

    private var header: some View {
        ScreenHeader("Shortcuts", subtitle: "Profile: \(state.activeProfile?.displayName ?? "—")") {
            Button {
                addingNew = true
            } label: {
                Label("Add Shortcut", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search shortcuts", text: $search).textFieldStyle(.plain)
        }
        .padding(8)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Theme.controlCorner))
        .frame(maxWidth: 320)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cursorarrow.click.2").font(.system(size: 46)).foregroundStyle(.secondary)
            Text("No shortcuts yet").font(.title3.bold())
            Text("Add your first shortcut to make a mouse button do something.")
                .foregroundStyle(.secondary)
            Button {
                addingNew = true
            } label: { Label("Add Shortcut", systemImage: "plus") }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func buttonCard(_ button: ButtonID, _ rules: [Rule]) -> some View {
        let conflicts = state.conflictingRuleIDs()
        return Card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: button.symbol).foregroundStyle(Color.accentColor)
                    Text(button.friendlyName).font(.headline)
                }
                .padding(.bottom, 8)

                ForEach(Array(rules.enumerated()), id: \.element.id) { index, rule in
                    if index > 0 { Divider() }
                    row(rule, conflicting: conflicts.contains(rule.id))
                }
            }
        }
    }

    private func row(_ rule: Rule, conflicting: Bool) -> some View {
        HStack(spacing: 12) {
            Pill(text: rule.trigger.gesture.friendlyName)
            if let partner = rule.trigger.chordWith {
                Pill(text: "+ \(partner.shortName)", color: .purple)
            }
            Image(systemName: "arrow.right").font(.caption).foregroundStyle(.secondary)
            Text(ActionCatalog.descriptor(for: rule.action.type)?.displayName ?? rule.action.type)
                .fontWeight(.medium)
            if conflicting {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .help("Another enabled shortcut uses the same trigger")
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { state.setRuleEnabled(id: rule.id, enabled: $0) }))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
            Button { editing = rule } label: { Image(systemName: "pencil") }
                .buttonStyle(.borderless)
            Button(role: .destructive) { state.deleteRule(id: rule.id) } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .opacity(rule.enabled ? 1 : 0.5)
    }
}
#endif
