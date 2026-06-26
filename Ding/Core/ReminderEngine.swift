import Foundation

/// Periodically evaluates all enabled reminders and fires popups on rising edges.
///
/// One timer ticks every few seconds; each enabled reminder is handed to its
/// plugin's `evaluate`. The engine owns the edge-trigger state transitions
/// (`triggered`, `lastFired`, one-shot disabling) and stays plugin-agnostic.
@MainActor
final class ReminderEngine {
    static let shared = ReminderEngine()

    private static let interval: TimeInterval = 5

    private let store = ReminderStore.shared
    private var timer: Timer?
    private var isTicking = false

    func start() {
        guard timer == nil else { return }
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func tick() {
        // Skip if a previous async tick is still running (network calls may suspend).
        guard !isTicking else { return }
        isTicking = true
        Task { @MainActor in
            defer { isTicking = false }
            let ctx = EvalContext(now: Date())
            // Iterate a snapshot; store mutations during the loop are id-based and safe.
            for reminder in store.reminders where reminder.enabled {
                guard let plugin = PluginRegistry.plugin(for: reminder.pluginId) else { continue }
                switch await plugin.evaluate(reminder, ctx) {
                case .fire(let result):
                    fire(reminder, result, disable: false)
                case .fireOnce(let result):
                    fire(reminder, result, disable: true)
                case .rearm:
                    rearm(reminder)
                case .none:
                    break
                }
            }
        }
    }

    private func fire(_ reminder: Reminder, _ result: TriggerResult, disable: Bool) {
        PopupManager.shared.show(title: result.title, body: result.body)
        var updated = reminder
        updated.triggered = true
        updated.lastFired = Date()
        if disable { updated.enabled = false }
        store.update(updated)
    }

    private func rearm(_ reminder: Reminder) {
        var updated = reminder
        updated.triggered = false
        store.update(updated)
    }
}
