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
            MenuContentView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Handles imperative startup that SwiftUI's scene graph doesn't cover.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a menu-bar accessory: no Dock icon, no app-switcher entry.
        NSApp.setActivationPolicy(.accessory)
        // Start the evaluation loop that drives reminders.
        ReminderEngine.shared.start()
    }
}
