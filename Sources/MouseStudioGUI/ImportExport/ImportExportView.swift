#if canImport(SwiftUI)
import SwiftUI
import MouseStudioConfig
import MouseStudioShared
#if canImport(AppKit)
import AppKit
#endif

/// Import/export configuration bundles and restore from automatic backups.
public struct ImportExportView: View {
    @ObservedObject var state: AppState
    @State private var backups: [BackupInfo] = []

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader("Backup", subtitle: "Export, import, and restore your setup.")

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Share or move your setup", systemImage: "square.and.arrow.up").font(.headline)
                        HStack {
                            Button { exportBundle() } label: { Label("Export…", systemImage: "square.and.arrow.up") }
                            Button { importBundle() } label: { Label("Import…", systemImage: "square.and.arrow.down") }
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Automatic Backups", systemImage: "clock.arrow.circlepath").font(.headline)
                        if backups.isEmpty {
                            Text("No backups yet. One is taken before every change.").foregroundStyle(.secondary)
                        }
                        ForEach(backups) { backup in
                            HStack {
                                Image(systemName: "doc").foregroundStyle(.secondary)
                                Text(backup.createdAt.formatted(date: .abbreviated, time: .shortened))
                                Spacer()
                                Button("Restore") { state.restore(backup); refresh() }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if let error = state.lastError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear(perform: refresh)
    }

    private func refresh() { backups = state.backups() }

    private func exportBundle() {
        #if canImport(AppKit)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MouseStudio.mousestudio.json"
        if panel.runModal() == .OK, let url = panel.url { state.exportBundle(to: url) }
        #endif
    }

    private func importBundle() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { state.importBundle(from: url); refresh() }
        #endif
    }
}
#endif
