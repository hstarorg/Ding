import Foundation

/// Registry of all available plugins.
///
/// To add a plugin: implement `ReminderPlugin`, then append an instance to `all`.
/// Concrete plugins are wired in later steps:
///   - `TimeReminderPlugin()`        (Step 5)
///   - `CryptoPriceReminderPlugin()` (Step 6)
enum PluginRegistry {
    static let all: [ReminderPlugin] = [
        TimeReminderPlugin(),
        // CryptoPriceReminderPlugin(), // added in Step 6
    ]

    static func plugin(for id: String) -> ReminderPlugin? {
        all.first { $0.id == id }
    }
}
