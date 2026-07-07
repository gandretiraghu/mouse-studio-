#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Live Mouse Tester: "Detect Mouse" enters learning mode and highlights each
/// physical button as it's pressed on a mouse illustration (TDD §7.3, §19).
public struct MouseTesterView: View {
    @StateObject private var vm: MouseTesterViewModel

    public init(viewModel: MouseTesterViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Live Mouse Tester").font(.headline)
            Text(vm.isDetecting
                 ? "Press each button on your mouse…"
                 : "Tap “Detect Mouse”, then press each button.")
                .foregroundColor(.secondary)

            mouseIllustration

            HStack {
                ForEach(ButtonID.allCases, id: \.self) { button in
                    Text(button.rawValue)
                        .font(.caption)
                        .padding(6)
                        .background(vm.detected.contains(button) ? Color.green.opacity(0.3) : Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            Button(vm.isDetecting ? "Stop" : "Detect Mouse") {
                vm.isDetecting ? vm.stopDetecting() : vm.startDetecting()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }

    private var mouseIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 60)
                .stroke(Color.secondary, lineWidth: 2)
                .frame(width: 140, height: 220)
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    buttonShape(.left)
                    buttonShape(.middle).frame(width: 24)
                    buttonShape(.right)
                }
                .frame(height: 90)
                Spacer()
            }
            .padding(10)
            .frame(width: 140, height: 220)

            // Side buttons
            HStack {
                VStack(spacing: 8) {
                    buttonShape(.button4).frame(width: 12, height: 26)
                    buttonShape(.button5).frame(width: 12, height: 26)
                }
                Spacer()
            }
            .frame(width: 170, height: 120)
        }
        .frame(height: 240)
    }

    private func buttonShape(_ button: ButtonID) -> some View {
        let isHot = vm.lastPressed == button
        let seen = vm.detected.contains(button)
        return RoundedRectangle(cornerRadius: 6)
            .fill(isHot ? Color.accentColor : (seen ? Color.green.opacity(0.5) : Color.secondary.opacity(0.15)))
            .animation(.easeOut(duration: 0.2), value: vm.lastPressed)
    }
}
#endif
