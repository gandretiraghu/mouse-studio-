#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Manage and switch between profiles.
public struct ProfilesView: View {
    @ObservedObject var state: AppState
    @State private var newName = ""

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader("Profiles", subtitle: "Switch between sets of shortcuts.")

                Card {
                    HStack {
                        TextField("New profile name", text: $newName).textFieldStyle(.roundedBorder)
                        Button {
                            let trimmed = newName.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            let id = trimmed.lowercased().replacingOccurrences(of: " ", with: "-")
                            state.addProfile(Profile(id: id, displayName: trimmed))
                            newName = ""
                        } label: { Label("Add", systemImage: "plus") }
                        .buttonStyle(.borderedProminent)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                ForEach(state.profiles) { profile in
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: profile.id == state.config.activeProfile ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(profile.id == state.config.activeProfile ? Color.accentColor : .secondary)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName).font(.headline)
                                Text("\(profile.rules.count) shortcut(s)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if profile.id != state.config.activeProfile {
                                Button("Activate") { state.setActiveProfile(profile.id) }
                            }
                            Button(role: .destructive) { state.deleteProfile(id: profile.id) } label: {
                                Image(systemName: "trash")
                            }.buttonStyle(.borderless)
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
    }
}
#endif
