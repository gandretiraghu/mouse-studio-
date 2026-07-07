#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Shows recent engine log entries fetched from the service (TDD §15).
public struct LogsView: View {
    @StateObject private var vm: LogsViewModel

    public init(viewModel: LogsViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Logs").font(.headline)
                Spacer()
                Button("Refresh") { vm.refresh() }
            }
            List(vm.entries) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Text(entry.level.label)
                        .font(.caption.monospaced())
                        .foregroundColor(color(for: entry.level))
                        .frame(width: 52, alignment: .leading)
                    VStack(alignment: .leading) {
                        Text(entry.message).font(.body)
                        Text("\(entry.subsystem) · \(entry.timestamp.formatted(date: .omitted, time: .standard))")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .onAppear { vm.refresh() }
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .debug: return .secondary
        case .info: return .primary
        case .warn: return .orange
        case .error: return .red
        }
    }
}
#endif
