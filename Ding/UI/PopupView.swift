import SwiftUI

/// The content rendered inside an always-on-top alert panel.
struct PopupView: View {
    let title: String
    let message: String
    let onSnooze: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }

            Text(message)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Snooze 5 min", action: onSnooze)
                Button("Got it", action: onDismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360, height: 180)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }
}
