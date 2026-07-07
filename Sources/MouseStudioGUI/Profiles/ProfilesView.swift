#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Manage and switch between profiles (TDD §19).
public struct ProfilesView: View {
    @ObservedObject var state: AppState
    @State private var newName = ""

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profiles").font(.headline)
            List {
                ForEach(state.profiles) { profile in
                    HStack {
                        Image(systemName: profile.id == state.config.activeProfile ? "largecircle.fill.circle" : "circle")
                        VStack(alignment: .leading) {
                            Text(profile.displayName)
                            Text("\(profile.rules.count) rule(s)").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if profile.id != state.config.activeProfile {
                            Button("Activate") { state.setActiveProfile(profile.id) }
                        }
                        Button(role: .destructive) {
                            state.deleteProfile(id: profile.id)
                        } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                    }
                }
            }
            HStack {
                TextField("New profile name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    let id = trimmed.lowercased().replacingOccurrences(of: " ", with: "-")
                    state.addProfile(Profile(id: id, displayName: trimmed))
                    newName = ""
                }
            }
            if let error = state.lastError {
                Text(error).font(.caption).foregroundColor(.red)
            }
        }
        .padding()
    }
}
#endif
