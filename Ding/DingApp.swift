//
//  DingApp.swift
//  Ding
//

import SwiftUI
import AppKit

@main
struct DingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ReminderStore.shared

    var body: some Scene {
        MenuBarExtra("Ding", systemImage: "bell.badge") {
            // Placeholder menu — the full list / add UI arrives in a later step.
            Text("Ding · \(store.reminders.count) reminder(s)")
            // TEMP: verify the always-on-top popup; removed once the engine drives it.
            Button("Test popup") {
                PopupManager.shared.show(
                    title: "Ding test",
                    body: "This popup floats above everything. Click Got it to dismiss."
                )
            }
            Divider()
            Button("Quit Ding") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

/// Handles imperative startup that SwiftUI's scene graph doesn't cover.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a menu-bar accessory: no Dock icon, no app-switcher entry.
        NSApp.setActivationPolicy(.accessory)
        // ReminderEngine.shared.start() is wired up in a later step.
    }
}
