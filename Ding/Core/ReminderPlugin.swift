import SwiftUI

/// Content shown in the popup when a reminder fires.
struct TriggerResult {
    let title: String
    let body: String
}

/// Context passed to a plugin on each evaluation tick.
struct EvalContext {
    let now: Date
}

/// Result of evaluating a single reminder.
///
/// Edge-triggered semantics: the `triggered` flag lives on `Reminder` and is
/// persisted by the engine, so a condition that stays true won't fire repeatedly.
enum EvalOutcome {
    /// Condition became true (rising edge): fire; the reminder stays active and
    /// re-arms once the condition later clears (`.rearm`).
    case fire(TriggerResult)
    /// Fire once, then disable this reminder permanently (one-shot).
    case fireOnce(TriggerResult)
    /// Condition cleared: reset `triggered` so it can fire again later.
    case rearm
    /// Nothing to do this tick.
    case none
}

/// A reminder type. Adding a new kind of reminder == implement this protocol
/// and register an instance in `PluginRegistry`.
///
/// Config is carried as `[String: String]` and parsed by the plugin itself —
/// simple and trivially Codable. Each plugin ships its own SwiftUI config view,
/// so users add and tune reminders from the menu-bar UI.
protocol ReminderPlugin {
    /// Stable identifier, e.g. "time" / "crypto_price". Used for persistence/lookup.
    var id: String { get }
    /// Human-readable name, e.g. "Time".
    var displayName: String { get }
    /// SF Symbol name used as the icon.
    var iconSystemName: String { get }

    /// Default config for a newly created reminder.
    func defaultConfig() -> [String: String]

    /// Short, human-readable summary of a configured reminder (shown in the list).
    func summary(_ config: [String: String]) -> String

    /// The plugin's config editor, bound to the reminder's config dictionary.
    func configView(_ config: Binding<[String: String]>) -> AnyView

    /// Evaluate whether this reminder should fire now. May be async (e.g. network).
    func evaluate(_ reminder: Reminder, _ ctx: EvalContext) async -> EvalOutcome
}
