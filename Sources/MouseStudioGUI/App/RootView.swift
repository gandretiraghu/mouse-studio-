#if canImport(SwiftUI)
import SwiftUI
import MouseStudioConfig
import MouseStudioShared

/// Modern sidebar-based main window.
public struct RootView: View {
    @StateObject private var state: AppState
    private let ipc: IPCClient

    @State private var section: Section = .shortcuts

    enum Section: String, CaseIterable, Identifiable {
        case shortcuts, tester, profiles, backup, logs
        var id: String { rawValue }
        var title: String {
            switch self {
            case .shortcuts: return "Shortcuts"
            case .tester: return "Live Tester"
            case .profiles: return "Profiles"
            case .backup: return "Backup"
            case .logs: return "Logs"
            }
        }
        var symbol: String {
            switch self {
            case .shortcuts: return "bolt.fill"
            case .tester: return "computermouse.fill"
            case .profiles: return "person.2.fill"
            case .backup: return "arrow.triangle.2.circlepath"
            case .logs: return "doc.plaintext"
            }
        }
    }

    public init(store: ConfigStoring, ipc: IPCClient) {
        _state = StateObject(wrappedValue: AppState(store: store, ipc: ipc))
        self.ipc = ipc
    }

    public var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $section) { item in
                Label(item.title, systemImage: item.symbol).tag(item)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Theme.accentGradient)
                        .frame(width: 34, height: 34)
                        .overlay(Image(systemName: "computermouse.fill").foregroundStyle(.white))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Mouse Studio").font(.headline)
                        Text("v\(MouseStudio.version)").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
            }
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 860, minHeight: 560)
    }

    @ViewBuilder private var detail: some View {
        switch section {
        case .shortcuts: ShortcutsView(state: state)
        case .tester: MouseTesterView(viewModel: MouseTesterViewModel(ipc: ipc))
        case .profiles: ProfilesView(state: state)
        case .backup: ImportExportView(state: state)
        case .logs: LogsView(viewModel: LogsViewModel(ipc: ipc))
        }
    }
}
#endif
