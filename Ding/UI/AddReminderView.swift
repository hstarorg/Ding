import SwiftUI

/// Inline "add reminder" form: pick a plugin, render its config editor, save.
struct AddReminderView: View {
    @EnvironmentObject private var store: ReminderStore
    let onClose: () -> Void

    @State private var pluginId: String = PluginRegistry.all.first?.id ?? ""
    @State private var title: String = ""
    @State private var config: [String: String] = [:]

    private var plugin: ReminderPlugin? { PluginRegistry.plugin(for: pluginId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                Text("Add Reminder").font(.headline)
                Spacer()
            }

            Divider()

            Picker("Type", selection: $pluginId) {
                ForEach(PluginRegistry.all, id: \.id) { plugin in
                    Label(plugin.displayName, systemImage: plugin.iconSystemName).tag(plugin.id)
                }
            }
            .onChange(of: pluginId) { _, _ in resetConfig() }

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
                    .disabled(plugin == nil)
            }
        }
        .padding(12)
        .frame(width: 320)
        .onAppear(perform: resetConfig)
    }

    private func resetConfig() {
        config = plugin?.defaultConfig() ?? [:]
    }

    private func save() {
        guard let plugin else { return }
        let reminder = Reminder(
            pluginId: plugin.id,
            title: title.isEmpty ? plugin.displayName : title,
            config: config
        )
        store.add(reminder)
        onClose()
    }
}
