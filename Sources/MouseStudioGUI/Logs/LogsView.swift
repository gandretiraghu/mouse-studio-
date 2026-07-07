#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Shows recent engine log entries fetched from the service.
public struct LogsView: View {
    @StateObject private var vm: LogsViewModel

    public init(viewModel: LogsViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenHeader("Logs", subtitle: "Recent engine activity.") {
                Button { vm.refresh() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
            }
            Card {
                if vm.entries.isEmpty {
                    Text("No log entries yet (or the service isn't running).")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(vm.entries) { entry in
                            HStack(alignment: .top, spacing: 10) {
                                Text(entry.level.label)
                                    .font(.caption.monospaced().weight(.semibold))
                                    .foregroundStyle(color(for: entry.level))
                                    .frame(width: 48, alignment: .leading)
                                Text(entry.message).font(.callout)
                                Spacer()
                                Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(24)
        .background(Color(nsColor: .windowBackgroundColor))
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
