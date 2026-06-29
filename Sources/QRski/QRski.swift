import SwiftUI
import AppKit

@main
struct QRskiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) fileprivate var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup("QRski") {
            ContentView()
                .environment(appState)
                .frame(minWidth: 700, minHeight: 450)
                .task { UpdateChecker.shared.check(silent: true) }
        }
        .windowResizability(.contentMinSize)
        .commands {
            AppCommands()
        }
    }
}

private class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}
