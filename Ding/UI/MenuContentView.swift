import SwiftUI

/// The menu-bar panel: a list of reminders with add / toggle / delete,
/// switching inline to the add form (no sheet — unreliable inside MenuBarExtra).
struct MenuContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @State private var adding = false

    var body: some View {
        Group {
            if adding {
                AddReminderView(onClose: { adding = false })
            } else {
                list
            }
        }
        .frame(width: 320)
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Ding").font(.headline)
                Spacer()
                Button { adding = true } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add reminder")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if store.reminders.isEmpty {
                Text("No reminders yet. Tap + to add one.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.reminders) { reminder in
                            ReminderRow(reminder: reminder)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 280)
            }

            Divider()

            Button("Quit Ding") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }
}

/// A single reminder row: icon, title, summary, enable toggle, delete.
private struct ReminderRow: View {
    @EnvironmentObject private var store: ReminderStore
    let reminder: Reminder

    private var plugin: ReminderPlugin? { PluginRegistry.plugin(for: reminder.pluginId) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: plugin?.iconSystemName ?? "bell")
                .foregroundStyle(.orange)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.system(size: 13, weight: .medium))
                Text(plugin?.summary(reminder.config) ?? "Unknown plugin")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { reminder.enabled },
                set: { _ in store.toggle(reminder) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)

            Button { store.delete(reminder) } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Delete")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
