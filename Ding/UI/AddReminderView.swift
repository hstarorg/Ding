import SwiftUI

/// Inline form to add a new reminder or edit an existing one.
/// Pass `editing` to edit; leave nil to create.
struct AddReminderView: View {
    @EnvironmentObject private var store: ReminderStore

    private let editing: Reminder?
    private let onClose: () -> Void

    @State private var pluginId: String
    @State private var title: String
    @State private var config: [String: String]

    init(editing: Reminder? = nil, onClose: @escaping () -> Void) {
        self.editing = editing
        self.onClose = onClose
        _pluginId = State(initialValue: editing?.pluginId ?? PluginRegistry.all.first?.id ?? "")
        _title = State(initialValue: editing?.title ?? "")
        _config = State(initialValue: editing?.config ?? [:])
    }

    private var plugin: ReminderPlugin? { PluginRegistry.plugin(for: pluginId) }
    private var isEditing: Bool { editing != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                Text(isEditing ? "Edit Reminder" : "Add Reminder").font(.headline)
                Spacer()
            }

            Divider()

            Picker("Type", selection: $pluginId) {
                ForEach(PluginRegistry.all, id: \.id) { plugin in
                    Label(plugin.displayName, systemImage: plugin.iconSystemName).tag(plugin.id)
                }
            }
            .onChange(of: pluginId) { _, _ in resetConfig() }
            // Changing a reminder's type would invalidate its config; lock it when editing.
            .disabled(isEditing)

            TextField("Name (optional)", text: $title)

            if let plugin {
                plugin.configView($config)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel", action: onClose)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!(plugin?.isValid(config) ?? false))
            }
        }
        .padding(12)
        .frame(width: 320)
        .onAppear {
            // Fill defaults for a brand-new reminder; keep existing config when editing.
            if editing == nil { resetConfig() }
        }
    }

    private func resetConfig() {
        config = plugin?.defaultConfig() ?? [:]
    }

    private func save() {
        guard let plugin else { return }
        let name = title.isEmpty ? plugin.displayName : title

        if var existing = editing {
            existing.title = name
            existing.config = config
            existing.triggered = false  // re-arm after editing
            existing.enabled = true     // editing implies you want it active
            store.update(existing)
        } else {
            store.add(Reminder(pluginId: plugin.id, title: name, config: config))
        }
        onClose()
    }
}
