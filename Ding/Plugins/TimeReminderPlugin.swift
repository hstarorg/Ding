import SwiftUI

/// Fires at a chosen time of day — either once or every day.
///
/// Config keys: `hour`, `minute`, `repeat` ("once" | "daily").
struct TimeReminderPlugin: ReminderPlugin {
    let id = "time"
    let displayName = "Time"
    let iconSystemName = "clock"

    func defaultConfig() -> [String: String] {
        ["hour": "9", "minute": "0", "repeat": "once"]
    }

    func summary(_ config: [String: String]) -> String {
        let hour = Int(config["hour"] ?? "") ?? 0
        let minute = Int(config["minute"] ?? "") ?? 0
        let time = String(format: "%02d:%02d", hour, minute)
        return config["repeat"] == "daily" ? "Every day at \(time)" : "Once at \(time)"
    }

    func configView(_ config: Binding<[String: String]>) -> AnyView {
        AnyView(TimeConfigView(config: config))
    }

    func evaluate(_ reminder: Reminder, _ ctx: EvalContext) async -> EvalOutcome {
        let hour = Int(reminder.config["hour"] ?? "") ?? -1
        let minute = Int(reminder.config["minute"] ?? "") ?? -1

        let calendar = Calendar.current
        let now = calendar.dateComponents([.hour, .minute], from: ctx.now)
        guard now.hour == hour, now.minute == minute else { return .none }

        // Don't fire twice within the same minute.
        if let last = reminder.lastFired,
           calendar.isDate(last, equalTo: ctx.now, toGranularity: .minute) {
            return .none
        }

        let result = TriggerResult(
            title: reminder.title.isEmpty ? displayName : reminder.title,
            body: "It's \(String(format: "%02d:%02d", hour, minute))."
        )
        // Daily reminders stay enabled and fire again tomorrow; once-only disable.
        return reminder.config["repeat"] == "daily" ? .fire(result) : .fireOnce(result)
    }
}

/// Config editor for `TimeReminderPlugin`.
private struct TimeConfigView: View {
    @Binding var config: [String: String]

    var body: some View {
        DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
        Picker("Repeat", selection: repeatBinding) {
            Text("Once").tag("once")
            Text("Every day").tag("daily")
        }
        .pickerStyle(.segmented)
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = Int(config["hour"] ?? "9") ?? 9
                components.minute = Int(config["minute"] ?? "0") ?? 0
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                config["hour"] = String(components.hour ?? 0)
                config["minute"] = String(components.minute ?? 0)
            }
        )
    }

    private var repeatBinding: Binding<String> {
        Binding(
            get: { config["repeat"] ?? "once" },
            set: { config["repeat"] = $0 }
        )
    }
}
