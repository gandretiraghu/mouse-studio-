#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Beginner-friendly step-by-step rule creation (TDD §19.1).
public struct RuleWizardView: View {
    @StateObject private var vm = RuleWizardViewModel()
    @State private var bundleID = ""
    @State private var keys = ""

    let onFinish: (Rule) -> Void
    let cancel: () -> Void

    public init(onFinish: @escaping (Rule) -> Void, cancel: @escaping () -> Void) {
        self.onFinish = onFinish
        self.cancel = cancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Rule").font(.headline)
            Text("Step \(vm.step.rawValue + 1) of \(RuleWizardViewModel.Step.allCases.count)")
                .font(.caption).foregroundColor(.secondary)
            Divider()
            content.frame(minHeight: 220)
            Divider()
            footer
        }
        .padding()
        .frame(width: 460)
    }

    @ViewBuilder private var content: some View {
        switch vm.step {
        case .button:
            picker("Which button?", ButtonID.allCases, selection: Binding(
                get: { vm.button }, set: { vm.button = $0 }))
        case .gesture:
            VStack(alignment: .leading) {
                picker("Which gesture?", GestureKind.allCases, selection: Binding(
                    get: { vm.gesture }, set: { vm.gesture = $0 }))
                if vm.gesture == .chordClick {
                    picker("Chord with", ButtonID.allCases, selection: Binding(
                        get: { vm.chordWith }, set: { vm.chordWith = $0 }))
                }
            }
        case .action:
            ActionBrowserView { descriptor in
                vm.actionType = descriptor.type
                vm.advance()
            }
        case .params:
            paramsForm
        case .review:
            VStack(alignment: .leading, spacing: 8) {
                Text("Review").font(.subheadline)
                Text(vm.summary).padding(8).background(Color.secondary.opacity(0.1)).cornerRadius(6)
            }
        }
    }

    @ViewBuilder private var paramsForm: some View {
        Form {
            if vm.actionType == "app.launch" || vm.actionType == "app.switch" {
                TextField("App bundle id (e.g. com.apple.finder)", text: $bundleID)
                    .onChange(of: bundleID) { _, newValue in vm.params["bundleID"] = .string(newValue) }
            } else if vm.actionType == "keystroke.send" {
                TextField("Keys (e.g. cmd+[)", text: $keys)
                    .onChange(of: keys) { _, newValue in vm.params["keys"] = .string(newValue) }
            } else {
                Text("No parameters needed.").foregroundColor(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Cancel", action: cancel)
            Spacer()
            if vm.step != .button {
                Button("Back") { vm.back() }
            }
            if vm.step == .review {
                Button("Add Rule") {
                    if let rule = vm.buildRule() { onFinish(rule) }
                }.keyboardShortcut(.defaultAction)
            } else {
                Button("Next") { vm.advance() }
                    .disabled(!vm.canAdvance)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func picker<T: RawRepresentable & Hashable>(
        _ title: String, _ options: [T], selection: Binding<T?>
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline)
            ForEach(options, id: \.self) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    HStack {
                        Image(systemName: selection.wrappedValue == option ? "largecircle.fill.circle" : "circle")
                        Text(option.rawValue)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
#endif
