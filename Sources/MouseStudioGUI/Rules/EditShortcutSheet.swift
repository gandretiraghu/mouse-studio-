#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// One-screen add/edit for a shortcut — trigger + action, no multi-step flow.
public struct EditShortcutSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var button: ButtonID
    @State private var gesture: GestureKind
    @State private var chordWith: ButtonID
    @State private var actionType: String
    @State private var bundleID: String
    @State private var keys: String
    @State private var enabled: Bool

    private let ruleID: String
    private let priority: Int
    private let isNew: Bool
    private let onSave: (Rule) -> Void

    /// Create for a new shortcut.
    public init(onSave: @escaping (Rule) -> Void) {
        self.init(rule: nil, onSave: onSave)
    }

    /// Create for editing an existing rule, or a new one if `rule` is nil.
    public init(rule: Rule?, onSave: @escaping (Rule) -> Void) {
        self.isNew = (rule == nil)
        self.ruleID = rule?.id ?? UUID().uuidString
        self.priority = rule?.priority ?? 0
        _button = State(initialValue: rule?.trigger.button ?? .button4)
        _gesture = State(initialValue: rule?.trigger.gesture ?? .double)
        _chordWith = State(initialValue: rule?.trigger.chordWith ?? .left)
        _actionType = State(initialValue: rule?.action.type ?? "app.launch")
        _bundleID = State(initialValue: rule?.action.params["bundleID"]?.stringValue ?? "")
        _keys = State(initialValue: rule?.action.params["keys"]?.stringValue ?? "")
        _enabled = State(initialValue: rule?.enabled ?? true)
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isNew ? "New Shortcut" : "Edit Shortcut").font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    triggerCard
                    actionCard
                }
                .padding()
            }

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    onSave(build()); dismiss()
                } label: {
                    Text(isNew ? "Add Shortcut" : "Save").frame(minWidth: 90)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 520, height: 560)
    }

    private var triggerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Label("When I…", systemImage: "cursorarrow.click").font(.headline)

                labeled("Button") {
                    Picker("", selection: $button) {
                        ForEach(ButtonID.allCases, id: \.self) { Text($0.friendlyName).tag($0) }
                    }.labelsHidden()
                }
                labeled("Gesture") {
                    Picker("", selection: $gesture) {
                        ForEach(GestureKind.allCases, id: \.self) { Text($0.friendlyName).tag($0) }
                    }.labelsHidden()
                }
                if gesture == .chordClick {
                    labeled("Together with") {
                        Picker("", selection: $chordWith) {
                            ForEach(ButtonID.allCases, id: \.self) { Text($0.shortName).tag($0) }
                        }.labelsHidden()
                    }
                }
                if !isNew {
                    Toggle("Enabled", isOn: $enabled)
                }
            }
        }
    }

    private var actionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Label("Do this", systemImage: "wand.and.stars").font(.headline)

                Menu {
                    ForEach(ActionCatalog.categories, id: \.self) { category in
                        Section(category) {
                            ForEach(ActionCatalog.all.filter { ($0.category ?? "") == category }, id: \.type) { descriptor in
                                Button(descriptor.displayName) { actionType = descriptor.type }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(ActionCatalog.descriptor(for: actionType)?.displayName ?? actionType)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: Theme.controlCorner))
                    .overlay(RoundedRectangle(cornerRadius: Theme.controlCorner).strokeBorder(Color.primary.opacity(0.1)))
                }
                .menuStyle(.borderlessButton)

                if needsBundleID {
                    labeled("Application") {
                        HStack {
                            Text(bundleID.isEmpty ? "No app chosen" : appDisplayName(bundleID))
                                .foregroundStyle(bundleID.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                            Spacer()
                            Button("Choose…") { chooseApp() }
                        }
                    }
                }
                if needsKeys {
                    labeled("Keys") {
                        TextField("cmd+[", text: $keys).textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack {
            Text(title).frame(width: 110, alignment: .leading).foregroundStyle(.secondary)
            content()
        }
    }

    private var needsBundleID: Bool { actionType == "app.launch" || actionType == "app.switch" }
    private var needsKeys: Bool { actionType == "keystroke.send" }

    /// Friendly display name for a bundle id, if the app is installed.
    private func appDisplayName(_ id: String) -> String {
        #if canImport(AppKit)
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            return FileManager.default.displayName(atPath: url.path)
        }
        #endif
        return id
    }

    /// Open a picker restricted to /Applications and resolve the bundle id.
    private func chooseApp() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        if panel.runModal() == .OK, let url = panel.url,
           let id = Bundle(url: url)?.bundleIdentifier {
            bundleID = id
        }
        #endif
    }

    private func build() -> Rule {
        var params: [String: JSONValue] = [:]
        if needsBundleID { params["bundleID"] = .string(bundleID) }
        if needsKeys { params["keys"] = .string(keys) }
        return Rule(
            id: ruleID,
            enabled: enabled,
            priority: priority,
            trigger: TriggerSpec(button: button, gesture: gesture,
                                 chordWith: gesture == .chordClick ? chordWith : nil),
            action: ActionSpec(type: actionType, params: params)
        )
    }
}
#endif
