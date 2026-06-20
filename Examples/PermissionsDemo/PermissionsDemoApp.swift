import AppKit
import MacAgentKit
import SwiftUI

// A tiny menu-bar (agent) app showing a live permission dashboard and a working
// "Toggle Do Not Disturb" button — built entirely on MacAgentKit.
//
// This is an SPM executable for demonstration. To run it as a real background
// menu-bar agent, bundle it as a .app with `LSUIElement = true` and the
// entitlements noted in this folder's README.
@main
struct PermissionsDemoApp: App {
    var body: some Scene {
        MenuBarExtra("MacAgentKit", systemImage: "gearshape.2") {
            DemoView()
        }
        .menuBarExtraStyle(.window)
    }
}

struct DemoView: View {
    @State private var statusMessage = ""
    @State private var isWorking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MacAgentKit Demo")
                .font(.headline)

            Text("Permissions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            PermissionsView([
                .accessibility,
                .screenRecording,
                .inputMonitoring,
            ])

            Divider()

            Button {
                toggleDoNotDisturb()
            } label: {
                Label("Toggle Do Not Disturb", systemImage: "moon.fill")
            }
            .disabled(isWorking)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func toggleDoNotDisturb() {
        isWorking = true
        statusMessage = "Toggling…"
        Task {
            do {
                try await DoNotDisturb.toggle()
                statusMessage = "Do Not Disturb toggled via Control Center."
            } catch {
                statusMessage =
                    "Couldn't toggle via Control Center (\(error)).\nTip: install a Shortcut and use DoNotDisturb.setViaShortcut."
            }
            isWorking = false
        }
    }
}
