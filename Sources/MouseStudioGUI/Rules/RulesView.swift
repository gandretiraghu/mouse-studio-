#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// The rules list: searchable, filterable, with enable toggles, conflict badges,
/// and entry points to the editor and the creation wizard (TDD §19.1, §19.3, §19.8).
public struct RulesView: View {
    @ObservedObject var state: AppState

    @State private var search = ""
    @State private var enabledOnly = false
    @State private var editingRule: Rule?
    @State private var showingWizard = false

    public init(state: AppState) {
        self.state = state
    }

    private var listModel: RuleListViewModel {
        RuleListViewModel(searchText: search, enabledOnly: enabledOnly)
    }

    private var rules: [Rule] { state.activeProfile?.rules ?? [] }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            list
        }
        .sheet(isPresented: $showingWizard) {
            RuleWizardView { rule in
                state.addRule(rule)
                showingWizard = false
            } cancel: { showingWizard = false }
        }
        .sheet(item: $editingRule) { rule in
            RuleEditorView(rule: rule) { updated in
                state.updateRule(updated)
                editingRule = nil
            } cancel: { editingRule = nil }
        }
    }

    private var toolbar: some View {
        HStack {
            TextField("Search rules", text: $search)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)
            Toggle("Enabled only", isOn: $enabledOnly)
            Spacer()
            Button {
                showingWizard = true
            } label: { Label("New Rule", systemImage: "plus") }
        }
        .padding(8)
    }

    private var list: some View {
        let conflicts = state.conflictingRuleIDs()
        let visible = listModel.filtered(rules)
        return List {
            if visible.isEmpty {
                Text("No rules. Tap “New Rule” to add one.")
                    .foregroundColor(.secondary)
            }
            ForEach(visible) { rule in
                RuleRow(
                    rule: rule,
                    conflicting: conflicts.contains(rule.id),
                    onToggle: { state.setRuleEnabled(id: rule.id, enabled: $0) },
                    onEdit: { editingRule = rule },
                    onDelete: { state.deleteRule(id: rule.id) }
                )
            }
        }
    }
}

private struct RuleRow: View {
    let rule: Rule
    let conflicting: Bool
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: Binding(get: { rule.enabled }, set: onToggle))
                .labelsHidden()
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if conflicting {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .help("Conflicts with another rule on the same trigger")
            }
            Button(action: onEdit) { Image(systemName: "pencil") }.buttonStyle(.borderless)
            Button(action: onDelete) { Image(systemName: "trash") }.buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    private var title: String {
        let actionName = ActionCatalog.descriptor(for: rule.action.type)?.displayName ?? rule.action.type
        return actionName
    }

    private var subtitle: String {
        var trigger = "\(rule.trigger.gesture.rawValue) · \(rule.trigger.button.rawValue)"
        if let partner = rule.trigger.chordWith { trigger += " + \(partner.rawValue)" }
        return trigger
    }
}
#endif
