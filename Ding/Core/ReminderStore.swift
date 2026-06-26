import Foundation
import Combine

/// Holds all configured reminders and persists them to disk as JSON.
///
/// Single source of truth shared by the UI (reads) and the engine (mutations).
/// Under App Sandbox the file lands in the app container automatically.
@MainActor
final class ReminderStore: ObservableObject {
    static let shared = ReminderStore()

    @Published private(set) var reminders: [Reminder] = []

    private let fileURL: URL

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("Ding", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("reminders.json")
        load()
    }

    // MARK: - Mutations

    func add(_ reminder: Reminder) {
        reminders.append(reminder)
        save()
    }

    func update(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index] = reminder
        save()
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        save()
    }

    /// Toggle enabled state and re-arm the edge trigger.
    func toggle(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].enabled.toggle()
        reminders[index].triggered = false
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Reminder].self, from: data)
        else { return }
        reminders = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
