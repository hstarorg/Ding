import Foundation

/// A configured reminder instance, driven by exactly one plugin.
struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// Identifier of the plugin that drives this reminder.
    var pluginId: String
    /// User-facing name.
    var title: String
    /// Plugin-private config, parsed by the owning plugin.
    var config: [String: String]
    /// Whether the reminder is active.
    var enabled: Bool = true
    /// Edge-trigger state: whether it is currently in the "fired" state.
    /// Prevents repeated popups while a condition stays satisfied.
    var triggered: Bool = false
    /// Timestamp of the last fire, if any.
    var lastFired: Date? = nil
}
