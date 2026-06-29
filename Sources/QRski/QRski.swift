import SwiftUI

@main
struct QRskiApp: App {
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
