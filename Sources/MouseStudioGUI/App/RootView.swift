#if canImport(SwiftUI)
import SwiftUI
import MouseStudioConfig
import MouseStudioShared

/// The top-level tabbed window of the Mouse Studio settings app.
public struct RootView: View {
    @StateObject private var state: AppState
    private let ipc: IPCClient

    public init(store: ConfigStoring, ipc: IPCClient) {
        _state = StateObject(wrappedValue: AppState(store: store, ipc: ipc))
        self.ipc = ipc
    }

    public var body: some View {
        TabView {
            RulesView(state: state)
                .tabItem { Label("Rules", systemImage: "list.bullet") }
            MouseTesterView(viewModel: MouseTesterViewModel(ipc: ipc))
                .tabItem { Label("Tester", systemImage: "computermouse") }
            ProfilesView(state: state)
                .tabItem { Label("Profiles", systemImage: "person.2") }
            ImportExportView(state: state)
                .tabItem { Label("Backup", systemImage: "arrow.up.arrow.down") }
            LogsView(viewModel: LogsViewModel(ipc: ipc))
                .tabItem { Label("Logs", systemImage: "doc.plaintext") }
        }
        .frame(minWidth: 720, minHeight: 480)
    }
}
#endif
