import AppKit
import SwiftUI

/// Shows always-on-top alert panels when reminders fire.
///
/// Each popup is a borderless, non-activating `NSPanel` floating above other
/// apps (including full-screen ones), hosting a SwiftUI `PopupView`.
@MainActor
final class PopupManager {
    static let shared = PopupManager()

    private static let panelSize = NSSize(width: 360, height: 180)

    private var panels: [NSPanel] = []

    func show(title: String, body: String) {
        let size = Self.panelSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        let dismiss: () -> Void = { [weak self] in self?.close(panel) }
        let snooze: () -> Void = { [weak self] in
            self?.close(panel)
            self?.scheduleResnooze(title: title, body: body)
        }

        let host = NSHostingView(
            rootView: PopupView(title: title, message: body, onSnooze: snooze, onDismiss: dismiss)
        )
        host.frame = NSRect(origin: .zero, size: size)
        panel.contentView = host

        positionPanel(panel, size: size)
        panel.orderFrontRegardless()
        NSSound(named: "Glass")?.play()
        panels.append(panel)
    }

    private func close(_ panel: NSPanel) {
        panel.orderOut(nil)
        panels.removeAll { $0 === panel }
    }

    /// Re-show the same alert after a fixed snooze interval.
    private func scheduleResnooze(title: String, body: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5 * 60) { [weak self] in
            self?.show(title: title, body: body)
        }
    }

    /// Center the panel, cascading additional panels so they don't fully overlap.
    private func positionPanel(_ panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let offset = CGFloat(panels.count) * 24
        let x = visible.midX - size.width / 2 + offset
        let y = visible.midY - size.height / 2 - offset
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
