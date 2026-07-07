#if canImport(SwiftUI)
import SwiftUI
import MouseStudioConfig
import MouseStudioShared
#if canImport(AppKit)
import AppKit
#endif

/// Import/export configuration bundles and restore from automatic backups
/// (TDD §9.5, §19.5).
public struct ImportExportView: View {
    @ObservedObject var state: AppState
    @State private var backups: [BackupInfo] = []

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Backup & Restore").font(.headline)

            HStack {
                Button("Export…") { exportBundle() }
                Button("Import…") { importBundle() }
            }

            Divider()
            Text("Automatic Backups").font(.subheadline)
            List {
                if backups.isEmpty {
                    Text("No backups yet.").foregroundColor(.secondary)
                }
                ForEach(backups) { backup in
                    HStack {
                        Text(backup.createdAt.formatted())
                        Spacer()
                        Button("Restore") { state.restore(backup); refresh() }
                    }
                }
            }
            if let error = state.lastError {
                Text(error).font(.caption).foregroundColor(.red)
            }
        }
        .padding()
        .onAppear(perform: refresh)
    }

    private func refresh() {
        backups = state.backups()
    }

    private func exportBundle() {
        #if canImport(AppKit)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MouseStudio.mousestudio.json"
        if panel.runModal() == .OK, let url = panel.url {
            state.exportBundle(to: url)
        }
        #endif
    }

    private func importBundle() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = []
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            state.importBundle(from: url)
            refresh()
        }
        #endif
    }
}
#endif
