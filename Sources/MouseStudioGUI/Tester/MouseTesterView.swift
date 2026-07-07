#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Live Mouse Tester: "Detect Mouse" highlights each physical button as pressed.
public struct MouseTesterView: View {
    @StateObject private var vm: MouseTesterViewModel

    public init(viewModel: MouseTesterViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader("Live Tester", subtitle: vm.isDetecting ? "Press each button on your mouse…" : "Check which buttons your mouse reports.")

                Card {
                    HStack(spacing: 30) {
                        mouseIllustration
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detected buttons").font(.headline)
                            FlowChips(items: ButtonID.allCases, seen: vm.detected, hot: vm.lastPressed)
                            Button {
                                vm.isDetecting ? vm.stopDetecting() : vm.startDetecting()
                            } label: {
                                Label(vm.isDetecting ? "Stop" : "Detect Mouse",
                                      systemImage: vm.isDetecting ? "stop.fill" : "dot.radiowaves.left.and.right")
                                    .frame(minWidth: 130)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        Spacer()
                    }
                }
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var mouseIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 55)
                .fill(.background.secondary)
                .overlay(RoundedRectangle(cornerRadius: 55).strokeBorder(Color.primary.opacity(0.1), lineWidth: 2))
                .frame(width: 130, height: 200)
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    key(.left); key(.middle).frame(width: 22); key(.right)
                }
                .frame(height: 80)
                Spacer()
            }
            .padding(12)
            .frame(width: 130, height: 200)
        }
    }

    private func key(_ button: ButtonID) -> some View {
        let hot = vm.lastPressed == button
        let seen = vm.detected.contains(button)
        return RoundedRectangle(cornerRadius: 6)
            .fill(hot ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(seen ? Color.green.opacity(0.5) : Color.secondary.opacity(0.15)))
            .animation(.easeOut(duration: 0.15), value: vm.lastPressed)
    }
}

private struct FlowChips: View {
    let items: [ButtonID]
    let seen: Set<ButtonID>
    let hot: ButtonID?
    var body: some View {
        HStack {
            ForEach(items, id: \.self) { b in
                Text(b.shortName)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(seen.contains(b) ? Color.green.opacity(0.25) : Color.secondary.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(hot == b ? Color.accentColor : .clear, lineWidth: 2))
            }
        }
    }
}
#endif
