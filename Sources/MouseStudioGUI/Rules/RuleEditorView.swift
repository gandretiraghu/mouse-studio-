#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Full editor for an existing rule: trigger, optional chord partner, and action.
public struct RuleEditorView: View {
    @State private var button: ButtonID
    @State private var gesture: GestureKind
    @State private var chordWith: ButtonID?
    @State private var actionType: String
    @State private var bundleID: String
    @State private var keys: String
    @State private var enabled: Bool
    @State private var showingActionBrowser = false

    private let ruleID: String
    private let priority: Int
    private let onSave: (Rule) -> Void
    private let cancel: () -> Void

    public init(rule: Rule, onSave: @escaping (Rule) -> Void, cancel: @escaping () -> Void) {
        self.ruleID = rule.id
        self.priority = rule.priority
        _button = State(initialValue: rule.trigger.button)
        _gesture = State(initialValue: rule.trigger.gesture)
        _chordWith = State(initialValue: rule.trigger.chordWith)
        _actionType = State(initialValue: rule.action.type)
        _bundleID = State(initialValue: rule.action.params["bundleID"]?.stringValue ?? "")
        _keys = State(initialValue: rule.action.params["keys"]?.stringValue ?? "")
        _enabled = State(initialValue: rule.enabled)
        self.onSave = onSave
        self.cancel = cancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Rule").font(.headline)
            Form {
                Picker("Button", selection: $button) {
                    ForEach(ButtonID.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Gesture", selection: $gesture) {
                    ForEach(GestureKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                if gesture == .chordClick {
                    Picker("Chord with", selection: Binding(
                        get: { chordWith ?? .left },
                        set: { chordWith = $0 })) {
                        ForEach(ButtonID.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
                HStack {
                    Text("Action")
                    Spacer()
                    Text(ActionCatalog.descriptor(for: actionType)?.displayName ?? actionType)
                        .foregroundColor(.secondary)
                    Button("Change") { showingActionBrowser = true }
                }
                if needsBundleID {
                    TextField("App bundle id (e.g. com.apple.finder)", text: $bundleID)
                }
                if needsKeys {
                    TextField("Keys (e.g. cmd+[)", text: $keys)
                }
                Toggle("Enabled", isOn: $enabled)
            }
            HStack {
                Button("Cancel", action: cancel)
                Spacer()
                Button("Save") { onSave(build()) }.keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 460)
        .sheet(isPresented: $showingActionBrowser) {
            VStack {
                ActionBrowserView { descriptor in
                    actionType = descriptor.type
                    showingActionBrowser = false
                }
                Button("Cancel") { showingActionBrowser = false }.padding(.bottom, 8)
            }
            .frame(width: 420, height: 460)
        }
    }

    private var needsBundleID: Bool { actionType == "app.launch" || actionType == "app.switch" }
    private var needsKeys: Bool { actionType == "keystroke.send" }

    private func build() -> Rule {
        var params: [String: JSONValue] = [:]
        if needsBundleID { params["bundleID"] = .string(bundleID) }
        if needsKeys { params["keys"] = .string(keys) }
        return Rule(
            id: ruleID,
            enabled: enabled,
            priority: priority,
            trigger: TriggerSpec(button: button, gesture: gesture,
                                 chordWith: gesture == .chordClick ? (chordWith ?? .left) : nil),
            action: ActionSpec(type: actionType, params: params)
        )
    }
}
#endif
